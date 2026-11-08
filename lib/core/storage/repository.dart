import 'dart:convert';

import '../chess/model.dart';
import 'database.dart';

class Repository {
  Repository(this.db);
  final AppDatabase db;
  Future<void> save(ChessGame g) => db.transaction(() async {
    await db.execute(
      'INSERT INTO games(id,title,source,root_fen,headers,result,created,updated,favorite,settings,current_node,assisted) VALUES(?,?,?,?,?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET title=excluded.title,headers=excluded.headers,result=excluded.result,updated=excluded.updated,favorite=excluded.favorite,settings=excluded.settings,current_node=excluded.current_node,assisted=excluded.assisted',
      [
        g.id,
        g.title,
        g.source,
        g.rootFen,
        jsonEncode(g.headers),
        g.result,
        g.created,
        DateTime.now().millisecondsSinceEpoch,
        g.favorite ? 1 : 0,
        jsonEncode(g.settings),
        g.current,
        g.assisted ? 1 : 0,
      ],
    );
    for (var i = 0; i < g.nodes.length; i++) {
      final n = g.nodes[i];
      await db.execute(
        'INSERT INTO nodes(id,game_id,parent_id,ordinal,uci,san,comment,nags,annotations,clocks) VALUES(?,?,?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET comment=excluded.comment,nags=excluded.nags,annotations=excluded.annotations,clocks=excluded.clocks',
        [
          n.id,
          g.id,
          n.parent,
          i,
          n.uci,
          n.san,
          n.comment,
          jsonEncode(n.nags),
          jsonEncode(n.shapes),
          jsonEncode(n.clocks),
        ],
      );
    }
  });
  Future<ChessGame> load(String id) async {
    final r = (await db.rows('SELECT * FROM games WHERE id=?', [id])).single;
    final g = ChessGame(
      id: id,
      title: r['title'],
      source: r['source'],
      rootFen: r['root_fen'],
      created: r['created'],
      headers: Map<String, String>.from(jsonDecode(r['headers'])),
      settings: decodeMap(r['settings']),
    );
    g.result = r['result'];
    g.current = r['current_node'];
    g.favorite = r['favorite'] == 1;
    g.assisted = r['assisted'] == 1;
    for (final n in await db.rows(
      'SELECT * FROM nodes WHERE game_id=? ORDER BY ordinal',
      [id],
    )) {
      g.nodes.add(
        StudyNode(
          id: n['id'],
          parent: n['parent_id'],
          uci: n['uci'],
          san: n['san'],
          comment: n['comment'],
          nags: List<int>.from(jsonDecode(n['nags'])),
          shapes: List<String>.from(jsonDecode(n['annotations'])),
          clocks: decodeMap(n['clocks']),
        ),
      );
    }
    return g;
  }

  Future<List<Map<String, dynamic>>> games() =>
      db.rows('SELECT * FROM games ORDER BY updated DESC');
  Future<void> delete(String id) => db.transaction(() async {
    final reps = await db.rows('SELECT id FROM repertoires WHERE game_id=?', [
      id,
    ]);
    for (final r in reps) {
      await db.execute(
        "DELETE FROM attempts WHERE kind='opening' AND json_extract(metadata,'\$.repertoire')=?",
        [r['id']],
      );
    }
    await db.execute('DELETE FROM games WHERE id=?', [id]);
  });
  Future<void> setPreference(String key, Object value) => db.execute(
    'INSERT INTO preferences VALUES(?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value',
    [key, jsonEncode(value)],
  );
  Future<dynamic> preference(String key, dynamic fallback) async {
    final r = await db.rows('SELECT value FROM preferences WHERE key=?', [key]);
    return r.isEmpty ? fallback : jsonDecode(r.first['value']);
  }
}
