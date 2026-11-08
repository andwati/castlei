import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/storage/repository.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key, required this.repo});
  final Repository repo;
  @override
  State<StatisticsScreen> createState() => _StatsState();
}

class _StatsState extends State<StatisticsScreen> {
  int days = 30;
  String category = 'unassisted';
  Future<Map<String, dynamic>> load() async {
    final since = days == 0
        ? 0
        : DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final games = await widget.repo.db.rows(
      "SELECT * FROM games WHERE source='engine' AND result IN ('1-0','0-1','1/2-1/2') AND COALESCE(json_extract(settings, '\$.completedAt'),updated)>=?",
      [since],
    );
    final attempts = await widget.repo.db.rows(
      'SELECT * FROM attempts WHERE created>=? ORDER BY created',
      [since],
    );
    return {'games': games, 'attempts': attempts};
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your progress')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final d in [7, 30, 90, 0])
              ChoiceChip(
                label: Text(d == 0 ? 'All time' : '$d days'),
                selected: days == d,
                onSelected: (_) => setState(() => days = d),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder(
          future: load(),
          builder: (context, s) {
            if (!s.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final games = s.data!['games'] as List;
            final attempts = s.data!['attempts'] as List;
            final puzzles = attempts
                .where((a) => a['kind'] == 'puzzle')
                .toList();
            final openings = attempts
                .where((a) => a['kind'] == 'opening')
                .toList();
            Widget metric(String name, List rows) => Card(
              child: ListTile(
                title: Text(name),
                subtitle: Text(
                  '${rows.length} attempts · ${rows.where((a) => a['success'] == 1).length} unassisted successes',
                ),
                trailing: Text(
                  rows.isEmpty
                      ? '—'
                      : '${(100 * rows.where((a) => a['success'] == 1).length / rows.length).round()}%',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            );
            final dates = <String, int>{};
            for (final a in attempts) {
              final day = DateTime.fromMillisecondsSinceEpoch(a['created'])
                  .toLocal()
                  .toIso8601String()
                  .substring(0, 10);
              dates[day] = (dates[day] ?? 0) + 1;
            }
            final daily = dates.values.toList();
            final themes = <String, List<int>>{};
            for (final a in puzzles) {
              final metadata = jsonDecode(a['metadata']);
              for (final theme in (metadata['themes'] as String? ?? '').split(
                ' ',
              )) {
                if (theme.isEmpty) continue;
                final counts = themes.putIfAbsent(theme, () => [0, 0]);
                counts[0]++;
                if (a['success'] == 1) counts[1]++;
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                metric('Tactical puzzles', puzzles),
                metric('Opening recall', openings),
                const SizedBox(height: 20),
                Text(
                  'Practice activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (daily.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Complete training to see your activity here.'),
                  )
                else
                  SizedBox(
                    height: 160,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: BarChart(
                        BarChartData(
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          barGroups: [
                            for (var i = 0; i < daily.length; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: daily[i].toDouble(),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    width: 10,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Engine games',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final c in ['unassisted', 'assisted', 'custom'])
                      ChoiceChip(
                        label: Text(c),
                        selected: category == c,
                        onSelected: (_) => setState(() => category = c),
                      ),
                  ],
                ),
                for (final skill in [0, 5, 10, 15, 20])
                  Builder(
                    builder: (c) {
                      final group = games.where((g) {
                        final settings = jsonDecode(g['settings']);
                        final custom =
                            g['root_fen'] !=
                            'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
                        return settings['skill'] == skill &&
                            (category == 'custom'
                                ? custom
                                : !custom &&
                                      (category == 'assisted'
                                          ? g['assisted'] == 1
                                          : g['assisted'] == 0));
                      }).toList();
                      var wins = 0, draws = 0;
                      for (final g in group) {
                        if (g['result'] == '1/2-1/2') {
                          draws++;
                        } else if (g['result'] ==
                            (jsonDecode(g['settings'])['side'] == 'white'
                                ? '1-0'
                                : '0-1')) {
                          wins++;
                        }
                      }
                      return ListTile(
                        title: Text(
                          [
                            'Gentle',
                            'Easy',
                            'Medium',
                            'Hard',
                            'Maximum',
                          ][skill ~/ 5],
                        ),
                        subtitle: Text('${group.length} games'),
                        trailing: Text(
                          '$wins W · $draws D · ${group.length - wins - draws} L',
                        ),
                      );
                    },
                  ),
                const Divider(),
                Text(
                  'Puzzle themes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final t in themes.entries)
                  ListTile(
                    title: Text(t.key),
                    trailing: Text('${t.value[1]} / ${t.value[0]}'),
                  ),
                if (attempts.isNotEmpty)
                  const Text(
                    'Small samples vary. Counts are shown alongside percentages.',
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
