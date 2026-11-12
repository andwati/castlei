import 'package:castlei/core/chess/model.dart';
import 'package:castlei/core/notifications/notifications.dart';
import 'package:castlei/core/storage/database.dart';
import 'package:castlei/core/storage/repository.dart';
import 'package:castlei/core/ui/theme.dart';
import 'package:castlei/features/play/game_common.dart';
import 'package:castlei/features/play/play_widgets.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
  theme: buildTheme(Brightness.light),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('result panel offers review and rematch', (t) async {
    var reviewed = 0, rematched = 0;
    await t.pumpWidget(
      host(
        ResultPanel(
          headline: 'You won',
          reason: 'Checkmate',
          won: true,
          onReview: () => reviewed++,
          onRematch: () => rematched++,
        ),
      ),
    );
    expect(find.text('You won'), findsOneWidget);
    await t.tap(find.text('Review game'));
    await t.tap(find.text('Play again'));
    expect((reviewed, rematched), (1, 1));
  });

  testWidgets('result panel disables review when there is nothing to review', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        ResultPanel(
          headline: 'Draw',
          reason: 'Agreed',
          won: false,
          onReview: null,
          onRematch: () {},
        ),
      ),
    );
    final button = t.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('player bar shows captures and the material lead', (t) async {
    await t.pumpWidget(
      host(
        PlayerBar(
          leading: const Text('♔'),
          name: 'You · White',
          captures: const Captures([Role.pawn, Role.knight], 3),
          capturedWhite: false,
          active: true,
        ),
      ),
    );
    expect(find.text('You · White'), findsOneWidget);
    expect(find.textContaining('+3'), findsOneWidget);
  });

  testWidgets('move strip shows the moves and opens the full list', (t) async {
    var opened = 0;
    final moves = [
      StudyNode(id: 'a', uci: 'e2e4', san: 'e4'),
      StudyNode(id: 'b', parent: 'a', uci: 'e7e5', san: 'e5'),
    ];
    await t.pumpWidget(
      host(
        MoveStrip(
          moves: moves,
          currentId: 'b',
          labels: const {},
          onOpen: () => opened++,
        ),
      ),
    );
    expect(find.textContaining('e4'), findsWidgets);
    await t.tap(find.byType(MoveStrip));
    expect(opened, 1);
  });

  testWidgets('the reminder offer never appears on its own under test', (
    t,
  ) async {
    final db = AppDatabase.memory();
    final repo = Repository(db);
    expect(await Notifications.shouldOffer(repo), isFalse);
    await t.pumpWidget(
      host(
        Builder(
          builder: (c) => TextButton(
            onPressed: () => Notifications.offerReminders(c, repo),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.text('Gentle reminders?'), findsNothing);
    expect(await repo.preference('notifPrompted', false), isFalse);
    await t.pumpWidget(const SizedBox());
    await t.runAsync(db.close);
  });

  testWidgets('the clock announces its time and whether it is running', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(
      host(const GameClock(label: 'White', value: '4:59', active: true)),
    );
    expect(find.bySemanticsLabel('White clock 4:59, running'), findsOneWidget);
    await t.pumpWidget(
      host(const GameClock(label: 'Black', value: '0:12', active: false)),
    );
    expect(find.bySemanticsLabel('Black clock 0:12'), findsOneWidget);
    handle.dispose();
  });
}
