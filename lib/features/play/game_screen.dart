import 'dart:convert';

import 'package:dartchess/dartchess.dart';

import '../../core/ui/board_workspace.dart';

import 'package:flutter/material.dart';

import '../../core/chess/openings.dart';
import '../../core/diagnostics/analytics.dart';
import '../analysis/eval_graph.dart';
import '../../core/notifications/notifications.dart';
import '../../core/ui/sfx.dart';
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
  Future<List<Map<String, dynamic>>>? _reviewRows;
  Map<String, String> _labels = {};
  int _reviewKey = -1;
  String? _soundNode;
  String _soundResult = '*';
  bool _soundSeeded = false;
  final Set<String> _lowTimeWarned = {};
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
    Openings.load().then((_) {
      if (mounted) setState(() {});
    });
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
      builder: (c) => ActionDialog(
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

  /// Plays a sound/haptic when a move is committed (by either side), not when
  /// the user merely browses the move list.
  void _announceMove(ChessGame g, StudyNode? current) {
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
    final kind = ended && !widget.study
        ? MoveSound.end
        : Sfx.forSan(current!.san);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Sfx.play(kind, sound: sound, haptics: haptics),
    );
  }

  Widget _player(ChessGame g, GameView state, Side side) {
    final white = side == Side.white;
    final human = side == cubit.human;
    final ms = white ? cubit.white : cubit.black;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(white ? '♔' : '♚', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.study
                  ? ''
                  : human
                  ? 'You · '
                  : 'Stockfish · '}${white ? 'White' : 'Black'}',
              style: context.text.titleSmall,
            ),
          ),
          if (cubit.timed && !widget.study)
            _Clock(
              label: white ? 'White' : 'Black',
              value: clock(ms),
              low: ms < 20000,
              active:
                  !state.paused && g.result == '*' && g.position.turn == side,
            ),
        ],
      ),
    );
  }

  String _variation(Position position, List<String> moves) {
    final words = <String>[];
    for (final uci in moves.take(8)) {
      final move = Move.parse(uci);
      if (move == null || !position.isLegal(move)) break;
      final next = position.makeSan(move);
      words.add(next.$2);
      position = next.$1;
    }
    return words.join(' ');
  }

  Future<void> _exploreLine(List<String> moves) async {
    var position = widget.game.position;
    final legal = <Move>[];
    for (final uci in moves) {
      final move = Move.parse(uci);
      if (move == null || !position.isLegal(move)) return;
      legal.add(move);
      position = position.play(move);
    }
    await cubit.pause();
    String? first;
    for (final move in legal) {
      final node = widget.game.play(move);
      first ??= node.id;
    }
    await cubit.persist();
    await cubit.navigate(first ?? widget.game.current);
    if (mounted) setState(() {});
  }

  Future<void> _rematch() async {
    final old = widget.game;
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
    await widget.repo.save(game);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GameScreen(game: game, repo: widget.repo, engine: widget.engine),
      ),
    );
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
      _announceMove(g, current);
      if (!widget.study && !state.paused && g.result == '*' && cubit.timed) {
        for (final pair in [('white', cubit.white), ('black', cubit.black)]) {
          if (pair.$2 > 0 && pair.$2 < 20000 && _lowTimeWarned.add(pair.$1)) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => Sfx.play(MoveSound.check, sound: sound, haptics: haptics),
            );
          }
        }
      }
      if (_reviewKey != state.reviewDone || _reviewRows == null) {
        _reviewKey = state.reviewDone;
        _reviewRows = widget.repo.db.rows(
          'SELECT nodes.id,nodes.san,analysis.data FROM analysis JOIN nodes ON nodes.id=analysis.node_id WHERE analysis.game_id=? ORDER BY nodes.ordinal',
          [g.id],
        );
        _reviewRows!.then((rows) {
          if (!mounted) return;
          setState(
            () => _labels = {
              for (final r in rows)
                r['id'] as String: jsonDecode(r['data'])['label'] as String,
            },
          );
        });
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
                    widget.study
                        ? 'Analysis workspace'
                        : 'Stockfish · ${g.settings['level'] ?? 'Medium'}',
                    icon: widget.study
                        ? Icons.analytics_outlined
                        : Icons.memory,
                  ),
                  if (widget.study)
                    StatusChip(
                      state.thinking ? 'Analyzing…' : 'Analysis stopped',
                      icon: Icons.analytics_outlined,
                    ),
                ],
              ),
              TurnCue(position: g.position),
              _player(g, state, flipped ? Side.white : Side.black),
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
                drawing: drawing,
                shapes: [
                  ...?current?.shapes,
                  if (state.hint != null && hintLevel == 1)
                    'Y${state.hint!.substring(0, 2)}',
                ],
                onShape: annotate,
                onMove: (m) {
                  hintLevel = 0;
                  cubit.move(m);
                },
                arrow: state.hint != null && hintLevel > 1
                    ? state.hint
                    : widget.study
                    ? state.lines.firstOrNull?.pv.firstOrNull
                    : null,
              ),
              _player(g, state, flipped ? Side.black : Side.white),
              const SizedBox(height: 8),
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
                        icon: Icon(
                          state.paused ? Icons.play_arrow : Icons.pause,
                        ),
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
                if (g.result != '*') const SizedBox(height: 12),
                if (g.result != '*')
                  TextButton.icon(
                    onPressed: _rematch,
                    icon: const Icon(Icons.replay),
                    label: const Text('Play again'),
                  ),
              ],
              if (widget.study) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
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
                const Text('Evaluation from White’s perspective'),
                for (final l in state.lines)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${l.label(g.position.turn == Side.white)} · depth ${l.depth}',
                      ),
                      subtitle: Text(_variation(g.position, l.pv)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exploreLine(l.pv),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Beginning',
                        onPressed: () => cubit.navigate(null),
                        icon: const Icon(Icons.first_page),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Previous move',
                        onPressed: () => cubit.navigate(current?.parent),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Next move',
                        onPressed: g.children(g.current).isEmpty
                            ? null
                            : () => cubit.navigate(
                                g.children(g.current).first.id,
                              ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Draw annotations',
                        isSelected: drawing,
                        onPressed: () => setState(() => drawing = !drawing),
                        icon: const Icon(Icons.draw_outlined),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Comment',
                        onPressed: comment,
                        icon: const Icon(Icons.comment_outlined),
                      ),
                      IconButton.filledTonal(
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
                ),
                if (drawing)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
                    spacing: 8,
                    runSpacing: 8,
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
                spacing: 4,
                runSpacing: 8,
                children: [
                  for (
                    var i = 0;
                    i < (widget.study ? path : g.mainline).length;
                    i++
                  )
                    MoveChip(
                      number: i % 2 == 0 ? '${i ~/ 2 + 1}.' : null,
                      san: (widget.study ? path : g.mainline)[i].san,
                      badge: badgeFor(
                        _labels[(widget.study ? path : g.mainline)[i].id] ?? '',
                      ),
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
                                builder: (c) => ActionDialog(
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
                const SizedBox(height: 12),
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
                  future: _reviewRows,
                  builder: (context, s) {
                    final points = parseReview(s.data ?? [], g);
                    return Column(
                      children: [
                        EvalGraph(
                          points: points,
                          selectedNodeId: g.current,
                          onSelect: cubit.navigate,
                        ),
                        for (final p in points)
                          ListTile(
                            dense: true,
                            title: Text(
                              '${(p.ply + 1) ~/ 2}${p.whiteMoved ? '.' : '...'} ${p.san}${badgeFor(p.label)}',
                            ),
                            subtitle: Text('${p.label} · ${p.evalText}'),
                            selected: p.nodeId == g.current,
                            onTap: () => cubit.navigate(p.nodeId),
                          ),
                      ],
                    );
                  },
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
