// Builds assets/openings.json from the CC0 lichess-org/chess-openings TSV files.
//   for f in a b c d e; do curl -sLO https://raw.githubusercontent.com/lichess-org/chess-openings/master/$f.tsv; done
//   dart run tool/build_openings.dart DIR_WITH_TSVS
import 'dart:convert';
import 'dart:io';

import 'package:castlei/core/chess/model.dart';
import 'package:dartchess/dartchess.dart' hide File;

void main(List<String> args) {
  final dir = Directory(args.single);
  final out = <List<String>>[];
  final seen = <String>{};
  var skipped = 0;
  for (final letter in ['a', 'b', 'c', 'd', 'e']) {
    final lines = File('${dir.path}/$letter.tsv').readAsLinesSync().skip(1);
    for (final line in lines) {
      final cols = line.split('\t');
      if (cols.length < 3) continue;
      try {
        Position p = Chess.initial;
        for (final node in PgnGame.parsePgn('${cols[2]} *').moves.mainline()) {
          p = p.play(p.parseSan(node.san)!);
        }
        final key = positionKey(p);
        // First entry wins; transpositions keep the earliest (most general) name.
        if (seen.add(key)) out.add([key, cols[0], cols[1]]);
      } catch (_) {
        skipped++;
      }
    }
  }
  File('assets/openings.json').writeAsStringSync(jsonEncode(out));
  stdout.writeln('${out.length} positions written, $skipped skipped');
}
