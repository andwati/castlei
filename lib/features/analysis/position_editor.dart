import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/ui/theme.dart';
import '../../core/ui/widgets.dart';

class PositionEditor extends StatefulWidget {
  const PositionEditor({super.key, required this.initialFen});
  final String initialFen;
  @override
  State<PositionEditor> createState() => _EditorState();
}

class _EditorState extends State<PositionEditor> {
  final board = List<String>.filled(64, '');
  String selected = 'K', side = 'w', rights = 'KQkq', ep = '-';
  int half = 0, full = 1;
  String? error;
  @override
  void initState() {
    super.initState();
    load(widget.initialFen);
  }

  void load(String fen) {
    final fields = fen.split(' ');
    var i = 0;
    for (final c in fields[0].split('')) {
      if (c == '/') continue;
      final n = int.tryParse(c);
      if (n != null) {
        for (var j = 0; j < n; j++) {
          board[i++] = '';
        }
      } else {
        board[i++] = c;
      }
    }
    side = fields[1];
    rights = fields[2];
    ep = fields[3];
    half = int.parse(fields[4]);
    full = int.parse(fields[5]);
  }

  String fen() {
    final rows = <String>[];
    for (var r = 0; r < 8; r++) {
      var row = '', empty = 0;
      for (var f = 0; f < 8; f++) {
        final p = board[r * 8 + f];
        if (p.isEmpty) {
          empty++;
        } else {
          if (empty > 0) {
            row += '$empty';
            empty = 0;
          }
          row += p;
        }
      }
      if (empty > 0) row += '$empty';
      rows.add(row);
    }
    return '${rows.join('/')} $side ${rights.isEmpty ? '-' : rights} $ep $half $full';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Set up a position'),
      actions: [
        TextButton(
          onPressed: () {
            try {
              final p = Chess.fromSetup(Setup.parseFen(fen()));
              Navigator.pop(context, p.fen);
            } catch (e) {
              setState(() => error = '$e');
            }
          },
          child: const Text('Use position'),
        ),
      ],
    ),
    body: ListView(
      padding: pagePadding(context),
      children: [
        if (error != null) ...[
          FeedbackCard(error!, tone: Tone.bad, icon: Icons.rule_rounded),
          const SizedBox(height: 12),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 64,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (c, i) {
                final p = board[i];
                return Semantics(
                  label:
                      '${String.fromCharCode(97 + i % 8)}${8 - i ~/ 8}, ${p.isEmpty ? 'empty' : p}',
                  button: true,
                  child: InkWell(
                    onTap: () => setState(() => board[i] = selected),
                    child: Container(
                      color: (i ~/ 8 + i % 8).isEven
                          ? context.tokens.boardLight
                          : context.tokens.boardDark,
                      child: p.isEmpty
                          ? null
                          : SvgPicture.asset(
                              'assets/pieces/${p == p.toUpperCase() ? 'w' : 'b'}${p.toUpperCase()}.svg',
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SectionLabel('Pieces'),
        Wrap(
          spacing: 4,
          children: [
            for (final p in [
              'K',
              'Q',
              'R',
              'B',
              'N',
              'P',
              'k',
              'q',
              'r',
              'b',
              'n',
              'p',
              '',
            ])
              ChoiceChip(
                label: p.isEmpty
                    ? const Icon(Icons.backspace_outlined)
                    : SizedBox(
                        width: 30,
                        height: 30,
                        child: SvgPicture.asset(
                          'assets/pieces/${p == p.toUpperCase() ? 'w' : 'b'}${p.toUpperCase()}.svg',
                        ),
                      ),
                selected: selected == p,
                onSelected: (_) => setState(() => selected = p),
              ),
          ],
        ),
        Wrap(
          children: [
            TextButton(
              onPressed: () => setState(() => board.fillRange(0, 64, '')),
              child: const Text('Clear board'),
            ),
            TextButton(
              onPressed: () => setState(() => load(Chess.initial.fen)),
              child: const Text('Initial position'),
            ),
          ],
        ),
        const SectionLabel('Position details'),
        DropdownButtonFormField<String>(
          initialValue: side,
          decoration: const InputDecoration(labelText: 'Side to move'),
          items: const [
            DropdownMenuItem(value: 'w', child: Text('White')),
            DropdownMenuItem(value: 'b', child: Text('Black')),
          ],
          onChanged: (v) => side = v!,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: rights,
          decoration: const InputDecoration(
            labelText: 'Castling rights (KQkq or -)',
          ),
          onChanged: (v) => rights = v,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: ep,
          decoration: const InputDecoration(
            labelText: 'En passant square or -',
          ),
          onChanged: (v) => ep = v,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: '$half',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Halfmove clock'),
          onChanged: (v) => half = int.tryParse(v) ?? -1,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: '$full',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Fullmove number'),
          onChanged: (v) => full = int.tryParse(v) ?? 0,
        ),
      ],
    ),
  );
}
