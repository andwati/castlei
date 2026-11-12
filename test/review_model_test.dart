import 'dart:convert';

import 'package:castlei/core/chess/model.dart';
import 'package:castlei/features/analysis/review_model.dart';
import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> row(
  String id,
  String san,
  String label, {
  int best = 30,
  int played = 30,
  bool bestMate = false,
  bool playedMate = false,
  List<String> pv = const ['e2e4'],
}) => {
  'id': id,
  'san': san,
  'data': jsonEncode({
    'best': {'score': best, 'mate': bestMate, 'pv': pv},
    'played': {'score': played, 'mate': playedMate},
    'label': label,
  }),
};

void main() {
  final g = ChessGame.importPgn(
    PgnGame.parsePgn('1. e4 e5 2. Qh5 Nc6 3. Bc4 Nf6 *'),
  );
  final ids = g.mainline.map((n) => n.id).toList();

  test('labels map to qualities and key moments', () {
    expect(MoveQuality.fromLabel('Engine best'), MoveQuality.best);
    expect(MoveQuality.fromLabel('Blunder').isKeyMoment, isTrue);
    expect(MoveQuality.fromLabel('Inaccuracy').isKeyMoment, isFalse);
    expect(MoveQuality.fromLabel('Inaccuracy').isSlip, isTrue);
    expect(MoveQuality.fromLabel('Good').isSlip, isFalse);
    expect(MoveQuality.fromLabel('anything else'), MoveQuality.uncertain);
  });

  test('accuracy is 100 for the best move and falls with the loss', () {
    final same = moveAccuracy(
      bestScore: 50,
      bestMate: false,
      playedScore: 50,
      playedMate: false,
    );
    final slip = moveAccuracy(
      bestScore: 50,
      bestMate: false,
      playedScore: -100,
      playedMate: false,
    );
    final blunder = moveAccuracy(
      bestScore: 300,
      bestMate: false,
      playedScore: -600,
      playedMate: false,
    );
    expect(same, closeTo(100, .01));
    expect(slip, lessThan(same));
    expect(blunder, lessThan(slip));
    expect(blunder, greaterThanOrEqualTo(0));
    // Playing a better move than the engine found never exceeds 100.
    expect(
      moveAccuracy(
        bestScore: 10,
        bestMate: false,
        playedScore: 90,
        playedMate: false,
      ),
      lessThanOrEqualTo(100),
    );
  });

  test('a review reads the rows, orders them and totals per side', () {
    final review = buildReview(
      [
        row(ids[3], 'Nc6', 'Good'),
        row(ids[0], 'e4', 'Engine best'),
        row(ids[1], 'e5', 'Good'),
        row(ids[2], 'Qh5', 'Blunder', best: 40, played: -300, pv: ['g1f3']),
      ],
      g,
      player: Side.white,
    );
    expect(review.moves.map((m) => m.ply), [1, 2, 3, 4]);
    expect(review.moves[2].numbered, '2. Qh5');
    expect(review.moves[3].numbered, '2... Nc6');
    expect(review.moves[2].bestUci, 'g1f3');
    expect(review.moves[2].quality, MoveQuality.blunder);
    expect(review.counts(Side.white)[MoveQuality.blunder], 1);
    expect(review.counts(Side.black)[MoveQuality.blunder], isNull);
    expect(
      review.accuracy(Side.white)!,
      lessThan(review.accuracy(Side.black)!),
    );
    // The player's blunder is the only key moment.
    expect(review.keyMoments(), [2]);
    expect(
      review.coachLine(),
      '1 blunder cost you the most. Let’s look at it.',
    );
  });

  test('key moments fall back to small slips, then to nothing', () {
    final slips = buildReview(
      [row(ids[0], 'e4', 'Inaccuracy'), row(ids[1], 'e5', 'Good')],
      g,
      player: Side.white,
    );
    expect(slips.keyMoments(), [0]);
    expect(slips.coachLine(), contains('no blunders or mistakes'));
    final clean = buildReview(
      [row(ids[0], 'e4', 'Engine best'), row(ids[1], 'e5', 'Good')],
      g,
      player: Side.white,
    );
    expect(clean.keyMoments(), isEmpty);
    expect(clean.coachLine(), 'A very clean game. No mistakes at all.');
  });

  test('moves are explained in plain words', () {
    final m = buildReview(
      [row(ids[2], 'Qh5', 'Mistake')],
      g,
      player: Side.white,
    ).moves.single;
    expect(
      explainMove(m, bestSan: 'Nf3'),
      'This lets the advantage slip. Nf3 was better.',
    );
    expect(explainMove(m), 'This lets the advantage slip.');
  });

  test('the better move is named in standard notation', () {
    final start = g.at(null);
    expect(sanOf(start, 'g1f3'), 'Nf3');
    expect(sanOf(start, 'e7e5'), isNull);
    expect(sanOf(start, null), isNull);
  });
}
