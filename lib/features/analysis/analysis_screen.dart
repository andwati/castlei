import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/chess/model.dart';
import '../../core/chess/openings.dart';
import '../../core/diagnostics/analytics.dart';
import '../../core/engine/engine.dart';
import '../../core/storage/repository.dart';
import '../../core/ui/board.dart';
import '../../core/ui/board_workspace.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/widgets.dart';
import '../play/game_common.dart';
import '../play/game_cubit.dart';
import 'eval_graph.dart';
import 'review_screen.dart';

/// Free-form analysis board: explore lines, annotate, run the engine, review a
/// finished game. Used for studies, repertoires and reviewing played games.
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({
    super.key,
    required this.game,
    required this.repo,
    required this.engine,
  });
  final ChessGame game;
  final Repository repo;
  final EngineClient engine;
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with WidgetsBindingObserver, GamePreferences<AnalysisScreen> {
  @override
  Repository get repo => widget.repo;
  @override
  EngineClient get engine => widget.engine;
  @override
  bool get isStudy => true;

  late final GameCubit cubit;
  bool drawing = false;
  String annotationColor = 'G';
  Future<List<Map<String, dynamic>>>? _reviewRows;
  Map<String, String> _labels = {};
  int _reviewKey = -1;

  @override
  void initState() {
    super.initState();
    cubit = GameCubit(widget.game, widget.repo, widget.engine, study: true);
    flipped = widget.game.settings['side'] == 'black';
    WidgetsBinding.instance.addObserver(this);
    loadPreferences();
    Openings.load().then((_) {
      if (mounted) setState(() {});
    });
    // Don't interrupt analysis with in-app announcements.
    Analytics.suppressMessages(true);
    Analytics.screen('analysis');
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

  @override
  Widget build(BuildContext context) => BlocBuilder<GameCubit, GameView>(
    bloc: cubit,
    builder: (context, state) {
      final g = widget.game;
      final current = g.nodes.where((n) => n.id == g.current).firstOrNull;
      final path = g.path(g.current);
      announceMove(g, current);
      if (_reviewKey != state.reviewDone || _reviewRows == null) {
        _reviewKey = state.reviewDone;
        _reviewRows = widget.repo.db.rows(
          'SELECT nodes.id,nodes.san,analysis.data FROM analysis JOIN nodes ON nodes.id=analysis.node_id WHERE analysis.game_id=? ORDER BY nodes.ordinal',
          [g.id],
        );
        loadReviewLabels(widget.repo, g.id).then((labels) {
          if (mounted) setState(() => _labels = labels);
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
                  const StatusChip(
                    'Analysis workspace',
                    icon: Icons.analytics_outlined,
                  ),
                  StatusChip(
                    state.thinking ? 'Analyzing…' : 'Analysis stopped',
                    icon: Icons.analytics_outlined,
                  ),
                ],
              ),
              TurnCue(position: g.position),
              PlayerRow(
                game: g,
                cubit: cubit,
                state: state,
                side: flipped ? Side.white : Side.black,
                study: true,
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
                drawing: drawing,
                shapes: [...?current?.shapes],
                onShape: annotate,
                onMove: (m) => cubit.move(m),
                arrow: state.lines.firstOrNull?.pv.firstOrNull,
              ),
              PlayerRow(
                game: g,
                cubit: cubit,
                state: state,
                side: flipped ? Side.black : Side.white,
                study: true,
              ),
              const SizedBox(height: 8),
              if (state.lines.isNotEmpty)
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
                        DropdownMenuItem(value: pair.$1, child: Text(pair.$2)),
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
                          : () =>
                                cubit.navigate(g.children(g.current).first.id),
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
                        onSelected: (_) => setState(() => annotationColor = c),
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
              const Divider(),
              Text('MOVES', style: Theme.of(context).textTheme.labelLarge),
              Wrap(
                spacing: 4,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < path.length; i++)
                    MoveChip(
                      number: i % 2 == 0 ? '${i ~/ 2 + 1}.' : null,
                      san: path[i].san,
                      badge: badgeFor(_labels[path[i].id] ?? ''),
                      selected: path[i].id == g.current,
                      onTap: () => cubit.navigate(path[i].id),
                    ),
                ],
              ),
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
                onPressed: state.thinking
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewScreen(
                            game: widget.game,
                            repo: widget.repo,
                            engine: widget.engine,
                          ),
                        ),
                      ),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Guided review'),
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
          ),
        ),
      );
    },
  );
}
