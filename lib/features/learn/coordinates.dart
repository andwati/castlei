import '../../core/ui/plural.dart';

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/storage/repository.dart';
import '../../core/ui/widgets.dart';
import '../../core/ui/theme.dart';
import '../puzzles/training.dart';

import 'dart:async';

String coordinateAt(int index, bool black) {
  final file = black ? 7 - index % 8 : index % 8;
  final rank = black ? index ~/ 8 : 7 - index ~/ 8;
  return '${'abcdefgh'[file]}${rank + 1}';
}

class CoordinateScreen extends StatefulWidget {
  const CoordinateScreen({super.key, required this.repo});
  final Repository repo;
  @override
  State<CoordinateScreen> createState() => _CoordinateState();
}

class _CoordinateState extends State<CoordinateScreen>
    with WidgetsBindingObserver {
  String mode = 'find',
      orientation = 'white',
      target = 'a1',
      message = '',
      file = '';
  bool timed = false,
      running = false,
      black = false,
      paused = false,
      saving = false,
      ready = false;
  int correct = 0, attempts = 0, best = 0;
  String? flashSquare;
  bool flashRight = true;
  Timer? flashTimer;
  final random = Random();
  final watch = Stopwatch();
  final response = Stopwatch();
  final responses = <int>[];
  Timer? timer;
  String get bestKey => 'coordinates.best.$mode.$orientation';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    restore();
  }

  Future<void> restore() async {
    final settings = await widget.repo.preference(
      'coordinates.settings',
      <String, dynamic>{},
    );
    mode = settings['mode'] ?? 'find';
    orientation = settings['orientation'] ?? 'white';
    timed = settings['timed'] != false;
    await refreshBest();
    if (mounted) setState(() => ready = true);
  }

  Future<void> refreshBest() async {
    final value = await widget.repo.preference(bestKey, 0);
    if (mounted) setState(() => best = value);
  }

  void next() {
    final old = target;
    do {
      target = coordinateAt(random.nextInt(64), false);
    } while (target == old);
    black =
        orientation == 'black' || orientation == 'random' && random.nextBool();
    file = '';
    response.reset();
    response.start();
  }

  Future<void> start() async {
    if (saving || running) return;
    setState(() => saving = true);
    await widget.repo.setPreference('coordinates.settings', {
      'mode': mode,
      'orientation': orientation,
      'timed': timed,
    });
    if (!mounted) return;
    setState(() {
      correct = 0;
      attempts = 0;
      responses.clear();
      running = true;
      saving = false;
      paused = false;
      message = '';
      watch.reset();
      watch.start();
      next();
    });
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || !running || paused) return;
      if (timed && watch.elapsedMilliseconds >= 30000) {
        finish();
      } else {
        setState(() {});
      }
    });
  }

  Future<void> finish() async {
    if (!running || saving) return;
    watch.stop();
    response.stop();
    timer?.cancel();
    final duration = watch.elapsedMilliseconds;
    setState(() {
      running = false;
      paused = false;
      saving = true;
    });
    await TrainingService(widget.repo).record(
      'coordinate',
      '$mode:$orientation',
      attempts > 0 && correct == attempts,
      0,
      duration,
      {
        'mode': mode,
        'orientation': orientation,
        'timed': timed,
        'correct': correct,
        'attempts': attempts,
        'responseMs': responses.isEmpty
            ? 0
            : responses.reduce((a, b) => a + b) ~/ responses.length,
      },
    );
    // Only a full timed challenge qualifies for a personal best.
    if (timed && duration >= 30000 && correct > best) {
      best = correct;
      await widget.repo.setPreference(bestKey, best);
    }
    widget.repo.touch();
    if (mounted) {
      setState(() {
        saving = false;
        message = 'Session complete';
      });
    }
  }

  void answer(String square) {
    if (!running || paused || saving) return;
    if (timed && watch.elapsedMilliseconds >= 30000) {
      finish();
      return;
    }
    setState(() {
      attempts++;
      responses.add(response.elapsedMilliseconds);
      flashSquare = mode == 'find' ? square : null;
      flashRight = square == target;
      flashTimer?.cancel();
      flashTimer = Timer(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => flashSquare = null);
      });
      if (square == target) {
        correct++;
        message = 'Correct · $square';
      } else {
        message = '$square was incorrect · Answer: $target';
      }
      next();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && running) {
      watch.stop();
      response.stop();
      setState(() => paused = true);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    flashTimer?.cancel();
    watch.stop();
    response.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Coordinate training')),
    body: !ready
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: pagePadding(context),
            children: [
              if (!running && !saving) ...[
                const SectionLabel('Exercise'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in ['find', 'name'])
                      ChoiceChip(
                        label: Text(
                          m == 'find' ? 'Find the square' : 'Name the square',
                        ),
                        selected: mode == m,
                        onSelected: (_) {
                          setState(() => mode = m);
                          refreshBest();
                        },
                      ),
                  ],
                ),
                const SectionLabel('View'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final side in ['white', 'black', 'random'])
                      ChoiceChip(
                        label: Text(
                          side == 'white'
                              ? 'White'
                              : side == 'black'
                              ? 'Black'
                              : 'Random',
                        ),
                        selected: orientation == side,
                        onSelected: (_) {
                          setState(() => orientation = side);
                          refreshBest();
                        },
                      ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('30-second challenge'),
                  subtitle: const Text('Turn off for untimed practice'),
                  value: timed,
                  onChanged: (v) => setState(() => timed = v),
                ),
                if (timed) Text('Personal best: $best correct'),
              ],
              if (running) ...[
                Text(
                  mode == 'find'
                      ? 'Find $target'
                      : 'Name the highlighted square',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '${black ? 'Black' : 'White'} view · $correct correct / ${plural(attempts, 'attempt')}${timed ? ' · ${((30000 - watch.elapsedMilliseconds).clamp(0, 30000) / 1000).ceil()}s left' : ''}',
                ),
                if (timed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      value:
                          (30000 - watch.elapsedMilliseconds).clamp(0, 30000) /
                          30000,
                    ),
                  ),
                const SizedBox(height: 12),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 64,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 8,
                            ),
                        itemBuilder: (context, i) {
                          final square = coordinateAt(i, black);
                          final highlight = mode == 'name' && square == target;
                          return Semantics(
                            button: mode == 'find',
                            label:
                                'Board cell ${i + 1}${highlight ? ', highlighted' : ''}',
                            child: InkWell(
                              onTap: mode == 'find' && !paused
                                  ? () => answer(square)
                                  : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: flashSquare == square
                                      ? (flashRight
                                            ? const Color(0xff3f9b6e)
                                            : const Color(0xffd8433a))
                                      : (i ~/ 8 + i % 8).isEven
                                      ? context.tokens.boardLight
                                      : context.tokens.boardDark,
                                  border: highlight
                                      ? Border.all(
                                          color: context.colors.primary,
                                          width: 4,
                                        )
                                      : null,
                                ),
                                child: highlight
                                    ? Icon(
                                        Icons.circle,
                                        color: context.colors.primary,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (mode == 'name') ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in 'abcdefgh'.split(''))
                        ChoiceChip(
                          label: Text(f),
                          selected: file == f,
                          onSelected: paused
                              ? null
                              : (_) => setState(() => file = f),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var rank = 1; rank <= 8; rank++)
                        OutlinedButton(
                          onPressed: paused || file.isEmpty
                              ? null
                              : () => answer('$file$rank'),
                          child: Text('$rank'),
                        ),
                    ],
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ActionStack(
                    children: [
                      if (paused)
                        FilledButton(
                          onPressed: () => setState(() {
                            paused = false;
                            watch.start();
                            response.start();
                          }),
                          child: const Text('Resume paused session'),
                        ),
                      TextButton(
                        onPressed: finish,
                        child: const Text('Finish session'),
                      ),
                    ],
                  ),
                ),
              ],
              if (message.isNotEmpty)
                Semantics(
                  liveRegion: true,
                  child: FeedbackCard(
                    message,
                    tone: Tone.info,
                    icon: Icons.grid_on,
                  ),
                ),
              if (!running && attempts > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '$correct of $attempts correct · ${(100 * correct / attempts).round()}% accuracy\nAverage response: ${(responses.reduce((a, b) => a + b) / responses.length / 1000).toStringAsFixed(1)}s',
                  ),
                ),
              if (!running) const SizedBox(height: 12),
              if (!running)
                FilledButton.icon(
                  onPressed: saving ? null : start,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(saving ? 'Saving…' : 'Start training'),
                ),
            ],
          ),
  );
}
