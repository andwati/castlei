import 'dart:convert';
import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import '../../core/chess/model.dart';

/// How good a reviewed move was, from the engine labels stored with each move.
enum MoveQuality {
  best,
  good,
  inaccuracy,
  mistake,
  blunder,
  missedMate,
  allowedMate,
  forcedMate,
  uncertain;

  static MoveQuality fromLabel(String label) => switch (label) {
    'Engine best' => best,
    'Good' => good,
    'Inaccuracy' => inaccuracy,
    'Mistake' => mistake,
    'Blunder' => blunder,
    'Missed Forced Mate' => missedMate,
    'Allowed Forced Mate' => allowedMate,
    'Forced mate' => forcedMate,
    _ => uncertain,
  };

  /// Moves worth stopping on in the walkthrough.
  bool get isKeyMoment =>
      this == mistake ||
      this == blunder ||
      this == missedMate ||
      this == allowedMate;

  /// Moves the player should learn from: key moments and small slips.
  bool get isSlip => isKeyMoment || this == inaccuracy;

  /// Short text mark. Text, not colour, carries the meaning.
  String get mark => switch (this) {
    best => '★',
    inaccuracy => '?!',
    mistake => '?',
    blunder => '??',
    missedMate => 'M?',
    allowedMate => '??',
    _ => '',
  };

  String get title => switch (this) {
    best => 'Best move',
    good => 'Good move',
    inaccuracy => 'Inaccuracy',
    mistake => 'Mistake',
    blunder => 'Blunder',
    missedMate => 'Missed mate',
    allowedMate => 'Allowed mate',
    forcedMate => 'Forced mate',
    uncertain => 'Unclear',
  };
}

/// Expected winning chances (0-100) for [centipawns] from the mover's side.
double winChance(int centipawns) =>
    50 + 50 * (2 / (1 + math.exp(-0.00368208 * centipawns)) - 1);

int _centipawns(int score, bool mate) =>
    mate ? (score > 0 ? 10000 : -10000) : score;

/// How accurate a move was, 0-100, from the winning chances it gave up.
double moveAccuracy({
  required int bestScore,
  required bool bestMate,
  required int playedScore,
  required bool playedMate,
}) {
  final lost =
      (winChance(_centipawns(bestScore, bestMate)) -
              winChance(_centipawns(playedScore, playedMate)))
          .clamp(0, 100);
  return (103.1668 * math.exp(-0.04354 * lost) - 3.1669).clamp(0, 100);
}

/// One reviewed move.
class ReviewMove {
  ReviewMove({
    required this.nodeId,
    required this.ply,
    required this.san,
    required this.uci,
    required this.whiteMoved,
    required this.label,
    required this.accuracy,
    required this.whiteEval,
    required this.evalText,
    this.bestUci,
  }) : quality = MoveQuality.fromLabel(label);
  final String nodeId, san, uci, label;

  /// 1-based half-move number.
  final int ply;
  final bool whiteMoved;
  final MoveQuality quality;
  final double accuracy;

  /// Evaluation after the move in pawns from White's side; mate is ±10.
  final double whiteEval;
  final String evalText;

  /// The engine's preferred move in the position before this one.
  final String? bestUci;

  Side get side => whiteMoved ? Side.white : Side.black;
  int get moveNumber => (ply + 1) ~/ 2;

  /// "5. Qe2" for White, "5... dxc4" for Black.
  String get numbered => '$moveNumber${whiteMoved ? '.' : '...'} $san';
}

/// The review of a whole game: every analysed move and the totals.
class GameReview {
  GameReview(this.moves, {this.player});
  final List<ReviewMove> moves;

  /// The side the user played, or null when it is not known.
  final Side? player;

  bool get isEmpty => moves.isEmpty;

  Iterable<ReviewMove> _of(Side? side) =>
      side == null ? moves : moves.where((m) => m.side == side);

  /// Average accuracy 0-100 for [side], or null with no analysed moves.
  double? accuracy(Side side) {
    final of = _of(side).toList();
    if (of.isEmpty) return null;
    return of.fold<double>(0, (a, m) => a + m.accuracy) / of.length;
  }

  Map<MoveQuality, int> counts(Side? side) {
    final out = <MoveQuality, int>{};
    for (final m in _of(side)) {
      out[m.quality] = (out[m.quality] ?? 0) + 1;
    }
    return out;
  }

  /// Indices in [moves] to stop on: the player's mistakes and blunders, or
  /// their smaller slips when there are none.
  List<int> keyMoments() {
    final mine = <int>[
      for (var i = 0; i < moves.length; i++)
        if (player == null || moves[i].side == player) i,
    ];
    final key = [
      for (final i in mine)
        if (moves[i].quality.isKeyMoment) i,
    ];
    if (key.isNotEmpty) return key;
    return [
      for (final i in mine)
        if (moves[i].quality.isSlip) i,
    ];
  }

  /// One friendly sentence about the player's game.
  String coachLine() {
    final c = counts(player);
    final blunders = (c[MoveQuality.blunder] ?? 0);
    final mistakes = (c[MoveQuality.mistake] ?? 0);
    final missed = (c[MoveQuality.missedMate] ?? 0);
    final slips = (c[MoveQuality.inaccuracy] ?? 0);
    if (moves.isEmpty) return 'Nothing to review yet.';
    if (blunders + mistakes + missed == 0) {
      return slips == 0
          ? 'A very clean game. No mistakes at all.'
          : 'A clean game: no blunders or mistakes, just ${_n(slips, 'small slip')}.';
    }
    if (blunders > 0) {
      return '${_n(blunders, 'blunder')} cost you the most. Let’s look at '
          '${blunders == 1 ? 'it' : 'them'}.';
    }
    if (missed > 0) {
      return 'You missed a forced checkmate. Let’s find it.';
    }
    return '${_n(mistakes, 'mistake')} to learn from. Let’s go through '
        '${mistakes == 1 ? 'it' : 'them'}.';
  }
}

String _n(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

/// Plain-language explanation of a move; [bestSan] is the better move, if any.
String explainMove(ReviewMove m, {String? bestSan}) {
  String better(String lead, String tail) =>
      bestSan == null ? lead : '$lead $bestSan $tail';
  return switch (m.quality) {
    MoveQuality.best => 'The engine’s top choice.',
    MoveQuality.good => 'A solid move.',
    MoveQuality.inaccuracy => better('A small slip.', 'was a little better.'),
    MoveQuality.mistake => better(
      'This lets the advantage slip.',
      'was better.',
    ),
    MoveQuality.blunder => better('A serious mistake.', 'was much stronger.'),
    MoveQuality.missedMate =>
      bestSan == null
          ? 'You missed a forced checkmate.'
          : 'You missed a forced checkmate: $bestSan wins.',
    MoveQuality.allowedMate => 'This allows a forced checkmate.',
    MoveQuality.forcedMate => 'A forced checkmate is on the board.',
    MoveQuality.uncertain => 'The engine could not judge this move clearly.',
  };
}

/// Builds the review from the stored analysis rows (`id`, `san`, `data`).
GameReview buildReview(
  List<Map<String, dynamic>> rows,
  ChessGame game, {
  Side? player,
}) {
  final line = game.mainline;
  final out = <ReviewMove>[];
  for (final r in rows) {
    final index = line.indexWhere((n) => n.id == r['id']);
    if (index < 0) continue;
    final node = line[index];
    final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
    final best = data['best'] as Map<String, dynamic>;
    final played = data['played'] as Map<String, dynamic>;
    final whiteMoved = game.at(node.parent).turn == Side.white;
    final playedMate = played['mate'] as bool;
    final playedScore = played['score'] as int;
    final pv = best['pv'];
    final label = data['label'] as String;
    final sign = whiteMoved ? 1 : -1;
    final pawns = playedMate
        ? (playedScore > 0 ? 10.0 : -10.0) * sign
        : playedScore * sign / 100;
    out.add(
      ReviewMove(
        nodeId: node.id,
        ply: index + 1,
        san: node.san,
        uci: node.uci,
        whiteMoved: whiteMoved,
        label: label,
        bestUci: pv is List && pv.isNotEmpty ? '${pv.first}' : null,
        accuracy: label == 'Engine best'
            ? 100
            : moveAccuracy(
                bestScore: best['score'] as int,
                bestMate: best['mate'] as bool,
                playedScore: playedScore,
                playedMate: playedMate,
              ),
        whiteEval: pawns,
        evalText: playedMate
            ? 'M${playedScore.abs()}'
            : '${pawns >= 0 ? '+' : ''}${pawns.toStringAsFixed(1)}',
      ),
    );
  }
  out.sort((a, b) => a.ply.compareTo(b.ply));
  return GameReview(out, player: player);
}

/// The SAN of [uci] in [position], or null when it is not legal there.
String? sanOf(Position position, String? uci) {
  if (uci == null) return null;
  final move = Move.parse(uci);
  if (move == null || !position.isLegal(move)) return null;
  return position.makeSan(move).$2;
}
