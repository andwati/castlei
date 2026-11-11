import 'package:castlei/core/app_info.dart';
import 'package:castlei/core/diagnostics/log.dart';
import 'package:castlei/core/diagnostics/snapshot.dart';
import 'package:castlei/core/storage/database.dart';
import 'package:castlei/core/storage/repository.dart';
import 'package:castlei/core/ui/theme.dart';
import 'package:castlei/features/settings/diagnostics_screen.dart';
import 'package:castlei/features/settings/open_source_screen.dart';
import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

Widget host(Widget child) =>
    MaterialApp(theme: buildTheme(Brightness.light), home: child);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Castlei',
      packageName: 'com.andwati.castlei',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    );
  });

  test('build number hides the per-ABI version-code offset', () {
    expect(displayBuild('2001'), '1'); // arm64-v8a build 1
    expect(displayBuild('1007'), '7'); // armeabi-v7a build 7
    expect(displayBuild('4012'), '12'); // x86_64 build 12
    expect(displayBuild('45'), '45'); // no offset (debug/flutter run)
    expect(displayBuild('abc'), 'abc');
  });

  test('report format lists sections and events', () {
    final text = formatSnapshot(
      {
        'app': {'version': '1.0.0', 'build': '1'},
        'switches': {'crash reports': 'on'},
      },
      [
        {'t': 0, 'k': 'event', 'm': 'screen:home'},
      ],
    );
    expect(text, startsWith('Castlei diagnostics snapshot'));
    expect(text, contains('[app]\nversion: 1.0.0\nbuild: 1'));
    expect(text, contains('[recent events (1)]'));
    expect(text, contains('1970-01-01T00:00:00.000Z event screen:home'));
    expect(formatSnapshot({}, []), contains('none'));
  });

  test('event log is bounded and scrubs chess content and paths', () {
    for (var i = 0; i < DiagnosticsLog.capacity + 25; i++) {
      DiagnosticsLog.add('event', 'screen:$i');
    }
    expect(DiagnosticsLog.entries.length, DiagnosticsLog.capacity);
    expect(
      DiagnosticsLog.entries.last['m'],
      'screen:${DiagnosticsLog.capacity + 24}',
    );
    DiagnosticsLog.add(
      'error',
      'bad rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1 in /home/ian/game.pgn',
    );
    final last = DiagnosticsLog.entries.last['m'] as String;
    expect(last, isNot(contains('rnbqkbnr')));
    expect(last, isNot(contains('/home/ian')));
  });

  test(
    'snapshot contains version, counts and settings but no personal data',
    () async {
      final db = AppDatabase.memory();
      final repo = Repository(db);
      await db.execute(
        "INSERT INTO games(id,title,source,root_fen,created,updated) VALUES('g1','My secret opening study','study','8/8/8/8/8/8/8/8 w - - 0 1',1,1)",
      );
      final text = await buildSnapshot(repo);
      expect(text, contains('version: 1.2.3'));
      expect(text, contains('build: 45'));
      expect(text, contains('version code: 45'));
      expect(text, contains('games: 1'));
      expect(text, contains('crash reports: on'));
      expect(text, contains('signed in: false'));
      expect(text, isNot(contains('secret')));
      expect(text, isNot(contains('8/8/8/8/8/8/8/8')));
      expect(text, isNot(contains('@')));
      await db.close();
    },
  );

  testWidgets('diagnostics screen shows the report and share controls', (
    t,
  ) async {
    final db = AppDatabase.memory();
    await t.pumpWidget(host(DiagnosticsScreen(repo: Repository(db))));
    await t.pumpAndSettle();
    expect(find.text('Send to developer'), findsOneWidget);
    expect(find.textContaining('Castlei diagnostics snapshot'), findsOneWidget);
    expect(
      find.textContaining('Nothing is sent unless you tap Send to developer or share it'),
      findsOneWidget,
    );
    expect(find.text('Send a test crash report'), findsNothing);
    await t.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets(
    'open-source screen lists components, packages and never says Powered by Flutter',
    (t) async {
      LicenseRegistry.addLicense(
        () => Stream.value(
          const LicenseEntryWithLineBreaks([
            'zzz_test_package',
          ], 'Test license text'),
        ),
      );
      await t.pumpWidget(host(const OpenSourceScreen()));
      await t.pumpAndSettle();
      expect(find.text('Open-source software'), findsOneWidget);
      expect(find.text('Stockfish'), findsOneWidget);
      expect(find.text('GPL-3.0-or-later'), findsOneWidget);
      expect(find.textContaining('Powered by Flutter'), findsNothing);
      await t.scrollUntilVisible(
        find.text('zzz_test_package'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.text('zzz_test_package'));
      await t.pumpAndSettle();
      expect(find.text('Test license text'), findsOneWidget);
    },
  );

  test('platform channel mock for package info is wired', () async {
    expect((await PackageInfo.fromPlatform()).buildNumber, '45');
    expect(SystemChannels.platform, isNotNull);
  });
}
