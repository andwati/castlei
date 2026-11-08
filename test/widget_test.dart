import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:castlei/main.dart';
import 'package:castlei/core/storage/database.dart';
import 'package:castlei/core/storage/repository.dart';

void main() {
  largeTextMain();
  testWidgets('home and study navigation render without overflow', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.pumpWidget(CastleiApp(repo: Repository(db)));
    await tester.pumpAndSettle();
    expect(find.text('Castlei'), findsOneWidget);
    expect(find.text('Play a game'), findsOneWidget);
    await tester.tap(find.text('Study'));
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
    for (final tab in ['Play', 'Study', 'Library', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$tab overflowed');
    }
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
