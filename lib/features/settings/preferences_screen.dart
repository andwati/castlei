import 'package:flutter/material.dart';

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
    appBar: AppBar(title: const Text('Practice preferences')),
    body: !ready
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final e in {
                'sound': 'Move sound',
                'haptics': 'Move haptics',
                'coordinates': 'Board coordinates',
              }.entries)
                SwitchListTile(
                  title: Text(e.value),
                  value: values[e.key],
                  onChanged: (v) => save(e.key, v),
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
              choice(
                'multiPv',
                'Candidate lines',
                [1, 2, 3],
                ['One', 'Two', 'Three'],
              ),
              choice(
                'resources',
                'Engine resources',
                [1, 2],
                ['1 thread · 64 MB', '2 threads · 128 MB'],
              ),
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
              const Text(
                'More engine resources can increase heat and battery use. Search budgets apply to each search, not the entire review.',
              ),
            ],
          ),
  );
}
