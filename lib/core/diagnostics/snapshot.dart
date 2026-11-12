import '../engine/engine.dart';

import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import '../app_info.dart';
import '../cloud/account.dart';
import '../cloud/remote_config.dart';
import '../notifications/notifications.dart';
import '../storage/repository.dart';
import 'analytics.dart';
import 'crash.dart';
import 'log.dart';
import 'perf.dart';

/// Formats the sections into the human-readable report the user reviews and
/// shares. Pure, so it is easy to test.
String formatSnapshot(
  Map<String, Map<String, Object?>> sections,
  List<Map<String, Object>> events,
) {
  final b = StringBuffer('Castlei diagnostics snapshot\n');
  for (final s in sections.entries) {
    b.writeln('\n[${s.key}]');
    for (final e in s.value.entries) {
      b.writeln('${e.key}: ${e.value}');
    }
  }
  b.writeln('\n[recent events (${events.length})]');
  if (events.isEmpty) b.writeln('none');
  for (final e in events) {
    final t = DateTime.fromMillisecondsSinceEpoch(e['t'] as int)
        .toUtc()
        .toIso8601String();
    b.writeln('$t ${e['k']} ${e['m']}');
  }
  return b.toString();
}

String onOff(Object? v) => v == true ? 'on' : 'off';

/// Collects a snapshot of what Castlei knows and collects on this device.
/// It contains counts, versions and settings — never positions, moves,
/// comments, game titles, names, e-mail addresses or file names.
Future<String> buildSnapshot(Repository repo) async {
  final info = await PackageInfo.fromPlatform();
  Future<int> count(String sql) async =>
      (await repo.db.rows(sql)).first.values.first as int;
  Future<Object?> pref(String key, Object fallback) =>
      repo.preference(key, fallback);

  final bySource = {
    for (final r in await repo.db.rows(
      'SELECT source, COUNT(*) AS c FROM games GROUP BY source',
    ))
      r['source']: r['c'],
  };
  final attempts = {
    for (final r in await repo.db.rows(
      'SELECT kind, COUNT(*) AS c FROM attempts GROUP BY kind',
    ))
      r['kind']: r['c'],
  };
  final packs = (await repo.db.rows('SELECT id FROM packs'))
      .map((r) => r['id'])
      .toList();
  final lastBackup = await pref('lastCloudBackup', 0) as int;
  final notifications = await Notifications.permissionGranted();

  return formatSnapshot({
    'app': {
      'version': info.version,
      'build': displayBuild(info.buildNumber),
      'version code': info.buildNumber,
      'engine': engineVersion,
      'mode': const bool.fromEnvironment('dart.vm.product')
          ? 'release'
          : 'debug',
      'generated (UTC)': DateTime.now().toUtc().toIso8601String(),
    },
    'device': {
      'platform': Platform.operatingSystem,
      'os version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
    },
    'account': {
      'signed in': AccountService.instance.signedIn,
      'cloud backup': onOff(await pref('cloudBackup', true)),
      'last cloud backup': lastBackup == 0
          ? 'never'
          : DateTime.fromMillisecondsSinceEpoch(lastBackup)
                .toUtc()
                .toIso8601String(),
    },
    'what is collected (switches)': {
      'crash reports':
          '${onOff(await pref('crashReports', true))} (available: ${CrashReporting.available})',
      'performance monitoring':
          '${onOff(await pref('perfMonitoring', true))} (available: ${Perf.available})',
      'usage analytics':
          '${onOff(await pref('analytics', true))} (available: ${Analytics.available})',
      'announcements (push)': onOff(await pref('announcements', true)),
    },
    'reminders': {
      'permission granted': notifications,
      'due drills': onOff(await pref('remindDrills', true)),
      'daily puzzle': onOff(await pref('remindPuzzle', true)),
      'unfinished game': onOff(await pref('remindResume', true)),
    },
    'remote config': {
      'available': RemoteSettings.available,
      'engine cap untimed (ms)': RemoteSettings.engineMaxMsUntimed,
      'engine cap timed (ms)': RemoteSettings.engineMaxMsTimed,
    },
    'data on this device (counts only)': {
      'games': bySource.isEmpty
          ? 0
          : bySource.values.fold<int>(0, (a, b) => a + (b as int)),
      'games by source': bySource,
      'analysis rows': await count('SELECT COUNT(*) FROM analysis'),
      'repertoires': await count('SELECT COUNT(*) FROM repertoires'),
      'drill cards': await count('SELECT COUNT(*) FROM cards'),
      'puzzles': await count('SELECT COUNT(*) FROM puzzles'),
      'puzzle packs': packs,
      'training attempts by kind': attempts,
    },
    'engine settings': {
      'threads/hash preset': await pref('resources', defaultEngineThreads),
      'analysis budget (ms)': await pref('analysisMs', 3000),
      'candidate lines': await pref('multiPv', 3),
    },
  }, DiagnosticsLog.entries);
}
