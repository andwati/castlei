import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:castlei/main.dart';
import 'package:castlei/core/storage/database.dart';
import 'package:castlei/core/storage/repository.dart';

void main() {
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
