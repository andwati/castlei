import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/diagnostics/analytics.dart';
import '../../core/notifications/notifications.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/widgets.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/chess/model.dart';
import '../../core/storage/repository.dart';
import '../../core/engine/engine.dart';
import '../../core/ui/board.dart';
import 'game_cubit.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.game,
    required this.repo,
    required this.engine,
    this.study = false,
  });
  final ChessGame game;
  final Repository repo;
  final EngineClient engine;
  final bool study;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameCubit cubit;
  bool flipped = false, drawing = false;
  int budget = 3000, multiPv = 3, hintLevel = 0;
  String annotationColor = 'G';
  bool coordinates = true, sound = false, haptics = true;
  @override
  void initState() {
    super.initState();
    cubit = GameCubit(
      widget.game,
      widget.repo,
      widget.engine,
      study: widget.study,
    );
    flipped = widget.game.settings['side'] == 'black';
    WidgetsBinding.instance.addObserver(this);
    loadPreferences();
    Notifications.cancelResume();
    // Don't interrupt a game with in-app announcements.
    Analytics.suppressMessages(true);
    Analytics.screen(widget.study ? 'analysis' : 'game');
  }

  Future<void> loadPreferences() async {
    final coords = await widget.repo.preference('coordinates', true);
    final snd = await widget.repo.preference('sound', false);
    final hap = await widget.repo.preference('haptics', true);
    final ms = await widget.repo.preference('analysisMs', 3000);
    final lines = await widget.repo.preference('multiPv', 3);
    final threads = await widget.repo.preference('resources', 1);
    widget.engine.threads = threads;
    widget.engine.hashMb = threads == 1 ? 64 : 128;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) cubit.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cubit.close();
    Analytics.suppressMessages(false);
    if (!widget.study && widget.game.result == '*') {
      Notifications.scheduleResume(widget.repo, widget.game.id);
    }
    super.dispose();
  }

  Future<void> annotate(String shape) async {
    final n = widget.game.nodes
        .where((n) => n.id == widget.game.current)
        .firstOrNull;
    if (n == null) return;
    final s = '$annotationColor${shape.substring(1)}';
    n.shapes.contains(s) ? n.shapes.remove(s) : n.shapes.add(s);
    await cubit.persist();
    setState(() {});
  }

  Future<void> comment() async {
    final n = widget.game.nodes
        .where((n) => n.id == widget.game.current)
        .firstOrNull;
    if (n == null) return;
    final controller = TextEditingController(text: n.comment);
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Position notes'),
        content: TextField(controller: controller, maxLines: 5),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (text != null) {
      n.comment = text;
      await cubit.persist();
      if (mounted) setState(() {});
    }
  }

  Future<void> _resign() async {
    final g = widget.game;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
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

  String clock(int ms) =>
      '${ms ~/ 60000}:${((ms ~/ 1000) % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) => BlocBuilder<GameCubit, GameView>(
    bloc: cubit,
    builder: (context, state) {
      final g = widget.game;
      final current = g.nodes.where((n) => n.id == g.current).firstOrNull;
      final path = g.path(g.current);
      return Scaffold(
        appBar: AppBar(
          title: Text(g.title),
          actions: [
            IconButton(
              tooltip: 'Copy PGN',
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: g.exportPgn())),
              icon: const Icon(Icons.ios_share),
            ),
            IconButton(
              tooltip: 'Flip board',
              onPressed: () => setState(() => flipped = !flipped),
              icon: const Icon(Icons.flip),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  StatusChip(
                    widget.study
                        ? 'Analysis workspace'
                        : 'Stockfish · ${g.settings['level'] ?? 'Medium'}',
                    icon: widget.study
                        ? Icons.analytics_outlined
                        : Icons.memory,
                    color: context.colors.primary,
                  ),
                  const Spacer(),
                  if (cubit.timed) ...[
                    _Clock(
                      label: 'Black',
                      value: clock(cubit.black),
                      active:
                          !state.paused &&
                          g.result == '*' &&
                          g.position.turn.name == 'black',
                    ),
                    const SizedBox(width: 8),
                    _Clock(
                      label: 'White',
                      value: clock(cubit.white),
                      active:
                          !state.paused &&
                          g.result == '*' &&
                          g.position.turn.name == 'white',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              ChessBoard(
                position: g.position,
                lastMove: current?.uci,
                coordinates: coordinates,
                flipped: flipped,
                enabled: cubit.canMove,
                drawing: drawing,
                shapes: [
                  ...?current?.shapes,
                  if (state.hint != null && hintLevel == 1)
                    'Y${state.hint!.substring(0, 2)}',
                ],
                onShape: annotate,
                onMove: (m) {
                  hintLevel = 0;
                  if (sound) SystemSound.play(SystemSoundType.click);
                  if (haptics) HapticFeedback.selectionClick();
                  cubit.move(m);
                },
                arrow: state.hint != null && hintLevel > 1
                    ? state.hint
                    : widget.study
                    ? state.lines.firstOrNull?.pv.firstOrNull
                    : null,
              ),
              const SizedBox(height: 14),
              if (widget.study && state.lines.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        state.lines.first.label(
                          g.position.turn.name == 'white',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LinearProgressIndicator(
                          minHeight: 12,
                          value: state.lines.first.mate
                              ? (state.lines.first.score *
                                            (g.position.turn.name == 'white'
                                                ? 1
                                                : -1) >
                                        0
                                    ? 1
                                    : 0)
                              : (.5 +
                                    (state.lines.first.score *
                                            (g.position.turn.name == 'white'
                                                ? 1
                                                : -1)) /
                                        (2 *
                                            (state.lines.first.score.abs() +
                                                400))),
                          backgroundColor: Colors.black87,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              if (state.error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Engine paused: ${state.error}'),
                  ),
                ),
              if (!widget.study) ...[
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
                                    : 'Your move')
                              : '${g.result} · ${g.settings['reason'] ?? 'Finished'}',
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (g.result == '*')
                      FilledButton.icon(
                        onPressed: state.paused ? cubit.resume : cubit.pause,
                        icon: Icon(
                          state.paused ? Icons.play_arrow : Icons.pause,
                        ),
                        label: Text(state.paused ? 'Resume' : 'Pause'),
                      ),
                    if (g.result == '*') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ToolButton(
                              icon: Icons.undo_rounded,
                              label: 'Take back',
                              onTap: g.current == null ? null : cubit.undo,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ToolButton(
                              icon: Icons.lightbulb_outline_rounded,
                              label: 'Hint',
                              onTap: () async {
                                setState(
                                  () => hintLevel = (hintLevel + 1).clamp(1, 2),
                                );
                                await cubit.hint();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ToolButton(
                              icon: Icons.flag_outlined,
                              label: 'Resign',
                              danger: true,
                              onTap: _resign,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                        builder: (_) => GameScreen(
                          game: g,
                          repo: widget.repo,
                          engine: widget.engine,
                          study: true,
                        ),
                      ),
                    ),
                    child: const Text('Review game'),
                  ),
              ],
              if (widget.study) ...[
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<int>(
                      value: budget,
                      items: [
                        for (final pair in [
                          (1000, 'Quick'),
                          (3000, 'Balanced'),
                          (10000, 'Deep'),
                        ])
                          DropdownMenuItem(
                            value: pair.$1,
                            child: Text(pair.$2),
                          ),
                      ],
                      onChanged: (v) => setState(() => budget = v!),
                    ),
                    DropdownButton<int>(
                      value: multiPv,
                      items: [
                        for (var i = 1; i <= 3; i++)
                          DropdownMenuItem(value: i, child: Text('$i lines')),
                      ],
                      onChanged: (v) => setState(() => multiPv = v!),
                    ),
                    FilledButton(
                      onPressed: () =>
                          cubit.analyze(milliseconds: budget, multiPv: multiPv),
                      child: const Text('Analyze'),
                    ),
                    IconButton(
                      tooltip: 'Stop',
                      onPressed: cubit.pause,
                      icon: const Icon(Icons.stop_circle_outlined),
                    ),
                  ],
                ),
                for (final l in state.lines)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${l.label(g.position.turn.name == 'white')}  ·  depth ${l.depth}\n${l.pv.take(8).join(' ')}',
                      ),
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Beginning',
                      onPressed: () => cubit.navigate(null),
                      icon: const Icon(Icons.first_page),
                    ),
                    IconButton(
                      tooltip: 'Previous move',
                      onPressed: () => cubit.navigate(current?.parent),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: 'Next move',
                      onPressed: g.children(g.current).isEmpty
                          ? null
                          : () =>
                                cubit.navigate(g.children(g.current).first.id),
                      icon: const Icon(Icons.chevron_right),
                    ),
                    IconButton(
                      tooltip: 'Draw annotations',
                      isSelected: drawing,
                      onPressed: () => setState(() => drawing = !drawing),
                      icon: const Icon(Icons.draw_outlined),
                    ),
                    IconButton(
                      tooltip: 'Comment',
                      onPressed: comment,
                      icon: const Icon(Icons.comment_outlined),
                    ),
                    IconButton(
                      tooltip: 'Clear annotations',
                      onPressed: () async {
                        current?.shapes.clear();
                        await cubit.persist();
                        setState(() {});
                      },
                      icon: const Icon(Icons.layers_clear),
                    ),
                  ],
                ),
                if (drawing)
                  Wrap(
                    children: [
                      for (final c in ['G', 'R', 'B', 'Y'])
                        ChoiceChip(
                          label: Text(
                            {
                              'G': 'Green',
                              'R': 'Red',
                              'B': 'Blue',
                              'Y': 'Yellow',
                            }[c]!,
                          ),
                          selected: annotationColor == c,
                          onSelected: (_) =>
                              setState(() => annotationColor = c),
                        ),
                    ],
                  ),
                if (current != null)
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final nag in [
                        (1, '!'),
                        (2, '?'),
                        (3, '!!'),
                        (4, '??'),
                        (5, '!?'),
                        (6, '?!'),
                      ])
                        FilterChip(
                          label: Text(nag.$2),
                          selected: current.nags.contains(nag.$1),
                          onSelected: (v) async {
                            v
                                ? current.nags.add(nag.$1)
                                : current.nags.remove(nag.$1);
                            await cubit.persist();
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                if (current?.comment.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(current!.comment),
                  ),
              ],
              const Divider(),
              Text('MOVES', style: Theme.of(context).textTheme.labelLarge),
              Wrap(
                spacing: 0,
                runSpacing: 2,
                children: [
                  for (
                    var i = 0;
                    i < (widget.study ? path : g.mainline).length;
                    i++
                  )
                    MoveChip(
                      number: i % 2 == 0 ? '${i ~/ 2 + 1}.' : null,
                      san: (widget.study ? path : g.mainline)[i].san,
                      selected:
                          (widget.study ? path : g.mainline)[i].id == g.current,
                      onTap: widget.study
                          ? () => cubit.navigate(
                              (widget.study ? path : g.mainline)[i].id,
                            )
                          : null,
                    ),
                ],
              ),
              if (widget.study) ...[
                for (final n in g.children(g.current))
                  ListTile(
                    title: Text(n.san),
                    subtitle: Text(n.comment, maxLines: 1),
                    trailing: (g.source == 'study' || !g.mainline.contains(n))
                        ? IconButton(
                            tooltip: 'Delete variation',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final yes = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Delete this variation?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (yes != true) return;
                              await cubit.pause();
                              final ids = <String>{n.id};
                              bool changed = true;
                              while (changed) {
                                final before = ids.length;
                                ids.addAll(
                                  g.nodes
                                      .where((e) => ids.contains(e.parent))
                                      .map((e) => e.id),
                                );
                                changed = ids.length != before;
                              }
                              await widget.repo.db.execute(
                                'DELETE FROM nodes WHERE id=?',
                                [n.id],
                              );
                              g.nodes.removeWhere((e) => ids.contains(e.id));
                              if (mounted) setState(() {});
                            },
                          )
                        : const Icon(Icons.call_split),
                    onTap: () => cubit.navigate(n.id),
                  ),
                OutlinedButton.icon(
                  onPressed: state.thinking ? null : () => cubit.review(budget),
                  icon: const Icon(Icons.analytics_outlined),
                  label: Text(
                    state.reviewTotal > 0
                        ? 'Review ${state.reviewDone}/${state.reviewTotal} moves'
                        : 'Review whole game',
                  ),
                ),
                FutureBuilder(
                  future: widget.repo.db.rows(
                    'SELECT nodes.san,analysis.data FROM analysis JOIN nodes ON nodes.id=analysis.node_id WHERE analysis.game_id=? ORDER BY nodes.ordinal',
                    [g.id],
                  ),
                  builder: (context, s) => Column(
                    children: [
                      for (final r in s.data ?? [])
                        ListTile(
                          title: Text(r['san']),
                          subtitle: Text(jsonDecode(r['data'])['label']),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _Clock extends StatelessWidget {
  const _Clock({
    required this.label,
    required this.value,
    required this.active,
  });
  final String label, value;
  final bool active;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label clock $value${active ? ', running' : ''}',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? context.colors.primary
            : context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExcludeSemantics(
        child: Text(
          value,
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: active ? context.colors.onPrimary : context.colors.onSurface,
          ),
        ),
      ),
    ),
  );
}
