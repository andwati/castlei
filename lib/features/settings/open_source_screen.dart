import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/ui/theme.dart';
import '../../core/ui/widgets.dart';

/// The open-source software Castlei is built on. Key components are listed
/// first, then every package whose license is registered with the app.
class OpenSourceScreen extends StatefulWidget {
  const OpenSourceScreen({super.key});
  @override
  State<OpenSourceScreen> createState() => _OpenSourceState();
}

class _Component {
  const _Component(this.name, this.what, this.license);
  final String name, what, license;
}

const _key = [
  _Component('Stockfish 18', 'Chess engine (on-device)', 'GPL-3.0-or-later'),
  _Component('dartchess', 'Rules, FEN, SAN and PGN', 'GPL-3.0'),
  _Component('Flutter and Dart', 'App framework', 'BSD-3-Clause'),
  _Component('Cburnett chess pieces', 'Piece artwork', 'GPL-2.0-or-later'),
  _Component('Lichess puzzle database', 'Tactics', 'CC0-1.0'),
  _Component('Lichess opening names', 'Opening names (ECO)', 'CC0-1.0'),
  _Component('Fraunces typeface', 'Display type', 'SIL OFL 1.1'),
  _Component('Drift and SQLite', 'Local database', 'MIT / public domain'),
  _Component(
    'Firebase SDKs',
    'Crash, performance, analytics, sign-in, backup',
    'Apache-2.0',
  ),
];

class _OpenSourceState extends State<OpenSourceScreen> {
  final Map<String, List<String>> packages = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final found = <String, List<String>>{};
    await for (final entry in LicenseRegistry.licenses) {
      final text = entry.paragraphs.map((p) => p.text).join('\n\n');
      for (final name in entry.packages) {
        found.putIfAbsent(name, () => []).add(text);
      }
    }
    if (!mounted) return;
    setState(() {
      packages
        ..clear()
        ..addEntries(
          found.entries.toList()..sort(
            (a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()),
          ),
        );
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Open-source software')),
    body: ListView(
      padding: pagePadding(context),
      children: [
        Text(
          'Castlei is built on the work of these open-source projects. Each keeps its own license.',
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SectionLabel('Key components'),
        GroupCard(
          children: [
            for (final c in _key)
              ListTile(
                title: Text(c.name),
                subtitle: Text(c.what),
                trailing: StatusChip(c.license, icon: Icons.balance_outlined),
              ),
          ],
        ),
        SectionLabel(
          loading ? 'All packages' : 'All packages (${packages.length})',
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        for (final e in packages.entries)
          Card(
            child: ListTile(
              title: Text(e.key),
              subtitle: Text(
                e.value.length == 1
                    ? '1 license'
                    : '${e.value.length} licenses',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _LicenseText(name: e.key, texts: e.value),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _LicenseText extends StatelessWidget {
  const _LicenseText({required this.name, required this.texts});
  final String name;
  final List<String> texts;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(name)),
    body: ListView(
      padding: pagePadding(context),
      children: [
        for (final t in texts) ...[
          SelectableText(
            t,
            style: context.text.bodySmall?.copyWith(height: 1.4),
          ),
          const Divider(height: 32),
        ],
      ],
    ),
  );
}
