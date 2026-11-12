import 'package:castlei/core/storage/database.dart';
import 'package:castlei/core/storage/repository.dart';
import 'package:castlei/core/ui/board_style.dart';
import 'package:castlei/core/ui/theme.dart';
import 'package:castlei/features/settings/board_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('choosing a palette and turning off legal moves is saved', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(400, 1200);
    addTearDown(t.view.reset);
    final db = AppDatabase.memory();
    final repo = Repository(db);
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: BoardSettingsScreen(repo: repo),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Walnut board'));
    await t.pumpAndSettle();
    expect(BoardStyle.palette, 'walnut');
    expect(await repo.preference('boardPalette', 'pine'), 'walnut');
    await t.tap(find.text('Show legal moves'));
    await t.pumpAndSettle();
    expect(BoardStyle.legalMoves, false);
    expect(await repo.preference('legalMoves', true), false);
    BoardStyle.palette = 'pine';
    BoardStyle.legalMoves = true;
    await t.pumpWidget(const SizedBox());
    await t.runAsync(db.close);
  });
}
