import 'dart:async';
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

import 'core/diagnostics/crash.dart';
import 'core/diagnostics/log.dart';
import 'core/diagnostics/perf.dart';
import 'core/diagnostics/analytics.dart';
import 'core/cloud/account.dart';
import 'core/cloud/cloud_backup.dart';
import 'core/cloud/entitlements.dart';
import 'core/cloud/remote_config.dart';
import 'core/notifications/notifications.dart';
import 'core/update/play_update.dart';
import 'features/settings/settings_screen.dart';

import 'package:quick_actions/quick_actions.dart';

import 'core/chess/model.dart';
import 'core/chess/engine_opponents.dart';
import 'core/ui/engine_avatar.dart';
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
import 'features/learn/lesson_screen.dart';
import 'features/learn/coordinates.dart';

/// Tests re-run main() in one process; never leave two connections on the file.
AppDatabase? _openDatabase;

Future<void> main() async {
  final startup = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([]);
  final dir = await getApplicationSupportDirectory();
  await _openDatabase?.close();
  _openDatabase = AppDatabase(io.File('${dir.path}/castlei.sqlite'));
  final repo = Repository(_openDatabase!);
  // Never let Firebase delay or block the first frame.
  var firstFrameMs = -1;
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => firstFrameMs = startup.elapsedMilliseconds,
  );
  unawaited(() async {
    // Local-only services first; none of this may delay the first frame.
    await Entitlements.instance.load(repo);
    await DiagnosticsLog.attach(repo);
    await Notifications.start(repo);
    await CrashReporting.start(repo);
    if (!CrashReporting.available) return;
    await Future.wait([
      Perf.start(repo),
      Analytics.start(repo),
      AccountService.instance.start(),
      RemoteSettings.start(),
    ]);
    await Messaging.start(repo);
    CloudBackup.attach(repo);
    Analytics.log('app_open');
    // Dart-side time from process entry to the first rendered frame.
    for (var i = 0; i < 50 && firstFrameMs < 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await Perf.record('first_frame', metrics: {'ms': firstFrameMs});
  }());
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Stockfish',
      'dartchess',
      'Cburnett pieces',
      'Lichess puzzles',
      'Lichess opening names',
      'Fraunces typeface',
    ], await rootBundle.loadString('assets/NOTICE.txt'));
  });
  runApp(CastleiApp(repo: repo));
  // Seed the starter puzzles after the first frame so first launch isn't delayed.
  repo.seeding = _seedStarterPuzzles(repo);
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
    // Keep every route, sheet, and scroll viewport above the system controls.
    // SafeArea consumes these insets so route-level padding cannot add them twice.
    builder: (context, child) => ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(top: false, child: child ?? const SizedBox.shrink()),
    ),
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

class _HomeState extends State<HomeShell> with WidgetsBindingObserver {
  StreamSubscription<String>? _taps;
  List<Timer> _bannerTimers = [];
  String _bannerId = '', _bannerText = '';
  int tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _taps = Notifications.taps.stream.listen(_onNotificationTap);
    _setupShortcuts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PlayUpdate.check(ScaffoldMessenger.of(context));
    });
    // Remote Config arrives asynchronously; check a couple of times early on.
    _bannerTimers = [
      for (final seconds in [3, 12])
        Timer(Duration(seconds: seconds), _loadBanner),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _taps?.cancel();
    for (final t in _bannerTimers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Notifications.reschedule(widget.repo);
      CloudBackup.maybeAutoBackup(reason: 'resume');
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    final id = RemoteSettings.announcementId;
    final text = RemoteSettings.announcementText;
    final seen = await widget.repo.preference('announcementSeen', '') as String;
    if (!mounted) return;
    setState(() {
      _bannerId = id;
      _bannerText = (text.isEmpty || id == seen) ? '' : text;
    });
  }

  Future<void> _dismissBanner() async {
    await widget.repo.setPreference('announcementSeen', _bannerId);
    if (mounted) setState(() => _bannerText = '');
  }

  void _setupShortcuts() {
    if (!(io.Platform.isAndroid || io.Platform.isIOS)) return;
    const quick = QuickActions();
    quick.initialize((type) => _onNotificationTap(type));
    quick.setShortcutItems(const [
      ShortcutItem(type: 'resume', localizedTitle: 'Resume game'),
      ShortcutItem(type: 'puzzle', localizedTitle: 'Daily tactics'),
    ]);
  }

  /// Handles notification taps and app-shortcut launches.
  Future<void> _onNotificationTap(String payload) async {
    if (!mounted) return;
    Analytics.log('notification_opened', {'kind': payload.split(':').first});
    if (payload == 'drills') {
      await repertoires();
    } else if (payload == 'puzzle') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TrainingScreen(repo: widget.repo)),
      );
    } else if (payload == 'resume' || payload.startsWith('resume:')) {
      final games = await widget.repo.games();
      final id = payload.contains(':') ? payload.split(':')[1] : null;
      final row = games
          .where(
            (r) =>
                r['source'] == 'engine' &&
                r['result'] == '*' &&
                (id == null || r['id'] == id),
          )
          .firstOrNull;
      if (row != null && mounted) await open(await widget.repo.load(row['id']));
    }
  }

  String search = '';
  bool favorites = false;
  String resultFilter = 'All';
  String? sourceFilter;
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
      builder: (ctx) => ActionDialog(
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

  String settingsLevel(ChessGame g) => g.settings['level'] as String;

  Future<void> newGame({bool study = false}) async {
    var level = 10;
    var side = 'white';
    var base = 0;
    var increment = 0;
    var fen = Chess.initial.fen;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => ActionDialog(
          title: Text(study ? 'Create study' : 'Play Stockfish'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!study) ...[
                  DropdownButtonFormField<int>(
                    initialValue: level,
                    isExpanded: true,
                    itemHeight: 64,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: [
                      for (final opponent in EngineOpponent.all)
                        DropdownMenuItem(
                          value: opponent.skill,
                          child: Row(
                            children: [
                              EngineAvatar(opponent: opponent, size: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  opponent.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
    if (ok != true || !mounted) return;
    final now = DateTime.now();
    final localizations = MaterialLocalizations.of(context);
    final stamp =
        '${localizations.formatMediumDate(now)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(now))}';
    final title = study
        ? 'Study · $stamp'
        : 'Stockfish · ${EngineOpponent.forSkill(level).label} · $stamp';
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
        'level': EngineOpponent.forSkill(level).label,
        'baseMs': base * 60000,
        'increment': increment,
      },
    );
    await widget.repo.save(g);
    Analytics.log(study ? 'study_created' : 'game_started', {
      if (!study) ...{
        'difficulty': settingsLevel(g),
        'timed': base == 0 ? 'no' : 'yes',
        'custom_position': fen == Chess.initial.fen ? 'no' : 'yes',
      },
    });
    if (mounted) await open(g, study: study);
  }

  Future<void> importPgn() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pgn'],
    );
    if (file == null) return;
    final importTimer = Stopwatch()..start();
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
    Perf.record(
      'pgn_import',
      metrics: {
        'ms': importTimer.elapsedMilliseconds,
        'games': games.length,
        'imported': imported,
        'rejected': errors.length,
        'kb': bytes.length ~/ 1024,
      },
    );
    if (mounted) {
      setState(() {});
      await showDialog(
        context: context,
        builder: (c) => ActionDialog(
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
    final bytes = await Perf.trace(
      'backup_export',
      () => BackupService(widget.repo.db).export(),
      metrics: (b) => {'kb': b.length ~/ 1024},
    );
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
    await restoreBytes(await selected.readAsBytes());
  }

  /// Validates a backup, asks for confirmation, then replaces local data.
  Future<void> restoreBytes(Uint8List bytes) async {
    final data = BackupService(widget.repo.db).validate(bytes);
    if (!mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => ActionDialog(
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
      await Perf.trace(
        'backup_restore',
        () => BackupService(widget.repo.db).restore(bytes),
        metrics: (_) => {'kb': bytes.length ~/ 1024},
      );
      await CrashReporting.applyPreference(widget.repo);
      await Perf.applyPreference(widget.repo);
      await Analytics.applyPreference(widget.repo);
      await Messaging.applyPreference(widget.repo);
      await Notifications.reschedule(widget.repo);
      Analytics.log('backup_restored');
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          const Icon(Icons.castle_outlined),
          const SizedBox(width: 10),
          Text(['Castlei', 'Play', 'Learn', 'Library'][tab]),
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
      onDestinationSelected: (i) {
        setState(() => tab = i);
        Analytics.screen(['home', 'play', 'learn', 'library'][i]);
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(
          icon: Icon(Icons.sports_esports_outlined),
          label: 'Play',
        ),
        NavigationDestination(
          icon: Icon(Icons.school_outlined),
          label: 'Learn',
        ),
        NavigationDestination(
          icon: Icon(Icons.collections_bookmark_outlined),
          label: 'Library',
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: pagePadding(context),
        children: [
          if (tab == 0) ...[
            if (_bannerText.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: Text(_bannerText),
                  trailing: IconButton(
                    tooltip: 'Dismiss',
                    icon: const Icon(Icons.close),
                    onPressed: _dismissBanner,
                  ),
                ),
              ),
            FutureBuilder(
              future: widget.repo.games(),
              builder: (c, snap) {
                final unfinished = (snap.data ?? [])
                    .where((r) => r['source'] == 'engine' && r['result'] == '*')
                    .firstOrNull;
                return unfinished == null
                    ? HeroCard(
                        eyebrow: 'Your next good move',
                        title: 'Ready for your next move?',
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
                  builder: (_) => StatisticsScreen(
                    repo: widget.repo,
                    onOpenRepertoires: repertoires,
                    onOpenGame: (id) async =>
                        open(await widget.repo.load(id), study: true),
                  ),
                ),
              ),
            ),
            ActionTile(
              title: 'Continue learning',
              subtitle: 'Resume your guided course',
              icon: Icons.school_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LessonsScreen(repo: widget.repo),
                ),
              ),
            ),
            const SectionLabel('Recent games'),
          ],
          if (tab == 1) ...[
            HeroCard(
              eyebrow: 'Play Stockfish',
              title: 'Play at your pace.',
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
              title: 'Guided lessons',
              subtitle: '24 lessons · Beginner to intermediate',
              icon: Icons.school_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LessonsScreen(repo: widget.repo),
                ),
              ),
            ),
            ActionTile(
              title: 'Coordinate training',
              subtitle: 'Find and name squares · Practice or timed challenge',
              icon: Icons.grid_on,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CoordinateScreen(repo: widget.repo),
                ),
              ),
            ),

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
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    avatar: const Icon(Icons.star_rounded, size: 18),
                    label: const Text('Favorites'),
                    selected: favorites,
                    onSelected: (v) => setState(() => favorites = v),
                  ),
                  const SizedBox(width: 8),
                  for (final e in {
                    'engine': ('Engine', Icons.memory),
                    'import': ('Imported', Icons.file_open_outlined),
                    'study': ('Studies', Icons.school_outlined),
                  }.entries) ...[
                    FilterChip(
                      avatar: Icon(e.value.$2, size: 18),
                      label: Text(e.value.$1),
                      selected: sourceFilter == e.key,
                      onSelected: (v) =>
                          setState(() => sourceFilter = v ? e.key : null),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.primaryContainer,
                foregroundColor: context.colors.onPrimaryContainer,
              ),
              onPressed: () => guard(importPgn),
              icon: const Icon(Icons.file_open_outlined),
              label: const Text('Import PGN'),
            ),
            const SizedBox(height: 12),
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
                          (tab != 3 ||
                              sourceFilter == null ||
                              r['source'] == sourceFilter) &&
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
                                  builder: (c) => ActionDialog(
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
              padding: pagePadding(context),
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.add_rounded),
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
                  label: const Text('Create from library'),
                ),
                const SizedBox(height: 12),
                const FeedbackCard(
                  'Create a study or import PGN in Library, add your variations, then build or refresh its repertoire here.',
                  tone: Tone.info,
                  icon: Icons.lightbulb_outline_rounded,
                ),
                FutureBuilder(
                  future: widget.repo.db.rows(
                    'SELECT repertoires.*,games.title,'
                    '(SELECT COUNT(*) FROM cards WHERE repertoire_id=repertoires.id AND stage=0) AS fresh,'
                    '(SELECT COUNT(*) FROM cards WHERE repertoire_id=repertoires.id AND stage>0 AND due<=?) AS due '
                    'FROM repertoires JOIN games ON games.id=repertoires.game_id',
                    [DateTime.now().millisecondsSinceEpoch],
                  ),
                  builder: (c, s) => Column(
                    children: [
                      for (final r in s.data ?? [])
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
                                r['side'] == 'white'
                                    ? Icons.circle_outlined
                                    : Icons.circle,
                                color: context.colors.onPrimaryContainer,
                              ),
                            ),
                            title: Text(
                              r['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  StatusChip(
                                    'Train ${r['side']}',
                                    icon: Icons.person_outline,
                                  ),
                                  StatusChip(
                                    '${r['due']} due',
                                    icon: Icons.schedule_rounded,
                                    color: (r['due'] as int) > 0
                                        ? context.colors.secondary
                                        : null,
                                  ),
                                  StatusChip(
                                    '${r['fresh']} new',
                                    icon: Icons.fiber_new_rounded,
                                    color: context.colors.primary,
                                  ),
                                ],
                              ),
                            ),
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
                                    builder: (c) => ActionDialog(
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
    final mode = ThemeMode.values.byName(
      await widget.repo.preference('theme', 'system') as String,
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          repo: widget.repo,
          engine: widget.engine,
          mode: mode,
          onTheme: widget.onTheme,
          onBackup: backup,
          onRestoreFile: restore,
          onRestoreBytes: restoreBytes,
          guard: (a) => guard(a),
        ),
      ),
    );
  }
}

/// Imports the bundled starter puzzles on first launch.
Future<void> _seedStarterPuzzles(Repository repo) async {
  if ((await repo.db.rows('SELECT id FROM puzzles LIMIT 1')).isNotEmpty) return;
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
