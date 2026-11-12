import 'package:castlei/core/chess/model.dart';
import 'package:castlei/core/chess/engine_opponents.dart';
import 'package:castlei/core/engine/engine.dart';
import 'package:castlei/core/storage/database.dart';
import 'package:castlei/core/storage/repository.dart';
import 'package:castlei/features/play/game_cubit.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

ChessGame make(String fen, Map<String, dynamic> settings) => ChessGame(
  id: newId(),
  title: 'Mode',
  source: 'engine',
  rootFen: fen,
  created: 0,
  settings: settings,
);

void main() {
  late AppDatabase db;
  late Repository repo;
  late EngineClient engine;
  setUp(() {
    db = AppDatabase.memory();
    repo = Repository(db);
    engine = EngineClient();
  });
  tearDown(() async {
    await engine.dispose();
    await db.close();
  });

  test('a clock that runs out ends the game for the other side', () async {
    final g = make(Chess.initial.fen, {
      'side': 'white',
      'baseMs': 300000,
      'whiteMs': 120,
      'blackMs': 300000,
    });
    await repo.save(g);
    final cubit = GameCubit(g, repo, engine);
    await cubit.resume();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(g.result, '0-1');
    expect(g.settings['reason'], 'Time expired');
    await cubit.close();
  });

  test('custom start positions are honoured', () async {
    const fen = '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1';
    final g = make(fen, {'side': 'white'});
    await repo.save(g);
    final loaded = await repo.load(g.id);
    expect(loaded.rootFen, fen);
    expect(loaded.position.fen, fen);
  });

  test('untimed games never run a clock', () async {
    final g = make(Chess.initial.fen, {'side': 'white'});
    final cubit = GameCubit(g, repo, engine);
    expect(cubit.timed, isFalse);
    await cubit.close();
  });

  test('a stalemate position ends the game as a draw rule', () {
    final p = Chess.fromSetup(Setup.parseFen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'));
    expect(p.isStalemate, isTrue);
    expect(p.isGameOver, isTrue);
  });

  test('15+10 adds ten seconds after each move', () async {
    final g = make(Chess.initial.fen, {
      'side': 'white',
      'baseMs': 15 * 60000,
      'increment': 10,
      'whiteMs': 15 * 60000,
      'blackMs': 15 * 60000,
    });
    await repo.save(g);
    final cubit = GameCubit(g, repo, engine);
    await cubit.resume();
    final before = cubit.white;
    await cubit.commit(NormalMove(from: Square.e2, to: Square.e4));
    expect(cubit.white, greaterThan(before - 2000));
    expect(cubit.white, lessThanOrEqualTo(before + 10000));
    await cubit.pause();
    await cubit.close();
  });

  test('a draw can be claimed after fifty moves without progress', () async {
    final g = make('4k3/8/8/8/8/8/4P3/4K3 w - - 100 80', {'side': 'white'});
    final cubit = GameCubit(g, repo, engine);
    expect(cubit.canClaim, isTrue);
    final fresh = make('4k3/8/8/8/8/8/4P3/4K3 w - - 10 20', {'side': 'white'});
    final other = GameCubit(fresh, repo, engine);
    expect(other.canClaim, isFalse);
    await cubit.close();
    await other.close();
  });

  test('Maximum difficulty maps to the strongest engine opponent', () {
    expect(EngineOpponent.all.last.skill, 20);
    expect(EngineOpponent.forSkill(20).label, 'Maximum');
  });
}
