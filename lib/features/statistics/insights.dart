import 'dart:convert';

import 'package:dartchess/dartchess.dart';

import '../../core/chess/model.dart';
import '../../core/chess/openings.dart';
import '../../core/storage/repository.dart';

class ResultGroup {
  final List<String> gameIds = [];
  int wins = 0, draws = 0, losses = 0;
  void add(ChessGame game) {
    gameIds.add(game.id);
    if (game.result == '1/2-1/2') {
      draws++;
    } else if (game.result ==
        (game.settings['side'] == 'black' ? '0-1' : '1-0')) {
      wins++;
    } else {
      losses++;
    }
  }
}

class ReviewSummary {
  int humanMoves = 0, reviewedMoves = 0, reviewedGames = 0, totalGames = 0;
  final Map<String, int> labels = {};
  final Map<String, List<String>> labelGames = {};
  final Map<String, Map<String, int>> daily = {};
  final Map<String, Map<String, int>> perGame = {};
  void add(ChessGame game, Map<String, String> labelsByNode) {
    totalGames++;
    final human = game.settings['side'] == 'black' ? Side.black : Side.white;
    final day = DateTime.fromMillisecondsSinceEpoch(
      (game.settings['completedAt'] ?? game.created) as int,
    ).toLocal().toIso8601String().substring(0, 10);
    var reviewed = false;
    for (final n in game.mainline) {
      if (game.at(n.parent).turn != human) continue;
      humanMoves++;
      final label = labelsByNode[n.id];
      if (label == null) continue;
      reviewed = true;
      reviewedMoves++;
      labels.update(label, (n) => n + 1, ifAbsent: () => 1);
      perGame
          .putIfAbsent(game.id, () => {})
          .update(label, (n) => n + 1, ifAbsent: () => 1);
      final ids = labelGames.putIfAbsent(label, () => []);
      if (!ids.contains(game.id)) ids.add(game.id);
      final bucket = daily.putIfAbsent(day, () => {});
      bucket.update(label, (n) => n + 1, ifAbsent: () => 1);
    }
    if (reviewed) reviewedGames++;
  }
}

class InsightsData {
  final colors = <String, ResultGroup>{},
      openings = <String, ResultGroup>{},
      difficulties = <String, ResultGroup>{};
  final review = ReviewSummary();
  final games = <String, ChessGame>{};
}

Future<InsightsData> loadInsights(
  Repository repo,
  int days,
  String category,
) async {
  final data = InsightsData();
  await Openings.load();
  final since = days == 0
      ? 0
      : DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
  final rows = await repo.db.rows(
    "SELECT * FROM games WHERE source='engine' AND result IN ('1-0','0-1','1/2-1/2') AND COALESCE(json_extract(settings,'\$.completedAt'),updated)>=?",
    [since],
  );
  for (final row in rows) {
    final game = await repo.load(row['id']);
    game.settings.putIfAbsent('completedAt', () => row['updated']);
    final custom = game.rootFen != Chess.initial.fen;
    if (category == 'custom'
        ? !custom
        : custom || game.assisted != (category == 'assisted')) {
      continue;
    }
    data.games[game.id] = game;
    final name =
        Openings.forLine(game, game.mainline.lastOrNull?.id)?.$2 ??
        'Unclassified opening';
    data.openings.putIfAbsent(name, ResultGroup.new).add(game);
    data.colors
        .putIfAbsent(
          game.settings['side'] == 'black' ? 'Black' : 'White',
          ResultGroup.new,
        )
        .add(game);
    data.difficulties
        .putIfAbsent(
          '${game.settings['level'] ?? 'Unknown difficulty'}',
          ResultGroup.new,
        )
        .add(game);
    final reviews = await repo.db.rows(
      'SELECT node_id,data FROM analysis WHERE game_id=? ORDER BY rowid',
      [game.id],
    );
    final labels = <String, String>{};
    // A later review replaces the earlier label; never count multiple budgets twice.
    for (final r in reviews) {
      labels[r['node_id']] = jsonDecode(r['data'])['label'];
    }
    data.review.add(game, labels);
  }
  return data;
}

Map<String, int> calendarActivity(
  List<Map<String, dynamic>> attempts,
  DateTime now,
  int days,
) {
  final dates = <String, int>{};
  DateTime day(DateTime date) => DateTime(date.year, date.month, date.day);
  final end = day(now);
  final start = days == 0 && attempts.isNotEmpty
      ? day(DateTime.fromMillisecondsSinceEpoch(attempts.first['created']))
      : end.subtract(Duration(days: days == 0 ? 29 : days));
  for (
    var date = start;
    !date.isAfter(end);
    date = DateTime(date.year, date.month, date.day + 1)
  ) {
    dates[date.toIso8601String().substring(0, 10)] = 0;
  }
  for (final attempt in attempts) {
    final date = DateTime.fromMillisecondsSinceEpoch(attempt['created'])
        .toLocal()
        .toIso8601String()
        .substring(0, 10);
    if (dates.containsKey(date)) dates[date] = dates[date]! + 1;
  }
  return dates;
}
