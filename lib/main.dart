import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:dartchess/dartchess.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'core/chess/model.dart';
import 'core/storage/database.dart' show AppDatabase;
import 'core/storage/repository.dart';
import 'core/storage/backup.dart';
import 'core/engine/engine.dart';
import 'core/ui/theme.dart';
import 'core/ui/widgets.dart';
import 'features/play/game_screen.dart';
import 'features/analysis/position_editor.dart';
import 'features/puzzles/training_screen.dart';
import 'features/puzzles/training.dart';
import 'features/puzzles/packs.dart';
import 'features/statistics/statistics.dart';
import 'features/settings/preferences_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final dir = await getApplicationSupportDirectory();
  final repo = Repository(AppDatabase(io.File('${dir.path}/castlei.sqlite')));
  if ((await repo.db.rows('SELECT id FROM puzzles LIMIT 1')).isEmpty) {
    final puzzles = jsonDecode(
      await rootBundle.loadString('assets/puzzles/starter.json'),
    ) as List;
    await repo.db.transaction(() async {
      for (final p in puzzles) {
        await repo.db.execute(
          'INSERT OR IGNORE INTO puzzles VALUES(?,?,?,?,?,?)',
          [
            p['id'],
            'starter',
            p['fen'],
            jsonEncode(p['moves']),
            p['rating'],
            p['themes'],
          ],
        );
      }
    });
  }
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Stockfish',
      'dartchess',
      'Cburnett pieces',
      'Lichess puzzles',
    ], await rootBundle.loadString('assets/NOTICE.txt'));
  });
  runApp(CastleiApp(repo: repo));
}

class CastleiApp extends StatefulWidget {
  const CastleiApp({super.key, required this.repo});
  final Repository repo;
  @override
  State<CastleiApp> createState() => _AppState();
}

class _AppState extends State<CastleiApp> {
  ThemeMode mode = ThemeMode.system;
  late GoRouter router;
  final engine = EngineClient();
  @override
  void initState() {
    super.initState();
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (c, s) => HomeShell(
            repo: widget.repo,
            engine: engine,
            onTheme: (m) => setState(() => mode = m),
          ),
        ),
      ],
    );
    widget.repo.preference('theme', 'system').then((v) {
      if (mounted) setState(() => mode = ThemeMode.values.byName(v));
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Castlei',
    debugShowCheckedModeBanner: false,
    routerConfig: router,
    themeMode: mode,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.repo,
    required this.engine,
    required this.onTheme,
  });
  final Repository repo;
  final EngineClient engine;
  final void Function(ThemeMode) onTheme;
  @override
  State<HomeShell> createState() => _HomeState();
}

class _HomeState extends State<HomeShell> {
  int tab = 0;
  String search = '';
  bool favorites = false;
  String resultFilter = 'All';
  Future<void> guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> open(ChessGame g, {bool study = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          game: g,
          repo: widget.repo,
          engine: widget.engine,
          study: study,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<String?> textDialog(
    String title, {
    String initial = '',
    int lines = 1,
  }) async {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, maxLines: lines),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> newGame({bool study = false}) async {
    var level = 10;
    var side = 'white';
    var base = 0;
    var increment = 0;
    var fen = Chess.initial.fen;
    var title = study ? 'New study' : 'Practice game';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(study ? 'Create study' : 'Play Stockfish'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (s) => title = s,
                ),
                const SizedBox(height: 16),
                if (!study) ...[
                  DropdownButtonFormField<int>(
                    initialValue: level,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: [
                      for (var i = 0; i < 5; i++)
                        DropdownMenuItem(
                          value: i * 5,
                          child: Text(
                            ['Gentle', 'Easy', 'Medium', 'Hard', 'Maximum'][i],
                          ),
                        ),
                    ],
                    onChanged: (v) => level = v!,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: side,
                    decoration: const InputDecoration(labelText: 'Your side'),
                    items: [
                      for (final s in ['white', 'black', 'random'])
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) => side = v!,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: 0,
                    decoration: const InputDecoration(
                      labelText: 'Time control',
                    ),
                    items: [
                      for (final p in [
                        (0, 'Untimed'),
                        (3, '3+2'),
                        (5, '5+3'),
                        (10, '10+0'),
                        (15, '15+10'),
                        (-1, 'Custom'),
                      ])
                        DropdownMenuItem(value: p.$1, child: Text(p.$2)),
                    ],
                    onChanged: (v) => update(() {
                      base = v!;
                      increment = {3: 2, 5: 3, 15: 10}[v] ?? 0;
                    }),
                  ),
                  if (base == -1) ...[
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Base minutes (1–180)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => base = int.tryParse(v) ?? -1,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Increment seconds (0–60)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => increment = int.tryParse(v) ?? 0,
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<String>(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => PositionEditor(initialFen: fen),
                      ),
                    );
                    if (result != null) update(() => fen = result);
                  },
                  icon: const Icon(Icons.grid_on),
                  label: const Text('Visual position editor'),
                ),
                TextFormField(
                  key: ValueKey(fen),
                  initialValue: fen,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Starting FEN'),
                  onChanged: (v) => fen = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  Chess.fromSetup(Setup.parseFen(fen));
                  if (base < 0 ||
                      base > 180 ||
                      increment < 0 ||
                      increment > 60) {
                    throw const FormatException('Invalid time control');
                  }
                  Navigator.pop(ctx, true);
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (side == 'random') {
      side = DateTime.now().microsecond.isEven ? 'white' : 'black';
    }
    final g = ChessGame(
      id: newId(),
      title: title,
      source: study ? 'study' : 'engine',
      rootFen: fen,
      created: DateTime.now().millisecondsSinceEpoch,
      settings: {
        'side': side,
        'skill': level,
        'level': ['Gentle', 'Easy', 'Medium', 'Hard', 'Maximum'][level ~/ 5],
        'baseMs': base * 60000,
        'increment': increment,
      },
    );
    await widget.repo.save(g);
    if (mounted) await open(g, study: study);
  }

  Future<void> importPgn() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pgn'],
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 20 * 1024 * 1024) {
      throw const FormatException('PGN exceeds 20 MB');
    }
    final games = PgnGame.parseMultiGamePgn(utf8.decode(bytes));
    if (games.length > 10000) throw const FormatException('Too many games');
    var imported = 0, duplicates = 0;
    final errors = <String>[];
    final existing = <String>{};
    for (final row in await widget.repo.games()) {
      existing.add((await widget.repo.load(row['id'])).exportPgn());
    }
    for (var i = 0; i < games.length; i++) {
      try {
        final g = ChessGame.importPgn(games[i]);
        if (existing.contains(g.exportPgn())) {
          duplicates++;
          continue;
        }
        await widget.repo.save(g);
        existing.add(g.exportPgn());
        imported++;
      } catch (e) {
        errors.add('Game ${i + 1}: $e');
      }
    }
    if (mounted) {
      setState(() {});
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Import report'),
          content: SingleChildScrollView(
            child: Text(
              '$imported imported · $duplicates duplicates\n${errors.join('\n')}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> backup() async {
    final bytes = await BackupService(widget.repo.db).export();
    await FilePicker.saveFile(
      dialogTitle: 'Unencrypted backup — store privately',
      fileName: 'castlei-backup.zip',
      bytes: bytes,
    );
  }

  Future<void> restore() async {
    final selected = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (selected == null) return;
    final bytes = await selected.readAsBytes();
    final data = BackupService(widget.repo.db).validate(bytes);
    if (!mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Replace all local data?'),
        content: Text(
          'This backup contains ${(data['games'] as List).length} games. Existing data will be replaced. Back up first if you want to keep it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => guard(backup),
            child: const Text('Export current data'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (yes == true) {
      widget.engine.cancel();
      await BackupService(widget.repo.db).restore(bytes);
      if (mounted) setState(() {});
    }
  }

  Widget activity(
    String title,
    String detail,
    IconData icon,
    VoidCallback onTap,
  ) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: 28,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          const Icon(Icons.castle_outlined),
          const SizedBox(width: 10),
          Text(['Castlei', 'Play', 'Study', 'Library'][tab]),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: settings,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (i) => setState(() => tab = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(
          icon: Icon(Icons.sports_esports_outlined),
          label: 'Play',
        ),
        NavigationDestination(
          icon: Icon(Icons.school_outlined),
          label: 'Study',
        ),
        NavigationDestination(
          icon: Icon(Icons.collections_bookmark_outlined),
          label: 'Library',
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          if (tab == 0) ...[
            FutureBuilder(
              future: widget.repo.games(),
              builder: (c, snap) {
                final unfinished = (snap.data ?? [])
                    .where((r) => r['source'] == 'engine' && r['result'] == '*')
                    .firstOrNull;
                return unfinished == null
                    ? HeroCard(
                        eyebrow: 'Your next good move',
                        title: 'A little practice.\nA stronger game.',
                        action: HeroButton(
                          label: 'Play a game',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () => guard(() => newGame()),
                        ),
                      )
                    : HeroCard(
                        eyebrow: 'Pick up where you left off',
                        title: unfinished['title'] as String,
                        detail: 'Paused — your progress is saved.',
                        action: HeroButton(
                          label: 'Resume game',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () => guard(() async {
                            await open(
                              await widget.repo.load(unfinished['id']),
                            );
                          }),
                        ),
                      );
              },
            ),
            const SizedBox(height: 12),
            ActionTile(
              title: 'Daily tactics',
              subtitle: 'A fresh position to think through',
              icon: Icons.extension_rounded,
              accent: context.colors.secondary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrainingScreen(repo: widget.repo),
                ),
              ),
            ),
            ActionTile(
              title: 'Your progress',
              subtitle: 'Results, recall, and training trends',
              icon: Icons.insights_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatisticsScreen(repo: widget.repo),
                ),
              ),
            ),
            const SectionLabel('Recent games'),
          ],
          if (tab == 1) ...[
            HeroCard(
              eyebrow: 'Play Stockfish',
              title: 'Make room for practice.',
              detail: 'Five difficulty levels, optional clocks, fully offline.',
              action: HeroButton(
                label: 'New engine game',
                icon: Icons.add_rounded,
                onPressed: () => guard(() => newGame()),
              ),
            ),
            const SectionLabel('Saved games'),
          ],
          if (tab == 2) ...[
            ActionTile(
              title: 'Analysis board',
              subtitle: 'Explore positions and save your ideas',
              icon: Icons.analytics_rounded,
              onTap: () => guard(() => newGame(study: true)),
            ),
            ActionTile(
              title: 'Tactical puzzles',
              subtitle: 'Offline practice by theme and difficulty',
              icon: Icons.extension_rounded,
              accent: context.colors.secondary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrainingScreen(repo: widget.repo),
                ),
              ),
            ),
            ActionTile(
              title: 'Puzzle collections',
              subtitle: 'Add more positions for offline practice',
              icon: Icons.download_rounded,
              accent: context.colors.tertiary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PackScreen(repo: widget.repo),
                ),
              ),
            ),
            ActionTile(
              title: 'Opening repertoires',
              subtitle: 'Rehearse the lines you want to remember',
              icon: Icons.account_tree_rounded,
              onTap: repertoires,
            ),
          ],
          if (tab == 3) ...[
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search title, players, event',
              ),
              onChanged: (s) => setState(() => search = s),
            ),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Favorites'),
                  selected: favorites,
                  onSelected: (v) => setState(() => favorites = v),
                ),
                TextButton.icon(
                  onPressed: () => guard(importPgn),
                  icon: const Icon(Icons.file_open_outlined),
                  label: const Text('Import PGN'),
                ),
              ],
            ),
          ],
          if (tab != 2)
            FutureBuilder(
              future: widget.repo.games(),
              builder: (c, s) {
                if (!s.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = s.data!
                    .where(
                      (r) =>
                          (tab != 1 || r['source'] == 'engine') &&
                          (!favorites || r['favorite'] == 1) &&
                          ('${r['title']} ${r['headers']}'
                              .toLowerCase()
                              .contains(search.toLowerCase())),
                    )
                    .take(tab == 0 ? 5 : 1000);
                return Column(
                  children: [
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.castle_outlined,
                              size: 44,
                              color: context.colors.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your games will appear here.',
                              style: context.text.bodyLarge?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final row in rows)
                      Card(
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: context.colors.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              row['result'] == '*'
                                  ? Icons.play_arrow_rounded
                                  : row['source'] == 'import'
                                  ? Icons.file_download_done_rounded
                                  : Icons.flag_rounded,
                              color: context.colors.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            row['title'],
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                StatusChip(
                                  row['result'] == '*'
                                      ? 'In progress'
                                      : '${row['result']}',
                                  icon: row['result'] == '*'
                                      ? Icons.pause_circle_outline
                                      : Icons.check_circle_outline,
                                  color: row['result'] == '*'
                                      ? context.colors.secondary
                                      : context.colors.primary,
                                ),
                                StatusChip(
                                  '${row['source']}',
                                  icon: row['source'] == 'engine'
                                      ? Icons.memory
                                      : row['source'] == 'study'
                                      ? Icons.school_outlined
                                      : Icons.file_open_outlined,
                                ),
                                if (row['assisted'] == 1)
                                  StatusChip(
                                    'assisted',
                                    icon: Icons.lightbulb_outline,
                                    color: context.tokens.warn,
                                  ),
                                if (row['favorite'] == 1)
                                  StatusChip(
                                    'favorite',
                                    icon: Icons.star_rounded,
                                    color: context.colors.tertiary,
                                  ),
                              ],
                            ),
                          ),
                          onTap: () => guard(() async {
                            await open(
                              await widget.repo.load(row['id']),
                              study:
                                  row['source'] != 'engine' ||
                                  row['result'] != '*',
                            );
                          }),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) => guard(() async {
                              final g = await widget.repo.load(row['id']);
                              if (action == 'favorite') {
                                g.favorite = !g.favorite;
                                await widget.repo.save(g);
                              }
                              if (action == 'export') {
                                await FilePicker.saveFile(
                                  fileName: 'castlei-game.pgn',
                                  bytes: Uint8List.fromList(
                                    utf8.encode(g.exportPgn()),
                                  ),
                                );
                              }
                              if (action == 'rename') {
                                final name = await textDialog(
                                  'Rename game',
                                  initial: g.title,
                                );
                                if (name != null) {
                                  g.title = name;
                                  await widget.repo.save(g);
                                }
                              }
                              if (action == 'delete' && context.mounted) {
                                final yes = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text(
                                      'Delete game and its history?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (yes == true) await widget.repo.delete(g.id);
                              }
                              if (mounted) setState(() {});
                            }),
                            itemBuilder: (_) => [
                              for (final e in [
                                ('favorite', 'Toggle favorite'),
                                ('rename', 'Rename'),
                                ('export', 'Export PGN'),
                                ('delete', 'Delete'),
                              ])
                                PopupMenuItem(value: e.$1, child: Text(e.$2)),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    ),
  );
  Future<void> repertoires() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, update) => Scaffold(
            appBar: AppBar(title: const Text('Opening repertoires')),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                FilledButton(
                  onPressed: () => guard(() async {
                    final rows = await widget.repo.games();
                    if (!context.mounted) return;
                    final id = await showDialog<String>(
                      context: context,
                      builder: (c) => SimpleDialog(
                        title: const Text('Build from a saved game or study'),
                        children: [
                          for (final r in rows)
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(c, r['id']),
                              child: Text(r['title']),
                            ),
                        ],
                      ),
                    );
                    if (id == null || !context.mounted) return;
                    final side = await showDialog<String>(
                      context: context,
                      builder: (c) => SimpleDialog(
                        title: const Text('Train which side?'),
                        children: [
                          for (final s in ['white', 'black'])
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(c, s),
                              child: Text(s),
                            ),
                        ],
                      ),
                    );
                    if (side == null) return;
                    await TrainingService(widget.repo)
                        .buildCards(await widget.repo.load(id), side);
                    update(() {});
                  }),
                  child: const Text('Create from library'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Create a study or import PGN in Library, add your variations, then build or refresh its repertoire here.',
                  ),
                ),
                FutureBuilder(
                  future: widget.repo.db.rows(
                    'SELECT repertoires.*,games.title FROM repertoires JOIN games ON games.id=repertoires.game_id',
                  ),
                  builder: (c, s) => Column(
                    children: [
                      for (final r in s.data ?? [])
                        Card(
                          child: ListTile(
                            title: Text(r['title']),
                            subtitle: Text('Train ${r['side']}'),
                            trailing: PopupMenuButton<String>(
                              tooltip: 'Repertoire actions',
                              onSelected: (a) => guard(() async {
                                final game = await widget.repo.load(
                                  r['game_id'],
                                );
                                if (a == 'edit') {
                                  if (!context.mounted) return;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GameScreen(
                                        game: game,
                                        repo: widget.repo,
                                        engine: widget.engine,
                                        study: true,
                                      ),
                                    ),
                                  );
                                  await TrainingService(widget.repo).buildCards(
                                    await widget.repo.load(r['game_id']),
                                    r['side'],
                                  );
                                } else if (a == 'delete') {
                                  if (!context.mounted) return;
                                  final yes = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Delete repertoire?'),
                                      content: const Text(
                                        'Its drill history will be removed. The source study stays in your library.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(c, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (yes != true) return;
                                  await widget.repo.deleteRepertoire(r['id']);
                                } else if (a == 'export') {
                                  await SharePlus.instance.share(
                                    ShareParams(
                                      files: [
                                        XFile.fromData(
                                          utf8.encode(game.exportPgn()),
                                          mimeType: 'application/x-chess-pgn',
                                          name: '${game.title}.pgn',
                                        ),
                                      ],
                                      fileNameOverrides: ['${game.title}.pgn'],
                                    ),
                                  );
                                }
                                update(() {});
                              }),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit lines & refresh'),
                                ),
                                PopupMenuItem(
                                  value: 'export',
                                  child: Text('Export PGN'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrainingScreen(
                                  repo: widget.repo,
                                  repertoire: r['id'],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> settings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('APPEARANCE'),
              for (final mode in ThemeMode.values)
                ListTile(
                  title: Text('${mode.name} theme'),
                  onTap: () {
                    widget.onTheme(mode);
                    widget.repo.setPreference('theme', mode.name);
                  },
                ),
              const Divider(),
              activity(
                'Practice preferences',
                'Feedback, engine resources, and drill limits',
                Icons.tune,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PreferencesScreen(
                      repo: widget.repo,
                      engine: widget.engine,
                    ),
                  ),
                ),
              ),
              activity(
                'Export full backup',
                'Unencrypted archive; store it privately',
                Icons.backup_outlined,
                () => guard(backup),
              ),
              activity(
                'Restore backup',
                'Validate, then replace local data',
                Icons.restore,
                () => guard(restore),
              ),
              activity(
                'Enable crash reports',
                'Optional Firebase reports; no Analytics',
                Icons.bug_report_outlined,
                () => guard(() async {
                  final enabled = await widget.repo.preference(
                    'crashConsent',
                    false,
                  ) as bool;
                  try {
                    await Firebase.initializeApp();
                    await FirebaseCrashlytics.instance
                        .setCrashlyticsCollectionEnabled(!enabled);
                    await widget.repo.setPreference('crashConsent', !enabled);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            enabled
                                ? 'Crash reports disabled'
                                : 'Crash reports enabled',
                          ),
                        ),
                      );
                    }
                  } catch (_) {
                    throw StateError(
                      'Firebase is not configured in this private build. No reports were enabled.',
                    );
                  }
                }),
              ),
              const Divider(),
              const ListTile(
                title: Text('Castlei 1.0.0'),
                subtitle: Text(
                  'Stockfish 18 · GPL-3.0\nLocal-first. No account required.\niOS validation pending.',
                ),
              ),
              TextButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'Castlei',
                ),
                child: const Text('Open-source licenses'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
