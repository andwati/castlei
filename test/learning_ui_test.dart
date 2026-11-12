import 'package:castlei/core/storage/database.dart';
import 'package:castlei/core/storage/repository.dart';
import 'package:castlei/core/ui/board.dart';
import 'package:castlei/core/ui/board_workspace.dart';
import 'package:castlei/core/ui/theme.dart';
import 'package:castlei/core/chess/model.dart';
import 'package:castlei/core/engine/engine.dart';
import 'package:castlei/core/ui/widgets.dart';
import 'package:castlei/features/analysis/analysis_screen.dart';
import 'package:castlei/features/play/play_screen.dart';
import 'package:castlei/features/learn/lesson_screen.dart';
import 'package:castlei/features/learn/lessons.dart';
import 'package:castlei/features/learn/coordinates.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(theme: buildTheme(brightness), home: child);
Finder square(String name) => find.bySemanticsLabel(RegExp('^$name,'));
void main() {
  testWidgets('promotion choices remain spaced on a narrow phone', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(320, 760);
    addTearDown(t.view.reset);
    final p = Chess.fromSetup(Setup.parseFen('8/P6k/8/8/8/8/8/K7 w - - 0 1'));
    await t.pumpWidget(
      host(
        Scaffold(
          body: ChessBoard(position: p, onMove: (_) {}),
        ),
      ),
    );
    await t.tap(square('a7'));
    await t.pump();
    await t.tap(square('a8'));
    await t.pumpAndSettle();
    Rect? previous;
    for (final role in ['queen', 'rook', 'bishop', 'knight']) {
      final rect = t.getRect(find.bySemanticsLabel('Promote to $role'));
      expect(rect.width, greaterThanOrEqualTo(48));
      if (previous != null) {
        expect(rect.left - previous.right, greaterThanOrEqualTo(12));
      }
      previous = rect;
    }
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('dialog actions wrap with gaps at large text', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(320, 760);
    addTearDown(t.view.reset);
    await t.pumpWidget(
      host(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 760),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: ActionDialog(
              title: const Text('Replace local data?'),
              content: const Text('Export a backup first.'),
              actions: [
                TextButton(onPressed: () {}, child: const Text('Cancel')),
                TextButton(onPressed: () {}, child: const Text('Export first')),
                FilledButton(
                  onPressed: () {},
                  child: const Text('Replace all'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final rects = [
      t.getRect(find.widgetWithText(TextButton, 'Cancel')),
      t.getRect(find.widgetWithText(TextButton, 'Export first')),
      t.getRect(find.widgetWithText(FilledButton, 'Replace all')),
    ]..sort((a, b) => a.top.compareTo(b.top));
    for (var i = 1; i < rects.length; i++) {
      expect(rects[i].top - rects[i - 1].bottom, greaterThanOrEqualTo(8));
    }
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'lesson actions have separate touch areas and clear vertical gaps',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(400, 1000);
      addTearDown(t.view.reset);
      final db = AppDatabase.memory();
      final repo = Repository(db);
      final lesson = (await loadLessons())[1];
      await t.pumpWidget(host(LessonScreen(repo: repo, lesson: lesson)));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Restart exercise'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      final example = t.getRect(
        find.widgetWithText(OutlinedButton, 'Show example'),
      );
      final hint = t.getRect(find.widgetWithText(OutlinedButton, 'Hint'));
      final restart = t.getRect(
        find.widgetWithText(TextButton, 'Restart exercise'),
      );
      expect(hint.top - example.bottom, greaterThanOrEqualTo(12));
      expect(restart.top - hint.bottom, greaterThanOrEqualTo(12));
      expect(example.height, greaterThanOrEqualTo(48));
      expect(hint.height, greaterThanOrEqualTo(48));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.runAsync(db.close);
    },
  );
  testWidgets(
    'game tools stay separated and analysis toolbar wraps with large text',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(320, 850);
      addTearDown(t.view.reset);
      final db = AppDatabase.memory();
      final repo = Repository(db);
      final engine = EngineClient();
      for (final study in [false, true]) {
        final game = ChessGame(
          id: newId(),
          title: 'Practice',
          source: study ? 'study' : 'engine',
          rootFen: Chess.initial.fen,
          created: 0,
        );
        await repo.save(game);
        await t.pumpWidget(
          host(
            MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 850),
                textScaler: TextScaler.linear(2),
              ),
              child: study
                  ? AnalysisScreen(
                      key: ValueKey(study),
                      game: game,
                      repo: repo,
                      engine: engine,
                    )
                  : PlayScreen(
                      key: ValueKey(study),
                      game: game,
                      repo: repo,
                      engine: engine,
                    ),
            ),
          ),
        );
        await t.pumpAndSettle();
        if (!study) {
          await t.scrollUntilVisible(
            find.text('Resign'),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          final takeback = t.getRect(
            find.widgetWithText(ToolButton, 'Take back'),
          );
          final hint = t.getRect(find.widgetWithText(ToolButton, 'Hint'));
          expect(hint.left - takeback.right, greaterThanOrEqualTo(12));
          expect(hint.height, takeback.height);
        } else {
          await t.scrollUntilVisible(
            find.byTooltip('Clear annotations'),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          final beginning = t.getRect(find.byTooltip('Beginning'));
          final clear = t.getRect(find.byTooltip('Clear annotations'));
          expect(clear.top, greaterThan(beginning.top));
          expect(clear.right, lessThanOrEqualTo(304));
        }
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
      }
      await t.runAsync(engine.dispose);
      await t.runAsync(db.close);
    },
  );
  testWidgets(
    'drag commits legal move, rejects illegal destination, cancels outside board',
    (t) async {
      final moves = <Move>[];
      var rejected = 0;
      await t.pumpWidget(
        host(
          Scaffold(
            body: SizedBox(
              width: 400,
              child: ChessBoard(
                position: Chess.initial,
                onMove: moves.add,
                onIllegalMove: () => rejected++,
              ),
            ),
          ),
        ),
      );
      await t.dragFrom(
        t.getCenter(square('e2')),
        t.getCenter(square('e4')) - t.getCenter(square('e2')),
      );
      await t.pumpAndSettle();
      expect(moves.single.uci, 'e2e4');
      moves.clear();
      await t.dragFrom(
        t.getCenter(square('e2')),
        t.getCenter(square('e5')) - t.getCenter(square('e2')),
      );
      await t.pumpAndSettle();
      expect(moves, isEmpty);
      expect(rejected, 1);
      await t.dragFrom(t.getCenter(square('e2')), const Offset(-500, 0));
      await t.pumpAndSettle();
      expect(moves, isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('turn cue is explicit for either color and check', (t) async {
    await t.pumpWidget(host(Scaffold(body: TurnCue(position: Chess.initial))));
    expect(find.text('White to move'), findsOneWidget);
    final p = Chess.fromSetup(Setup.parseFen('4k3/8/8/8/8/8/8/K3R3 b - - 0 1'));
    await t.pumpWidget(host(Scaffold(body: TurnCue(position: p))));
    expect(find.text('Black to move · Black is in check'), findsOneWidget);
  });
  testWidgets(
    'lesson can finish, persist checkpoint, and resume next exercise',
    (t) async {
      final db = AppDatabase.memory();
      final repo = Repository(db);
      final lesson = (await loadLessons()).first;
      await t.pumpWidget(host(LessonScreen(repo: repo, lesson: lesson)));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('d4'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await t.ensureVisible(find.text('d4'));
      await t.pumpAndSettle();
      await t.tap(find.text('d4'));
      await t.pumpAndSettle();
      expect(
        (await repo.preference('lessons.progress.v1', {}))[lesson.id]['next'],
        1,
      );
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      await t.pumpWidget(host(LessonScreen(repo: repo, lesson: lesson)));
      await t.pumpAndSettle();
      expect(find.text('Exercise 2 of 3'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('c6'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await t.ensureVisible(find.text('c6'));
      await t.pumpAndSettle();
      await t.tap(find.text('c6'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Next exercise'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await t.ensureVisible(find.text('Next exercise'));
      await t.pumpAndSettle();
      await t.tap(find.text('Next exercise'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('h2'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await t.ensureVisible(find.text('h2'));
      await t.pumpAndSettle();
      await t.tap(find.text('h2'));
      await t.pumpAndSettle();
      expect(
        (await repo.preference(
          'lessons.progress.v1',
          {},
        ))[lesson.id]['completed'],
        true,
      );
      expect(
        (await db.rows("SELECT * FROM attempts WHERE kind='lesson'")).length,
        3,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.runAsync(db.close);
    },
  );
  testWidgets('hinted lesson answers stay assisted after restart', (t) async {
    final db = AppDatabase.memory();
    final repo = Repository(db);
    final lesson = (await loadLessons()).first;
    await t.pumpWidget(host(LessonScreen(repo: repo, lesson: lesson)));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.text('Hint'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.text('Hint'));
    await t.pump();
    await t.scrollUntilVisible(
      find.text('Restart exercise'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Restart exercise'));
    await t.pump();
    await t.scrollUntilVisible(
      find.text('d4'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.text('d4'));
    await t.pumpAndSettle();
    expect(
      (await db.rows("SELECT success FROM attempts WHERE kind='lesson'"))
          .single['success'],
      0,
    );
    await t.pumpWidget(const SizedBox());
    await t.runAsync(db.close);
  });
  testWidgets(
    'coordinate training hides labels, scores answers, pauses and saves summary',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(400, 1000);
      addTearDown(t.view.reset);
      final db = AppDatabase.memory();
      final repo = Repository(db);
      await t.pumpWidget(host(CoordinateScreen(repo: repo)));
      await t.pumpAndSettle();
      await t.tap(find.text('Start training'));
      await t.pump();
      final label = t
          .widget<Text>(find.textContaining(RegExp('^Find [a-h][1-8]')))
          .data!;
      final target = label.substring(5);
      final i = List.generate(
        64,
        (i) => i,
      ).indexWhere((i) => coordinateAt(i, false) == target);
      await t.ensureVisible(find.bySemanticsLabel('Board cell ${i + 1}'));
      await t.tap(find.bySemanticsLabel('Board cell ${i + 1}'));
      await t.pump();
      await t.scrollUntilVisible(
        find.textContaining('1 correct / 1 attempts'),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('1 correct / 1 attempts'), findsOneWidget);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      await t.scrollUntilVisible(
        find.text('Resume paused session'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Resume paused session'), findsOneWidget);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      await t.tap(find.text('Resume paused session'));
      await t.pump();
      await t.scrollUntilVisible(
        find.text('Finish session'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.text('Finish session'));
      await t.pumpAndSettle();
      expect(
        (await db.rows("SELECT * FROM attempts WHERE kind='coordinate'"))
            .length,
        1,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.runAsync(db.close);
    },
  );
  testWidgets(
    'lesson layout supports dark wide view and large text narrow view',
    (t) async {
      final db = AppDatabase.memory();
      final repo = Repository(db);
      final lesson = (await loadLessons())[1];
      for (final size in [const Size(1100, 800), const Size(320, 740)]) {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = size;
        await t.pumpWidget(
          host(
            MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(size.width < 400 ? 2 : 1),
              ),
              child: LessonScreen(
                key: ValueKey(size),
                repo: repo,
                lesson: lesson,
              ),
            ),
            brightness: Brightness.dark,
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }
      await t.pumpWidget(const SizedBox());
      t.view.reset();
      await t.runAsync(db.close);
    },
  );
  testWidgets('play screen lays out on a wide tablet without overflow', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1280, 800);
    addTearDown(t.view.reset);
    final db = AppDatabase.memory();
    final repo = Repository(db);
    final engine = EngineClient();
    final game = ChessGame(
      id: newId(),
      title: 'Wide',
      source: 'engine',
      rootFen: Chess.initial.fen,
      created: 0,
    );
    await repo.save(game);
    await t.pumpWidget(
      host(PlayScreen(game: game, repo: repo, engine: engine)),
    );
    await t.pumpAndSettle();
    expect(find.text('Resign'), findsOneWidget);
    expect(find.byType(ChessBoard), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
    await t.runAsync(engine.dispose);
    await t.runAsync(db.close);
  });
}
