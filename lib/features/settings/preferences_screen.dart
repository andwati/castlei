import 'package:flutter/material.dart';

import '../../core/ui/board_style.dart';
import '../../core/ui/theme.dart';

import '../../core/ui/widgets.dart';

import '../../core/storage/repository.dart';
import '../../core/engine/engine.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({
    super.key,
    required this.repo,
    required this.engine,
  });
  final Repository repo;
  final EngineClient engine;
  @override
  State<PreferencesScreen> createState() => _PreferencesState();
}

class _PreferencesState extends State<PreferencesScreen> {
  Map<String, dynamic> values = {};
  bool ready = false;
  final defaults = <String, dynamic>{
    'sound': false,
    'haptics': true,
    'coordinates': true,
    'analysisMs': 3000,
    'multiPv': 3,
    'resources': 1,
    'dueLimit': 20,
    'newLimit': 5,
  };
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    for (final e in defaults.entries) {
      values[e.key] = await widget.repo.preference(e.key, e.value);
    }
    if (mounted) setState(() => ready = true);
  }

  Future<void> save(String key, dynamic value) async {
    await widget.repo.setPreference(key, value);
    if (key == 'resources') {
      widget.engine.cancel();
      widget.engine.threads = value as int;
      widget.engine.hashMb = value == 1 ? 64 : 128;
    }
    setState(() => values[key] = value);
  }

  Widget choice(
    String key,
    String label,
    List<int> options,
    List<String> labels,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: DropdownButtonFormField<int>(
      initialValue: values[key],
      decoration: InputDecoration(labelText: label),
      items: [
        for (var i = 0; i < options.length; i++)
          DropdownMenuItem(value: options[i], child: Text(labels[i])),
      ],
      onChanged: (v) => save(key, v),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Analysis and practice')),
    body: !ready
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: pagePadding(context),
            children: [
              const SectionLabel('Analysis board'),
              GroupCard(
                children: [
                  SwitchListTile(
                    title: const Text('Evaluation bar'),
                    subtitle: const Text(
                      'A bar under the board showing who is better.',
                    ),
                    value: BoardStyle.evalBar,
                    onChanged: (v) async {
                      await BoardStyle.save(widget.repo, evalBar: v);
                      setState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Suggestion arrow'),
                    subtitle: const Text(
                      'An arrow for the engine’s best move.',
                    ),
                    value: BoardStyle.suggestionArrow,
                    onChanged: (v) async {
                      await BoardStyle.save(widget.repo, suggestionArrow: v);
                      setState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Threat arrow'),
                    subtitle: const Text(
                      'A red arrow for what the opponent threatens. Takes a little longer.',
                    ),
                    value: BoardStyle.threatArrow,
                    onChanged: (v) async {
                      await BoardStyle.save(widget.repo, threatArrow: v);
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SectionLabel('Analysis'),
              const _Hint(
                'How long the engine thinks about each move in a review or hint.',
              ),
              choice(
                'analysisMs',
                'Default analysis budget',
                [1000, 3000, 10000],
                [
                  'Quick · 1 second',
                  'Balanced · 3 seconds',
                  'Deep · 10 seconds',
                ],
              ),
              const _Hint(
                'How many alternative moves the analysis board shows.',
              ),
              choice(
                'multiPv',
                'Candidate lines',
                [1, 2, 3],
                ['One', 'Two', 'Three'],
              ),
              const SectionLabel('Engine'),
              choice(
                'resources',
                'Engine resources',
                [1, 2],
                ['1 thread · 64 MB', '2 threads · 128 MB'],
              ),
              const FeedbackCard(
                'More engine resources can increase heat and battery use. Search budgets apply to each search, not the entire review.',
                tone: Tone.info,
                icon: Icons.thermostat_outlined,
              ),
              const SectionLabel('Opening drills'),
              const _Hint('How many positions a drill session asks for.'),
              choice(
                'dueLimit',
                'Due positions per session',
                [10, 20, 50],
                ['10', '20', '50'],
              ),
              choice(
                'newLimit',
                'New positions per session',
                [0, 5, 10],
                ['None', '5', '10'],
              ),
            ],
          ),
  );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.text.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    ),
  );
}
