import 'package:flutter/material.dart';
import 'package:dartchess/dartchess.dart';

import 'board.dart';

/// Keeps the board beside its tools when there is room for two columns.
class BoardWorkspace extends StatelessWidget {
  const BoardWorkspace({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(16),
  });
  final List<Widget> children;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, box) {
        final board = children.indexWhere((w) => w is ChessBoard);
        if (box.maxWidth < 840 ||
            board < 0 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.5) {
          return ListView(padding: padding, children: children);
        }
        final width = (box.maxWidth * .52).clamp(320.0, 600.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: width,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: children.take(board + 1).toList(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: children.skip(board + 1).toList(),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class TurnCue extends StatelessWidget {
  const TurnCue({super.key, required this.position, this.detail});
  final Position position;
  final String? detail;
  @override
  Widget build(BuildContext context) {
    final side = position.turn == Side.white ? 'White' : 'Black';
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              position.turn == Side.white ? '♔' : '♚',
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$side to move${position.isCheck ? ' · $side is in check' : ''}${detail == null ? '' : '\n$detail'}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
