import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../diagnostics/analytics.dart';
import '../diagnostics/crash.dart';
import '../storage/backup.dart';
import '../storage/repository.dart';
import 'account.dart';
import 'remote_config.dart';

class CloudBackupEntry {
  CloudBackupEntry({
    required this.id,
    required this.created,
    required this.bytes,
    required this.games,
    required this.chunks,
    required this.sha256,
  });
  final String id, sha256;
  final DateTime created;
  final int bytes, games, chunks;
}

/// Pure retention rule: keep the newest [keep] ids (ids are creation millis).
List<String> backupsToDelete(List<String> ids, {int keep = 5}) {
  final sorted = [...ids]..sort((a, b) => b.compareTo(a));
  return sorted.length <= keep ? [] : sorted.sublist(keep);
}

/// Splits [data] into pieces of at most [size] bytes.
List<Uint8List> splitChunks(
  Uint8List data, {
  int size = CloudBackup.chunkSize,
}) => [
  for (var i = 0; i < data.length; i += size)
    Uint8List.sublistView(
      data,
      i,
      i + size > data.length ? data.length : i + size,
    ),
];

/// Joins chunks back together, verifying length and SHA-256.
Uint8List joinChunks(
  List<Uint8List> chunks, {
  required int bytes,
  required String sha256Hex,
}) {
  final out = BytesBuilder(copy: false);
  for (final c in chunks) {
    out.add(c);
  }
  final data = out.takeBytes();
  if (data.length != bytes) {
    throw StateError('The cloud backup is incomplete.');
  }
  if (sha256.convert(data).toString() != sha256Hex) {
    throw StateError('The cloud backup failed its integrity check.');
  }
  return data;
}

/// Automatic cloud backup of the full app backup to the signed-in user's
/// private Firestore area (free plan friendly: the archive is split into
/// ~700 KB chunks). Runs after finished games and at most daily, on Wi-Fi only;
/// "Back up now" always works. Keeps the last 5 versions.
class CloudBackup {
  static const keep = 5;
  static const chunkSize = 700 * 1024;
  static const maxBytes = 12 * 1024 * 1024;
  static const minGap = Duration(hours: 3);
  static Repository? _repo;
  static Timer? _debounce;
  static bool _running = false;
  static String status = '';
  static final changed = ValueNotifier<int>(0);

  static CollectionReference<Map<String, dynamic>>? get _backups {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null
        ? null
        : FirebaseFirestore.instance.collection('users/$uid/backups');
  }

  static bool get available => AccountService.instance.signedIn;

  /// Backups are uploaded only on Wi-Fi, so keep Firestore from queueing
  /// writes offline and sending them later over mobile data.
  static void configure() {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    } catch (_) {}
  }

  /// Watches for changes and tries a backup when the app returns after a day.
  static void attach(Repository repo) {
    _repo?.changes.removeListener(_markDirty);
    _repo = repo;
    repo.changes.addListener(_markDirty);
    AccountService.instance.addListener(() {
      if (AccountService.instance.signedIn) {
        maybeAutoBackup(reason: 'signed_in');
      }
    });
  }

  static Future<void> _markDirty() async {
    final repo = _repo;
    if (repo == null) return;
    try {
      if (await repo.preference('cloudDirtySince', 0) == 0) {
        await repo.setPreference(
          'cloudDirtySince',
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (_) {
      // Background bookkeeping must never surface as an unhandled error
      // (for example if the database was closed during a restore).
    }
  }

  /// Call when a game finishes: schedules a backup shortly after.
  static void scheduleSoon() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(seconds: 45),
      () => maybeAutoBackup(reason: 'game_finished', force: true),
    );
  }

  static Future<bool> _onWifi() async {
    final r = await Connectivity().checkConnectivity();
    return r.contains(ConnectivityResult.wifi) ||
        r.contains(ConnectivityResult.ethernet);
  }

  static Future<void> maybeAutoBackup({
    required String reason,
    bool force = false,
  }) async {
    final repo = _repo;
    if (repo == null || !available || _running) return;
    if (!RemoteSettings.cloudBackupEnabled) return;
    try {
      if (await repo.preference('cloudBackup', true) != true) return;
      final last = await repo.preference('lastCloudBackup', 0) as int;
      final dirty = await repo.preference('cloudDirtySince', 0) as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (dirty == 0 && last != 0) return; // nothing changed since last backup
      final gap = Duration(milliseconds: now - last);
      if (!force && last != 0 && gap < const Duration(hours: 24)) return;
      if (force && gap < minGap) return;
      if (!await _onWifi()) return; // retried on the next trigger
      await backupNow(reason: reason);
    } catch (_) {
      // Automatic backup is best effort; failures are retried on the next trigger.
    }
  }

  /// Uploads a backup immediately. Returns null on success or a message.
  static Future<String?> backupNow({String reason = 'manual'}) async {
    final repo = _repo;
    final backups = _backups;
    if (repo == null || backups == null) {
      return 'Sign in to back up to the cloud.';
    }
    if (_running) return 'A backup is already running.';
    _running = true;
    try {
      final bytes = await BackupService(repo.db).export();
      if (bytes.length > maxBytes) {
        return 'This backup (${(bytes.length / 1048576).toStringAsFixed(1)} MB) is too large for free cloud storage. Export a file instead.';
      }
      final games = (await repo.games()).length;
      final id = '${DateTime.now().millisecondsSinceEpoch}';
      final doc = backups.doc(id);
      final chunks = splitChunks(bytes);
      for (var i = 0; i < chunks.length; i++) {
        await doc.collection('chunks').doc('$i').set({
          'i': i,
          'data': Blob(chunks[i]),
        });
      }
      // The metadata document is written last: an interrupted upload is never listed.
      await doc.set({
        'created': int.parse(id),
        'games': games,
        'app': appVersion,
        'reason': reason,
        'bytes': bytes.length,
        'chunks': chunks.length,
        'sha256': sha256.convert(bytes).toString(),
      });
      await _prune(backups);
      await repo.setPreference(
        'lastCloudBackup',
        DateTime.now().millisecondsSinceEpoch,
      );
      await repo.setPreference('cloudDirtySince', 0);
      status = 'Backed up';
      changed.value++;
      Analytics.log('cloud_backup', {'result': 'ok', 'reason': reason});
      return null;
    } on FirebaseException catch (e) {
      status = e.code;
      Analytics.log('cloud_backup', {'result': 'error', 'reason': reason});
      CrashReporting.nonFatal('cloud_backup', e, StackTrace.current);
      return switch (e.code) {
        'permission-denied' =>
          'Cloud backup is not allowed for this account yet (security rules).',
        'not-found' || 'failed-precondition' =>
          'Cloud database is not set up for this project yet.',
        'unavailable' =>
          'Could not reach the cloud. Try again on a good connection.',
        _ => 'Cloud backup failed (${e.code}).',
      };
    } catch (e, st) {
      CrashReporting.nonFatal('cloud_backup', e, st);
      return 'Cloud backup failed.';
    } finally {
      _running = false;
    }
  }

  static Future<void> _deleteBackup(
    CollectionReference<Map<String, dynamic>> backups,
    String id,
  ) async {
    final doc = backups.doc(id);
    final chunks = await doc.collection('chunks').get();
    for (final c in chunks.docs) {
      await c.reference.delete();
    }
    await doc.delete();
  }

  static Future<void> _prune(
    CollectionReference<Map<String, dynamic>> backups,
  ) async {
    final ids = (await backups.get()).docs.map((d) => d.id).toList();
    for (final old in backupsToDelete(ids, keep: keep)) {
      await _deleteBackup(backups, old);
    }
  }

  static Future<List<CloudBackupEntry>> list() async {
    final backups = _backups;
    if (backups == null) return [];
    final snap = await backups
        .orderBy('created', descending: true)
        .limit(keep)
        .get();
    return [
      for (final d in snap.docs)
        CloudBackupEntry(
          id: d.id,
          created: DateTime.fromMillisecondsSinceEpoch(
            (d['created'] as num).toInt(),
          ),
          bytes: (d['bytes'] as num).toInt(),
          games: (d['games'] as num).toInt(),
          chunks: (d['chunks'] as num).toInt(),
          sha256: d['sha256'] as String,
        ),
    ];
  }

  static Future<Uint8List> download(CloudBackupEntry e) async {
    final backups = _backups;
    if (backups == null) throw StateError('Sign in to restore from the cloud.');
    final snap = await backups
        .doc(e.id)
        .collection('chunks')
        .orderBy('i')
        .get();
    if (snap.docs.length != e.chunks) {
      throw StateError('The cloud backup is incomplete.');
    }
    return joinChunks(
      [
        for (final d in snap.docs)
          Uint8List.fromList((d['data'] as Blob).bytes),
      ],
      bytes: e.bytes,
      sha256Hex: e.sha256,
    );
  }

  /// Deletes every cloud backup for this account (used before account deletion).
  static Future<void> deleteAll() async {
    final backups = _backups;
    if (backups == null) return;
    for (final d in (await backups.get()).docs) {
      await _deleteBackup(backups, d.id);
    }
  }
}
