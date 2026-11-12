import 'package:castlei/core/ui/board.dart';
import 'package:castlei/core/ui/theme.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
  theme: buildTheme(Brightness.light),
  home: Scaffold(
    body: Center(child: SizedBox(width: 400, child: child)),
  ),
);

void main() {
  testWidgets('a mark is drawn in the top-right corner of its square', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        ChessBoard(
          position: Chess.initial,
          onMove: (_) {},
          marks: const {'e4': BoardMark('??', Colors.red, label: 'Blunder')},
        ),
      ),
    );
    expect(find.text('??'), findsOneWidget);
    final board = t.getRect(find.byType(ChessBoard));
    final mark = t.getCenter(find.text('??'));
    final square = board.width / 8;
    // e4 is file 4 (e), rank 3 (row 4 from the top for White at the bottom).
    expect(mark.dx, greaterThan(board.left + 4 * square + square * .5));
    expect(mark.dx, lessThan(board.left + 5 * square + square * .3));
    expect(mark.dy, greaterThan(board.top + 4 * square - square * .3));
    expect(mark.dy, lessThan(board.top + 4 * square + square * .5));
  });

  testWidgets('marks follow the board when it is flipped', (t) async {
    await t.pumpWidget(
      host(
        ChessBoard(
          position: Chess.initial,
          onMove: (_) {},
          flipped: true,
          marks: const {'a1': BoardMark('?', Colors.orange)},
        ),
      ),
    );
    final board = t.getRect(find.byType(ChessBoard));
    final mark = t.getCenter(find.text('?'));
    // a1 sits at the top-right when flipped.
    expect(mark.dx, greaterThan(board.left + board.width * .8));
    expect(mark.dy, lessThan(board.top + board.height * .2));
  });
}
