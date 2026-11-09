import 'dart:convert';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/diagnostics/analytics.dart';
import '../../core/notifications/notifications.dart';
import '../../core/ui/board.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/board_workspace.dart';
import '../../core/ui/sfx.dart';
import '../../core/ui/widgets.dart';
import '../../core/chess/model.dart';
import '../../core/storage/repository.dart';
import 'training.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({
    super.key,
    required this.repo,
    this.repertoire,
    this.initialTheme = '',
  });
  final Repository repo;
  final String? repertoire;
  final String initialTheme;
  @override
  State<TrainingScreen> createState() => _TrainingState();
}

class _TrainingState extends State<TrainingScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> items = [];
  int index = 0, ply = 0, hints = 0;
  bool sound = false, haptics = true, revealing = false;
  String? lastMove;
  int revealPly = 0;
  bool failed = false, complete = false, busy = false, loading = true;
  String message = 'Find the move';
  Position? position;
  List<String> solution = [];
  final watch = Stopwatch();
  String theme = '';
  int rating = 3000;
  bool get opening => widget.repertoire != null;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Analytics.screen(opening ? 'drills' : 'puzzles');
    theme = widget.initialTheme;
    _preferences();
    load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    watch.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !loading && !complete) {
      watch.start();
    } else {
      watch.stop();
    }
  }

  Future<void> _preferences() async {
    sound = await widget.repo.preference('sound', false);
    haptics = await widget.repo.preference('haptics', true);
  }

  void _play(String uci) {
    final move = Move.parse(uci)!;
    final san = position!.makeSan(move).$2;
    position = position!.play(move);
    lastMove = uci;
    Sfx.play(Sfx.forSan(san), sound: sound, haptics: haptics);
  }

  void _reveal(int next) {
    position = Chess.fromSetup(Setup.parseFen(items[index]['fen']));
    lastMove = null;
    for (final uci in solution.take(next)) {
      position = position!.play(Move.parse(uci)!);
      lastMove = uci;
    }
    revealPly = next;
    setState(() {});
  }

  String get solutionSan {
    Position p = Chess.fromSetup(Setup.parseFen(items[index]['fen']));
    final out = <String>[];
    for (final uci in solution) {
      final move = Move.parse(uci)!;
      if (!p.isLegal(move)) break;
      final next = p.makeSan(move);
      out.add(next.$2);
      p = next.$1;
      if (opening) break;
    }
    return out.join(' ');
  }

  Future<void> load() async {
    await widget.repo.seeding;
    final db = widget.repo.db;
    List<Map<String, dynamic>> rows;
    if (opening) {
      final due = await db.rows(
        'SELECT * FROM cards WHERE repertoire_id=? AND stage>0 AND due<=? ORDER BY due LIMIT ?',
        [
          widget.repertoire!,
          DateTime.now().millisecondsSinceEpoch,
          await widget.repo.preference('dueLimit', 20),
        ],
      );
      final fresh = await db.rows(
        'SELECT * FROM cards WHERE repertoire_id=? AND stage=0 LIMIT ?',
        [widget.repertoire!, await widget.repo.preference('newLimit', 5)],
      );
      rows = [...due, ...fresh];
    } else {
      rows = await db.rows(
        "SELECT * FROM puzzles WHERE rating<=? AND themes LIKE ? ORDER BY (SELECT count(*) FROM attempts WHERE target=puzzles.id),id LIMIT 100",
        [rating, '%$theme%'],
      );
    }
    if (!mounted) return;
    items = rows;
    index = 0;
    loading = false;
    if (items.isNotEmpty) start();
    setState(() {});
  }

  void start() {
    final item = items[index];
    position = Chess.fromSetup(Setup.parseFen(item['fen']));
    solution = List<String>.from(jsonDecode(item['moves']));
    ply = 0;
    lastMove = null;
    revealing = false;
    revealPly = 0;
    hints = 0;
    failed = false;
    complete = false;
    message = opening ? 'Play a repertoire move' : 'Find the best continuation';
    watch.reset();
    watch.start();
  }

  Future<void> finish(bool success) async {
    complete = true;
    watch.stop();
    final service = TrainingService(widget.repo);
    if (opening) {
      if (items[index]['_retry'] == true) {
        await service.record(
          'opening',
          items[index]['id'],
          success,
          hints,
          watch.elapsedMilliseconds,
          {'repertoire': items[index]['repertoire_id'], 'retry': true},
        );
      } else {
        await service.answerCard(
          items[index],
          success,
          hints,
          watch.elapsedMilliseconds,
        );
      }
      if (!success && items[index]['_retry'] != true) {
        items.insert((index + 4).clamp(0, items.length), {
          ...items[index],
          '_retry': true,
        });
      }
    } else {
      await service.record(
        'puzzle',
        items[index]['id'],
        success,
        hints,
        watch.elapsedMilliseconds,
        {'rating': items[index]['rating'], 'themes': items[index]['themes']},
      );
    }
    Analytics.log(opening ? 'drill_completed' : 'puzzle_completed', {
      'first_attempt': success ? 'yes' : 'no',
      'hints': hints,
    });
    // Reschedule reminders around the new schedule; ask for permission once.
    Notifications.maybePromptOnce(widget.repo);
    Notifications.reschedule(widget.repo);
    if (mounted) setState(() {});
  }

  Future<void> move(Move m) async {
    if (complete || busy) return;
    final normalized = standardUci(position!, m);
    if (opening
        ? !solution.contains(normalized)
        : solution[ply] != normalized) {
      setState(() {
        failed = true;
        message = opening
            ? 'Outside your repertoire. Try again.'
            : 'Not the supplied solution. Try again.';
      });
      return;
    }
    busy = true;
    setState(() {
      _play(normalized);
      ply++;
      message = opening || ply == solution.length
          ? 'Good move'
          : 'Opponent’s reply…';
    });
    if (opening || ply == solution.length) {
      await finish(!failed && hints == 0);
      message = failed || hints > 0
          ? 'Completed with practice'
          : 'Solved without help';
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      _play(solution[ply]);
      ply++;
      if (ply == solution.length) {
        await finish(!failed && hints == 0);
      } else {
        message = 'Your turn · Find the continuation';
      }
    }
    busy = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(opening ? 'Opening practice' : 'Tactical puzzles'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : BoardWorkspace(
            padding: pagePadding(context),
            children: [
              if (!opening)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PopupMenuButton<int>(
                      tooltip: 'Maximum rating',
                      initialValue: rating,
                      onSelected: (r) {
                        rating = r;
                        load();
                      },
                      itemBuilder: (_) => [
                        for (final r in [1000, 1500, 2000, 2500, 3000])
                          PopupMenuItem(value: r, child: Text('Up to $r')),
                      ],
                      child: Chip(
                        avatar: const Icon(Icons.speed_rounded, size: 18),
                        label: Text('Up to $rating'),
                        deleteIcon: const Icon(Icons.arrow_drop_down),
                        onDeleted: null,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Theme',
                      initialValue: theme,
                      onSelected: (t) {
                        theme = t;
                        load();
                      },
                      itemBuilder: (_) => [
                        for (final t in [
                          '',
                          'fork',
                          'pin',
                          'mate',
                          'endgame',
                          'sacrifice',
                        ])
                          PopupMenuItem(
                            value: t,
                            child: Text(t.isEmpty ? 'All themes' : t),
                          ),
                      ],
                      child: Chip(
                        avatar: const Icon(Icons.category_outlined, size: 18),
                        label: Text(theme.isEmpty ? 'All themes' : theme),
                      ),
                    ),
                  ],
                ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.task_alt_rounded,
                        size: 52,
                        color: context.colors.primary,
                      ),
                      const SizedBox(height: 14),
                      Text('All caught up', style: context.text.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        opening
                            ? 'Nothing is due in this repertoire. Come back tomorrow, or add more lines.'
                            : 'Nothing matches this filter. Try a higher rating or another theme.',
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              if (position != null && items.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1} of ${items.length}',
                        style: context.text.labelLarge,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (index + (complete ? 1 : 0)) / items.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TurnCue(
                  position: position!,
                  detail:
                      'You play ${Chess.fromSetup(Setup.parseFen(items[index]['fen'])).turn == Side.white ? 'White' : 'Black'}',
                ),
                ChessBoard(
                  position: position!,
                  lastMove: lastMove,
                  flipped:
                      Chess.fromSetup(Setup.parseFen(items[index]['fen']))
                          .turn ==
                      Side.black,
                  enabled: !complete && !busy,
                  onMove: move,
                  shapes: hints == 1 && !complete
                      ? ['Y${solution[opening ? 0 : ply].substring(0, 2)}']
                      : [],
                  arrow: hints > 1 && !complete
                      ? solution[opening ? 0 : ply]
                      : null,
                ),
                const SizedBox(height: 16),
                FeedbackCard(
                  message,
                  tone: failed && !complete
                      ? Tone.bad
                      : complete
                      ? (failed || hints > 0 ? Tone.info : Tone.good)
                      : Tone.neutral,
                  icon: complete
                      ? (failed || hints > 0
                            ? Icons.school_outlined
                            : Icons.emoji_events_outlined)
                      : failed
                      ? Icons.refresh_rounded
                      : Icons.touch_app_outlined,
                ),
                const SizedBox(height: 12),
                if (!complete)
                  ToolRow(
                    children: [
                      ToolButton(
                        icon: Icons.lightbulb_outline_rounded,
                        label: 'Hint',
                        onTap: () => setState(() => hints++),
                      ),
                      ToolButton(
                        icon: Icons.visibility_outlined,
                        label: 'Reveal',
                        onTap: () async {
                          setState(() {
                            failed = true;
                            message = 'Solution: $solutionSan';
                            revealing = true;
                          });
                          await finish(false);
                          if (mounted) _reveal(0);
                        },
                      ),
                    ],
                  ),
                if (revealing) const SizedBox(height: 12),
                if (revealing)
                  Row(
                    spacing: 12,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Previous solution move',
                        onPressed: revealPly > 0
                            ? () => _reveal(revealPly - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('$revealPly / ${opening ? 1 : solution.length}'),
                      IconButton(
                        tooltip: 'Next solution move',
                        onPressed: revealPly < (opening ? 1 : solution.length)
                            ? () => _reveal(revealPly + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                if (complete) const SizedBox(height: 12),
                if (complete && index + 1 < items.length)
                  FilledButton.icon(
                    onPressed: () => setState(() {
                      index++;
                      start();
                    }),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Next position'),
                  ),
                if (complete && index + 1 >= items.length)
                  FeedbackCard(
                    'Session complete — nice work.',
                    tone: Tone.good,
                    icon: Icons.celebration_outlined,
                  ),
              ],
            ],
          ),
  );
}
