import 'dart:convert';

import 'package:dartchess/dartchess.dart';

import '../../core/chess/model.dart';
import '../../core/storage/repository.dart';

const intervals = [1, 3, 7, 14, 30];
(int, int) schedule(int stage, bool success, DateTime now) {
  final next = success ? (stage + 1).clamp(1, 5) : 1;
  return (
    next,
    now.toUtc().add(Duration(days: intervals[next - 1])).millisecondsSinceEpoch,
  );
}

class TrainingService {
  TrainingService(this.repo);
  final Repository repo;
  Future<void> record(
    String kind,
    String target,
    bool success,
    int hints,
    int duration,
    Map<String, dynamic> metadata,
  ) => repo.db
      .execute(
        'INSERT INTO attempts VALUES(?,?,?,?,?,?,?,?)',
        [
          newId(),
          kind,
          target,
          DateTime.now().millisecondsSinceEpoch,
          success ? 1 : 0,
          hints,
          duration,
          jsonEncode(metadata),
        ].asMap().values.toList(),
      )
      .then((_) => repo.touch());
  Future<void> buildCards(ChessGame game, String side) async {
    await repo.save(game);
    final matches = await repo.db.rows(
      'SELECT id FROM repertoires WHERE game_id=?',
      [game.id],
    );
    final id = matches.isEmpty ? newId() : matches.first['id'] as String;
    await repo.db.execute(
      'INSERT INTO repertoires VALUES(?,?,?) ON CONFLICT(id) DO UPDATE SET side=excluded.side',
      [id, game.id, side],
    );
    final positions = <String, (String, Set<String>)>{};
    for (final n in game.nodes) {
      final p = game.at(n.parent);
      if (p.turn.name != side) continue;
      final key = positionKey(p);
      positions.putIfAbsent(key, () => (p.fen, <String>{})).$2.add(n.uci);
    }
    await repo.db.transaction(() async {
      final existing = await repo.db.rows(
        'SELECT * FROM cards WHERE repertoire_id=?',
        [id],
      );
      for (final entry in positions.entries) {
        final moves = entry.value.$2.toList()..sort();
        final old = existing
            .where(
              (r) =>
                  positionKey(Chess.fromSetup(Setup.parseFen(r['fen']))) ==
                  entry.key,
            )
            .firstOrNull;
        if (old == null) {
          await repo.db.execute(
            'INSERT INTO cards(id,repertoire_id,fen,moves) VALUES(?,?,?,?)',
            [newId(), id, entry.value.$1, jsonEncode(moves)],
          );
        } else if (old['moves'] != jsonEncode(moves)) {
          await repo.db.execute(
            'UPDATE cards SET moves=?,stage=0,due=0 WHERE id=?',
            [jsonEncode(moves), old['id']],
          );
        }
      }
      for (final old in existing) {
        if (!positions.containsKey(
          positionKey(Chess.fromSetup(Setup.parseFen(old['fen']))),
        )) {
          await repo.db.execute('DELETE FROM cards WHERE id=?', [old['id']]);
        }
      }
    });
  }

  Future<void> answerCard(
    Map<String, dynamic> card,
    bool success,
    int hints,
    int duration,
  ) async {
    final (stage, due) = schedule(
      card['stage'] as int,
      success && hints == 0,
      DateTime.now(),
    );
    await repo.db.transaction(() async {
      await repo.db.execute('UPDATE cards SET stage=?,due=? WHERE id=?', [
        stage,
        due,
        card['id'],
      ]);
      await record('opening', card['id'], success, hints, duration, {
        'repertoire': card['repertoire_id'],
      });
    });
  }
}
