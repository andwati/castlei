import 'package:share_plus/share_plus.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/chess/model.dart';
import '../../core/diagnostics/analytics.dart';
import '../../core/engine/engine.dart';
import '../../core/storage/repository.dart';
import '../../core/ui/board.dart';
import '../../core/ui/theme.dart';
import '../play/game_common.dart';
import '../play/game_cubit.dart';
import 'analysis_screen.dart';
import 'eval_graph.dart';
import 'review_model.dart';

/// Colour for a move-quality mark; the glyph, not the colour, carries meaning.
Color markColor(MoveQuality q, CastleiTokens t) => switch (q) {
  MoveQuality.best || MoveQuality.good || MoveQuality.forcedMate => t.good,
  MoveQuality.inaccuracy => t.warn,
  MoveQuality.mistake => t.selected,
  MoveQuality.blunder ||
  MoveQuality.missedMate ||
  MoveQuality.allowedMate => t.bad,
  MoveQuality.uncertain => t.warn,
};

/// A guided look back at a finished game: it analyses on its own, summarises,
/// then walks through the moments that mattered.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.game,
    required this.repo,
    required this.engine,
  });
  final ChessGame game;
  final Repository repo;
  final EngineClient engine;
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

enum _Phase { analysing, summary, walking }

class _ReviewScreenState extends State<ReviewScreen>
    with WidgetsBindingObserver, GamePreferences<ReviewScreen> {
  @override
  Repository get repo => widget.repo;
  @override
  EngineClient get engine => widget.engine;
  @override
  bool get isStudy => true;

  late final GameCubit cubit;
  _Phase phase = _Phase.analysing;
  GameReview? review;
  List<ReviewPoint> points = [];
  List<int> stops = [];
  int index = 0;

  /// Each position is searched once, for a third of the analysis budget: a
  /// review needs a clear verdict per move, not the deepest possible line.
  int get reviewBudget => (budget ~/ 3).clamp(500, 4000);
  bool everyMove = false;
  bool showBest = false, retrying = false, loaded = false, started = false;
  String? retryNote;

  Side? get player => widget.game.source == 'engine'
      ? (widget.game.settings['side'] == 'black' ? Side.black : Side.white)
      : null;

  @override
  void initState() {
    super.initState();
    cubit = GameCubit(widget.game, widget.repo, widget.engine, study: true);
    flipped = player == Side.black;
    WidgetsBinding.instance.addObserver(this);
    Analytics.screen('review');
    if (widget.game.mainline.isNotEmpty) {
      loadPreferences().then((_) => _start());
    }
  }

  void _start() {
    if (!mounted || started) return;
    started = true;
    cubit.review(budget, searchMs: reviewBudget);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cubit.close();
    super.dispose();
  }

  Future<void> _load() async {
    loaded = true;
    final g = widget.game;
    final rows = await widget.repo.db.rows(
      'SELECT nodes.id,nodes.san,analysis.data FROM analysis JOIN nodes ON nodes.id=analysis.node_id WHERE analysis.game_id=? ORDER BY nodes.ordinal',
      [g.id],
    );
    if (!mounted) return;
    final r = buildReview(rows, g, player: player);
    final all = [for (var i = 0; i < r.moves.length; i++) i];
    final key = r.keyMoments();
    setState(() {
      review = r;
      points = parseReview(rows, g);
      stops = key.isEmpty ? all : key;
      phase = _Phase.summary;
    });
    Analytics.log('review_completed', {'moves': r.moves.length});
  }

  /// Toggles between stopping on mistakes only and stepping through every move.
  void _toggleEvery() {
    final r = review;
    if (r == null) return;
    final all = [for (var i = 0; i < r.moves.length; i++) i];
    final key = r.keyMoments();
    setState(() {
      everyMove = !everyMove;
      stops = everyMove || key.isEmpty ? all : key;
    });
  }

  Future<void> _share() async {
    final r = review;
    if (r == null) return;
    String pct(double? v) => v == null ? '–' : '${v.round()}%';
    final me = player ?? Side.white;
    final text = StringBuffer('Castlei game review\n')
      ..writeln(r.coachLine())
      ..writeln(
        '${player == null ? 'White' : 'Me'} ${pct(r.accuracy(me))} · '
        '${player == null ? 'Black' : 'Stockfish'} ${pct(r.accuracy(me.opposite))} accuracy',
      );
    await SharePlus.instance.share(ShareParams(text: text.toString()));
  }

  void _update(VoidCallback fn) => setState(fn);

  void _walkTo(int i) => setState(() {
    index = i;
    phase = _Phase.walking;
    showBest = false;
    retrying = false;
    retryNote = null;
  });

  void _next() {
    final after = stops.where((s) => s > index);
    after.isEmpty
        ? setState(() => phase = _Phase.summary)
        : _walkTo(after.first);
  }

  void _previous() {
    final before = stops.where((s) => s < index);
    before.isEmpty
        ? setState(() => phase = _Phase.summary)
        : _walkTo(before.last);
  }

  Position _before(ReviewMove m) => widget.game.at(
    widget.game.nodes.firstWhere((n) => n.id == m.nodeId).parent,
  );

  void _tryMove(ReviewMove m, Move move) {
    final before = _before(m);
    final uci = standardUci(before, move);
    final best = sanOf(before, m.bestUci);
    if (uci == m.bestUci) {
      HapticFeedback.lightImpact();
      setState(() {
        retrying = false;
        showBest = true;
        retryNote = 'That’s the move: ${best ?? 'well found'}.';
      });
    } else if (uci == m.uci) {
      setState(() => retryNote = 'That’s the move you played. Try another.');
    } else {
      setState(
        () => retryNote = 'Not quite. Try again, or show the best move.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<GameCubit, GameView>(
    bloc: cubit,
    listener: (context, s) {
      if (!loaded &&
          s.reviewTotal > 0 &&
          s.reviewDone == s.reviewTotal &&
          !s.thinking) {
        _load();
      }
    },
    builder: (context, s) {
      final g = widget.game;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Game review'),
          leading: phase == _Phase.walking
              ? IconButton(
                  tooltip: 'Back to summary',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => phase = _Phase.summary),
                )
              : null,
          actions: [
            if (phase == _Phase.walking)
              IconButton(
                tooltip: everyMove
                    ? 'Stop only on mistakes'
                    : 'Step through every move',
                isSelected: everyMove,
                icon: const Icon(Icons.format_list_numbered_rounded),
                onPressed: _toggleEvery,
              ),
            if (phase != _Phase.analysing && review != null)
              IconButton(
                tooltip: 'Share summary',
                icon: const Icon(Icons.ios_share_rounded),
                onPressed: _share,
              ),
            IconButton(
              tooltip: 'Explore this game',
              icon: const Icon(Icons.travel_explore),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AnalysisScreen(
                    game: g,
                    repo: widget.repo,
                    engine: widget.engine,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: g.mainline.isEmpty
            ? const _Message('There are no moves to review yet.')
            : s.error != null
            ? _Failed(
                message: s.error!,
                onRetry: () {
                  loaded = false;
                  cubit.review(budget, searchMs: reviewBudget);
                },
              )
            : switch (phase) {
                _Phase.analysing => _Analysing(
                  game: g,
                  done: s.reviewDone,
                  total: s.reviewTotal == 0 ? g.mainline.length : s.reviewTotal,
                  flipped: flipped,
                  coordinates: coordinates,
                ),
                _Phase.summary => _Summary(
                  review: review!,
                  points: points,
                  player: player,
                  keyCount: review!.keyMoments().length,
                  onStart: () => _walkTo(stops.first),
                  onJump: (id) {
                    final i = review!.moves.indexWhere((m) => m.nodeId == id);
                    if (i >= 0) _walkTo(i);
                  },
                ),
                _Phase.walking => _Walk(this),
              },
        bottomNavigationBar: switch (phase) {
          _Phase.summary => _BottomBar(
            child: FilledButton.icon(
              onPressed: stops.isEmpty ? null : () => _walkTo(stops.first),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                review!.keyMoments().isEmpty
                    ? 'Step through the game'
                    : 'Start review',
              ),
            ),
          ),
          _Phase.walking => _BottomBar(
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previous,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Back'),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _next,
                    icon: const Icon(Icons.chevron_right),
                    label: Text(
                      stops.where((x) => x > index).isEmpty ? 'Finish' : 'Next',
                    ),
                  ),
                ),
              ],
            ),
          ),
          _ => null,
        },
      );
    },
  );
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.text.titleMedium,
      ),
    ),
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Text('The review stopped.', style: context.text.titleMedium),
          Text(message, textAlign: TextAlign.center),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

/// Shown while the engine works through the game.
class _Analysing extends StatelessWidget {
  const _Analysing({
    required this.game,
    required this.done,
    required this.total,
    required this.flipped,
    required this.coordinates,
  });
  final ChessGame game;
  final int done, total;
  final bool flipped, coordinates;
  @override
  Widget build(BuildContext context) {
    final line = game.mainline;
    final at = done.clamp(0, line.length);
    final node = at == 0 ? null : line[at - 1];
    return LayoutBuilder(
      builder: (context, box) {
        final side = (box.maxWidth - 32).clamp(0.0, 460.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Semantics(
                liveRegion: true,
                label: 'Reviewing your game, $done of $total moves',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviewing your game…',
                      style: context.text.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$done of $total moves checked',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: total == 0 ? null : done / total,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: side,
                child: ChessBoard(
                  position: game.at(node?.id),
                  lastMove: node?.uci,
                  flipped: flipped,
                  coordinates: coordinates,
                  enabled: false,
                  onMove: (_) {},
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You can leave this screen; the review carries on where it '
                'stopped next time.',
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.review,
    required this.points,
    required this.player,
    required this.keyCount,
    required this.onStart,
    required this.onJump,
  });
  final GameReview review;
  final List<ReviewPoint> points;
  final Side? player;
  final int keyCount;
  final VoidCallback onStart;
  final void Function(String nodeId) onJump;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final me = player ?? Side.white;
    final them = me.opposite;
    final mine = review.counts(player);
    String pct(double? v) => v == null ? '–' : '${v.round()}%';
    final rows = <MoveQuality>[
      MoveQuality.best,
      MoveQuality.good,
      MoveQuality.inaccuracy,
      MoveQuality.mistake,
      MoveQuality.blunder,
      if ((mine[MoveQuality.missedMate] ?? 0) > 0) MoveQuality.missedMate,
      if ((mine[MoveQuality.allowedMate] ?? 0) > 0) MoveQuality.allowedMate,
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.primaryContainer,
            borderRadius: BorderRadius.circular(Corner.md),
          ),
          child: Row(
            spacing: 12,
            children: [
              Icon(Icons.school_outlined, color: c.onPrimaryContainer),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    review.coachLine(),
                    style: context.text.titleMedium?.copyWith(
                      color: c.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: _AccuracyTile(
                label: player == null ? 'White' : 'You',
                value: pct(review.accuracy(me)),
              ),
            ),
            Expanded(
              child: _AccuracyTile(
                label: player == null ? 'Black' : 'Stockfish',
                value: pct(review.accuracy(them)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        EvalGraph(points: points, selectedNodeId: null, onSelect: onJump),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                for (final q in rows)
                  Semantics(
                    container: true,
                    label: '${q.title}: ${mine[q] ?? 0}',
                    child: ExcludeSemantics(
                      child: ListTile(
                        dense: true,
                        leading: _Mark(quality: q),
                        title: Text(q.title),
                        trailing: Text(
                          '${mine[q] ?? 0}',
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          player == null
              ? 'Counts cover both sides.'
              : 'Counts show your moves.',
          style: context.text.bodySmall?.copyWith(color: c.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _AccuracyTile extends StatelessWidget {
  const _AccuracyTile({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$label accuracy $value',
    child: ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(Corner.md),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: context.text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$label · accuracy',
              style: context.text.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The round badge used for a move quality, in summaries and move cards.
class _Mark extends StatelessWidget {
  const _Mark({required this.quality, this.size = 28});
  final MoveQuality quality;
  final double size;
  @override
  Widget build(BuildContext context) {
    final glyph = switch (quality) {
      MoveQuality.good || MoveQuality.forcedMate => '✓',
      MoveQuality.uncertain => '·',
      _ => quality.mark,
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: markColor(quality, context.tokens),
        shape: BoxShape.circle,
      ),
      child: FittedBox(
        child: Padding(
          padding: EdgeInsets.all(size * .18),
          child: Text(
            glyph,
            style: TextStyle(
              color: markForeground(markColor(quality, context.tokens)),
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// One move at a time: the board, what happened, and the better move.
class _Walk extends StatelessWidget {
  const _Walk(this.s);
  final _ReviewScreenState s;

  @override
  Widget build(BuildContext context) {
    final r = s.review!;
    final m = r.moves[s.index];
    final g = s.widget.game;
    final before = s._before(m);
    final bestSan = m.bestUci == m.uci ? null : sanOf(before, m.bestUci);
    final mine = s.player == null || m.side == s.player;
    final canRetry = mine && m.quality.isSlip && m.bestUci != null;
    final showingBefore = s.retrying || s.showBest;
    final marks = <String, BoardMark>{};
    if (!showingBefore && m.quality.mark.isNotEmpty) {
      marks[m.uci.substring(2, 4)] = BoardMark(
        m.quality.mark,
        markColor(m.quality, context.tokens),
        label: m.quality.title,
      );
    }
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final side = (box.maxWidth - 32).clamp(0.0, 460.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 168),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(Corner.md),
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 12,
                          children: [
                            _Mark(quality: m.quality, size: 36),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${m.numbered} · ${m.quality.title}',
                                    style: context.text.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Evaluation ${m.evalText}'
                                    '${s.player == null
                                        ? ''
                                        : mine
                                        ? ' · your move'
                                        : ' · Stockfish’s move'}',
                                    style: context.text.bodySmall?.copyWith(
                                      color: c.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.retrying
                              ? 'Your turn: find a better move than ${m.san}.'
                              : explainMove(m, bestSan: bestSan),
                          style: context.text.bodyLarge,
                        ),
                        if (canRetry) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: () => s._update(() {
                                  s.showBest = !s.showBest;
                                  s.retrying = false;
                                  s.retryNote = null;
                                }),
                                icon: Icon(
                                  s.showBest
                                      ? Icons.visibility_off_outlined
                                      : Icons.lightbulb_outline,
                                ),
                                label: Text(
                                  s.showBest
                                      ? 'Back to the game'
                                      : 'Show best move',
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => s._update(() {
                                  s.retrying = !s.retrying;
                                  s.showBest = false;
                                  s.retryNote = null;
                                }),
                                icon: const Icon(Icons.replay),
                                label: Text(
                                  s.retrying ? 'Cancel' : 'Try again',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: side,
                  child: ChessBoard(
                    position: showingBefore ? before : g.at(m.nodeId),
                    lastMove: showingBefore ? null : m.uci,
                    flipped: s.flipped,
                    coordinates: s.coordinates,
                    enabled: s.retrying,
                    marks: marks,
                    arrow: s.showBest ? m.bestUci : null,
                    onMove: (mv) => s._tryMove(m, mv),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Reserved so feedback never moves the board.
              SizedBox(
                height: 48,
                child: Center(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      s.retryNote ?? '',
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                'Move ${s.index + 1} of ${r.moves.length}',
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: c.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
