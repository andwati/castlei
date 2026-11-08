import 'dart:isolate';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../storage/repository.dart';

const appVersion = '1.0.0+1';
const engineVersion = 'stockfish-18';

/// An error stripped of anything that could expose chess content or files.
class SanitizedError implements Exception {
  SanitizedError(Object original)
    : type = original.runtimeType.toString(),
      message = scrub('$original');
  final String type, message;
  @override
  String toString() => '$type: $message';
}

final _fen = RegExp(
  r'[prnbqkPRNBQK1-8]+(?:/[prnbqkPRNBQK1-8]+){3,}(?:\s+[wb]\s+\S+\s+\S+(?:\s+\d+\s+\d+)?)?',
);
final _path = RegExp(r'(?:[A-Za-z]:)?(?:/[^\s/:]+){2,}');
final _pgnHeader = RegExp(r'\[[A-Za-z]+\s+"[^"]*"\]');

/// Removes FEN strings, PGN headers and file paths and bounds the length.
String scrub(String text) {
  var out = text
      .replaceAll(_pgnHeader, '<pgn>')
      .replaceAll(_fen, '<fen>')
      .replaceAll(_path, '<path>')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (out.length > 160) out = '${out.substring(0, 160)}…';
  return out;
}

/// Crash reporting (Firebase Crashlytics). On by default, user-controllable,
/// never required: the app starts and works offline without Firebase.
class CrashReporting {
  static bool available = false;
  static bool enabled = false;

  static Future<void> start(Repository repo) async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10));
      available = true;
      await applyPreference(repo);
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCustomKey('app_version', appVersion);
      await crashlytics.setCustomKey('engine', engineVersion);
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        if (enabled) {
          crashlytics.recordError(
            SanitizedError(details.exception),
            details.stack,
            reason: 'flutter',
            fatal: true,
          );
        }
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        if (enabled) {
          crashlytics.recordError(
            SanitizedError(error),
            stack,
            reason: 'platform',
            fatal: true,
          );
        }
        return true;
      };
      Isolate.current.addErrorListener(
        RawReceivePort((pair) {
          final list = pair as List;
          if (enabled) {
            crashlytics.recordError(
              SanitizedError(list.first),
              StackTrace.fromString('${list.last}'),
              reason: 'isolate',
              fatal: true,
            );
          }
        }).sendPort,
      );
    } catch (e) {
      available = false;
      enabled = false;
      debugPrint('Crash reporting unavailable: ${scrub('$e')}');
    }
  }

  /// Reads the saved preference (default: on) and applies it.
  static Future<void> applyPreference(Repository repo) async =>
      setEnabled(await repo.preference('crashReports', true) as bool);

  static Future<void> setEnabled(bool value) async {
    // Debug runs never report, so development noise stays out of the console.
    enabled = available && value && !kDebugMode;
    if (available) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        enabled,
      );
    }
  }

  /// Records a handled problem with only an error category.
  static Future<void> nonFatal(
    String feature,
    Object error,
    StackTrace stack,
  ) async {
    if (!enabled) return;
    await FirebaseCrashlytics.instance.recordError(
      SanitizedError(error),
      stack,
      reason: feature,
    );
  }

  /// Sends a harmless test report so you can confirm delivery in the console.
  static Future<bool> sendTest() async {
    if (!available) return false;
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(true);
    await crashlytics.recordError(
      StateError('Castlei test report'),
      StackTrace.current,
      reason: 'manual-test',
    );
    await crashlytics.sendUnsentReports();
    await crashlytics.setCrashlyticsCollectionEnabled(enabled);
    return true;
  }
}
