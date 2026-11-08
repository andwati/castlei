import 'dart:convert';
import 'dart:math';

import 'package:dartchess/dartchess.dart';

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${Random.secure().nextInt(1 << 32).toRadixString(36)}';
String standardUci(Position p, Move move) {
  final m = p.normalizeMove(move as NormalMove) as NormalMove;
  if (p.board.pieceAt(m.from)?.role == Role.king &&
      p.board.pieceAt(m.to)?.role == Role.rook &&
      p.board.pieceAt(m.to)?.color == p.turn) {
    return NormalMove(
      from: m.from,
      to: Square(m.from.rank * 8 + (m.to > m.from ? 6 : 2)),
    ).uci;
  }
  return m.uci;
}

String positionKey(Position p) {
  final f = p.fen.split(' ');
  if (p.epSquare != null &&
      !p.legalMoves.entries.any(
        (e) =>
            p.board.pieceAt(e.key)?.role == Role.pawn &&
            e.value.has(p.epSquare!),
      )) {
    f[3] = '-';
  }
  return f.take(4).join(' ');
}

class StudyNode {
  StudyNode({
    required this.id,
    this.parent,
    required this.uci,
    required this.san,
    this.comment = '',
    List<int>? nags,
    List<String>? shapes,
    Map<String, dynamic>? clocks,
  }) : nags = nags ?? [],
       shapes = shapes ?? [],
       clocks = clocks ?? {};
  final String id;
  String? parent;
  final String uci, san;
  String comment;
  List<int> nags;
  List<String> shapes;
  Map<String, dynamic> clocks;
}

class ChessGame {
  ChessGame({
    required this.id,
    required this.title,
    required this.source,
    required this.rootFen,
    required this.created,
    Map<String, dynamic>? settings,
    Map<String, String>? headers,
  }) : settings = settings ?? {},
       headers = headers ?? {};
  final String id, source, rootFen;
  String title;
  final int created;
  final Map<String, dynamic> settings;
  final Map<String, String> headers;
  final List<StudyNode> nodes = [];
  String? current;
  String result = '*';
  bool favorite = false, assisted = false;
  List<StudyNode> children(String? parent) =>
      nodes.where((n) => n.parent == parent).toList();
  List<StudyNode> path([String? node]) {
    final out = <StudyNode>[];
    var id = node;
    while (id != null) {
      final n = nodes.firstWhere((e) => e.id == id);
      out.insert(0, n);
      id = n.parent;
      if (out.length > 10000) throw StateError('Cyclic tree');
    }
    return out;
  }

  Position at(String? node) {
    var p = Chess.fromSetup(Setup.parseFen(rootFen));
    Position position = p;
    for (final n in path(node)) {
      position = position.play(Move.parse(n.uci)!);
    }
    return position;
  }

  Position get position => at(current);
  List<StudyNode> get mainline {
    final out = <StudyNode>[];
    String? id;
    while (children(id).isNotEmpty) {
      final n = children(id).first;
      out.add(n);
      id = n.id;
    }
    return out;
  }

  StudyNode play(Move move) {
    final p = position;
    final uci = standardUci(p, move);
    final match = children(current).where((n) => n.uci == uci);
    if (match.isNotEmpty) {
      current = match.first.id;
      return match.first;
    }
    final (_, san) = p.makeSan(move);
    final n = StudyNode(id: newId(), parent: current, uci: uci, san: san);
    nodes.add(n);
    current = n.id;
    return n;
  }

  String exportPgn() {
    final root = PgnNode<PgnNodeData>();
    final map = <String, PgnNode<PgnNodeData>>{};
    for (final n in nodes) {
      final c = PgnChildNode(
        PgnNodeData(
          san: n.san,
          comments: [
            if (n.comment.isNotEmpty) n.comment,
            if (n.shapes.where((s) => s.length == 5).isNotEmpty)
              '[%cal ${n.shapes.where((s) => s.length == 5).join(',')}]',
            if (n.shapes.where((s) => s.length == 3).isNotEmpty)
              '[%csl ${n.shapes.where((s) => s.length == 3).join(',')}]',
          ],
          nags: n.nags,
        ),
      );
      (n.parent == null ? root : map[n.parent]!).children.add(c);
      map[n.id] = c;
    }
    return PgnGame(
      headers: {
        ...PgnGame.defaultHeaders(),
        ...headers,
        'Event': title,
        'Result': result,
        if (rootFen != Chess.initial.fen) ...{'SetUp': '1', 'FEN': rootFen},
      },
      moves: root,
      comments: [],
    ).makePgn();
  }

  static ChessGame importPgn(PgnGame<PgnNodeData> pgn) {
    if (pgn.headers['Variant'] != null &&
        pgn.headers['Variant'] != 'Standard') {
      throw FormatException('Unsupported variant');
    }
    final start = PgnGame.startingPosition(pgn.headers);
    final g = ChessGame(
      id: newId(),
      title: pgn.headers['Event'] ?? 'Imported game',
      source: 'import',
      rootFen: start.fen,
      created: DateTime.now().millisecondsSinceEpoch,
      headers: pgn.headers,
    );
    g.result = pgn.headers['Result'] ?? '*';
    void visit(
      PgnNode<PgnNodeData> node,
      String? parent,
      Position p,
      int depth,
    ) {
      if (depth > 1024) throw FormatException('Variation too deep');
      for (final child in node.children) {
        final move = p.parseSan(child.data.san);
        if (move == null) {
          throw FormatException('Illegal move: ${child.data.san}');
        }
        g.current = parent;
        final n = g.play(move);
        n.comment = (child.data.comments ?? []).join('\n');
        final shapes = RegExp(r'\[%c(?:al|sl) ([^\]]+)\]')
            .allMatches(n.comment)
            .expand((m) => m.group(1)!.split(','));
        n.shapes = shapes
            .where(
              (s) => RegExp(r'^[GRBY][a-h][1-8]([a-h][1-8])?$').hasMatch(s),
            )
            .toSet()
            .toList();
        n.comment = n.comment
            .replaceAll(RegExp(r'\[%c(?:al|sl) [^\]]+\]'), '')
            .trim();
        n.nags = child.data.nags ?? [];
        visit(child, n.id, p.play(move), depth + 1);
      }
    }

    visit(pgn.moves, null, start, 0);
    g.current = g.mainline.lastOrNull?.id;
    return g;
  }
}

Map<String, dynamic> decodeMap(String text) =>
    Map<String, dynamic>.from(jsonDecode(text) as Map);
