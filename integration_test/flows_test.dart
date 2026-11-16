import 'dart:io';

import 'package:material_ui/material_ui.dart';

import 'package:castlei/core/storage/backup.dart';
import 'package:castlei/core/storage/database.dart';
import 'package:castlei/core/storage/repository.dart';
import 'package:castlei/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

Future<void> waitFor(WidgetTester t, Finder f, {int seconds = 20}) async {
  for (var i = 0; i < seconds * 5; i++) {
    await t.pump(const Duration(milliseconds: 200));
    if (f.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $f');
}

Finder sq(String s) => find.bySemanticsLabel(RegExp('^$s,'));

Future<void> startGame(WidgetTester t) async {
  await app.main();
  await t.pumpAndSettle();
  await t.tap(find.text('Play').last);
  await t.pumpAndSettle();
  await t.tap(find.text('New engine game'));
  await t.pumpAndSettle();
  await t.tap(find.text('Create'));
  await waitFor(t, sq('e2'));
  // A game opens running; Resume only shows after leaving it.
  if (find.text('Resume').evaluate().isNotEmpty) {
    await t.tap(find.text('Resume'));
    await t.pump(const Duration(milliseconds: 500));
  }
}

/// Plays 1. e4 and waits for the engine's reply to be on the board.
Future<void> playE4(WidgetTester t) async {
  await t.tap(sq('e2'));
  await t.pump(const Duration(milliseconds: 300));
  await t.tap(sq('e4'));
  // Some black pawn or knight has left its home square.
  await waitFor(
    t,
    find.bySemanticsLabel(RegExp(r'^[a-h][78], empty')),
    seconds: 15,
  );
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('takeback restores the position and a hint can follow', (
    t,
  ) async {
    await startGame(t);
    await playE4(t);
    await t.tap(find.text('Take back'));
    await waitFor(t, find.bySemanticsLabel(RegExp('^e2, white pawn')));
    // Both moves are gone and the game carries on without a Resume tap.
    expect(find.bySemanticsLabel(RegExp(r'^[a-h][78], empty')), findsNothing);
    expect(find.text('Resume'), findsNothing);
    await t.tap(find.text('Hint'));
    // The hint search runs for a second, then the board is playable again.
    for (var i = 0; i < 15; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(find.textContaining('Engine paused'), findsNothing);
    await playE4(t);
    expect(t.takeException(), isNull);
  });

  testWidgets('resign finishes the game and the review runs', (t) async {
    await startGame(t);
    await playE4(t);
    await t.tap(find.text('Resign'));
    await t.pumpAndSettle();
    await t.tap(find.text('Resign').last);
    await waitFor(t, find.text('You lost'));
    expect(find.text('Resignation'), findsOneWidget);
    await t.tap(find.text('Review game'));
    // The review starts by itself and ends on its summary.
    await waitFor(
      t,
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Start review' || w.data == 'Step through the game'),
      ),
      seconds: 90,
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('puzzle can be revealed and advanced', (t) async {
    await app.main();
    await t.pumpAndSettle();
    await t.tap(find.text('Practice puzzles'));
    await waitFor(t, find.text('Reveal'));
    expect(find.text('Tactical puzzles'), findsOneWidget);
    await t.ensureVisible(find.text('Reveal'));
    await t.pumpAndSettle();
    await t.tap(find.text('Reveal'));
    await waitFor(t, find.text('Next position'));
    await t.ensureVisible(find.text('Next position'));
    await t.pumpAndSettle();
    await t.tap(find.text('Next position'));
    await waitFor(t, find.text('Reveal'));
    expect(find.textContaining('2 of '), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('repertoire screen opens from Study', (t) async {
    await app.main();
    await t.pumpAndSettle();
    await t.tap(find.text('Learn'));
    await t.pumpAndSettle();
    await t.tap(find.text('Opening repertoires'));
    await t.pumpAndSettle();
    expect(find.text('Create from library'), findsOneWidget);
  });

  testWidgets('statistics and settings screens render', (t) async {
    await app.main();
    await t.pumpAndSettle();
    await t.tap(find.text('Your progress'));
    await t.pumpAndSettle();
    expect(find.text('Your progress'), findsWidgets);
    await t.pageBack();
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Settings'));
    await t.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('pack catalog refresh and install over network', (t) async {
    await app.main();
    await t.pumpAndSettle();
    await t.tap(find.text('Learn'));
    await t.pumpAndSettle();
    await t.tap(find.text('Puzzle collections'));
    await t.pumpAndSettle();
    await t.tap(find.text('Refresh catalog'));
    await waitFor(t, find.text('Catalog refreshed'), seconds: 30);
    await t.tap(find.byIcon(Icons.download).first);
    await waitFor(t, find.textContaining('Installed 5000'), seconds: 60);
    await t.pumpAndSettle();
    expect(find.text('On this device'), findsWidgets);
  });

  test('backup round trip on a real on-device sqlite file', () async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/backup_test.sqlite');
    if (file.existsSync()) file.deleteSync();
    final db = AppDatabase(file);
    final repo = Repository(db);
    await repo.setPreference('x', 1);
    final bytes = await BackupService(db).export();
    await repo.setPreference('x', 2);
    await BackupService(db).restore(bytes);
    expect(await repo.preference('x', 0), 1);
    await db.close();
  });
}
