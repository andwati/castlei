import 'dart:convert';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/chess/engine_opponents.dart';
import '../../core/chess/model.dart';
import '../../core/engine/engine.dart';
import '../../core/storage/repository.dart';
import '../../core/ui/engine_avatar.dart';
import '../../core/ui/sfx.dart';
import '../../core/ui/theme.dart';
import 'game_cubit.dart';

/// Preferences and move sounds shared by the play and analysis screens.
mixin GamePreferences<T extends StatefulWidget> on State<T> {
  Repository get repo;
  EngineClient get engine;
  bool get isStudy;

  bool flipped = false;
  bool coordinates = true, sound = false, haptics = true;
  int budget = 3000, multiPv = 3;
  String? _soundNode;
  String _soundResult = '*';
  bool _soundSeeded = false;

  Future<void> loadPreferences() async {
    final coords = await repo.preference('coordinates', true);
    final snd = await repo.preference('sound', false);
    final hap = await repo.preference('haptics', true);
    final ms = await repo.preference('analysisMs', 3000);
    final lines = await repo.preference('multiPv', 3);
    final threads = await repo.preference('resources', defaultEngineThreads);
    engine.threads = threads;
    engine.hashMb = hashFor(threads);
    if (mounted) {
      setState(() {
        coordinates = coords;
        sound = snd;
        haptics = hap;
        budget = ms;
        multiPv = lines;
      });
    }
  }

  /// Plays a sound/haptic when a move is committed (by either side), not when
  /// the user merely browses the move list.
  void announceMove(ChessGame g, StudyNode? current) {
    if (!_soundSeeded) {
      _soundSeeded = true;
      _soundNode = current?.id;
      _soundResult = g.result;
      return;
    }
    final moved =
        current != null &&
        current.id != _soundNode &&
        current.parent == _soundNode;
    final ended = _soundResult == '*' && g.result != '*';
    _soundNode = current?.id;
    _soundResult = g.result;
    if (!moved && !ended) return;
    final kind = ended && !isStudy ? MoveSound.end : Sfx.forSan(current!.san);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Sfx.play(kind, sound: sound, haptics: haptics),
    );
  }
}

String clockText(int ms) =>
    '${ms ~/ 60000}:${((ms ~/ 1000) % 60).toString().padLeft(2, '0')}';

/// Who is playing this side, and their clock when the game is timed.
class PlayerRow extends StatelessWidget {
  const PlayerRow({
    super.key,
    required this.game,
    required this.cubit,
    required this.state,
    required this.side,
    required this.study,
  });
  final ChessGame game;
  final GameCubit cubit;
  final GameView state;
  final Side side;
  final bool study;
  @override
  Widget build(BuildContext context) {
    final white = side == Side.white;
    final human = side == cubit.human;
    final ms = white ? cubit.white : cubit.black;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (!study && !human)
            EngineAvatar(opponent: EngineOpponent.fromSettings(game.settings))
          else
            Text(white ? '♔' : '♚', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${study
                  ? ''
                  : human
                  ? 'You · '
                  : 'Stockfish · '}${white ? 'White' : 'Black'}',
              style: context.text.titleSmall,
            ),
          ),
          if (cubit.timed && !study)
            GameClock(
              label: white ? 'White' : 'Black',
              value: clockText(ms),
              low: ms < 20000,
              active:
                  !state.paused &&
                  game.result == '*' &&
                  game.position.turn == side,
            ),
        ],
      ),
    );
  }
}

class GameClock extends StatelessWidget {
  const GameClock({
    super.key,
    required this.label,
    required this.value,
    required this.active,
    this.low = false,
  });
  final String label, value;
  final bool active, low;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label clock $value${active ? ', running' : ''}',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: low
            ? context.colors.errorContainer
            : active
            ? context.colors.primary
            : context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExcludeSemantics(
        child: Text(
          '$value${low ? ' !' : ''}',
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: low
                ? context.colors.onErrorContainer
                : active
                ? context.colors.onPrimary
                : context.colors.onSurface,
          ),
        ),
      ),
    ),
  );
}

/// Review labels by node id, for marking moves in the list.
Future<Map<String, String>> loadReviewLabels(
  Repository repo,
  String gameId,
) async {
  final rows = await repo.db.rows(
    'SELECT nodes.id,nodes.san,analysis.data FROM analysis JOIN nodes ON nodes.id=analysis.node_id WHERE analysis.game_id=? ORDER BY nodes.ordinal',
    [gameId],
  );
  return {
    for (final r in rows)
      r['id'] as String: jsonDecode(r['data'])['label'] as String,
  };
}

/// Opens a rematch of [old] with the same settings, replacing the current
/// route.
Future<ChessGame> newRematch(Repository repo, ChessGame old) async {
  final settings = Map<String, dynamic>.from(old.settings)
    ..remove('reason')
    ..remove('completedAt')
    ..remove('whiteMs')
    ..remove('blackMs');
  final game = ChessGame(
    id: newId(),
    title: old.title,
    source: 'engine',
    rootFen: old.rootFen,
    created: DateTime.now().millisecondsSinceEpoch,
    settings: settings,
  );
  await repo.save(game);
  return game;
}

const _pieceValue = {
  Role.pawn: 1,
  Role.knight: 3,
  Role.bishop: 3,
  Role.rook: 5,
  Role.queen: 9,
};

/// Pieces one side has captured so far, worth in pawns, and how far ahead in
/// material that side is (0 when level or behind).
class Captures {
  const Captures(this.taken, this.lead);
  final List<Role> taken;
  final int lead;
}

/// Compares [now] with [start]: what [taker] has captured, and their material
/// lead. Promotions can make a side own more of a piece than it started with;
/// those never count as captures.
Captures capturesBy(Position start, Position now, Side taker) {
  List<Role> lost(Side victim) {
    final before = start.board.materialCount(victim);
    final after = now.board.materialCount(victim);
    // Each piece gained beyond the starting count is a promoted pawn, which
    // left the board without being captured.
    var promoted = 0;
    for (final role in _pieceValue.keys) {
      if (role == Role.pawn) continue;
      promoted += (after[role]! - before[role]!).clamp(0, 8);
    }
    return [
      for (final role in _pieceValue.keys.toList().reversed)
        for (
          var i = 0;
          i <
              (before[role]! -
                      after[role]! -
                      (role == Role.pawn ? promoted : 0))
                  .clamp(0, 8);
          i++
        )
          role,
    ];
  }

  int worth(Side side) {
    var total = 0;
    final count = now.board.materialCount(side);
    for (final entry in _pieceValue.entries) {
      total += count[entry.key]! * entry.value;
    }
    return total;
  }

  final taken = lost(taker.opposite);
  return Captures(taken, (worth(taker) - worth(taker.opposite)).clamp(0, 99));
}

String roleGlyph(Role role, {required bool white}) => switch (role) {
  Role.pawn => white ? '♙' : '♟',
  Role.knight => white ? '♘' : '♞',
  Role.bishop => white ? '♗' : '♝',
  Role.rook => white ? '♖' : '♜',
  Role.queen => white ? '♕' : '♛',
  Role.king => '',
};
