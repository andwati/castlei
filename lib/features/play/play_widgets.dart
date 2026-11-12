import 'package:flutter/material.dart';

import '../../core/chess/model.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/widgets.dart';
import '../analysis/eval_graph.dart';
import 'game_common.dart';

/// One side of the board: who they are, what they have captured, whose turn it
/// is and, in a timed game, their clock.
class PlayerBar extends StatelessWidget {
  const PlayerBar({
    super.key,
    required this.leading,
    required this.name,
    required this.captures,
    required this.capturedWhite,
    required this.active,
    this.inCheck = false,
    this.thinking = false,
    this.clock,
  });
  final Widget leading;
  final String name;
  final Captures captures;

  /// Whether the captured pieces were White's (drawn in outline) or Black's.
  final bool capturedWhite;
  final bool active, inCheck, thinking;
  final Widget? clock;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final glyphs = captures.taken
        .map((r) => roleGlyph(r, white: capturedWhite))
        .join();
    return Semantics(
      container: true,
      label:
          '$name${active ? ', to move' : ''}${inCheck ? ', in check' : ''}'
          '${captures.taken.isEmpty ? '' : ', has captured ${captures.taken.length} pieces'}'
          '${captures.lead > 0 ? ', ahead by ${captures.lead}' : ''}',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              SizedBox.square(dimension: 40, child: Center(child: leading)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleSmall,
                          ),
                        ),
                        if (active && !thinking) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: c.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        if (thinking) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                        if (inCheck) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Check',
                            style: context.text.labelLarge?.copyWith(
                              color: context.tokens.check,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (glyphs.isNotEmpty || captures.lead > 0)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: glyphs,
                              style: const TextStyle(letterSpacing: -2),
                            ),
                            if (captures.lead > 0)
                              TextSpan(
                                text:
                                    '${glyphs.isEmpty ? '' : '  '}+${captures.lead}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(
                          color: c.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              ?clock,
            ],
          ),
        ),
      ),
    );
  }
}

/// The game so far on a single line that follows the latest move. Tap it for
/// the whole list.
class MoveStrip extends StatefulWidget {
  const MoveStrip({
    super.key,
    required this.moves,
    required this.currentId,
    required this.labels,
    required this.onOpen,
  });
  final List<StudyNode> moves;
  final String? currentId;
  final Map<String, String> labels;
  final VoidCallback onOpen;
  @override
  State<MoveStrip> createState() => _MoveStripState();
}

class _MoveStripState extends State<MoveStrip> {
  final _controller = ScrollController();

  @override
  void didUpdateWidget(MoveStrip old) {
    super.didUpdateWidget(old);
    if (old.moves.length != widget.moves.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_controller.hasClients) return;
        _controller.animateTo(
          _controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: widget.moves.isEmpty
          ? 'Moves. None yet'
          : 'Moves. Last move ${widget.moves.last.san}. Show all moves',
      child: Material(
        color: c.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Corner.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(Corner.sm),
          onTap: widget.onOpen,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              children: [
                Expanded(
                  child: widget.moves.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Moves will appear here',
                              style: context.text.bodyMedium?.copyWith(
                                color: c.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : ExcludeSemantics(
                          child: IgnorePointer(
                            child: SingleChildScrollView(
                              controller: _controller,
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                children: [
                                  for (var i = 0; i < widget.moves.length; i++)
                                    MoveChip(
                                      number: i % 2 == 0
                                          ? '${i ~/ 2 + 1}.'
                                          : null,
                                      san: widget.moves[i].san,
                                      badge: badgeFor(
                                        widget.labels[widget.moves[i].id] ?? '',
                                      ),
                                      selected:
                                          widget.moves[i].id ==
                                          widget.currentId,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.unfold_more_rounded,
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Every move in the game, for when the strip is not enough.
Future<void> showMovesSheet(
  BuildContext context, {
  required List<StudyNode> moves,
  required String? currentId,
  required Map<String, String> labels,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .7,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Moves', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            moves.isEmpty
                ? const Text('No moves yet.')
                : Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < moves.length; i++)
                        MoveChip(
                          number: i % 2 == 0 ? '${i ~/ 2 + 1}.' : null,
                          san: moves[i].san,
                          badge: badgeFor(labels[moves[i].id] ?? ''),
                          selected: moves[i].id == currentId,
                        ),
                    ],
                  ),
          ],
        ),
      ),
    ),
  ),
);

/// How the game ended, with the obvious next step.
class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.headline,
    required this.reason,
    required this.won,
    required this.onReview,
    required this.onRematch,
  });
  final String headline, reason;
  final bool won;
  final VoidCallback onReview, onRematch;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: won ? c.primaryContainer : c.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Corner.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              headline,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            reason,
            style: context.text.bodyMedium?.copyWith(color: c.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onReview,
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Review game'),
          ),
          TextButton.icon(
            onPressed: onRematch,
            icon: const Icon(Icons.replay),
            label: const Text('Play again'),
          ),
        ],
      ),
    );
  }
}
