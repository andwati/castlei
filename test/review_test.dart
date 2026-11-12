import 'dart:convert';

import 'package:castlei/core/chess/model.dart';
import 'package:castlei/core/ui/theme.dart';
import 'package:castlei/features/analysis/eval_graph.dart';
import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> row(
  String id,
  String san,
  int score,
  bool mate,
  String label,
) => {
  'id': id,
  'san': san,
  'data': jsonEncode({
    'best': {'score': score, 'mate': mate},
    'played': {'score': score, 'mate': mate},
    'label': label,
  }),
};

void main() {
  final g = ChessGame.importPgn(PgnGame.parsePgn('1. e4 e5 2. Nf3 Nc6 *'));
  final ids = g.mainline.map((n) => n.id).toList();

  test('evaluations are normalised to White\'s perspective', () {
    final points = parseReview([
      row(ids[0], 'e4', 30, false, 'Good'), // white moved, +0.30 for white
      row(
        ids[1],
        'e5',
        30,
        false,
        'Good',
      ), // black moved, +0.30 for black = -0.30
      row(ids[2], 'Nf3', 3, true, 'Forced mate'), // white mates in 3
      row(
        ids[3],
        'Nc6',
        2,
        true,
        'Allowed Forced Mate',
      ), // black mates in 2 = bad for white
    ], g);
    expect(points.map((p) => p.ply), [1, 2, 3, 4]);
    expect(points[0].whitePawns, closeTo(.3, 1e-9));
    expect(points[1].whitePawns, closeTo(-.3, 1e-9));
    expect(points[2].whitePawns, 10);
    expect(points[3].whitePawns, -10);
    expect(points[0].evalText, '+0.3');
    expect(points[1].evalText, '-0.3');
    expect(points[2].evalText, 'M3');
    expect(points[3].evalText, 'M2');
  });

  test('quality marks are text, not colour alone', () {
    expect(badgeFor('Inaccuracy'), '?!');
    expect(badgeFor('Mistake'), '?');
    expect(badgeFor('Blunder'), '??');
    expect(badgeFor('Missed Forced Mate'), 'M?');
    expect(badgeFor('Allowed Forced Mate'), '??M');
    expect(badgeFor('Good'), '');
    expect(badgeFor('Engine best'), '');
  });

  testWidgets('graph renders with an accessible summary', (t) async {
    final handle = t.ensureSemantics();
    final points = parseReview([
      row(ids[0], 'e4', 30, false, 'Good'),
      row(ids[1], 'e5', -250, false, 'Blunder'),
      row(ids[2], 'Nf3', 80, false, 'Mistake'),
      row(ids[3], 'Nc6', 10, false, 'Inaccuracy'),
    ], g);
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: EvalGraph(
            points: points,
            selectedNodeId: ids[1],
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byType(EvalGraph), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp('Evaluation graph. 1 blunder, 1 mistake, 1 inaccuracy'),
      ),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
    handle.dispose();
  });
}
