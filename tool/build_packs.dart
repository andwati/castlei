import 'dart:convert';
import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/build_packs.dart dataset.csv');
    exitCode = 64;
    return;
  }
  final selected = <Map<String, dynamic>>[];
  var rejected = 0;
  final buckets = <int, int>{};
  await for (final line in File(
    args[0],
  ).openRead().transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.startsWith('PuzzleId')) continue;
    final f = line.split(',');
    if (f.length < 8) continue;
    try {
      final rating = int.parse(f[3]);
      final band = (rating ~/ 500).clamp(0, 5);
      if ((buckets[band] ?? 0) >= 1000) continue;
      Position p = Chess.fromSetup(Setup.parseFen(f[1]));
      final moves = f[2].split(' ');
      p = p.play(Move.parse(moves.first)!);
      final fen = p.fen;
      for (final m in moves.skip(1)) {
        p = p.play(Move.parse(m)!);
      }
      selected.add({
        'id': f[0],
        'fen': fen,
        'moves': moves.skip(1).toList(),
        'rating': rating,
        'themes': f[7],
      });
      buckets[band] = (buckets[band] ?? 0) + 1;
    } catch (_) {
      rejected++;
    }
    if (selected.length == 6000) break;
  }
  if (selected.length < 1000) throw StateError('Insufficient valid puzzles');
  // Deterministically interleave difficulty bands before splitting packs.
  selected.sort((a, b) {
    final mod = (a['rating'] as int) % 500 - (b['rating'] as int) % 500;
    return mod != 0 ? mod : (a['id'] as String).compareTo(b['id']);
  });
  await Directory('assets/puzzles').create(recursive: true);
  await Directory('catalog/packs').create(recursive: true);
  await File('assets/puzzles/starter.json')
      .writeAsString(jsonEncode(selected.take(1000).toList()));
  final remaining = selected.skip(1000).take(5000).toList();
  final data = utf8.encode(remaining.map(jsonEncode).join('\n'));
  final manifest = {
    'schema': 1,
    'id': 'mixed-01',
    'version': 1,
    'count': remaining.length,
    'source': 'https://database.lichess.org/',
    'license': 'CC0-1.0',
  };
  final meta = utf8.encode(jsonEncode(manifest));
  final zip = ZipEncoder().encode(
    Archive()
      ..addFile(ArchiveFile('manifest.json', meta.length, meta))
      ..addFile(ArchiveFile('puzzles.jsonl', data.length, data)),
  );
  await File('catalog/packs/mixed-01.zip').writeAsBytes(zip);
  await File('catalog/catalog.json').writeAsString(
    jsonEncode({
      'schema': 1,
      'packs': [
        {
          ...manifest,
          'title': 'Mixed tactics · collection 1',
          'url': 'packs/mixed-01.zip',
          'bytes': zip.length,
          'expandedBytes': data.length + meta.length,
          'sha256': sha256.convert(zip).toString(),
        },
      ],
    }),
  );
  await File('docs/PUZZLE_PROVENANCE.json').writeAsString(
    jsonEncode({
      'source': 'https://database.lichess.org/lichess_db_puzzle.csv.zst',
      'csvSha256': (await sha256.bind(File(args[0]).openRead()).first)
          .toString(),
      'selected': selected.length,
      'rejected': rejected,
      'bands': buckets.map((k, v) => MapEntry('$k', v)),
    }),
  );
  stdout.writeln(
    'Generated ${selected.length} validated puzzles; rejected $rejected.',
  );
}
