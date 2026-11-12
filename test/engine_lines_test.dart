import 'package:castlei/core/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EngineLine? parse(String s) => EngineLine.parse(s);

  test(
    'a bound line does not replace an exact score for the same variation',
    () {
      final lines = <int, EngineLine>{};
      final exact = parse(
        'info depth 14 multipv 1 score cp 31 nodes 1000 pv e2e4 e7e5',
      )!;
      final bound = parse(
        'info depth 15 multipv 1 score cp 120 lowerbound nodes 1500 pv e2e4',
      )!;
      mergeLine(lines, exact);
      final kept = mergeLine(lines, bound);
      expect(kept.bounded, isFalse);
      expect(lines[1]!.score, 31);
    },
  );

  test('a bound line is kept when nothing exact has arrived yet', () {
    final lines = <int, EngineLine>{};
    final bound = parse(
      'info depth 3 multipv 1 score cp 50 upperbound pv e2e4',
    )!;
    mergeLine(lines, bound);
    expect(lines[1]!.bounded, isTrue);
  });

  test('a newer exact line replaces an older one, per variation', () {
    final lines = <int, EngineLine>{};
    mergeLine(lines, parse('info depth 10 multipv 1 score cp 10 pv e2e4')!);
    mergeLine(lines, parse('info depth 10 multipv 2 score cp 5 pv d2d4')!);
    mergeLine(lines, parse('info depth 11 multipv 1 score cp 20 pv e2e4')!);
    expect(lines[1]!.score, 20);
    expect(lines[2]!.score, 5);
  });

  test('a move is only called uncertain when no exact score exists', () {
    final exact = parse('info depth 12 multipv 1 score cp 40 pv e2e4')!;
    final worse = parse('info depth 12 multipv 1 score cp -250 pv a2a3')!;
    expect(classify(exact, exact, sameMove: true), 'Engine best');
    expect(classify(exact, worse), 'Blunder');
    final bound = parse(
      'info depth 12 multipv 1 score cp 40 lowerbound pv e2e4',
    )!;
    expect(classify(bound, worse), 'Uncertain');
  });
}
