import 'package:castlei/core/ui/board.dart';
import 'package:castlei/core/ui/board_style.dart';
import 'package:castlei/core/ui/theme.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder square(String name) => find.bySemanticsLabel(RegExp('^$name,'));

Future<void> board(WidgetTester t, String fen, void Function(Move) on) =>
    t.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: ChessBoard(
            position: Chess.fromSetup(Setup.parseFen(fen)),
            onMove: on,
          ),
        ),
      ),
    );

void main() {
  tearDown(() {
    BoardStyle.autoQueen = false;
    BoardStyle.castleTwoSquares = true;
    BoardStyle.figurine = false;
  });

  test('figurine notation swaps piece letters for symbols', () {
    expect(BoardStyle.san('Nf3'), 'Nf3');
    BoardStyle.figurine = true;
    expect(BoardStyle.san('Nf3'), '♘f3');
    expect(BoardStyle.san('exd5'), 'exd5');
    expect(BoardStyle.san('O-O'), 'O-O');
  });

  testWidgets('auto-queen promotes without asking', (t) async {
    BoardStyle.autoQueen = true;
    Move? played;
    await board(t, '8/P6k/8/8/8/8/8/K7 w - - 0 1', (m) => played = m);
    await t.tap(square('a7'));
    await t.pump();
    await t.tap(square('a8'));
    await t.pumpAndSettle();
    expect((played as NormalMove).promotion, Role.queen);
    expect(find.bySemanticsLabel('Promote to knight'), findsNothing);
  });

  testWidgets('two-square castling shows and accepts the g-file', (t) async {
    Move? played;
    await board(t, 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1', (m) => played = m);
    await t.tap(square('e1'));
    await t.pump();
    expect(square('g1'), findsOneWidget);
    await t.tap(square('g1'));
    await t.pumpAndSettle();
    expect(played, isNotNull);
  });
}
