import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:castlei/main.dart';
import 'package:castlei/core/storage/database.dart';
import 'package:castlei/core/storage/repository.dart';

void main() {
  largeTextMain();
  testWidgets(
    'system navigation inset is consumed across home and pushed routes',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(400, 850);
      t.view.padding = const FakeViewPadding(bottom: 48);
      t.view.viewPadding = const FakeViewPadding(bottom: 48);
      addTearDown(t.view.reset);
      final db = AppDatabase.memory();
      await t.pumpWidget(CastleiApp(repo: Repository(db)));
      await t.pumpAndSettle();
      expect(
        t.getBottomRight(find.byType(NavigationBar)).dy,
        lessThanOrEqualTo(802),
      );
      await t.tap(find.text('Learn'));
      await t.pumpAndSettle();
      await t.tap(find.text('Guided lessons'));
      await t.pumpAndSettle();
      expect(
        t.getBottomRight(find.byType(Scrollable).first).dy,
        lessThanOrEqualTo(802),
      );
      await t.tap(find.text('Continue · Board and notation'));
      await t.pumpAndSettle();
      expect(
        t.getBottomRight(find.byType(Scrollable).first).dy,
        lessThanOrEqualTo(802),
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.runAsync(db.close);
    },
  );
  testWidgets('new engine games have automatic titles without a title input', (
    t,
  ) async {
    final db = AppDatabase.memory();
    final repo = Repository(db);
    await t.pumpWidget(CastleiApp(repo: repo));
    await t.pumpAndSettle();
    await t.tap(find.text('Play a game'));
    await t.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Title'), findsNothing);
    expect(find.text('Title'), findsNothing);
    await t.tap(find.text('Create'));
    await t.pumpAndSettle();
    final row = (await repo.games()).single;
    expect(row['title'], startsWith('Stockfish · Medium · '));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
    await t.runAsync(db.close);
  });

  testWidgets('home and learn navigation render without overflow', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.pumpWidget(CastleiApp(repo: Repository(db)));
    await tester.pumpAndSettle();
    expect(find.text('Castlei'), findsOneWidget);
    expect(find.text('Play a game'), findsOneWidget);
    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    expect(find.text('Analysis board'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}

void largeTextMain() {
  testWidgets('tabs survive 200% text on a narrow phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1520); // 360x760 dp @2x
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final db = AppDatabase.memory();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 760),
          textScaler: TextScaler.linear(2),
        ),
        child: CastleiApp(repo: Repository(db)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      MediaQuery.of(tester.element(find.text('Play a game'))).textScaler
          .scale(10),
      20,
      reason: 'text scale must reach the app',
    );
    for (final tab in ['Play', 'Learn', 'Library', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$tab overflowed');
    }
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
