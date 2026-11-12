import 'dart:convert';

import 'package:dartchess/dartchess.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/chess/model.dart';
import '../../core/ui/theme.dart';

/// One reviewed move, with the evaluation after it from White's point of view.
class ReviewPoint {
  ReviewPoint({
    required this.nodeId,
    required this.san,
    required this.ply,
    required this.whiteMoved,
    required this.score,
    required this.mate,
    required this.label,
  });
  final String nodeId, san, label;
  final int ply, score;
  final bool whiteMoved, mate;

  /// Evaluation after the move in pawns, White's perspective; mate = ±10.
  double get whitePawns {
    final mover = whiteMoved ? 1 : -1;
    if (mate) return score > 0 ? 10.0 * mover : -10.0 * mover;
    return score * mover / 100;
  }

  String get evalText {
    final mover = whiteMoved ? 1 : -1;
    if (mate) return 'M${(score * mover).abs()}';
    final v = whitePawns;
    return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}';
  }
}

/// Text mark shown next to a move; text, not colour, carries the meaning.
String badgeFor(String label) => switch (label) {
  'Inaccuracy' => '?!',
  'Mistake' => '?',
  'Blunder' => '??',
  'Missed Forced Mate' => 'M?',
  'Allowed Forced Mate' => '??M',
  _ => '',
};

List<ReviewPoint> parseReview(List<Map<String, dynamic>> rows, ChessGame g) {
  final out = <ReviewPoint>[];
  final line = g.mainline;
  for (final r in rows) {
    final index = line.indexWhere((n) => n.id == r['id']);
    if (index < 0) continue;
    final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
    final played = data['played'] as Map<String, dynamic>;
    out.add(
      ReviewPoint(
        nodeId: r['id'] as String,
        san: r['san'] as String,
        ply: index + 1,
        whiteMoved: g.at(line[index].parent).turn == Side.white,
        score: played['score'] as int,
        mate: played['mate'] as bool,
        label: data['label'] as String,
      ),
    );
  }
  out.sort((a, b) => a.ply.compareTo(b.ply));
  return out;
}

/// Evaluation over the game. Tap a point to jump to that move.
class EvalGraph extends StatelessWidget {
  const EvalGraph({
    super.key,
    required this.points,
    required this.selectedNodeId,
    required this.onSelect,
  });
  final List<ReviewPoint> points;
  final String? selectedNodeId;
  final void Function(String nodeId) onSelect;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();
    final c = context.colors;
    final spots = [
      for (final p in points)
        FlSpot(p.ply.toDouble(), p.whitePawns.clamp(-8, 8)),
    ];
    int count(String l) => points.where((p) => p.label == l).length;
    String n(int c, String one, String many) => '$c ${c == 1 ? one : many}';
    final summary =
        '${n(count('Blunder'), 'blunder', 'blunders')}, ${n(count('Mistake'), 'mistake', 'mistakes')}, ${n(count('Inaccuracy'), 'inaccuracy', 'inaccuracies')}';
    return Semantics(
      label: 'Evaluation graph. $summary. Tap a point to jump to that move.',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  'Evaluation · $summary',
                  style: context.text.labelMedium?.copyWith(
                    color: c.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                height: 150,
                child: LineChart(
                  LineChartData(
                    minY: -8,
                    maxY: 8,
                    minX: 1,
                    maxX: points.last.ply.toDouble(),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      bottomTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 4,
                          getTitlesWidget: (v, _) => Text(
                            v == 0 ? '0' : '${v > 0 ? '+' : ''}${v.toInt()}',
                            style: context.text.labelSmall?.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(y: 0, color: c.outline, strokeWidth: 1),
                      ],
                    ),
                    lineTouchData: LineTouchData(
                      touchCallback: (event, response) {
                        final spot = response?.lineBarSpots?.firstOrNull;
                        if (event is FlTapUpEvent && spot != null) {
                          final p = points.firstWhere(
                            (p) => p.ply == spot.x.toInt(),
                          );
                          onSelect(p.nodeId);
                        }
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) => [
                          for (final s in spots)
                            LineTooltipItem(
                              () {
                                final p = points.firstWhere(
                                  (p) => p.ply == s.x.toInt(),
                                );
                                final badge = badgeFor(p.label);
                                return '${(p.ply + 1) ~/ 2}${p.whiteMoved ? '.' : '...'} ${p.san}$badge\n${p.evalText}';
                              }(),
                              TextStyle(
                                color: c.onInverseSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: false,
                        color: c.primary,
                        barWidth: 2.5,
                        belowBarData: BarAreaData(
                          show: true,
                          color: c.onSurface.withValues(alpha: .12),
                          cutOffY: 0,
                          applyCutOffY: true,
                        ),
                        aboveBarData: BarAreaData(
                          show: true,
                          color: c.onSurface.withValues(alpha: .28),
                          cutOffY: 0,
                          applyCutOffY: true,
                        ),
                        dotData: FlDotData(
                          getDotPainter: (spot, _, _, _) {
                            final p = points.firstWhere(
                              (p) => p.ply == spot.x.toInt(),
                            );
                            final bad = badgeFor(p.label).isNotEmpty;
                            final selected = p.nodeId == selectedNodeId;
                            return FlDotCirclePainter(
                              radius: selected ? 6 : (bad ? 4.5 : 2),
                              color: bad ? c.error : c.primary,
                              strokeWidth: selected ? 2 : 0,
                              strokeColor: c.onSurface,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
