import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dartchess/dartchess.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../../core/storage/repository.dart';

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
    } catch (e) {
      status = 'Installation failed: $e';
    } finally {
      client.close();
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Puzzle collections')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(status),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: busy ? null : refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh catalog'),
        ),
        if (busy) const LinearProgressIndicator(),
        for (final p in packs)
          Card(
            child: ListTile(
              title: Text(p['title']),
              subtitle: Text(
                '${p['count']} puzzles · ${((p['bytes'] as int) / 1024).round()} KB',
              ),
              trailing: IconButton(
                onPressed: busy
                    ? null
                    : () => install(Map<String, dynamic>.from(p)),
                icon: const Icon(Icons.download),
              ),
            ),
          ),
        FutureBuilder(
          future: widget.repo.db.rows('SELECT * FROM packs'),
          builder: (c, s) => Column(
            children: [
              for (final p in s.data ?? [])
                ListTile(
                  title: Text('Installed: ${p['id']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await widget.repo.db.transaction(() async {
                        await widget.repo.db.execute(
                          'DELETE FROM puzzles WHERE pack=?',
                          [p['id']],
                        );
                        await widget.repo.db.execute(
                          'DELETE FROM packs WHERE id=?',
                          [p['id']],
                        );
                      });
                      setState(() {});
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
