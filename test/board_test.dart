import 'package:castlei/core/ui/board.dart';
import 'package:castlei/core/ui/theme.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
  theme: buildTheme(Brightness.light),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('check and last move are indicated and announced', (t) async {
    final handle = t.ensureSemantics();
    // Fool's mate: white king on e1 is in check from the queen on h4.
    final p = Chess.fromSetup(
      Setup.parseFen(
        'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
      ),
    );
    await t.pumpWidget(
      host(
        SizedBox(
          width: 400,
          child: ChessBoard(position: p, onMove: (_) {}, lastMove: 'd8h4'),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(RegExp('^e1, white king.*king in check')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('^h4, black queen.*last move')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('^d8, empty.*last move')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('promotion sheet offers four pieces and returns the choice', (
    t,
  ) async {
    final p = Chess.fromSetup(Setup.parseFen('8/P6k/8/8/8/8/8/K7 w - - 0 1'));
    Move? played;
    await t.pumpWidget(
      host(
        SizedBox(
          width: 400,
          child: ChessBoard(position: p, onMove: (m) => played = m),
        ),
      ),
    );
    await t.tap(find.bySemanticsLabel(RegExp('^a7, white pawn')));
    await t.pump();
    await t.tap(find.bySemanticsLabel(RegExp('^a8, empty')));
    await t.pumpAndSettle();
    for (final r in ['queen', 'rook', 'bishop', 'knight']) {
      expect(find.bySemanticsLabel('Promote to $r'), findsOneWidget);
    }
    await t.tap(find.bySemanticsLabel('Promote to knight'));
    await t.pumpAndSettle();
    expect((played as NormalMove).promotion, Role.knight);
  });

  testWidgets('capture squares are labelled as legal destinations', (t) async {
    final p = Chess.fromSetup(
      Setup.parseFen('4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1'),
    );
    await t.pumpWidget(
      host(
        SizedBox(
          width: 400,
          child: ChessBoard(position: p, onMove: (_) {}),
        ),
      ),
    );
    await t.tap(find.bySemanticsLabel(RegExp('^e4, white pawn')));
    await t.pump();
    final handle = t.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('^d5, black pawn.*legal destination')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('^e4, white pawn, selected')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
