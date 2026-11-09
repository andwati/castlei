import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:castlei/core/chess/model.dart';
import 'package:castlei/core/storage/backup.dart';
import 'package:castlei/core/storage/database.dart';
import 'package:castlei/core/storage/repository.dart';
import 'package:castlei/features/learn/lessons.dart';
import 'package:castlei/features/learn/coordinates.dart';
import 'package:castlei/features/puzzles/training.dart';
import 'package:castlei/features/statistics/insights.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all authored setup positions validate', () async {
    final rows = jsonDecode(await rootBundle.loadString('assets/lessons.json'));
    final errors = <String>[];
    for (final row in rows) {
      for (final e in row['exercises']) {
        try {
          LessonExercise(Map<String, dynamic>.from(e)).validate();
        } catch (error) {
          errors.add('${row['title']}: ${e['goal']} ${e['fen']}: $error');
        }
      }
    }
    expect(errors, isEmpty, reason: errors.join('\n'));
  });
  test('24 lessons have 72 legal exercises and unique stable IDs', () async {
    final lessons = await loadLessons();
    expect(lessons.length, 24);
    expect(lessons.map((l) => l.id).toSet().length, 24);
    expect(lessons.map((l) => l.module).toSet().length, 6);
    for (final lesson in lessons) {
      expect(lesson.exercises.length, 3);
      for (final exercise in lesson.exercises) {
        try {
          exercise.validate();
        } catch (e) {
          fail('${lesson.title}: ${exercise.goal}: $e');
        }
      }
    }
  });
  test('authored mate exercises really finish with checkmate', () async {
    for (final lesson in await loadLessons()) {
      for (final exercise in lesson.exercises) {
        if (!exercise.goal.toLowerCase().contains('mate') ||
            exercise.solutions.isEmpty) {
          continue;
        }
        for (final line in exercise.solutions) {
          var p = exercise.initial;
          for (final uci in line) {
            p = p.play(Move.parse(uci)!);
          }
          expect(
            p.isCheckmate,
            true,
            reason: '${lesson.title}: ${exercise.goal}',
          );
        }
      }
    }
  });
  test('coordinate orientation mapping covers exactly 64 squares', () {
    expect(coordinateAt(0, false), 'a8');
    expect(coordinateAt(63, false), 'h1');
    expect(coordinateAt(0, true), 'h1');
    expect(coordinateAt(63, true), 'a8');
    for (final black in [true, false]) {
      expect({for (var i = 0; i < 64; i++) coordinateAt(i, black)}.length, 64);
    }
  });
  test('calendar includes inactive days and local chronological buckets', () {
    final now = DateTime(2026, 11, 9, 12);
    final rows = [
      {'created': DateTime(2026, 11, 7, 12).millisecondsSinceEpoch},
      {'created': now.millisecondsSinceEpoch},
    ];
    expect(calendarActivity(rows, now, 3), {
      '2026-11-06': 0,
      '2026-11-07': 1,
      '2026-11-08': 0,
      '2026-11-09': 1,
    });
  });
  test('reviews count only human mainline moves and retain coverage', () {
    final game = ChessGame(
      id: 'g',
      title: 'g',
      source: 'engine',
      rootFen: Chess.initial.fen,
      created: 0,
      settings: {'side': 'black'},
    );
    game.play(Move.parse('e2e4')!);
    final white = game.current!;
    game.play(Move.parse('e7e5')!);
    final black = game.current!;
    game.play(Move.parse('g1f3')!);
    final summary = ReviewSummary()
      ..add(game, {white: 'Blunder', black: 'Mistake'});
    expect(summary.humanMoves, 1);
    expect(summary.reviewedMoves, 1);
    expect(summary.labels, {'Mistake': 1});
    expect(summary.reviewedGames, 1);
    final missing = ReviewSummary()..add(game, {});
    expect(missing.reviewedMoves, 0);
    expect(missing.humanMoves, 1);
    expect(missing.labels, isEmpty);
  });
  test(
    'new lesson and coordinate records survive unchanged backup format',
    () async {
      final db = AppDatabase.memory();
      final repo = Repository(db);
      final restored = AppDatabase.memory();
      addTearDown(db.close);
      addTearDown(restored.close);
      await repo.setPreference('lessons.progress.v1', {
        'lesson-01': {'next': 3, 'completed': true, 'assisted': false},
      });
      await repo.setPreference('coordinates.best.find.white', 14);
      await TrainingService(
        repo,
      ).record('lesson', 'lesson-01:0', true, 0, 1200, {'lesson': 'lesson-01'});
      await TrainingService(repo).record(
        'coordinate',
        'find:white',
        false,
        0,
        30000,
        {'correct': 14, 'attempts': 16},
      );
      final bytes = await BackupService(db).export();
      await BackupService(restored).restore(bytes);
      final copy = Repository(restored);
      expect(
        (await copy.preference(
          'lessons.progress.v1',
          {},
        ))['lesson-01']['completed'],
        true,
      );
      expect(await copy.preference('coordinates.best.find.white', 0), 14);
      expect(
        (await restored.rows('SELECT * FROM attempts'))
            .map((r) => r['kind'])
            .toSet(),
        {'lesson', 'coordinate'},
      );
      expect(
        jsonDecode(
          (await restored.rows(
            "SELECT value FROM preferences WHERE key='coordinates.best.find.white'",
          )).single['value'],
        ),
        14,
      );
    },
  );
}
