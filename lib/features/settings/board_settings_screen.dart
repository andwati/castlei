import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/storage/repository.dart';
import '../../core/ui/board.dart';
import '../../core/ui/board_style.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/widgets.dart';

/// Board look and feel, with a live board that shows each change at once.
class BoardSettingsScreen extends StatefulWidget {
  const BoardSettingsScreen({super.key, required this.repo});
  final Repository repo;
  @override
  State<BoardSettingsScreen> createState() => _BoardSettingsState();
}

class _BoardSettingsState extends State<BoardSettingsScreen> {
  bool coordinates = true, sound = false, haptics = true, ready = false;
  late Position preview;
  String? lastMove = 'e2e4';

  @override
  void initState() {
    super.initState();
    preview = Chess.initial.play(Move.parse('e2e4')!);
    load();
  }

  Future<void> load() async {
    coordinates = await widget.repo.preference('coordinates', true) as bool;
    sound = await widget.repo.preference('sound', false) as bool;
    haptics = await widget.repo.preference('haptics', true) as bool;
    if (mounted) setState(() => ready = true);
  }

  Future<void> flag(String key, bool value) async {
    await widget.repo.setPreference(key, value);
    setState(() {
      if (key == 'coordinates') coordinates = value;
      if (key == 'sound') sound = value;
      if (key == 'haptics') haptics = value;
    });
  }

  Widget _flag(
    String title,
    String subtitle,
    bool value,
    Future<void> Function(bool) onChanged,
  ) => SwitchListTile(
    title: Text(title),
    subtitle: Text(subtitle),
    value: value,
    onChanged: onChanged,
  );

  Future<void> _style({
    String? palette,
    bool? legalMoves,
    bool? highlightLast,
    bool? magnify,
    bool? contrast,
    bool? castleTwoSquares,
    bool? autoQueen,
    bool? figurine,
  }) async {
    await BoardStyle.save(
      widget.repo,
      palette: palette,
      legalMoves: legalMoves,
      highlightLast: highlightLast,
      magnify: magnify,
      contrast: contrast,
      castleTwoSquares: castleTwoSquares,
      autoQueen: autoQueen,
      figurine: figurine,
    );
    if (mounted) setState(() {});
  }

  Widget _preview() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: ChessBoard(
          position: preview,
          lastMove: lastMove,
          coordinates: coordinates,
          onMove: (_) {},
          enabled: false,
        ),
      ),
    ),
  );

  Widget _swatch(BoardPalette p) => Semantics(
    button: true,
    selected: BoardStyle.palette == p.id,
    excludeSemantics: true,
    label: '${p.name} board',
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _style(palette: p.id),
      child: Container(
        width: 72,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            width: 3,
            color: BoardStyle.palette == p.id
                ? context.colors.primary
                : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: ColoredBox(
                        color: p.light,
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: p.dark,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(p.name, style: context.text.labelSmall),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Board and sound'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Board'),
            Tab(text: 'Pieces'),
            Tab(text: 'Sound'),
          ],
        ),
      ),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _preview(),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView(
                        padding: pagePadding(context),
                        children: [
                          const SectionLabel('Colours'),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final p in BoardStyle.palettes) _swatch(p),
                            ],
                          ),
                          const SectionLabel('Behaviour'),
                          GroupCard(
                            children: [
                              _flag(
                                'Show legal moves',
                                'Dots on the squares a selected piece can move to.',
                                BoardStyle.legalMoves,
                                (v) => _style(legalMoves: v),
                              ),
                              _flag(
                                'Highlight the last move',
                                'Colours the squares the last piece moved from and to.',
                                BoardStyle.highlightLast,
                                (v) => _style(highlightLast: v),
                              ),
                              _flag(
                                'Board coordinates',
                                'Letters and numbers along the edges of the board.',
                                coordinates,
                                (v) => flag('coordinates', v),
                              ),
                              _flag(
                                'Castle with a two-square king move',
                                'Off: castle by moving the king onto its rook.',
                                BoardStyle.castleTwoSquares,
                                (v) => _style(castleTwoSquares: v),
                              ),
                              _flag(
                                'Promote to a queen automatically',
                                'Skips the choice of piece when a pawn reaches the end.',
                                BoardStyle.autoQueen,
                                (v) => _style(autoQueen: v),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ListView(
                        padding: pagePadding(context),
                        children: [
                          GroupCard(
                            children: [
                              _flag(
                                'Larger pieces',
                                'Fills more of each square so pieces are easier to see.',
                                BoardStyle.magnify,
                                (v) => _style(magnify: v),
                              ),
                              _flag(
                                'Stronger piece contrast',
                                'Makes white pieces brighter and black pieces darker.',
                                BoardStyle.contrast,
                                (v) => _style(contrast: v),
                              ),
                              _flag(
                                'Figurine notation',
                                'Shows moves with piece symbols, like ♘f3, instead of letters.',
                                BoardStyle.figurine,
                                (v) => _style(figurine: v),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ListView(
                        padding: pagePadding(context),
                        children: [
                          GroupCard(
                            children: [
                              _flag(
                                'Move sounds',
                                'A short sound for each move.',
                                sound,
                                (v) => flag('sound', v),
                              ),
                              _flag(
                                'Move vibration',
                                'A light buzz when a move is played.',
                                haptics,
                                (v) => flag('haptics', v),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    ),
  );
}
