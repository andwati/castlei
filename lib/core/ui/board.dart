import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dartchess/dartchess.dart';

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
  });
  final Position position;
  final void Function(Move) onMove;
  final bool flipped, enabled, drawing, coordinates;
  final List<String> shapes;
  final void Function(String)? onShape;
  final String? arrow;
  @override
  State<ChessBoard> createState() => _BoardState();
}

class _BoardState extends State<ChessBoard> {
  Square? selected, dragFrom;
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
          final role = await showDialog<Role>(
            context: context,
            builder: (c) => SimpleDialog(
              title: const Text('Promote pawn'),
              children: [
                for (final r in [
                  Role.queen,
                  Role.rook,
                  Role.bishop,
                  Role.knight,
                ])
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(c, r),
                    child: Text(r.name),
                  ),
              ],
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
    setState(() => selected = p.board.pieceAt(s)?.color == p.turn ? s : null);
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
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
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              GestureDetector(
                onPanStart: (d) {
                  dragFrom = squareAt(d.localPosition);
                  if (!widget.drawing) setState(() => selected = dragFrom);
                },
                onPanEnd: (_) => dragFrom = null,
                onPanUpdate: (d) {},
                onPanDown: (d) {},
                child: Listener(
                  onPointerUp: (e) {
                    if (dragFrom != null) {
                      final to = squareAt(e.localPosition);
                      if (to != dragFrom) {
                        if (widget.drawing) {
                          widget.onShape?.call('G${dragFrom!.name}${to.name}');
                        } else {
                          choose(to);
                        }
                      }
                      dragFrom = null;
                    }
                  },
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
                      final color = selected == sq
                          ? const Color(0xffedb978)
                          : light
                          ? const Color(0xffe9eee4)
                          : const Color(0xff72958a);
                      return Semantics(
                        button: true,
                        label:
                            '${sq.name}, ${piece == null ? 'empty' : '${piece.color.name} ${piece.role.name}'}${selected == sq ? ', selected' : ''}${legal ? ', legal destination' : ''}',
                        child: GestureDetector(
                          onTap: () => choose(sq),
                          child: Container(
                            color: color,
                            child: Stack(
                              children: [
                                if (piece != null)
                                  Padding(
                                    padding: EdgeInsets.all(size * .07),
                                    child: SvgPicture.asset(
                                      'assets/pieces/${piece.color == Side.white ? 'w' : 'b'}${piece.role.letter.toUpperCase()}.svg',
                                    ),
                                  ),
                                if (legal)
                                  Center(
                                    child: Container(
                                      width: size * .22,
                                      height: size * .22,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: .22,
                                        ),
                                        shape: BoxShape.circle,
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
                                        color: light
                                            ? Colors.black54
                                            : Colors.white,
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
                                        color: light
                                            ? Colors.black54
                                            : Colors.white,
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
        );
      },
    ),
  );
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
      final colors = {
        'G': Colors.green,
        'R': Colors.red,
        'B': Colors.blue,
        'Y': Colors.amber,
      };
      final p = Paint()
        ..color = (colors[shape[0]] ?? Colors.green).withValues(alpha: .65)
        ..strokeWidth = cell * .13
        ..strokeCap = StrokeCap.round;
      final a = center(shape.substring(1, 3));
      if (shape.length == 3) {
        c.drawCircle(a, cell * .37, p..style = PaintingStyle.stroke);
        continue;
      }
      final b = center(shape.substring(3));
      c.drawLine(a, b, p);
      final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
      for (final sign in [-1, 1]) {
        c.drawLine(
          b,
          b -
              Offset(
                    math.cos(angle + sign * .55),
                    math.sin(angle + sign * .55),
                  ) *
                  cell *
                  .3,
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Arrows old) => true;
}
