import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../diagnostics/analytics.dart';
import '../diagnostics/crash.dart';
import '../storage/backup.dart';
import '../storage/repository.dart';
import 'account.dart';
import 'remote_config.dart';

class CloudBackupEntry {
  CloudBackupEntry(this.ref, this.created, this.bytes, this.games);
  final Reference ref;
  final DateTime created;
  final int bytes, games;
}

/// Pure retention rule: keep the newest [keep] names (timestamps in the name).
List<String> backupsToDelete(List<String> names, {int keep = 5}) {
  final sorted = [...names]..sort((a, b) => b.compareTo(a));
  return sorted.length <= keep ? [] : sorted.sublist(keep);
}

/// Automatic cloud backup of the full app backup to the signed-in user's
/// private Storage folder. Runs after finished games and at most daily,
/// on Wi-Fi only; "Back up now" always works. Keeps the last 5 versions.
class CloudBackup {
  static const keep = 5;
  static const minGap = Duration(hours: 3);
  static Repository? _repo;
  static Timer? _debounce;
  static bool _running = false;
  static String status = '';
  static final changed = ValueNotifier<int>(0);

  static Reference? get _dir {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null
        ? null
        : FirebaseStorage.instance.ref('users/$uid/backups');
  }

  static bool get available => AccountService.instance.signedIn;

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
    final dir = _dir;
    if (repo == null || dir == null) return 'Sign in to back up to the cloud.';
    if (_running) return 'A backup is already running.';
    _running = true;
    try {
      final bytes = await BackupService(repo.db).export();
      final games = (await repo.games()).length;
      final name = '${DateTime.now().millisecondsSinceEpoch}.zip';
      await dir
          .child(name)
          .putData(
            bytes,
            SettableMetadata(
              contentType: 'application/zip',
              customMetadata: {
                'games': '$games',
                'app': appVersion,
                'reason': reason,
              },
            ),
          );
      final names = (await dir.listAll()).items.map((e) => e.name).toList();
      for (final old in backupsToDelete(names, keep: keep)) {
        await dir.child(old).delete();
      }
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
      return e.code == 'object-not-found' || e.code == 'bucket-not-found'
          ? 'Cloud storage is not set up for this project yet.'
          : 'Cloud backup failed (${e.code}).';
    } catch (e, st) {
      CrashReporting.nonFatal('cloud_backup', e, st);
      return 'Cloud backup failed.';
    } finally {
      _running = false;
    }
  }

  static Future<List<CloudBackupEntry>> list() async {
    final dir = _dir;
    if (dir == null) return [];
    final items = (await dir.listAll()).items;
    final out = <CloudBackupEntry>[];
    for (final ref in items) {
      final meta = await ref.getMetadata();
      final ms = int.tryParse(ref.name.split('.').first) ?? 0;
      out.add(
        CloudBackupEntry(
          ref,
          DateTime.fromMillisecondsSinceEpoch(ms),
          meta.size ?? 0,
          int.tryParse(meta.customMetadata?['games'] ?? '') ?? 0,
        ),
      );
    }
    out.sort((a, b) => b.created.compareTo(a.created));
    return out;
  }

  static Future<Uint8List> download(CloudBackupEntry e) async {
    final data = await e.ref.getData(250 * 1024 * 1024);
    if (data == null) throw StateError('The backup could not be downloaded.');
    return data;
  }

  /// Deletes every cloud backup for this account (used before account deletion).
  static Future<void> deleteAll() async {
    final dir = _dir;
    if (dir == null) return;
    for (final item in (await dir.listAll()).items) {
      await item.delete();
    }
  }
}
