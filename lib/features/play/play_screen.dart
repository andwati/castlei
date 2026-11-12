import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/chess/model.dart';
import '../../core/chess/openings.dart';
import '../../core/diagnostics/analytics.dart';
import '../../core/engine/engine.dart';
import '../../core/notifications/notifications.dart';
import '../../core/storage/repository.dart';
import '../../core/ui/board.dart';
import '../../core/ui/board_workspace.dart';
import '../../core/ui/sfx.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/widgets.dart';
import '../analysis/analysis_screen.dart';
import '../analysis/eval_graph.dart';
import 'game_common.dart';
import 'game_cubit.dart';

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

  @override
  Widget build(BuildContext context) => BlocBuilder<GameCubit, GameView>(
    bloc: cubit,
    builder: (context, state) {
      final g = widget.game;
      final current = g.nodes.where((n) => n.id == g.current).firstOrNull;
      announceMove(g, current);
      if (!state.paused && g.result == '*' && cubit.timed) {
        for (final pair in [('white', cubit.white), ('black', cubit.black)]) {
          if (pair.$2 > 0 && pair.$2 < 20000 && _lowTimeWarned.add(pair.$1)) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => Sfx.play(MoveSound.check, sound: sound, haptics: haptics),
            );
          }
        }
      }
      return Scaffold(
        appBar: AppBar(
          title: Text(g.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              tooltip: 'Copy PGN',
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: g.exportPgn())),
              icon: const Icon(Icons.ios_share),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Flip board',
              onPressed: () => setState(() => flipped = !flipped),
              icon: const Icon(Icons.flip),
            ),
          ],
        ),
        body: SafeArea(
          child: BoardWorkspace(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(
                    'Stockfish · ${g.settings['level'] ?? 'Medium'}',
                    icon: Icons.memory,
                  ),
                ],
              ),
              TurnCue(position: g.position),
              PlayerRow(
                game: g,
                cubit: cubit,
                state: state,
                side: flipped ? Side.white : Side.black,
                study: false,
              ),
              Builder(
                builder: (_) {
                  final o = Openings.forLine(g, g.current);
                  if (o == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Semantics(
                      label: 'Opening: ${o.$2}',
                      child: Text(
                        '${o.$1} · ${o.$2}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ChessBoard(
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
              PlayerRow(
                game: g,
                cubit: cubit,
                state: state,
                side: flipped ? Side.black : Side.white,
                study: false,
              ),
              const SizedBox(height: 8),
              if (state.error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Engine paused: ${state.error}'),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: g.result != '*'
                      ? context.colors.secondaryContainer
                      : state.thinking
                      ? context.colors.surfaceContainerHigh
                      : context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(Corner.md),
                ),
                child: Row(
                  children: [
                    if (state.thinking)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    else
                      Icon(
                        g.result != '*'
                            ? Icons.flag_rounded
                            : state.paused
                            ? Icons.pause_circle_outline
                            : Icons.touch_app_outlined,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        g.result == '*'
                            ? (state.thinking
                                  ? 'Stockfish is thinking…'
                                  : state.paused
                                  ? 'Game paused — your progress is saved'
                                  : '${cubit.human == Side.white ? 'White' : 'Black'} · Your move')
                            : '${g.result == '1/2-1/2'
                                  ? 'Draw'
                                  : g.result == (cubit.human == Side.white ? '1-0' : '0-1')
                                  ? 'You won'
                                  : 'You lost'} · ${g.settings['reason'] ?? 'Finished'}',
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ActionStack(
                children: [
                  if (g.result == '*')
                    FilledButton.icon(
                      onPressed: state.paused ? cubit.resume : cubit.pause,
                      icon: Icon(state.paused ? Icons.play_arrow : Icons.pause),
                      label: Text(state.paused ? 'Resume' : 'Pause'),
                    ),
                  if (g.result == '*')
                    ToolRow(
                      children: [
                        ToolButton(
                          icon: Icons.undo_rounded,
                          label: 'Take back',
                          onTap: g.current == null ? null : cubit.undo,
                        ),
                        ToolButton(
                          icon: Icons.lightbulb_outline_rounded,
                          label: 'Hint',
                          onTap: () async {
                            setState(
                              () => hintLevel = (hintLevel + 1).clamp(1, 2),
                            );
                            await cubit.hint();
                          },
                        ),
                        ToolButton(
                          icon: Icons.flag_outlined,
                          label: 'Resign',
                          danger: true,
                          onTap: _resign,
                        ),
                      ],
                    ),
                  if (!cubit.canClaim && cubit.intendedClaims.isNotEmpty)
                    TextButton(
                      onPressed: () async {
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
                            cubit.intendedClaims.firstWhere(
                              (m) => m.uci == move,
                            ),
                          );
                        }
                      },
                      child: const Text('Claim with move'),
                    ),
                  if (cubit.canClaim)
                    TextButton(
                      onPressed: cubit.claim,
                      child: const Text('Claim draw'),
                    ),
                ],
              ),
              if (g.result != '*')
                FilledButton.tonal(
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
                  child: const Text('Review game'),
                ),
              if (g.result != '*') const SizedBox(height: 12),
              if (g.result != '*')
                TextButton.icon(
                  onPressed: _rematch,
                  icon: const Icon(Icons.replay),
                  label: const Text('Play again'),
                ),
              const Divider(),
              Text('MOVES', style: Theme.of(context).textTheme.labelLarge),
              Wrap(
                spacing: 4,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < g.mainline.length; i++)
                    MoveChip(
                      number: i % 2 == 0 ? '${i ~/ 2 + 1}.' : null,
                      san: g.mainline[i].san,
                      badge: badgeFor(_labels[g.mainline[i].id] ?? ''),
                      selected: g.mainline[i].id == g.current,
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
