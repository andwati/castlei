import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dartchess/dartchess.dart';

import 'theme.dart';

class ChessBoard extends StatefulWidget {
  const ChessBoard({
    super.key,
    required this.position,
    required this.onMove,
    this.flipped = false,
    this.enabled = true,
    this.drawing = false,
    this.shapes = const [],
    this.onShape,
    this.arrow,
    this.coordinates = true,
    this.lastMove,
    this.onIllegalMove,
  });
  final Position position;
  final VoidCallback? onIllegalMove;
  final void Function(Move) onMove;
  final bool flipped, enabled, drawing, coordinates;
  final List<String> shapes;
  final void Function(String)? onShape;
  final String? arrow, lastMove;
  @override
  State<ChessBoard> createState() => _BoardState();
}

class _Tracked {
  _Tracked(this.id, this.piece);
  final int id;
  final Piece piece;
}

class _BoardState extends State<ChessBoard> {
  Square? selected, dragFrom, rejected;
  Offset? dragPosition;
  Timer? rejectionTimer;
  @override
  void dispose() {
    rejectionTimer?.cancel();
    super.dispose();
  }

  // Pieces keep an identity across moves so they can slide to new squares.
  Map<Square, _Tracked> _pieces = {};
  int _nextId = 0;

  /// Matches pieces on the new position to the old ones: unchanged squares
  /// keep their piece, moved pieces reuse the nearest vacated same-type piece.
  void _sync() {
    final old = _pieces;
    final next = <Square, _Tracked>{};
    final fresh = <Square, Piece>{};
    for (final entry in widget.position.board.pieces) {
      final sq = entry.$1, piece = entry.$2;
      final before = old[sq];
      if (before != null && before.piece == piece) {
        next[sq] = before;
      } else {
        fresh[sq] = piece;
      }
    }
    final keptIds = {for (final t in next.values) t.id};
    final free = <Square, _Tracked>{
      for (final e in old.entries)
        if (!keptIds.contains(e.value.id)) e.key: e.value,
    };
    for (final e in fresh.entries) {
      Square? best;
      var bestDistance = 99;
      for (final o in free.entries) {
        if (o.value.piece != e.value) continue;
        final d = math.max(
          (o.key.file - e.key.file).abs(),
          (o.key.rank - e.key.rank).abs(),
        );
        if (d < bestDistance) {
          bestDistance = d;
          best = o.key;
        }
      }
      if (best != null) {
        next[e.key] = free.remove(best)!;
      } else {
        next[e.key] = _Tracked(_nextId++, e.value);
      }
    }
    _pieces = next;
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  int squareIndex(int index) => widget.flipped
      ? ((index ~/ 8) * 8 + 7 - index % 8)
      : ((7 - index ~/ 8) * 8 + index % 8);
  @override
  void didUpdateWidget(ChessBoard old) {
    super.didUpdateWidget(old);
    if (old.position.fen != widget.position.fen ||
        old.drawing != widget.drawing) {
      selected = null;
    }
    if (old.position.fen != widget.position.fen) _sync();
  }

  Future<void> choose(Square s) async {
    if (widget.drawing) {
      widget.onShape?.call('G${s.name}');
      return;
    }
    if (!widget.enabled) return;
    final p = widget.position;
    if (selected != null) {
      final from = selected!;
      Move move = NormalMove(from: from, to: s);
      final piece = p.board.pieceAt(from);
      if (piece?.role == Role.pawn && (s.rank == 0 || s.rank == 7)) {
        final legal = p.isLegal(
          NormalMove(from: from, to: s, promotion: Role.queen),
        );
        if (legal) {
          final role = await showModalBottomSheet<Role>(
            context: context,
            builder: (c) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Promote to',
                      style: Theme.of(c).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 12,
                      children: [
                        for (final r in [
                          Role.queen,
                          Role.rook,
                          Role.bishop,
                          Role.knight,
                        ])
                          Semantics(
                            button: true,
                            label: 'Promote to ${r.name}',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.pop(c, r),
                              child: Container(
                                width: math.min(
                                  72,
                                  (MediaQuery.sizeOf(c).width - 76) / 4,
                                ),
                                height: math.min(
                                  72,
                                  (MediaQuery.sizeOf(c).width - 76) / 4,
                                ),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(c)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: SvgPicture.asset(
                                  'assets/pieces/${p.turn == Side.white ? 'w' : 'b'}${r.letter.toUpperCase()}.svg',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          if (role == null || !mounted) return;
          move = NormalMove(from: from, to: s, promotion: role);
        }
      }
      if (p.isLegal(move)) {
        setState(() => selected = null);
        widget.onMove(move);
        return;
      }
    }
    if (selected != null &&
        s != selected &&
        p.board.pieceAt(s)?.color != p.turn) {
      widget.onIllegalMove?.call();
      setState(() => rejected = s);
      rejectionTimer?.cancel();
      rejectionTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => rejected = null);
      });
      return;
    }
    setState(
      () => selected = selected == s
          ? null
          : p.board.pieceAt(s)?.color == p.turn
          ? s
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final last = widget.lastMove != null && widget.lastMove!.length >= 4
        ? {widget.lastMove!.substring(0, 2), widget.lastMove!.substring(2, 4)}
        : <String>{};
    final kingInCheck = widget.position.isCheck
        ? widget.position.board.kingOf(widget.position.turn)
        : null;
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.maxWidth / 8;
          Square squareAt(Offset o) => Square(
            squareIndex(
              (o.dy / size).floor().clamp(0, 7) * 8 +
                  (o.dx / size).floor().clamp(0, 7),
            ),
          );
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  GestureDetector(
                    onPanStart: (d) {
                      if (!widget.enabled && !widget.drawing) return;
                      final from = squareAt(d.localPosition);
                      if (!widget.drawing &&
                          widget.position.board.pieceAt(from)?.color !=
                              widget.position.turn) {
                        return;
                      }
                      setState(() {
                        dragFrom = from;
                        selected = from;
                        dragPosition = d.localPosition;
                      });
                    },
                    onPanUpdate: (d) {
                      if (dragFrom != null) {
                        setState(() => dragPosition = d.localPosition);
                      }
                    },
                    onPanCancel: () => setState(() {
                      dragFrom = null;
                      dragPosition = null;
                    }),
                    onPanEnd: (_) {
                      final from = dragFrom;
                      final offset = dragPosition;
                      if (from == null || offset == null) return;
                      setState(() {
                        dragFrom = null;
                        dragPosition = null;
                      });
                      if (offset.dx < 0 ||
                          offset.dy < 0 ||
                          offset.dx >= box.maxWidth ||
                          offset.dy >= box.maxWidth) {
                        return;
                      }
                      final to = squareAt(offset);
                      if (widget.drawing) {
                        widget.onShape?.call('G${from.name}${to.name}');
                      } else if (to != from) {
                        choose(to);
                      }
                    },
                    child: Listener(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: 64,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 8,
                            ),
                        itemBuilder: (c, i) {
                          final sq = Square(squareIndex(i));
                          final piece = widget.position.board.pieceAt(sq);
                          final legal =
                              selected != null &&
                              widget.position.legalMovesOf(selected!).has(sq);
                          final light = (sq.file + sq.rank) % 2 != 0;
                          final base = light ? tk.boardLight : tk.boardDark;
                          final isLast = last.contains(sq.name);
                          final isSel = selected == sq;
                          final isCheck = kingInCheck == sq;
                          final color = rejected == sq
                              ? tk.check
                              : isSel
                              ? Color.alphaBlend(
                                  tk.selected.withValues(alpha: .55),
                                  base,
                                )
                              : isLast
                              ? Color.alphaBlend(
                                  tk.lastMove.withValues(alpha: .6),
                                  base,
                                )
                              : base;
                          final capture = legal && piece != null;
                          final onSquare = light ? tk.boardDark : tk.boardLight;
                          return Semantics(
                            button: true,
                            label:
                                '${sq.name}, ${piece == null ? 'empty' : '${piece.color.name} ${piece.role.name}'}${isSel ? ', selected' : ''}${legal ? ', legal destination' : ''}${isLast ? ', last move' : ''}${isCheck ? ', king in check' : ''}',
                            child: GestureDetector(
                              onTap: () => choose(sq),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  gradient: isCheck
                                      ? RadialGradient(
                                          colors: [
                                            tk.check,
                                            tk.check.withValues(alpha: .0),
                                          ],
                                          stops: const [.35, 1],
                                        )
                                      : null,
                                  border: isSel
                                      ? Border.all(color: tk.selected, width: 3)
                                      : null,
                                ),
                                child: Stack(
                                  children: [
                                    if (legal && !capture)
                                      Center(
                                        child: Container(
                                          width: size * .26,
                                          height: size * .26,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: .26,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    if (capture)
                                      Container(
                                        margin: EdgeInsets.all(size * .04),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.black.withValues(
                                              alpha: .35,
                                            ),
                                            width: size * .07,
                                          ),
                                        ),
                                      ),
                                    if (widget.coordinates && i % 8 == 0)
                                      Positioned(
                                        left: 3,
                                        top: 1,
                                        child: Text(
                                          '${sq.rank + 1}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: onSquare,
                                          ),
                                        ),
                                      ),
                                    if (widget.coordinates && i >= 56)
                                      Positioned(
                                        right: 3,
                                        bottom: 1,
                                        child: Text(
                                          sq.name[0],
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: onSquare,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (dragFrom != null &&
                      dragPosition != null &&
                      !widget.drawing &&
                      widget.position.board.pieceAt(dragFrom!) != null)
                    Positioned(
                      left: dragPosition!.dx - size / 2,
                      top: dragPosition!.dy - size / 2,
                      width: size,
                      height: size,
                      child: IgnorePointer(
                        child: SvgPicture.asset(
                          'assets/pieces/${widget.position.turn == Side.white ? 'w' : 'b'}${widget.position.board.pieceAt(dragFrom!)!.role.letter.toUpperCase()}.svg',
                        ),
                      ),
                    ),
                  IgnorePointer(
                    child: SizedBox.square(
                      dimension: box.maxWidth,
                      child: Stack(
                        children: [
                          for (final e in _pieces.entries)
                            if (e.key != dragFrom || widget.drawing)
                              AnimatedPositioned(
                                key: ValueKey(e.value.id),
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 150),
                                curve: Curves.easeOutCubic,
                                left:
                                    (widget.flipped
                                        ? 7 - e.key.file
                                        : e.key.file) *
                                    size,
                                top:
                                    (widget.flipped
                                        ? e.key.rank
                                        : 7 - e.key.rank) *
                                    size,
                                width: size,
                                height: size,
                                child: Padding(
                                  padding: EdgeInsets.all(size * .06),
                                  child: SvgPicture.asset(
                                    'assets/pieces/${e.value.piece.color == Side.white ? 'w' : 'b'}${e.value.piece.role.letter.toUpperCase()}.svg',
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: CustomPaint(
                      size: Size.square(box.maxWidth),
                      painter: _Arrows([
                        ...widget.shapes,
                        if (widget.arrow != null)
                          'B${widget.arrow!.substring(0, 4)}',
                      ], widget.flipped),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Arrows extends CustomPainter {
  _Arrows(this.shapes, this.flipped);
  final List<String> shapes;
  final bool flipped;
  @override
  void paint(Canvas c, Size size) {
    final cell = size.width / 8;
    Offset center(String name) {
      final sq = Square.fromName(name);
      return Offset(
        (flipped ? 7 - sq.file : sq.file) * cell + cell / 2,
        (flipped ? sq.rank : 7 - sq.rank) * cell + cell / 2,
      );
    }

    for (final shape in shapes) {
      if (shape.length != 3 && shape.length != 5) continue;
      const colors = {
        'G': Color(0xff3f9b6e),
        'R': Color(0xffd8433a),
        'B': Color(0xff3b7dd8),
        'Y': Color(0xffe0a526),
      };
      final color = (colors[shape[0]] ?? colors['G']!).withValues(alpha: .82);
      final a = center(shape.substring(1, 3));
      if (shape.length == 3) {
        c.drawCircle(
          a,
          cell * .42,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * .09,
        );
        continue;
      }
      final b = center(shape.substring(3));
      final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
      final head = cell * .34;
      final tip = b - Offset(math.cos(angle), math.sin(angle)) * (cell * .08);
      final neck = tip - Offset(math.cos(angle), math.sin(angle)) * head;
      final start = a + Offset(math.cos(angle), math.sin(angle)) * (cell * .22);
      c.drawLine(
        start,
        neck,
        Paint()
          ..color = color
          ..strokeWidth = cell * .17
          ..strokeCap = StrokeCap.round,
      );
      final wing = Offset(-math.sin(angle), math.cos(angle)) * head * .55;
      c.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(neck.dx + wing.dx, neck.dy + wing.dy)
          ..lineTo(neck.dx - wing.dx, neck.dy - wing.dy)
          ..close(),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_Arrows old) => true;
}
