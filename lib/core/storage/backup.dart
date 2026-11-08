import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import 'database.dart';
import 'repository.dart';

const backupTables = [
  'games',
  'nodes',
  'analysis',
  'repertoires',
  'cards',
  'puzzles',
  'packs',
  'attempts',
  'preferences',
];

class BackupService {
  BackupService(this.db);
  final AppDatabase db;
  Future<Uint8List> export() async {
    final data = <String, dynamic>{};
    await db.transaction(() async {
      for (final table in backupTables) {
        data[table] = await db.rows('SELECT * FROM $table');
      }
    });
    final bytes = utf8.encode(jsonEncode(data));
    final manifest = utf8.encode(
      jsonEncode({
        'format': 1,
        'schema': 1,
        'created': DateTime.now().toUtc().toIso8601String(),
        'sha256': sha256.convert(bytes).toString(),
      }),
    );
    final archive = Archive()
      ..addFile(ArchiveFile('manifest.json', manifest.length, manifest))
      ..addFile(ArchiveFile('data.json', bytes.length, bytes));
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Map<String, dynamic> validate(Uint8List bytes) {
    if (bytes.length > 250 * 1024 * 1024) {
      throw FormatException('Backup exceeds 250 MB');
    }
    final decoder = ZipDecoder();
    final archive = decoder.decodeBytes(bytes, verify: true);
    if (decoder.directory.fileHeaders.length != 2) {
      throw const FormatException("Duplicate or unexpected entries");
    }
    var expanded = 0;
    for (final f in archive) {
      expanded += f.size;
      if (expanded > 1024 * 1024 * 1024) {
        throw FormatException('Backup exceeds expanded limit');
      }
      if (!['manifest.json', 'data.json'].contains(f.name) || !f.isFile) {
        throw FormatException('Unexpected archive entry');
      }
    }
    if (archive.length != 2) throw FormatException('Missing backup files');
    final manifest = jsonDecode(
      utf8.decode(archive.findFile('manifest.json')!.content),
    );
    final data = archive.findFile('data.json')!.content;
    if (manifest['format'] != 1 || manifest['schema'] != 1) {
      throw FormatException('Unsupported backup version');
    }
    if (sha256.convert(data).toString() != manifest['sha256']) {
      throw FormatException('Backup checksum mismatch');
    }
    final payload = Map<String, dynamic>.from(jsonDecode(utf8.decode(data)));
    if (payload.keys.toSet().difference(backupTables.toSet()).isNotEmpty ||
        backupTables.any((t) => payload[t] is! List)) {
      throw FormatException('Invalid table set');
    }
    return payload;
  }

  Future<void> restore(Uint8List bytes) async {
    final payload = validate(bytes);
    final staging = AppDatabase.memory();
    try {
      await _insert(staging, payload);
      final repo = Repository(staging);
      for (final row in await repo.games()) {
        final game = await repo.load(row['id']);
        game.at(null);
        for (final node in game.nodes) {
          game.at(node.id);
        }
        if (game.current != null) game.at(game.current);
      }
      final check = await staging.rows('PRAGMA foreign_key_check');
      if (check.isNotEmpty) throw FormatException('Broken backup references');
      // Crash-report choice belongs to this device, not to the backup.
      final deviceChoice = await db.rows(
        'SELECT value FROM preferences WHERE "key"=?',
        ['crashReports'],
      );
      await db.transaction(() async {
        for (final table in backupTables.reversed) {
          await db.execute('DELETE FROM $table');
        }
        await _insert(db, payload);
        await db.execute('DELETE FROM preferences WHERE "key"=?', [
          'crashReports',
        ]);
        if (deviceChoice.isNotEmpty) {
          await db.execute('INSERT INTO preferences VALUES(?,?)', [
            'crashReports',
            deviceChoice.first['value'],
          ]);
        }
      });
    } finally {
      await staging.close();
    }
  }

  Future<void> _insert(AppDatabase target, Map<String, dynamic> payload) async {
    for (final table in backupTables) {
      final columns = (await target.rows('PRAGMA table_info($table)'))
          .map((r) => r['name'] as String)
          .toSet();
      final rows = List<Map<String, dynamic>>.from(
        (payload[table] as List).map((r) => Map<String, dynamic>.from(r)),
      );
      // Export preserves insertion order; node parents precede their children.
      for (final row in rows) {
        if (row.keys.any((k) => !columns.contains(k))) {
          throw FormatException('Unknown column');
        }
        await target.execute(
          'INSERT INTO $table (${row.keys.map((k) => '"$k"').join(',')}) VALUES (${List.filled(row.length, '?').join(',')})',
          row.values.toList(),
        );
      }
    }
  }
}
