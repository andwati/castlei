import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/chess/engine_opponents.dart';
import '../../core/chess/model.dart';
import '../../core/chess/openings.dart';
import '../../core/diagnostics/analytics.dart';
import '../../core/engine/engine.dart';
import '../../core/notifications/notifications.dart';
import '../../core/storage/repository.dart';
import '../../core/ui/board.dart';
import '../../core/ui/engine_avatar.dart';
import '../../core/ui/sfx.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/widgets.dart';
import '../analysis/eval_graph.dart';
import '../analysis/review_screen.dart';
import 'game_common.dart';
import 'game_cubit.dart';
import 'play_widgets.dart';

/// A live game against the engine.
class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.game,
    required this.repo,
    required this.engine,
  });
  final ChessGame game;
  final Repository repo;
  final EngineClient engine;
  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen>
    with WidgetsBindingObserver, GamePreferences<PlayScreen> {
  @override
  Repository get repo => widget.repo;
  @override
  EngineClient get engine => widget.engine;
  @override
  bool get isStudy => false;

  late final GameCubit cubit;
  int hintLevel = 0;
  bool _offeredReminders = false;
  Map<String, String> _labels = {};
  final Set<String> _lowTimeWarned = {};

  @override
  void initState() {
    super.initState();
    cubit = GameCubit(widget.game, widget.repo, widget.engine);
    flipped = widget.game.settings['side'] == 'black';
    WidgetsBinding.instance.addObserver(this);
    loadPreferences();
    loadReviewLabels(widget.repo, widget.game.id).then((labels) {
      if (mounted) setState(() => _labels = labels);
    });
    Openings.load().then((_) {
      if (mounted) setState(() {});
    });
    Notifications.cancelResume();
    // A game opens running; it only waits for the player after they leave it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.game.result == '*') cubit.resume();
    });
    // Don't interrupt a game with in-app announcements.
    Analytics.suppressMessages(true);
    Analytics.screen('game');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) cubit.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cubit.close();
    Analytics.suppressMessages(false);
    if (widget.game.result == '*') {
      Notifications.scheduleResume(widget.repo, widget.game.id);
    }
    super.dispose();
  }

  Future<void> _resign() async {
    final g = widget.game;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => ActionDialog(
        title: const Text('Resign this game?'),
        content: const Text('It will be saved as a loss.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep playing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
    if (yes == true) {
      g.result = cubit.human.name == 'white' ? '0-1' : '1-0';
      g.settings['reason'] = 'Resignation';
      await cubit.pause();
    }
  }

  Future<void> _rematch() async {
    final game = await newRematch(widget.repo, widget.game);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PlayScreen(game: game, repo: widget.repo, engine: widget.engine),
      ),
    );
  }

  Widget _bar(ChessGame g, GameView state, Side side) {
    final human = side == cubit.human;
    final over = g.result != '*';
    final white = side == Side.white;
    final ms = white ? cubit.white : cubit.black;
    final turn = g.position.turn == side;
    return PlayerBar(
      leading: human
          ? Text(white ? '♔' : '♚', style: const TextStyle(fontSize: 28))
          : EngineAvatar(
              opponent: EngineOpponent.fromSettings(g.settings),
              size: 40,
            ),
      name: human
          ? 'You'
          : 'Stockfish · ${EngineOpponent.fromSettings(g.settings).label}',
      captures: capturesBy(g.at(null), g.position, side),
      capturedWhite: !white,
      active: !over && !state.paused && turn,
      inCheck: g.position.isCheck && turn,
      thinking: !human && state.thinking,
      clock: cubit.timed
          ? GameClock(
              label: white ? 'White' : 'Black',
              value: clockText(ms),
              low: ms < 20000,
              active: !state.paused && !over && turn,
            )
          : null,
    );
  }

  Future<void> _hint() async {
    setState(() => hintLevel = (hintLevel + 1).clamp(1, 2));
    await cubit.hint();
  }

  Future<void> _takeBack() async {
    final wasPaused = cubit.state.paused;
    await cubit.undo();
    hintLevel = 0;
    if (mounted && widget.game.result == '*' && !wasPaused) {
      await cubit.resume();
    }
  }

  void _review() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ReviewScreen(
        game: widget.game,
        repo: widget.repo,
        engine: widget.engine,
      ),
    ),
  );

  Future<void> _claimWithMove() async {
    final g = widget.game;
    final move = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Claim with intended move'),
        children: [
          for (final m in cubit.intendedClaims)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, m.uci),
              child: Text(g.position.makeSan(m).$2),
            ),
        ],
      ),
    );
    if (move != null) {
      await cubit.claimIntended(
        cubit.intendedClaims.firstWhere((m) => m.uci == move),
      );
    }
  }

  Widget _bottom(ChessGame g, GameView state) {
    if (g.result != '*') {
      final won = g.result == (cubit.human == Side.white ? '1-0' : '0-1');
      return ResultPanel(
        headline: g.result == '1/2-1/2'
            ? 'Draw'
            : won
            ? 'You won'
            : 'You lost',
        reason: '${g.settings['reason'] ?? 'Finished'}',
        won: won || g.result == '1/2-1/2',
        onReview: widget.game.mainline.isEmpty ? null : _review,
        onRematch: _rematch,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!cubit.canClaim && cubit.intendedClaims.isNotEmpty)
          TextButton(
            onPressed: _claimWithMove,
            child: const Text('Claim with move'),
          ),
        if (cubit.canClaim)
          TextButton(onPressed: cubit.claim, child: const Text('Claim draw')),
        if (state.paused) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Paused · your progress is saved',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: cubit.resume,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
          ),
          const SizedBox(height: 8),
        ],
        ToolRow(
          children: [
            ToolButton(
              icon: Icons.undo_rounded,
              label: 'Take back',
              onTap: g.current == null || state.thinking ? null : _takeBack,
            ),
            ToolButton(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Hint',
              onTap: cubit.canMove ? _hint : null,
            ),
            ToolButton(
              icon: Icons.flag_outlined,
              label: 'Resign',
              danger: true,
              onTap: _resign,
            ),
          ],
        ),
      ],
    );
  }

  Widget _board(ChessGame g, GameView state, StudyNode? current, double side) =>
      Center(
        child: SizedBox(
          width: side,
          child: ChessBoard(
            position: g.position,
            lastMove: current?.uci,
            coordinates: coordinates,
            flipped: flipped,
            enabled: cubit.canMove,
            onIllegalMove: () {
              if (haptics) HapticFeedback.lightImpact();
            },
            shapes: [
              if (state.hint != null && hintLevel == 1)
                'Y${state.hint!.substring(0, 2)}',
            ],
            onMove: (m) {
              hintLevel = 0;
              cubit.move(m);
            },
            arrow: state.hint != null && hintLevel > 1 ? state.hint : null,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => BlocBuilder<GameCubit, GameView>(
    bloc: cubit,
    builder: (context, state) {
      final g = widget.game;
      final current = g.nodes.where((n) => n.id == g.current).firstOrNull;
      final over = g.result != '*';
      announceMove(g, current);
      if (over && !_offeredReminders) {
        _offeredReminders = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Notifications.offerReminders(context, widget.repo);
        });
      }
      if (!state.paused && !over && cubit.timed) {
        for (final pair in [('white', cubit.white), ('black', cubit.black)]) {
          if (pair.$2 > 0 && pair.$2 < 20000 && _lowTimeWarned.add(pair.$1)) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => Sfx.play(MoveSound.check, sound: sound, haptics: haptics),
            );
          }
        }
      }
      final opening = Openings.forLine(g, g.current);
      final turnLabel = over
          ? ''
          : '${g.position.turn == Side.white ? 'White' : 'Black'} to move'
                '${g.position.isCheck ? ', in check' : ''}';
      return Scaffold(
        appBar: AppBar(
          title: Text(
            opening?.$2 ?? 'Game',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (cubit.timed && !over && !state.paused)
              IconButton(
                tooltip: 'Pause',
                onPressed: cubit.pause,
                icon: const Icon(Icons.pause),
              ),
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (v) {
                switch (v) {
                  case 'flip':
                    setState(() => flipped = !flipped);
                  case 'pgn':
                    Clipboard.setData(ClipboardData(text: g.exportPgn()));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('PGN copied')));
                  case 'pause':
                    state.paused ? cubit.resume() : cubit.pause();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'flip', child: Text('Flip board')),
                if (!over)
                  PopupMenuItem(
                    value: 'pause',
                    child: Text(state.paused ? 'Resume game' : 'Pause game'),
                  ),
                const PopupMenuItem(value: 'pgn', child: Text('Copy PGN')),
              ],
            ),
          ],
        ),
        bottomNavigationBar: Material(
          color: context.colors.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _bottom(g, state),
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, box) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final wide = box.maxWidth >= 840 && scale <= 1.5;
            final column = wide
                ? (box.maxWidth * .52).clamp(320.0, 620.0)
                : box.maxWidth;
            final chrome = 196 * scale.clamp(1.0, 1.6);
            final side = (column - 32)
                .clamp(0.0, 640.0)
                .clamp(0.0, (box.maxHeight - chrome).clamp(220.0, 640.0));
            final moves = g.mainline;
            final board = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  liveRegion: true,
                  label: turnLabel,
                  child: const SizedBox.shrink(),
                ),
                _bar(g, state, flipped ? Side.white : Side.black),
                _board(g, state, current, side),
                _bar(g, state, flipped ? Side.black : Side.white),
                const SizedBox(height: 8),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Engine paused: ${state.error}',
                      style: TextStyle(color: context.colors.error),
                    ),
                  ),
                if (!wide)
                  MoveStrip(
                    moves: moves,
                    currentId: g.current,
                    labels: _labels,
                    onOpen: () => showMovesSheet(
                      context,
                      moves: moves,
                      currentId: g.current,
                      labels: _labels,
                    ),
                  ),
              ],
            );
            return SafeArea(
              bottom: false,
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: column,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: board,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Moves', style: context.text.titleLarge),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    for (var i = 0; i < moves.length; i++)
                                      MoveChip(
                                        number: i % 2 == 0
                                            ? '${i ~/ 2 + 1}.'
                                            : null,
                                        san: moves[i].san,
                                        badge: badgeFor(
                                          _labels[moves[i].id] ?? '',
                                        ),
                                        selected: moves[i].id == g.current,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: board,
                    ),
            );
          },
        ),
      );
    },
  );
}
