import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/storage/repository.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/widgets.dart';

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
    final now = DateTime.now().millisecondsSinceEpoch;
    final cards = await widget.repo.db.rows(
      'SELECT SUM(stage=0) AS fresh, SUM(stage>0 AND due<=?) AS due, SUM(stage>0) AS learned FROM cards',
      [now],
    );
    return {'games': games, 'attempts': attempts, 'cards': cards.first};
  }

  static const levels = ['Gentle', 'Easy', 'Medium', 'Hard', 'Maximum'];
  static const standard =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  Widget _record(BuildContext context, int skill, List games) {
    final group = games.where((g) {
      final settings = jsonDecode(g['settings']);
      final custom = g['root_fen'] != standard;
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
          (jsonDecode(g['settings'])['side'] == 'white' ? '1-0' : '0-1')) {
        wins++;
      }
    }
    final losses = group.length - wins - draws;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    levels[skill ~/ 5],
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${group.length} ${group.length == 1 ? 'game' : 'games'}',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (group.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      if (wins > 0)
                        Expanded(
                          flex: wins,
                          child: ColoredBox(color: context.tokens.good),
                        ),
                      if (draws > 0)
                        Expanded(
                          flex: draws,
                          child: ColoredBox(color: context.colors.outline),
                        ),
                      if (losses > 0)
                        Expanded(
                          flex: losses,
                          child: ColoredBox(color: context.tokens.bad),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                StatusChip(
                  '$wins won',
                  icon: Icons.arrow_upward_rounded,
                  color: context.tokens.good,
                ),
                StatusChip('$draws drawn', icon: Icons.drag_handle_rounded),
                StatusChip(
                  '$losses lost',
                  icon: Icons.arrow_downward_rounded,
                  color: context.tokens.bad,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your progress')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 7, label: Text('7 days')),
            ButtonSegment(value: 30, label: Text('30 days')),
            ButtonSegment(value: 90, label: Text('90 days')),
            ButtonSegment(value: 0, label: Text('All')),
          ],
          selected: {days},
          onSelectionChanged: (v) => setState(() => days = v.first),
        ),
        FutureBuilder(
          future: load(),
          builder: (context, s) {
            if (!s.hasData) {
              return const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final games = s.data!['games'] as List;
            final attempts = s.data!['attempts'] as List;
            final cards = s.data!['cards'] as Map;
            final puzzles = attempts
                .where((a) => a['kind'] == 'puzzle')
                .toList();
            final openings = attempts
                .where((a) => a['kind'] == 'opening')
                .toList();
            Widget metric(String name, List rows, IconData icon, Color tint) {
              final ok = rows.where((a) => a['success'] == 1).length;
              return StatTile(
                title: name,
                icon: icon,
                accent: tint,
                value: rows.isEmpty
                    ? '—'
                    : '${(100 * ok / rows.length).round()}%',
                progress: rows.isEmpty ? 0 : ok / rows.length,
                caption:
                    '$ok of ${rows.length} solved without help (first attempt)',
              );
            }

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
                const SectionLabel('Training'),
                metric(
                  'Tactical puzzles',
                  puzzles,
                  Icons.extension_rounded,
                  context.colors.secondary,
                ),
                metric(
                  'Opening recall',
                  openings,
                  Icons.account_tree_rounded,
                  context.colors.primary,
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final e in {
                          'Due': cards['due'] ?? 0,
                          'New': cards['fresh'] ?? 0,
                          'Learned': cards['learned'] ?? 0,
                        }.entries)
                          Column(
                            children: [
                              Text(
                                '${e.value}',
                                style: context.text.headlineMedium,
                              ),
                              Text(
                                e.key,
                                style: context.text.labelMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SectionLabel('Practice activity'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: daily.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: Center(
                              child: Text(
                                'Complete training to see your activity here.',
                                style: context.text.bodyMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 140,
                            child: BarChart(
                              BarChartData(
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                barGroups: [
                                  for (var i = 0; i < daily.length; i++)
                                    BarChartGroupData(
                                      x: i,
                                      barRods: [
                                        BarChartRodData(
                                          toY: daily[i].toDouble(),
                                          color: context.colors.primary,
                                          width: 12,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(6),
                                              ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                const SectionLabel('Engine games'),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: 'unassisted',
                        label: Text('Unassisted'),
                      ),
                      ButtonSegment(value: 'assisted', label: Text('Assisted')),
                      ButtonSegment(value: 'custom', label: Text('Custom')),
                    ],
                    selected: {category},
                    onSelectionChanged: (v) =>
                        setState(() => category = v.first),
                  ),
                ),
                const SizedBox(height: 8),
                for (final skill in [0, 5, 10, 15, 20])
                  _record(context, skill, games),
                if (themes.isNotEmpty) const SectionLabel('Puzzle themes'),
                for (final t in themes.entries)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.key,
                                  style: context.text.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: t.value[1] / t.value[0],
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${t.value[1]} / ${t.value[0]}',
                            style: context.text.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (attempts.isNotEmpty || games.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Small samples vary. Counts are shown alongside percentages.',
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
