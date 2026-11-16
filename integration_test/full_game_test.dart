import 'dart:io';

import 'package:castlei/core/engine/engine.dart';
import 'package:castlei/core/storage/database.dart';
import 'package:castlei/main.dart' as app;
import 'package:dartchess/dartchess.dart' hide File;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

Finder sq(String s) => find.bySemanticsLabel(RegExp('^$s,'));

/// Plays a complete game against the app's engine through the real UI: every
/// move is entered by tapping squares. The tester's own moves come from a
/// separate full-strength Stockfish instance.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('play a full game to a result by tapping the board', (t) async {
    await app.main();
    await t.pumpAndSettle();
    await t.tap(find.text('Play a game'));
    await t.pumpAndSettle();
    await t.tap(find.text('Create'));
    for (var i = 0; i < 50 && sq('e2').evaluate().isEmpty; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    if (find.text('Resume').evaluate().isNotEmpty) {
      await t.tap(find.text('Resume'));
      await t.pump(const Duration(milliseconds: 500));
    }

    final dir = await getApplicationSupportDirectory();
    final db = AppDatabase(File('${dir.path}/castlei.sqlite'));
    final helper = EngineClient();

    Future<(String, String, List<String>)> state() async {
      for (var attempt = 0; attempt < 20; attempt++) {
        try {
          final g = (await db.rows(
            'SELECT id,result FROM games ORDER BY created DESC LIMIT 1',
          )).first;
          final moves = (await db.rows(
            'SELECT uci FROM nodes WHERE game_id=? ORDER BY ordinal',
            [g['id']],
          )).map((r) => r['uci'] as String).toList();
          return (g['id'] as String, g['result'] as String, moves);
        } catch (_) {
          await t.pump(const Duration(milliseconds: 100));
        }
      }
      throw TestFailure('could not read the game from the database');
    }

    Future<void> waitForPly(int ply) async {
      for (var i = 0; i < 150; i++) {
        await t.pump(const Duration(milliseconds: 200));
        final (_, result, moves) = await state();
        if (moves.length >= ply || result != '*') return;
      }
      final (_, _, played) = await state();
      throw TestFailure(
        'timed out waiting for ply $ply after ${played.join(' ')}; '
        'paused=${find.text('Resume').evaluate().isNotEmpty}',
      );
    }

    var result = '*';
    var moves = <String>[];
    for (var turn = 0; turn < 150; turn++) {
      (_, result, moves) = await state();
      if (result != '*') break;
      if (moves.length.isOdd) {
        await waitForPly(moves.length + 1);
        continue;
      }
      final best = await helper.search(
        fen: Chess.initial.fen,
        moves: moves,
        milliseconds: 300,
      );
      final uci = best.bestmove;
      if (uci.length < 4 || uci == '(none)') break;
      final before = moves.length;
      // The reply is in the database before it is on screen: draw it first, or
      // the tap lands on the previous position and is ignored.
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(sq(uci.substring(0, 2)));
      await t.pump(const Duration(milliseconds: 250));
      await t.tap(sq(uci.substring(2, 4)));
      await t.pump(const Duration(milliseconds: 300));
      if (uci.length == 5) {
        const roles = {'q': 'queen', 'r': 'rook', 'b': 'bishop', 'n': 'knight'};
        await t.tap(find.bySemanticsLabel('Promote to ${roles[uci[4]]}'));
        await t.pump(const Duration(milliseconds: 300));
      }
      try {
        await waitForPly(before + 1);
      } on TestFailure catch (e) {
        final selected = find
            .bySemanticsLabel(RegExp(', selected'))
            .evaluate()
            .length;
        throw TestFailure(
          '${e.message}; tried $uci; selected squares $selected; '
          'thinking=${find.byType(CircularProgressIndicator).evaluate().length}',
        );
      }
    }

    (_, result, moves) = await state();
    // ignore: avoid_print
    print('GAME OVER result=$result plies=${moves.length}');
    expect(
      result,
      isNot('*'),
      reason: 'game did not finish: ${moves.join(' ')}',
    );
    // Hold the final screen so it can be captured.
    for (var i = 0; i < 100; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
    await helper.dispose();
    await db.close();
  });
}
