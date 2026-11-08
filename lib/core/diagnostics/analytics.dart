import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';

import '../storage/repository.dart';
import 'crash.dart' show scrub;

/// Anonymous usage analytics (Firebase Analytics). On by default, switchable in
/// Settings. Events carry only coarse categories and counts — never positions,
/// moves, comments, titles, names or file contents.
class Analytics {
  static bool available = false;
  static bool enabled = false;

  static Future<void> start(Repository repo) async {
    try {
      available = true;
      await applyPreference(repo);
    } catch (e) {
      available = false;
      enabled = false;
      debugPrint('Analytics unavailable: ${scrub('$e')}');
    }
  }

  static Future<void> applyPreference(Repository repo) async =>
      setEnabled(await repo.preference('analytics', true) as bool);

  static Future<void> setEnabled(bool value) async {
    enabled = available && value && !kDebugMode;
    if (!available) return;
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    // In-app messages are targeted using analytics, so they follow the same switch.
    await FirebaseInAppMessaging.instance.setAutomaticDataCollectionEnabled(
      enabled,
    );
  }

  /// Logs an event. Parameter values must be short categories or numbers.
  static void log(String name, [Map<String, Object> params = const {}]) {
    if (!enabled) return;
    final clean = <String, Object>{
      for (final e in params.entries)
        e.key: e.value is String
            ? (e.value as String).substring(
                0,
                (e.value as String).length.clamp(0, 40),
              )
            : e.value,
    };
    FirebaseAnalytics.instance
        .logEvent(name: name, parameters: clean)
        .catchError((_) {});
  }

  static void screen(String name) {
    if (!enabled) return;
    FirebaseAnalytics.instance
        .logScreenView(screenName: name, screenClass: name)
        .catchError((_) {});
  }

  /// Buckets a count so exact values are not reported.
  static String bucket(int n) => n <= 0
      ? '0'
      : n <= 5
      ? '1-5'
      : n <= 20
      ? '6-20'
      : n <= 100
      ? '21-100'
      : '100+';

  /// Pauses in-app messages (e.g. during a game).
  static Future<void> suppressMessages(bool value) async {
    if (!available) return;
    try {
      await FirebaseInAppMessaging.instance.setMessagesSuppressed(value);
    } catch (_) {}
  }
}
