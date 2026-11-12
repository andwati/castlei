import 'package:castlei/features/play/game_common.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('captures and material lead are counted per side', () {
    final start = Chess.initial;
    // 1.e4 d5 2.exd5: White has taken a pawn and leads by one.
    Position p = start;
    for (final san in ['e4', 'd5', 'exd5']) {
      p = p.play(p.parseSan(san)!);
    }
    final white = capturesBy(start, p, Side.white);
    expect(white.taken, [Role.pawn]);
    expect(white.lead, 1);
    final black = capturesBy(start, p, Side.black);
    expect(black.taken, isEmpty);
    expect(black.lead, 0);
  });

  test('a promotion is not counted as a capture', () {
    final start = Chess.fromSetup(
      Setup.parseFen('8/P6k/8/8/8/8/8/K7 w - - 0 1'),
    );
    final p = start.play(start.parseSan('a8=Q')!);
    expect(capturesBy(start, p, Side.white).taken, isEmpty);
    expect(capturesBy(start, p, Side.black).taken, isEmpty);
  });
}
