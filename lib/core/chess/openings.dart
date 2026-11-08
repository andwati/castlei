import 'dart:convert';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';

import 'model.dart';

/// Opening names (ECO) from the CC0 lichess-org/chess-openings dataset,
/// matched by position so transpositions are recognised. Fully offline.
class Openings {
  static Map<String, (String, String)>? _map;

  static Future<void> load() async {
    if (_map != null) return;
    final rows =
        jsonDecode(await rootBundle.loadString('assets/openings.json')) as List;
    _map = {
      for (final r in rows) r[0] as String: (r[1] as String, r[2] as String),
    };
  }

  static (String eco, String name)? lookup(Position p) => _map?[positionKey(p)];

  /// The deepest named opening reached along the line up to [node].
  static (String eco, String name)? forLine(ChessGame g, String? node) {
    if (_map == null) return null;
    Position p = Chess.fromSetup(Setup.parseFen(g.rootFen));
    (String, String)? found = lookup(p);
    var plies = 0;
    for (final n in g.path(node)) {
      if (++plies > 40) break;
      p = p.play(Move.parse(n.uci)!);
      found = lookup(p) ?? found;
    }
    return found;
  }
}
