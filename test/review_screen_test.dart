import 'dart:convert';

import 'package:castlei/core/chess/model.dart';
import 'package:castlei/core/engine/engine.dart';
import 'package:castlei/core/storage/database.dart';
import 'package:castlei/core/storage/repository.dart';
import 'package:castlei/core/ui/theme.dart';
import 'package:castlei/features/analysis/review_screen.dart';
import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String data(String label, int best, int played, List<String> pv) => jsonEncode({
  'best': {
    'score': best,
    'mate': false,
    'pv': pv,
    'depth': 12,
    'bounded': false,
  },
  'played': {
    'score': played,
    'mate': false,
    'pv': const <String>[],
    'depth': 12,
    'bounded': false,
  },
  'label': label,
});

void main() {
  testWidgets('a stored review opens on a summary and walks to the mistake', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(411, 900);
    addTearDown(t.view.reset);
    final db = AppDatabase.memory();
    final repo = Repository(db);
    final engine = EngineClient();
    final game = ChessGame.importPgn(
      PgnGame.parsePgn('1. e4 e5 2. Qh5 Nc6 3. Bc4 Nf6 *'),
    );
    final copy = ChessGame(
      id: newId(),
      title: 'Test game',
      source: 'engine',
      rootFen: game.rootFen,
      created: 0,
      settings: {'side': 'white'},
    );
    for (final n in game.mainline) {
      copy.play(Move.parse(n.uci)!);
    }
    copy.result = '0-1';
    await repo.save(copy);
    final line = copy.mainline;
    final labels = ['Engine best', 'Good', 'Blunder', 'Good', 'Good', 'Good'];
    for (var i = 0; i < line.length; i++) {
      await db.execute('INSERT INTO analysis VALUES(?,?,?,?,?)', [
        newId(),
        copy.id,
        line[i].id,
        'sf18-v1-3000',
        labels[i] == 'Blunder'
            ? data(labels[i], 40, -300, ['g1f3'])
            : data(labels[i], 30, 30, ['e2e4']),
      ]);
    }
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: ReviewScreen(game: copy, repo: repo, engine: engine),
      ),
    );
    await t.pumpAndSettle();

    // Summary first: coach line, accuracy for both sides, a way to start.
    expect(
      find.text('1 blunder cost you the most. Let’s look at it.'),
      findsOneWidget,
    );
    expect(find.textContaining('accuracy'), findsWidgets);
    expect(find.text('Start review'), findsOneWidget);

    // The walkthrough goes straight to the player's blunder.
    await t.tap(find.text('Start review'));
    await t.pumpAndSettle();
    expect(find.textContaining('2. Qh5 · Blunder'), findsOneWidget);
    expect(find.textContaining('Nf3 was much stronger.'), findsOneWidget);
    expect(find.text('Show best move'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    // It is the only key moment, so Next finishes.
    expect(find.text('Finish'), findsOneWidget);
    await t.tap(find.text('Finish'));
    await t.pumpAndSettle();
    expect(find.text('Start review'), findsOneWidget);
    expect(t.takeException(), isNull);

    await t.pumpWidget(const SizedBox());
    await t.runAsync(engine.dispose);
    await t.runAsync(db.close);
  });

  testWidgets('a game with no moves says so and offers nothing to start', (
    t,
  ) async {
    final db = AppDatabase.memory();
    final repo = Repository(db);
    final engine = EngineClient();
    final empty = ChessGame(
      id: newId(),
      title: 'Empty',
      source: 'engine',
      rootFen: Chess.initial.fen,
      created: 0,
    );
    await repo.save(empty);
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: ReviewScreen(game: empty, repo: repo, engine: engine),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('There are no moves to review yet.'), findsOneWidget);
    expect(find.text('Start review'), findsNothing);
    await t.pumpWidget(const SizedBox());
    await t.runAsync(engine.dispose);
    await t.runAsync(db.close);
  });
}
