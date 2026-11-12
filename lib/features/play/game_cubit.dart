import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartchess/dartchess.dart';

import '../../core/chess/model.dart';
import '../../core/cloud/cloud_backup.dart';
import '../../core/cloud/remote_config.dart';
import '../../core/diagnostics/analytics.dart';
import '../../core/diagnostics/crash.dart';
import '../../core/diagnostics/perf.dart';
import '../../core/notifications/notifications.dart';
import '../../core/engine/engine.dart';
import '../../core/storage/repository.dart';

class GameView {
  const GameView({
    this.paused = true,
    this.thinking = false,
    this.error,
    this.lines = const [],
    this.hint,
    this.reviewDone = 0,
    this.reviewTotal = 0,
  });
  final bool paused, thinking;
  final String? error, hint;
  final List<EngineLine> lines;
  final int reviewDone, reviewTotal;
}

class GameCubit extends Cubit<GameView> {
  GameCubit(this.game, this.repo, this.engine, {this.study = false})
    : super(const GameView()) {
    white = (game.settings['whiteMs'] ?? game.settings['baseMs'] ?? 0) as int;
    black = (game.settings['blackMs'] ?? game.settings['baseMs'] ?? 0) as int;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => tick());
  }
  final ChessGame game;
  final Repository repo;
  final EngineClient engine;
  final bool study;
  late Timer _timer;
  final watch = Stopwatch();
  int lastTick = 0;
  int white = 0, black = 0;
  bool saving = false;
  int epoch = 0;
  bool get timed =>
      game.settings['baseMs'] != null && game.settings['baseMs'] != 0;
  Side get human => game.settings['side'] == 'black' ? Side.black : Side.white;
  bool get canMove =>
      study ||
      (!state.paused &&
          !state.thinking &&
          game.result == '*' &&
          game.position.turn == human);
  @override
  void emit(GameView state) {
    if (!isClosed) super.emit(state);
  }

  Future<void> persist() async {
    if (game.result != '*') {
      final first = !game.settings.containsKey('completedAt');
      game.settings.putIfAbsent(
        'completedAt',
        () => DateTime.now().millisecondsSinceEpoch,
      );
      if (first && !study) {
        final human = game.settings['side'] == 'black' ? '0-1' : '1-0';
        Analytics.log('game_finished', {
          'result': game.result == '1/2-1/2'
              ? 'draw'
              : game.result == human
              ? 'win'
              : 'loss',
          'reason': '${game.settings['reason'] ?? 'other'}',
          'assisted': game.assisted ? 'yes' : 'no',
          'length': Analytics.bucket(game.nodes.length ~/ 2),
          'difficulty': '${game.settings['level'] ?? ''}',
        });
        Notifications.cancelResume();
        CloudBackup.scheduleSoon();
      }
    }
    game.settings['whiteMs'] = white;
    game.settings['blackMs'] = black;
    await repo.save(game);
  }

  void tick() {
    if (state.paused || study || game.result != '*' || !timed) return;
    final now = watch.elapsedMilliseconds;
    final elapsed = now - lastTick;
    lastTick = now;
    if (game.position.turn == Side.white) {
      white = max(0, white - elapsed);
    } else {
      black = max(0, black - elapsed);
    }
    if (white == 0 || black == 0) {
      engine.cancel();
      final winner = white == 0 ? Side.black : Side.white;
      game.result = game.position.hasInsufficientMaterial(winner)
          ? '1/2-1/2'
          : white == 0
          ? '0-1'
          : '1-0';
      game.settings['reason'] = 'Time expired';
      pause();
    } else {
      emit(
        GameView(
          paused: state.paused,
          thinking: state.thinking,
          hint: state.hint,
        ),
      );
    }
  }

  Future<void> pause() async {
    epoch++;
    engine.cancel();
    watch.stop();
    emit(GameView(paused: true, lines: state.lines));
    await persist();
  }

  Future<void> resume() async {
    if (game.result != '*') return;
    watch.reset();
    watch.start();
    lastTick = 0;
    emit(const GameView(paused: false));
    if (game.position.turn != human) await engineMove();
  }

  Future<void> move(Move move) async {
    if (!canMove || saving) return;
    try {
      await commit(move);
      if (!study && game.result == '*') {
        await engineMove();
      } else if (!isClosed) {
        emit(const GameView());
      }
    } catch (e) {
      if (!isClosed) emit(GameView(error: e.toString()));
    }
  }

  Future<void> commit(Move move) async {
    saving = true;
    try {
      final before = game.position;
      final n = game.play(move);
      n.clocks = {'white': white, 'black': black};
      if (!study && timed) {
        final increment = (game.settings['increment'] ?? 0) as int;
        if (before.turn == Side.white) {
          white += increment * 1000;
        } else {
          black += increment * 1000;
        }
      }
      final p = game.position;
      if (!study) {
        if (p.outcome != null) {
          game.result = p.outcome!.winner == Side.white
              ? '1-0'
              : p.outcome!.winner == Side.black
              ? '0-1'
              : '1/2-1/2';
          game.settings['reason'] = p.isCheckmate ? 'Checkmate' : 'Draw';
        } else if (repetitions >= 5 || p.halfmoves >= 150) {
          game.result = '1/2-1/2';
          game.settings['reason'] = 'Automatic draw';
        }
      }
      await persist();
    } finally {
      saving = false;
    }
  }

  int get repetitions {
    final key = positionKey(game.position);
    var count = positionKey(game.at(null)) == key ? 1 : 0;
    for (final n in game.path(game.current)) {
      if (positionKey(game.at(n.id)) == key) count++;
    }
    return count;
  }

  bool get canClaim => repetitions >= 3 || game.position.halfmoves >= 100;
  List<Move> get intendedClaims {
    if (study || game.position.turn != human || game.result != '*') return [];
    final p = game.position;
    final candidates = <Move>[];
    for (final entry in p.legalMoves.entries) {
      for (final to in entry.value.squares) {
        final roles =
            p.board.pieceAt(entry.key)?.role == Role.pawn &&
                (to.rank == 0 || to.rank == 7)
            ? [Role.queen, Role.rook, Role.bishop, Role.knight]
            : <Role?>[null];
        for (final role in roles) {
          final m = NormalMove(from: entry.key, to: to, promotion: role);
          if (!p.isLegal(m)) continue;
          final next = p.play(m);
          final key = positionKey(next);
          var count = positionKey(game.at(null)) == key ? 1 : 0;
          for (final n in game.path(game.current)) {
            if (positionKey(game.at(n.id)) == key) count++;
          }
          if (next.halfmoves >= 100 || count >= 2) candidates.add(m);
        }
      }
    }
    return candidates;
  }

  Future<void> claimIntended(Move m) async {
    if (!intendedClaims.any((candidate) => candidate.uci == m.uci)) return;
    game.result = '1/2-1/2';
    game.settings['reason'] = 'Draw claimed with intended move ${m.uci}';
    await pause();
  }

  Future<void> claim() async {
    if (canClaim) {
      game.result = '1/2-1/2';
      game.settings['reason'] = 'Claimed draw';
      await pause();
    }
  }

  Future<void> engineMove() async {
    if (game.result != '*' || state.paused) return;
    if (canClaim) {
      await claim();
      return;
    }
    final token = ++epoch;
    emit(const GameView(paused: false, thinking: true));
    try {
      final remaining = game.position.turn == Side.white ? white : black;
      final ms = timed
          ? min(
              RemoteSettings.engineMaxMsTimed,
              max(
                1,
                min(
                  remaining - 50,
                  remaining ~/ 30 +
                      ((game.settings['increment'] ?? 0) as int) * 500,
                ),
              ),
            )
          : RemoteSettings.engineMaxMsUntimed;
      final result = await engine.search(
        fen: game.rootFen,
        moves: game.path(game.current).map((e) => e.uci).toList(),
        milliseconds: ms,
        skill: (game.settings['skill'] ?? 10) as int,
      );
      if (token != epoch || isClosed) return;
      final move = Move.parse(result.bestmove);
      if (move == null || !game.position.isLegal(move)) {
        throw StateError('Engine returned an illegal move');
      }
      await commit(move);
      if (!isClosed) emit(GameView(paused: game.result != '*'));
    } on SearchCanceled {
      /* Paused or replaced. */
    } catch (e, st) {
      CrashReporting.nonFatal('engine_move', e, st);
      watch.stop();
      if (!isClosed) emit(GameView(error: e.toString()));
    }
  }

  Future<void> undo() async {
    await pause();
    if (game.current == null) return;
    var removed = game.nodes.firstWhere((n) => n.id == game.current);
    var target = removed.parent;
    if (game.at(target).turn != human && target != null) {
      removed = game.nodes.firstWhere((n) => n.id == target);
      target = removed.parent;
    }
    white = (removed.clocks['white'] ?? white) as int;
    black = (removed.clocks['black'] ?? black) as int;
    final removeIds = game
        .path(game.current)
        .skip(game.path(target).length)
        .map((n) => n.id)
        .toSet();
    await repo.db.transaction(() async {
      for (final id in removeIds) {
        await repo.db.execute('DELETE FROM nodes WHERE id=?', [id]);
      }
    });
    game.nodes.removeWhere((n) => removeIds.contains(n.id));
    game.current = target;
    game.result = '*';
    game.assisted = true;
    await persist();
    Analytics.log('takeback_used');
    emit(const GameView());
  }

  Future<void> analyze({int milliseconds = 3000, int multiPv = 3}) async {
    engine.cancel();
    final token = ++epoch;
    emit(const GameView(thinking: true));
    final lines = <int, EngineLine>{};
    try {
      await engine.search(
        fen: game.rootFen,
        moves: game.path(game.current).map((n) => n.uci).toList(),
        milliseconds: milliseconds,
        multiPv: multiPv,
        onLine: (l) {
          if (token != epoch || isClosed) return;
          lines[l.index] = l;
          emit(GameView(thinking: true, lines: lines.values.toList()));
        },
      );
      if (token == epoch && !isClosed) {
        emit(GameView(lines: lines.values.toList()));
      }
    } catch (e) {
      if (!isClosed) emit(GameView(error: e.toString()));
    }
  }

  Future<void> hint() async {
    if (state.hint != null) {
      emit(
        GameView(hint: state.hint, lines: state.lines, paused: state.paused),
      );
      return;
    }
    await pause();
    game.assisted = true;
    await persist();
    Analytics.log('hint_used');
    CrashReporting.breadcrumb('hint');
    try {
      final r = await engine.search(
        fen: game.rootFen,
        moves: game.path(game.current).map((n) => n.uci).toList(),
        milliseconds: 1000,
      );
      if (isClosed) return;
      // A hint is a look at the board, not a pause: the game carries on.
      if (game.result == '*') watch.start();
      emit(GameView(hint: r.bestmove, paused: game.result != '*'));
    } catch (e) {
      if (!isClosed) emit(GameView(error: e.toString()));
    }
  }

  Future<void> navigate(String? id) async {
    await pause();
    game.current = id;
    await persist();
    emit(const GameView());
  }

  Future<void> review(int milliseconds) async {
    engine.cancel();
    Analytics.log('review_started', {'budget_ms': milliseconds});
    final token = ++epoch;
    final nodes = game.mainline;
    var done = 0;
    final config = 'sf18-v1-$milliseconds';
    final reviewTimer = Stopwatch()..start();
    try {
      for (final n in nodes) {
        if (token != epoch || isClosed) return;
        emit(
          GameView(thinking: true, reviewDone: done, reviewTotal: nodes.length),
        );
        final existing = await repo.db.rows(
          'SELECT id FROM analysis WHERE game_id=? AND node_id=? AND config=?',
          [game.id, n.id, config],
        );
        if (existing.isNotEmpty) {
          done++;
          continue;
        }
        final moveTimer = Stopwatch()..start();
        final path = game.path(n.parent).map((e) => e.uci).toList();
        final best = await engine.search(
          fen: game.rootFen,
          moves: path,
          milliseconds: milliseconds,
        );
        if (token != epoch) return;
        final played = await engine.search(
          fen: game.rootFen,
          moves: path,
          milliseconds: milliseconds,
          onlyMove: n.uci,
        );
        if (token != epoch) return;
        if (best.lines.isNotEmpty && played.lines.isNotEmpty) {
          await repo.db.execute('INSERT INTO analysis VALUES(?,?,?,?,?)', [
            newId(),
            game.id,
            n.id,
            config,
            jsonText(
              best.lines.first,
              played.lines.first,
              best.bestmove == n.uci,
            ),
          ]);
        }
        Perf.record(
          'review_move',
          metrics: {
            'ms': moveTimer.elapsedMilliseconds,
            'budget_ms': milliseconds,
          },
        );
        done++;
      }
      Perf.record(
        'review_game',
        metrics: {'ms': reviewTimer.elapsedMilliseconds, 'moves': nodes.length},
      );
      emit(GameView(reviewDone: done, reviewTotal: nodes.length));
    } catch (e) {
      if (!isClosed) {
        emit(
          GameView(
            error: e.toString(),
            reviewDone: done,
            reviewTotal: nodes.length,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    _timer.cancel();
    await pause();
    return super.close();
  }
}

String jsonText(EngineLine a, EngineLine b, bool same) => jsonEncode({
  'best': a.toJson(),
  'played': b.toJson(),
  'label': classify(a, b, sameMove: same),
});
