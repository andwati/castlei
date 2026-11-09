import 'dart:convert';

import 'package:castlei/core/chess/engine_opponents.dart';
import 'package:castlei/core/ui/engine_avatar.dart';
import 'package:castlei/core/storage/database.dart';
import 'package:castlei/core/storage/repository.dart';
import 'package:castlei/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('existing saved games resolve the same difficulty portrait', () {
    for (final opponent in EngineOpponent.all) {
      expect(
        EngineOpponent.fromSettings({'skill': opponent.skill}),
        same(opponent),
      );
      expect(
        EngineOpponent.fromSettings({'level': opponent.label}),
        same(opponent),
      );
    }
    expect(EngineOpponent.fromSettings({}).label, 'Medium');
    expect(EngineOpponent.fromSettings({'level': 'Unknown'}).label, 'Medium');
    expect(EngineOpponent.forSkill(-1).label, 'Gentle');
    expect(EngineOpponent.forSkill(100).label, 'Maximum');
    expect(EngineOpponent.all.map((o) => o.asset).toSet().length, 5);
  });

  testWidgets('choosing a face preserves the corresponding Stockfish skill', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(400, 1000);
    addTearDown(t.view.reset);
    final db = AppDatabase.memory();
    final repo = Repository(db);
    await t.pumpWidget(CastleiApp(repo: repo));
    await t.pumpAndSettle();
    await t.tap(find.text('Play a game'));
    await t.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => w is EngineAvatar && w.opponent.label == 'Medium',
      ),
      findsOneWidget,
    );
    await t.tap(find.text('Medium'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Hard'));
    await t.pumpAndSettle();
    await t.tap(find.text('Hard'));
    await t.pumpAndSettle();
    await t.tap(find.text('Create'));
    await t.pumpAndSettle();
    final game = (await repo.games()).single;
    expect(jsonDecode(game['settings'])['skill'], 15);
    expect(jsonDecode(game['settings'])['level'], 'Hard');
    expect(
      find.byWidgetPredicate(
        (w) => w is EngineAvatar && w.opponent.label == 'Hard',
      ),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
    await t.runAsync(db.close);
  });
}
