import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/chess/model.dart';
import '../../core/storage/repository.dart';
import '../../core/ui/board.dart';
import '../../core/ui/board_workspace.dart';
import '../../core/ui/sfx.dart';
import '../../core/ui/widgets.dart';
import '../../core/ui/theme.dart';
import '../puzzles/training.dart';
import 'lessons.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key, required this.repo});
  final Repository repo;
  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  late Future<List<GuidedLesson>> course = loadLessons();
  Map<String, dynamic> progress = {};
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final p = await widget.repo.preference(
      'lessons.progress.v1',
      <String, dynamic>{},
    );
    if (mounted) setState(() => progress = Map<String, dynamic>.from(p));
  }

  Future<void> open(GuidedLesson lesson) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(repo: widget.repo, lesson: lesson),
      ),
    );
    await refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Guided lessons')),
    body: FutureBuilder<List<GuidedLesson>>(
      future: course,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(() => course = loadLessons()),
              child: const Text('Unable to load lessons · Retry'),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final lessons = snap.data!;
        final completed = lessons
            .where((l) => progress[l.id]?['completed'] == true)
            .length;
        final unfinished = lessons
            .where((l) => progress[l.id]?['completed'] != true)
            .toList();
        final active =
            unfinished.where((l) => progress[l.id] != null).firstOrNull ??
            unfinished.firstOrNull;
        return ListView(
          padding: pagePadding(context),
          children: [
            Text(
              '$completed of ${lessons.length} lessons complete',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: completed / lessons.length),
            if (active != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: FilledButton.icon(
                  onPressed: () => open(active),
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Continue · ${active.title}'),
                ),
              ),
            for (final module in lessons.map((l) => l.module).toSet()) ...[
              SectionLabel(module),
              for (final l in lessons.where((l) => l.module == module))
                Card(
                  child: ListTile(
                    leading: Icon(
                      progress[l.id]?['completed'] == true
                          ? Icons.check_circle
                          : Icons.school_outlined,
                    ),
                    title: Text(l.title),
                    subtitle: Text(
                      progress[l.id]?['completed'] == true
                          ? (progress[l.id]?['assisted'] == true
                                ? 'Completed with help · Review anytime'
                                : 'Completed without help · Review anytime')
                          : 'Explanation · 3 board exercises',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => open(l),
                  ),
                ),
            ],
          ],
        );
      },
    ),
  );
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.repo, required this.lesson});
  final Repository repo;
  final GuidedLesson lesson;
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with WidgetsBindingObserver {
  int index = 0, ply = 0, hints = 0;
  bool loading = true,
      done = false,
      busy = false,
      failed = false,
      assisted = false,
      sound = false,
      haptics = true;
  String? lastMove, feedback;
  late Position position;
  List<String> played = [];
  final watch = Stopwatch();
  final Set<int> helped = {};
  LessonExercise get exercise => widget.lesson.exercises[index];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    restore();
  }

  Future<void> restore() async {
    sound = await widget.repo.preference('sound', false);
    haptics = await widget.repo.preference('haptics', true);
    final progress = await widget.repo.preference(
      'lessons.progress.v1',
      <String, dynamic>{},
    );
    final old = progress[widget.lesson.id];
    if (old != null && old['completed'] != true) {
      index = (old['next'] as int? ?? 0).clamp(0, 2);
      assisted = old['assisted'] == true;
      helped.addAll(List<int>.from(old['helped'] ?? []));
    }
    if (!mounted) return;
    start();
    await save(index, false);
    if (mounted) setState(() => loading = false);
  }

  void start() {
    position = exercise.initial;
    ply = 0;
    played = [];
    done = false;
    hints = 0;
    failed = false;
    busy = false;
    feedback = null;
    lastMove = null;
    watch.reset();
    watch.start();
  }

  Future<void> save(int next, bool completed) async {
    final progress = Map<String, dynamic>.from(
      await widget.repo.preference('lessons.progress.v1', <String, dynamic>{}),
    );
    final old = progress[widget.lesson.id];
    progress[widget.lesson.id] = {
      'next': next,
      'helped': helped.toList(),
      'completed': completed || old?['completed'] == true,
      'assisted': old?['completed'] == true && old?['assisted'] == false
          ? false
          : assisted,
    };
    await widget.repo.setPreference('lessons.progress.v1', progress);
    widget.repo.touch();
  }

  Future<void> finish() async {
    if (done) return;
    watch.stop();
    setState(() {
      done = true;
      busy = true;
      assisted = assisted || hints > 0 || failed;
    });
    await TrainingService(widget.repo).record(
      'lesson',
      '${widget.lesson.id}:$index',
      !failed && hints == 0 && !helped.contains(index),
      hints,
      watch.elapsedMilliseconds,
      {
        'lesson': widget.lesson.id,
        'module': widget.lesson.module,
        'exercise': index,
        'assisted': helped.contains(index),
      },
    );
    await save(index + 1, index == 2);
    if (mounted) {
      setState(() {
        busy = false;
        feedback = assisted
            ? 'Completed with practice. You can review this lesson anytime.'
            : 'Well done · Completed without help';
      });
    }
  }

  Future<void> demonstrate() async {
    if (busy || done || exercise.solutions.isEmpty) return;
    setState(() {
      assisted = true;
      helped.add(index);
      busy = true;
      position = exercise.initial;
      played = [];
      ply = 0;
    });
    await save(index, false);
    for (final uci in exercise.solutions.first) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() {
        commit(uci);
        feedback = 'Example · Watch the continuation';
      });
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      start();
      feedback = 'Now try it yourself';
    });
  }

  void wrong() {
    setState(() {
      failed = true;
      helped.add(index);
      feedback = 'Try again. ${exercise.hint}';
    });
  }

  Future<void> answer(int choice) async {
    if (done || busy) return;
    if (choice == exercise.correct) {
      await finish();
    } else {
      wrong();
    }
  }

  void commit(String uci) {
    final move = Move.parse(uci)!;
    Sfx.play(
      Sfx.forSan(position.makeSan(move).$2),
      sound: sound,
      haptics: haptics,
    );
    position = position.play(move);
    lastMove = uci;
    played.add(uci);
    ply++;
  }

  Future<void> move(Move move) async {
    if (busy || done) return;
    final uci = standardUci(position, move);
    final candidates = exercise.solutions
        .where(
          (line) =>
              line.length > ply &&
              line.take(ply).join(' ') == played.join(' ') &&
              line[ply] == uci,
        )
        .toList();
    if (candidates.isEmpty) {
      wrong();
      return;
    }
    setState(() {
      busy = true;
      commit(uci);
      feedback = 'Good move';
    });
    final line = candidates.first;
    if (ply < line.length) {
      setState(() => feedback = 'Opponent’s reply…');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        commit(line[ply]);
        feedback = 'Your turn';
      });
    }
    if (ply == line.length) await finish();
    if (mounted) setState(() => busy = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !done && !loading && !busy) {
      watch.start();
    } else {
      watch.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    watch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.lesson.title)),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : BoardWorkspace(
            children: [
              Text(
                widget.lesson.module,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  widget.lesson.body,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Text(
                'Exercise ${index + 1} of 3',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TurnCue(position: position),
              ChessBoard(
                position: position,
                flipped: exercise.initial.turn == Side.black,
                lastMove: lastMove,
                enabled: !done && !busy && exercise.options.isEmpty,
                onMove: move,
                arrow: hints > 0 && exercise.solutions.isNotEmpty && !done
                    ? exercise.solutions.firstWhere(
                        (line) => line.take(ply).join(' ') == played.join(' '),
                      )[ply]
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  exercise.goal,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (exercise.options.isNotEmpty)
                for (var i = 0; i < exercise.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton(
                      onPressed: done || busy ? null : () => answer(i),
                      child: Text(exercise.options[i]),
                    ),
                  ),
              if (feedback != null)
                Semantics(
                  liveRegion: true,
                  child: FeedbackCard(
                    feedback!,
                    tone: done
                        ? Tone.good
                        : failed
                        ? Tone.bad
                        : Tone.info,
                    icon: done ? Icons.check_circle : Icons.info_outline,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ActionStack(
                  children: [
                    if (!done && exercise.solutions.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: busy ? null : demonstrate,
                        icon: const Icon(Icons.slideshow),
                        label: const Text('Show example'),
                      ),
                    if (!done)
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                hints++;
                                helped.add(index);
                                assisted = true;
                                feedback = exercise.hint;
                              }),
                        icon: const Icon(Icons.lightbulb_outline),
                        label: const Text('Hint'),
                      ),
                    if (done)
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () {
                                if (index == 2) {
                                  Navigator.pop(context);
                                } else {
                                  setState(() {
                                    index++;
                                    start();
                                  });
                                }
                              },
                        child: Text(
                          index == 2 ? 'Finish lesson' : 'Next exercise',
                        ),
                      ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              assisted = assisted || failed || hints > 0;
                              start();
                            }),
                      child: const Text('Restart exercise'),
                    ),
                  ],
                ),
              ),
            ],
          ),
  );
}
