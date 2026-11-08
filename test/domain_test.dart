import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dartchess/dartchess.dart';
import 'package:castlei/core/chess/model.dart';
import 'package:castlei/core/engine/engine.dart';
import 'package:castlei/core/storage/database.dart';
import 'package:castlei/core/storage/repository.dart';
import 'package:castlei/core/storage/backup.dart';
import 'package:castlei/features/puzzles/training.dart';
import 'package:castlei/core/diagnostics/crash.dart';
import 'package:castlei/core/diagnostics/perf.dart';

void main() {
  test('PGN branches and comments survive storage and backup', () async {
    final db = AppDatabase.memory();
    final repo = Repository(db);
    final g = ChessGame.importPgn(
      PgnGame.parsePgn(
        '[Event "Study"]\n\n1. e4 {Idea} (1. d4 d5) e5 2. Nf3 *',
      ),
    );
    await repo.save(g);
    final restored = await repo.load(g.id);
    expect(restored.nodes.length, 5);
    expect(restored.exportPgn(), contains('Idea'));
    expect(restored.exportPgn(), contains('d4'));
    final backup = await BackupService(db).export();
    await repo.delete(g.id);
    expect(await repo.games(), isEmpty);
    await BackupService(db).restore(backup);
    expect((await repo.load(g.id)).exportPgn(), restored.exportPgn());
    await db.close();
  });
  test('illegal import rejected', () {
    expect(
      () => ChessGame.importPgn(PgnGame.parsePgn('1. e4 e5 2. Ke3 *')),
      throwsFormatException,
    );
  });
  test('finite loss thresholds and mate labels', () {
    EngineLine line(int cp, {bool mate = false}) =>
        EngineLine(depth: 12, score: cp, mate: mate, pv: []);
    expect(classify(line(100), line(51)), 'Good');
    expect(classify(line(100), line(50)), 'Inaccuracy');
    expect(classify(line(100), line(0)), 'Mistake');
    expect(classify(line(100), line(-100)), 'Blunder');
    expect(classify(line(3, mate: true), line(50)), 'Missed Forced Mate');
    expect(classify(line(0), line(-3, mate: true)), 'Allowed Forced Mate');
  });
  test('UCI parser preserves mate, perspective and bounds', () {
    final line = EngineLine.parse(
      'info depth 18 multipv 2 score mate -3 upperbound nodes 10 pv e2e4 e7e5',
    )!;
    expect(line.index, 2);
    expect(line.mate, isTrue);
    expect(line.bounded, isTrue);
    expect(line.label(false), 'M3');
  });
  test('scheduler resets and caps intervals in UTC', () {
    final now = DateTime.utc(2026, 11, 8);
    expect(schedule(0, true, now), (
      1,
      now.add(const Duration(days: 1)).millisecondsSinceEpoch,
    ));
    expect(schedule(4, true, now).$1, 5);
    expect(schedule(5, true, now).$1, 5);
    expect(schedule(4, false, now).$1, 1);
  });
  test('repertoire accepts transposed positions and records recall', () async {
    final db = AppDatabase.memory();
    final repo = Repository(db);
    final g = ChessGame.importPgn(
      PgnGame.parsePgn('1. Nf3 Nf6 2. g3 g6 3. Bg2 *'),
    );
    final service = TrainingService(repo);
    await service.buildCards(g, 'white');
    final cards = await db.rows('SELECT * FROM cards');
    expect(cards.length, 3);
    await service.answerCard(cards.first, true, 0, 1000);
    expect((await db.rows('SELECT * FROM attempts')).length, 1);
    await db.close();
  });
  test('invalid restore leaves games intact', () async {
    final db = AppDatabase.memory();
    final repo = Repository(db);
    final g = ChessGame.importPgn(PgnGame.parsePgn('1. d4 *'));
    await repo.save(g);
    expect(
      () => BackupService(db).validate(utf8.encode('bad') as dynamic),
      throwsA(anything),
    );
    expect(await repo.games(), hasLength(1));
    await db.close();
  });
  test(
    'repertoire merges transpositions, resets edits, deletes cleanly',
    () async {
      final db = AppDatabase.memory();
      final repo = Repository(db);
      final svc = TrainingService(repo);
      final g = ChessGame.importPgn(
        PgnGame.parsePgn('1. Nf3 (1. d4 d5 2. Nf3 Nf6) d5 2. d4 Nf6 *'),
      );
      await svc.buildCards(g, 'white');
      final cards = await db.rows('SELECT * FROM cards');
      // Initial position + the shared post-1...d5 transposition (Nf3/d4 orders differ).
      final keys = cards
          .map((c) => positionKey(Chess.fromSetup(Setup.parseFen(c['fen']))))
          .toSet();
      expect(keys.length, cards.length);
      await db.execute('UPDATE cards SET stage=3,due=99');
      final extra = await repo.load(g.id);
      extra.current = null;
      extra.play(Move.parse('c2c4')!);
      await svc.buildCards(extra, 'white');
      final reset = await db.rows('SELECT * FROM cards WHERE stage=0');
      expect(reset, isNotEmpty);
      final rep = (await db.rows('SELECT id FROM repertoires')).single['id'];
      await repo.deleteRepertoire(rep);
      expect(await db.rows('SELECT * FROM cards'), isEmpty);
      expect(await repo.games(), isNotEmpty);
      await db.close();
    },
  );
  test('crash reports never carry FEN, PGN headers or file paths', () {
    final e = SanitizedError(
      FormatException(
        'bad rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1 in /home/ian/.local/share/castlei/game.pgn [Event "My secret study"]',
      ),
    );
    expect(e.toString(), startsWith('FormatException: '));
    expect(e.message, isNot(contains('rnbqkbnr')));
    expect(e.message, isNot(contains('/home/ian')));
    expect(e.message, isNot(contains('secret')));
    expect(e.message, contains('<fen>'));
    expect(scrub('x' * 500).length, lessThanOrEqualTo(161));
  });
  test(
    'restore keeps this device crash-report choice, default is on',
    () async {
      final db = AppDatabase.memory();
      final repo = Repository(db);
      expect(await repo.preference('crashReports', true), true);
      await repo.setPreference('crashReports', false);
      final backup = await BackupService(db).export();
      await repo.setPreference('crashReports', true);
      await BackupService(db).restore(backup);
      expect(await repo.preference('crashReports', true), true);
      await db.close();
    },
  );
  test('performance tracing is transparent when monitoring is off', () async {
    expect(Perf.enabled, isFalse);
    expect(await Perf.trace('x', () async => 42), 42);
    await expectLater(
      Perf.trace('x', () async => throw StateError('boom')),
      throwsStateError,
    );
    await Perf.record('x', metrics: {'ms': 1}); // must not throw
  });
}
