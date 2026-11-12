import '../../core/ui/plural.dart';

import 'package:flutter/material.dart';

import '../../core/storage/repository.dart';
import '../../core/ui/widgets.dart';
import 'insights.dart';

class InsightsView extends StatefulWidget {
  const InsightsView({
    super.key,
    required this.repo,
    required this.days,
    required this.category,
    this.onOpenGame,
  });
  final Repository repo;
  final int days;
  final String category;
  final Future<void> Function(String)? onOpenGame;
  @override
  State<InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends State<InsightsView> {
  late Future<InsightsData> future = loadInsights(
    widget.repo,
    widget.days,
    widget.category,
  );
  @override
  void didUpdateWidget(covariant InsightsView old) {
    super.didUpdateWidget(old);
    if (old.days != widget.days || old.category != widget.category) {
      future = loadInsights(widget.repo, widget.days, widget.category);
    }
  }

  Future<void> showGames(
    InsightsData data,
    List<String> ids,
    String title,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          for (final id in ids)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, id),
              child: Text(
                '${data.games[id]!.title} · ${data.games[id]!.result}',
              ),
            ),
        ],
      ),
    );
    if (selected != null) await widget.onOpenGame?.call(selected);
  }

  Widget groups(
    InsightsData data,
    String title,
    Map<String, ResultGroup> groups,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionLabel(title),
      for (final entry in groups.entries)
        Card(
          child: ListTile(
            title: Text(entry.key),
            subtitle: Text(
              '${plural(entry.value.gameIds.length, 'game')} · ${entry.value.wins} won · ${entry.value.draws} drawn · ${entry.value.losses} lost',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showGames(data, entry.value.gameIds, entry.key),
          ),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<InsightsData>(
    future: future,
    builder: (context, snap) {
      if (snap.hasError) {
        return TextButton(
          onPressed: () => setState(
            () => future = loadInsights(
              widget.repo,
              widget.days,
              widget.category,
            ),
          ),
          child: const Text('Unable to load insights · Retry'),
        );
      }
      if (!snap.hasData) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        );
      }
      final data = snap.data!, review = data.review;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Game insights'),
          if (data.games.isEmpty)
            const Text(
              'Finish engine games to see results by color, opening, and difficulty.',
            ),
          if (data.games.isNotEmpty) ...[
            groups(data, 'By playing color', data.colors),
            groups(data, 'By opening', data.openings),
            groups(data, 'By difficulty', data.difficulties),
            const SectionLabel('Reviewed games'),
            for (final game in data.games.values)
              Builder(
                builder: (context) {
                  final labels =
                      review.perGame[game.id]?.entries
                          .map(
                            (entry) =>
                                '${entry.value} ${entry.key.toLowerCase()}',
                          )
                          .toList() ??
                      <String>[];
                  return ListTile(
                    title: Text(game.title),
                    subtitle: Text(
                      labels.isEmpty
                          ? 'No reviewed human moves'
                          : labels.join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => widget.onOpenGame?.call(game.id),
                  );
                },
              ),
            const SectionLabel('Your reviewed moves'),
            Text(
              '${review.reviewedGames} of ${plural(review.totalGames, 'game')} reviewed · ${review.reviewedMoves} of ${plural(review.humanMoves, 'move')} checked',
            ),
            const Text(
              'Counts reflect available reviews. Unreviewed moves are not treated as good moves.',
            ),
            for (final label in [
              'Inaccuracy',
              'Mistake',
              'Blunder',
              'Missed Forced Mate',
              'Allowed Forced Mate',
              'Uncertain',
            ])
              Card(
                child: ListTile(
                  title: Text(label),
                  subtitle: Text(
                    review.reviewedMoves == 0
                        ? 'No reviewed moves yet'
                        : '${plural(review.labels[label] ?? 0, 'move')} · ${((review.labels[label] ?? 0) * 100 / review.reviewedMoves).toStringAsFixed(1)}% of reviewed human moves',
                  ),
                  onTap: (review.labelGames[label] ?? []).isEmpty
                      ? null
                      : () => showGames(data, review.labelGames[label]!, label),
                ),
              ),
            if (review.daily.isNotEmpty) ...[
              const SectionLabel('Mistakes over time'),
              const Text('Daily counts / reviewed human moves'),
              for (final day in (review.daily.keys.toList()..sort()))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '$day · ${['Inaccuracy', 'Mistake', 'Blunder'].map((label) => '${review.daily[day]![label] ?? 0} ${label.toLowerCase()}').join(' · ')} / ${review.daily[day]!.values.fold<int>(0, (a, b) => a + b)} reviewed',
                  ),
                ),
            ],
          ],
        ],
      );
    },
  );
}
