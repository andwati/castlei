import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dartchess/dartchess.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../../core/storage/repository.dart';
import '../../core/diagnostics/perf.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/widgets.dart';

class PackScreen extends StatefulWidget {
  const PackScreen({super.key, required this.repo});
  final Repository repo;
  @override
  State<PackScreen> createState() => _PackState();
}

class _PackState extends State<PackScreen> {
  static const base = String.fromEnvironment(
    'CASTLEI_CATALOG_URL',
    defaultValue: 'https://andwati.github.io/castlei-puzzles/catalog.json',
  );
  List<dynamic> packs = [];
  String status = 'Refresh to check the catalog';
  bool busy = false;
  @override
  void initState() {
    super.initState();
    widget.repo.preference('catalog', <dynamic>[]).then((p) {
      if (mounted) setState(() => packs = List<dynamic>.from(p));
    });
  }

  Future<void> refresh() async {
    if (base.isEmpty) {
      setState(
        () => status = 'Catalog hosting is not configured in this build.',
      );
      return;
    }
    setState(() => busy = true);
    final timer = Stopwatch()..start();
    try {
      final uri = Uri.parse(base);
      if (uri.scheme != 'https') throw FormatException('HTTPS required');
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200 ||
          response.bodyBytes.length > 1024 * 1024) {
        throw FormatException('Invalid catalog response');
      }
      final data = jsonDecode(response.body);
      if (data['schema'] != 1) throw FormatException('Unsupported catalog');
      packs = data['packs'];
      await widget.repo.setPreference('catalog', packs);
      status = 'Catalog refreshed';
      Perf.record(
        'catalog_refresh',
        metrics: {'ms': timer.elapsedMilliseconds, 'packs': packs.length},
      );
    } catch (e) {
      status = '$e';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> install(Map<String, dynamic> pack) async {
    setState(() {
      busy = true;
      status = 'Downloading ${pack['title']}…';
    });
    final client = http.Client();
    final timer = Stopwatch()..start();
    try {
      final uri = Uri.parse(base).resolve(pack['url']);
      if (uri.scheme != 'https') throw FormatException('HTTPS required');
      final response = await client.send(http.Request('GET', uri));
      if (response.statusCode != 200) throw StateError('Download failed');
      final bytes = <int>[];
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 30),
      )) {
        bytes.addAll(chunk);
        if (bytes.length > 20 * 1024 * 1024) {
          throw FormatException('Pack exceeds 20 MB');
        }
      }
      if (sha256.convert(bytes).toString() != pack['sha256']) {
        throw FormatException('Checksum mismatch');
      }
      final zip = ZipDecoder().decodeBytes(bytes, verify: true);
      if (zip.files.fold<int>(0, (s, f) => s + f.size) > 50 * 1024 * 1024) {
        throw FormatException('Pack expands beyond limit');
      }
      if (zip.any(
        (f) => !['manifest.json', 'puzzles.jsonl'].contains(f.name),
      )) {
        throw FormatException('Invalid entry');
      }
      final manifest = jsonDecode(
        utf8.decode(zip.findFile('manifest.json')!.content),
      );
      if (manifest['schema'] != 1 || manifest['id'] != pack['id']) {
        throw FormatException('Manifest mismatch');
      }
      final rows = const LineSplitter()
          .convert(utf8.decode(zip.findFile('puzzles.jsonl')!.content))
          .map((l) => Map<String, dynamic>.from(jsonDecode(l)))
          .toList();
      if (rows.length != pack['count'] || rows.length > 5000) {
        throw FormatException('Invalid count');
      }
      for (final row in rows) {
        Position p = Chess.fromSetup(Setup.parseFen(row['fen']));
        for (final m in row['moves']) {
          p = p.play(Move.parse(m)!);
        }
      }
      await widget.repo.db.transaction(() async {
        for (final row in rows) {
          await widget.repo.db.execute(
            'INSERT OR IGNORE INTO puzzles VALUES(?,?,?,?,?,?)',
            [
              row['id'],
              pack['id'],
              row['fen'],
              jsonEncode(row['moves']),
              row['rating'],
              row['themes'],
            ],
          );
        }
        await widget.repo.db.execute(
          'INSERT OR REPLACE INTO packs VALUES(?,?)',
          [pack['id'], jsonEncode(manifest)],
        );
      });
      status = 'Installed ${rows.length} puzzles';
      Perf.record(
        'pack_install',
        metrics: {
          'ms': timer.elapsedMilliseconds,
          'puzzles': rows.length,
          'kb': bytes.length ~/ 1024,
        },
      );
    } catch (e) {
      status = 'Installation failed: $e';
    } finally {
      client.close();
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _remove(Map<String, dynamic> p) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Remove ${p['id']}?'),
        content: const Text(
          'Its puzzles are deleted from this device. Your completed attempts and statistics are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await widget.repo.db.transaction(() async {
      await widget.repo.db.execute('DELETE FROM puzzles WHERE pack=?', [
        p['id'],
      ]);
      await widget.repo.db.execute('DELETE FROM packs WHERE id=?', [p['id']]);
    });
    if (mounted) setState(() => status = 'Removed ${p['id']}');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Puzzle collections')),
    body: FutureBuilder(
      future: widget.repo.db.rows('SELECT * FROM packs'),
      builder: (c, snap) {
        final installed = {
          for (final r in snap.data ?? []) r['id'] as String: r,
        };
        final failed =
            status.contains('failed') ||
            status.contains('Invalid') ||
            status.contains('mismatch') ||
            status.contains('Exception') ||
            status.contains('Error');
        return ListView(
          padding: pagePadding(context),
          children: [
            FeedbackCard(
              status,
              busy: busy,
              tone: failed
                  ? Tone.bad
                  : status.startsWith('Installed') ||
                        status.startsWith('Catalog refreshed')
                  ? Tone.good
                  : Tone.info,
              icon: failed
                  ? Icons.cloud_off_rounded
                  : Icons.cloud_done_outlined,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh catalog'),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            const SectionLabel('Available'),
            if (packs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Refresh the catalog to see optional puzzle packs. Downloads only happen when you choose one.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            for (final p in packs)
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['title'],
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                StatusChip(
                                  '${p['count']} puzzles',
                                  icon: Icons.extension_outlined,
                                ),
                                StatusChip(
                                  '${((p['bytes'] as int) / 1024).round()} KB',
                                  icon: Icons.download_for_offline_outlined,
                                ),
                                if (installed.containsKey(p['id']))
                                  StatusChip(
                                    'On this device',
                                    icon: Icons.check_circle_outline,
                                    color: context.colors.primary,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: installed.containsKey(p['id'])
                            ? 'Reinstall ${p['title']}'
                            : 'Download ${p['title']}',
                        onPressed: busy
                            ? null
                            : () => install(Map<String, dynamic>.from(p)),
                        icon: const Icon(Icons.download),
                      ),
                    ],
                  ),
                ),
              ),
            if (installed.isNotEmpty) const SectionLabel('Installed'),
            for (final p in installed.values)
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.inventory_2_outlined,
                    color: context.colors.primary,
                  ),
                  title: Text('Installed: ${p['id']}'),
                  trailing: IconButton(
                    tooltip: 'Remove ${p['id']}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: busy ? null : () => _remove(p),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
