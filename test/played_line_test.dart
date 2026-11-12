import 'package:castlei/core/engine/engine.dart';
import 'package:castlei/features/play/game_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EngineLine line(int score, {bool mate = false, int depth = 18}) =>
      EngineLine(depth: depth, score: score, mate: mate, pv: const ['e7e5']);

  test('the played move is scored from the mover\'s side', () {
    final played = playedLine('e2e4', line(35));
    expect(played.score, -35);
    expect(played.mate, isFalse);
    expect(played.pv, ['e2e4', 'e7e5']);
  });

  test('allowing a forced mate stays a mate against the mover', () {
    final played = playedLine('e2e4', line(3, mate: true));
    expect(played.mate, isTrue);
    expect(played.score, -3);
  });

  test('delivering checkmate counts as a mate for the mover', () {
    final played = playedLine('d1h5', line(0, mate: true, depth: 0));
    expect(played.mate, isTrue);
    expect(played.score, greaterThan(0));
  });

  test('a stalemate is an even position', () {
    final played = playedLine('d1h5', line(0, depth: 0));
    expect(played.mate, isFalse);
    expect(played.score, 0);
  });

  test('review results are keyed by engine version', () {
    expect(reviewConfig(3000), 'sf19-v2-3000');
  });
}
