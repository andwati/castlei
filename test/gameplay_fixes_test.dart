import 'dart:convert';
import 'dart:io';

import 'package:castlei/core/chess/model.dart';
import 'package:castlei/core/engine/engine.dart';
import 'package:castlei/core/storage/database.dart';
import 'package:castlei/core/storage/repository.dart';
import 'package:castlei/core/ui/board.dart';
import 'package:castlei/core/ui/board_style.dart';
import 'package:castlei/core/ui/theme.dart';
import 'package:castlei/features/analysis/eval_graph.dart';
import 'package:castlei/features/analysis/review_model.dart';
import 'package:castlei/features/learn/lesson_screen.dart';
import 'package:castlei/features/learn/lessons.dart';
import 'package:castlei/features/play/game_cubit.dart';
import 'package:castlei/features/puzzles/training_screen.dart';
import 'package:castlei/main.dart' show newGameProblem;
import 'package:dartchess/dartchess.dart' hide File;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// An engine that answers every search with a fixed move and score.
class FakeEngine extends EngineClient {
  FakeEngine(this.bestmove, this.score, {this.mate = false});
  final String bestmove;
  final int score;
  final bool mate;
  int searches = 0;
  @override
  void cancel() {}
  @override
  Future<void> dispose() async {}
  @override
  Future<SearchResult> search({
    required String fen,
    List<String> moves = const [],
    int milliseconds = 3000,
    int skill = 20,
    int multiPv = 1,
    String? onlyMove,
    bool newGame = true,
    void Function(EngineLine)? onLine,
  }) async {
    searches++;
    return SearchResult(bestmove, [
      EngineLine(depth: 10, score: score, mate: mate, pv: [bestmove]),
    ]);
  }
}

ChessGame make(String fen, Map<String, dynamic> settings) => ChessGame(
  id: newId(),
  title: 'Fix',
  source: 'engine',
  rootFen: fen,
  created: 0,
  settings: settings,
);

Map<String, dynamic> row(
  String id,
  String label, {
  int score = 30,
  bool mate = false,
  int depth = 12,
}) => {
  'id': id,
  'san': 'x',
  'data': jsonEncode({
    'best': {'score': score, 'mate': mate, 'pv': <String>[]},
    'played': {'score': score, 'mate': mate, 'depth': depth},
    'label': label,
  }),
};

void main() {
  moreFixes();
  late AppDatabase db;
  late Repository repo;
  setUp(() {
    db = AppDatabase.memory();
    repo = Repository(db);
  });
  tearDown(() => db.close());

  // Black (the engine) has a queen against a bare king and fifty moves have
  // passed without progress.
  const fiftyMoves = '7K/8/8/3k4/8/8/5q2/8 w - - 100 90';

  test('a winning engine plays on instead of claiming a draw', () async {
    final g = make(fiftyMoves, {'side': 'white'});
    await repo.save(g);
    final engine = FakeEngine('f2f7', 900);
    final cubit = GameCubit(g, repo, engine);
    await cubit.resume();
    await cubit.move(NormalMove(from: Square.h8, to: Square.g8));
    expect(engine.searches, 1);
    expect(g.result, '*');
    expect(g.mainline.last.uci, 'f2f7');
    await cubit.close();
  });

  test('an engine that is not better takes the draw', () async {
    final g = make(fiftyMoves, {'side': 'white'});
    await repo.save(g);
    final cubit = GameCubit(g, repo, FakeEngine('f2f7', 0));
    await cubit.resume();
    await cubit.move(NormalMove(from: Square.h8, to: Square.g8));
    expect(g.result, '1/2-1/2');
    expect(g.settings['reason'], 'Claimed draw');
    await cubit.close();
  });

  test('repetition is counted along the game, start included', () async {
    final g = make(Chess.initial.fen, {'side': 'white'});
    final cubit = GameCubit(g, repo, FakeEngine('e7e5', 0));
    void shuffle() {
      for (final uci in ['g1f3', 'g8f6', 'f3g1', 'f6g8']) {
        g.play(Move.parse(uci)!);
      }
    }

    expect(cubit.repetitions, 1);
    shuffle();
    expect(cubit.repetitions, 2);
    expect(cubit.canClaim, isFalse);
    // Nf3 would bring a position up for the third time.
    g.play(Move.parse('g1f3')!);
    g.play(Move.parse('g8f6')!);
    g.play(Move.parse('f3g1')!);
    expect(cubit.intendedClaims, isEmpty); // Black to move, not the player
    g.play(Move.parse('f6g8')!);
    expect(cubit.repetitions, 3);
    expect(cubit.canClaim, isTrue);
    await cubit.close();
  });

  test('positions stay right after a takeback', () async {
    final g = make(Chess.initial.fen, {'side': 'white'});
    await repo.save(g);
    final cubit = GameCubit(g, repo, FakeEngine('e7e5', 0));
    await cubit.resume();
    await cubit.move(NormalMove(from: Square.e2, to: Square.e4));
    expect(g.mainline.map((n) => n.uci), ['e2e4', 'e7e5']);
    expect(cubit.canTakeBack, isTrue);
    await cubit.undo();
    expect(g.nodes, isEmpty);
    expect(g.position.fen, Chess.initial.fen);
    expect(cubit.canTakeBack, isFalse);
    await cubit.resume();
    await cubit.move(NormalMove(from: Square.d2, to: Square.d4));
    expect(g.position.board.pieceAt(Square.d4)?.role, Role.pawn);
    expect(g.position.board.pieceAt(Square.e4), isNull);
    await cubit.close();
  });

  test('the engine opening move alone cannot be taken back', () async {
    final g = make(Chess.initial.fen, {'side': 'black'});
    await repo.save(g);
    final cubit = GameCubit(g, repo, FakeEngine('e2e4', 20));
    await cubit.resume();
    expect(g.mainline.single.uci, 'e2e4');
    expect(cubit.canTakeBack, isFalse);
    await cubit.undo();
    expect(g.mainline.single.uci, 'e2e4');
    expect(g.assisted, isFalse);
    await cubit.close();
  });

  test('mates are graded by the moves given away', () {
    EngineLine mate(int n, {int depth = 12}) =>
        EngineLine(depth: depth, score: n, mate: true, pv: []);
    EngineLine cp(int n) =>
        EngineLine(depth: 12, score: n, mate: false, pv: []);
    // Played lines come from the position after the move: mate in 2 there is
    // the same mate in 3 seen from before it.
    expect(classify(mate(3), mate(2)), 'Forced mate');
    expect(classify(mate(3), mate(3)), 'Good');
    expect(classify(mate(3), mate(5)), 'Inaccuracy');
    // Delivering checkmate is as fast as it gets.
    expect(classify(mate(1), mate(1, depth: 0)), 'Forced mate');
    // Lost either way: holding out as long as possible is the best there is.
    expect(classify(mate(-3), mate(-3)), 'Forced mate');
    expect(classify(mate(-3), mate(-1)), 'Good');
    expect(classify(mate(-6), mate(-1)), 'Inaccuracy');
    expect(classify(mate(-3), cp(-900)), 'Good');
    expect(classify(cp(900), mate(4)), 'Forced mate');
    expect(classify(mate(3), cp(900)), 'Missed Forced Mate');
    expect(classify(cp(0), mate(-2)), 'Allowed Forced Mate');
    expect(classify(mate(2), mate(-2)), 'Missed Forced Mate');
  });

  test('mate scores carry a sign for White', () {
    expect(mateText(3), '+M3');
    expect(mateText(-3), '-M3');
    expect(mateText(0), '#');
    const line = EngineLine(depth: 9, score: 35, mate: false, pv: []);
    expect(line.label(true), '+0.35');
    expect(line.label(false), '-0.35');
  });

  test('an allowed mate is not a clean game', () {
    final g = ChessGame.importPgn(
      PgnGame.parsePgn('1. e4 e5 2. Qh5 Nc6 3. Bc4 Nf6 4. Qxf7# 1-0'),
    );
    final ids = g.mainline.map((n) => n.id).toList();
    final rows = [
      for (var i = 0; i < 5; i++) row(ids[i], 'Good'),
      // 3... Nf6 lets White mate in one: -1 for the mover, Black.
      row(ids[5], 'Allowed Forced Mate', score: -1, mate: true),
      // 4. Qxf7# is checkmate: a search with no moves, stored as mate in 1.
      row(ids[6], 'Engine best', score: 1, mate: true, depth: 0),
    ];
    final review = buildReview(rows, g, player: Side.black);
    expect(review.coachLine(), contains('allowed a forced checkmate'));
    expect(review.keyMoments(), [5]);
    expect(review.moves[5].evalText, '+M1');
    expect(review.moves[6].evalText, 'Checkmate');
    final points = parseReview(rows, g);
    expect(points[5].evalText, '+M1');
    expect(points[6].evalText, 'Checkmate');
  });

  testWidgets('the graph summary counts mates as blunders', (t) async {
    final g = ChessGame.importPgn(PgnGame.parsePgn('1. e4 e5 2. Qh5 Nc6 *'));
    final ids = g.mainline.map((n) => n.id).toList();
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: EvalGraph(
            points: parseReview([
              row(ids[0], 'Good'),
              row(ids[1], 'Allowed Forced Mate', score: -2, mate: true),
              row(ids[2], 'Missed Forced Mate'),
              row(ids[3], 'Blunder'),
            ], g),
            selectedNodeId: null,
            onSelect: (_) {},
          ),
        ),
      ),
    );
    expect(find.textContaining('3 blunders'), findsOneWidget);
  });

  group('two-square castling', () {
    Finder square(String name) => find.bySemanticsLabel(RegExp('^$name,'));
    Future<void> board(WidgetTester t, void Function(Move) on) => t.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: ChessBoard(
            position: Chess.fromSetup(
              Setup.parseFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1'),
            ),
            onMove: on,
          ),
        ),
      ),
    );
    tearDown(() => BoardStyle.castleTwoSquares = true);

    testWidgets('a tap on the rook picks it up instead of castling', (t) async {
      final played = <Move>[];
      await board(t, played.add);
      await t.tap(square('e1'));
      await t.pump();
      await t.tap(square('h1'));
      await t.pump();
      expect(played, isEmpty);
      expect(find.bySemanticsLabel(RegExp('^h1,.*selected')), findsOneWidget);
      await t.tap(square('h5'));
      await t.pumpAndSettle();
      expect(played.single.uci, 'h1h5');
    });

    testWidgets('king onto rook castles when that method is chosen', (t) async {
      BoardStyle.castleTwoSquares = false;
      final played = <Move>[];
      await board(t, played.add);
      await t.tap(square('e1'));
      await t.pump();
      await t.tap(square('h1'));
      await t.pumpAndSettle();
      expect(played.single.uci, 'e1h1');
    });
  });

  test('engine games export who played', () {
    final g = make(Chess.initial.fen, {
      'side': 'black',
      'level': 'Medium',
      'baseMs': 300000,
      'increment': 3,
    });
    final pgn = g.exportPgn();
    expect(pgn, contains('[White "Stockfish (Medium)"]'));
    expect(pgn, contains('[Black "Player"]'));
    expect(pgn, contains('[TimeControl "300+3"]'));
  });
}

// Appended: fixes that had no test of their own.
void moreFixes() {
  test('a new game needs a legal, unfinished start position', () {
    expect(newGameProblem(Chess.initial.fen, 0, 0), isNull);
    expect(newGameProblem('  ${Chess.initial.fen}  ', 10, 5), isNull);
    expect(newGameProblem('not a fen', 0, 0), contains('not a legal'));
    // Two kings next to each other.
    expect(newGameProblem('8/8/8/3kK3/8/8/8/8 w - - 0 1', 0, 0), isNotNull);
    // Fool's mate, and a stalemate.
    expect(
      newGameProblem(
        'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
        0,
        0,
      ),
      contains('already finished'),
    );
    expect(
      newGameProblem('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1', 0, 0),
      contains('already finished'),
    );
    expect(newGameProblem(Chess.initial.fen, 181, 0), contains('180 minutes'));
    expect(newGameProblem(Chess.initial.fen, 5, 61), contains('60 seconds'));
  });

  test(
    'an engine that cannot start fails fast and can be tried again',
    () async {
      final engine = EngineClient();
      final sw = Stopwatch()..start();
      for (var attempt = 0; attempt < 2; attempt++) {
        await expectLater(
          engine.search(fen: Chess.initial.fen, milliseconds: 10),
          throwsA(isA<StateError>()),
        );
      }
      // Each attempt reported the load error itself, not a 20 s timeout.
      expect(sw.elapsed, lessThan(const Duration(seconds: 10)));
      await engine.dispose();
    },
    skip: File('build/native/libcastlei_engine.so').existsSync(),
  );

  testWidgets('a hint followed by the example does not break the lesson', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(420, 1600);
    addTearDown(t.view.reset);
    final db = AppDatabase.memory();
    final lesson = (await loadLessons()).firstWhere(
      (l) => l.exercises.first.solutions.isNotEmpty,
    );
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: LessonScreen(
          repo: Repository(db),
          lesson: lesson,
          introDemo: false,
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Hint'));
    await t.tap(find.text('Hint'));
    await t.pump();
    await t.ensureVisible(find.text('Show example'));
    await t.tap(find.text('Show example'));
    // The example plays every move of the line, then resets the board.
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 250));
      expect(t.takeException(), isNull);
    }
    expect(find.text('Now try it yourself'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await db.close();
  });

  group('puzzles', () {
    late AppDatabase db;
    late Repository repo;
    setUp(() async {
      db = AppDatabase.memory();
      repo = Repository(db);
      // White mates with Qa8, Qg7 or Qh7; the listed line is Qa8.
      await db.execute('INSERT INTO puzzles VALUES(?,?,?,?,?,?)', [
        'p1',
        'test',
        '7k/Q7/6K1/8/8/8/8/8 w - - 0 1',
        jsonEncode(['a7a8']),
        800,
        'mate',
      ]);
    });
    tearDown(() => db.close());
    Finder square(String name) => find.bySemanticsLabel(RegExp('^$name,'));
    Future<void> open(WidgetTester t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(420, 1400);
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: TrainingScreen(repo: repo),
        ),
      );
      for (var i = 0; i < 10 && square('a7').evaluate().isEmpty; i++) {
        await t.runAsync(() => Future<void>.delayed(Duration.zero));
        await t.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> settle(WidgetTester t) async {
      for (var i = 0; i < 10; i++) {
        await t.runAsync(() => Future<void>.delayed(Duration.zero));
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    Future<List<Map<String, dynamic>>> attempts(WidgetTester t) async =>
        (await t.runAsync(() => db.rows('SELECT * FROM attempts')))!;

    testWidgets('another checkmate also solves the puzzle', (t) async {
      await open(t);
      await t.tap(square('a7'));
      await t.pump();
      await t.tap(square('g7'));
      await settle(t);
      expect(find.text('Solved without help'), findsOneWidget);
      final rows = await attempts(t);
      expect(rows.single['success'], 1);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('Reveal during the reply records one attempt', (t) async {
      await db.execute('DELETE FROM puzzles');
      await db.execute('INSERT INTO puzzles VALUES(?,?,?,?,?,?)', [
        'p2',
        'test',
        Chess.initial.fen,
        jsonEncode(['e2e4', 'e7e5', 'g1f3']),
        800,
        'opening',
      ]);
      await open(t);
      await t.tap(square('e2'));
      await t.pump();
      await t.tap(square('e4'));
      await t.pump(const Duration(milliseconds: 50));
      // The opponent's reply is still on its way.
      await t.tap(find.text('Reveal'));
      await settle(t);
      expect((await attempts(t)).single['success'], 0);
      // The reveal starts from the first position, untouched by the reply.
      expect(find.bySemanticsLabel(RegExp('^e2, white pawn')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^e7, black pawn')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('a move that is not mate is still wrong', (t) async {
      await open(t);
      await t.tap(square('a7'));
      await t.pump();
      await t.tap(square('a1'));
      await settle(t);
      expect(find.textContaining('Not quite'), findsOneWidget);
      expect(await attempts(t), isEmpty);
      await t.pumpWidget(const SizedBox());
    });
  });
}
