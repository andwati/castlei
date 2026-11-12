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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Board and sound')),
    body: !ready
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: pagePadding(context),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: ChessBoard(
                    position: preview,
                    lastMove: lastMove,
                    coordinates: coordinates,
                    onMove: (_) {},
                    enabled: false,
                  ),
                ),
              ),
              const SectionLabel('Colours'),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final p in BoardStyle.palettes)
                    Semantics(
                      button: true,
                      selected: BoardStyle.palette == p.id,
                      excludeSemantics: true,
                      label: '${p.name} board',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          await BoardStyle.save(widget.repo, palette: p.id);
                          setState(() {});
                        },
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
                    ),
                ],
              ),
              const SectionLabel('Board'),
              GroupCard(
                children: [
                  SwitchListTile(
                    title: const Text('Show legal moves'),
                    subtitle: const Text(
                      'Dots on the squares a selected piece can move to.',
                    ),
                    value: BoardStyle.legalMoves,
                    onChanged: (v) async {
                      await BoardStyle.save(widget.repo, legalMoves: v);
                      setState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Highlight the last move'),
                    subtitle: const Text(
                      'Colours the squares the last piece moved from and to.',
                    ),
                    value: BoardStyle.highlightLast,
                    onChanged: (v) async {
                      await BoardStyle.save(widget.repo, highlightLast: v);
                      setState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Board coordinates'),
                    subtitle: const Text(
                      'Letters and numbers along the edges of the board.',
                    ),
                    value: coordinates,
                    onChanged: (v) => flag('coordinates', v),
                  ),
                ],
              ),
              const SectionLabel('Sound and touch'),
              GroupCard(
                children: [
                  SwitchListTile(
                    title: const Text('Move sounds'),
                    subtitle: const Text('A short sound for each move.'),
                    value: sound,
                    onChanged: (v) => flag('sound', v),
                  ),
                  SwitchListTile(
                    title: const Text('Move vibration'),
                    subtitle: const Text('A light buzz when a move is played.'),
                    value: haptics,
                    onChanged: (v) => flag('haptics', v),
                  ),
                ],
              ),
            ],
          ),
  );
}
