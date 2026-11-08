import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../storage/repository.dart';
import 'crash.dart' show scrub;

/// Performance monitoring (Firebase Performance). On by default, switchable in
/// Settings, never required. Traces carry only names, durations, counts and
/// coarse categories — never positions, moves, comments, names or files.
class Perf {
  static bool available = false;
  static bool enabled = false;
  static final _frames = _FrameStats();

  /// Call after Firebase is initialized.
  static Future<void> start(Repository repo) async {
    try {
      available = true;
      await applyPreference(repo);
      SchedulerBinding.instance.addTimingsCallback(_frames.add);
      WidgetsBinding.instance.addObserver(_Lifecycle());
    } catch (e) {
      available = false;
      enabled = false;
      debugPrint('Performance monitoring unavailable: ${scrub('$e')}');
    }
  }

  static Future<void> applyPreference(Repository repo) async =>
      setEnabled(await repo.preference('perfMonitoring', true) as bool);

  static Future<void> setEnabled(bool value) async {
    // Debug runs are not representative, so they never report.
    enabled = available && value && !kDebugMode;
    if (available) {
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(
        enabled,
      );
    }
  }

  /// Times [action] as a custom trace. [attributes] must be coarse categories.
  static Future<T> trace<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String> attributes = const {},
    Map<String, int> Function(T result)? metrics,
  }) async {
    if (!enabled) return action();
    Trace? t;
    try {
      t = FirebasePerformance.instance.newTrace(name);
      for (final e in attributes.entries) {
        t.putAttribute(e.key, e.value);
      }
      await t.start();
    } catch (_) {
      t = null;
    }
    try {
      final result = await action();
      if (t != null && metrics != null) {
        for (final e in metrics(result).entries) {
          t.setMetric(e.key, e.value);
        }
      }
      return result;
    } catch (e) {
      t?.putAttribute('outcome', 'error');
      rethrow;
    } finally {
      try {
        await t?.stop();
      } catch (_) {}
    }
  }

  /// Wraps a network call in an HTTP metric (status, size, duration).
  /// [call] returns the HTTP status code and payload size in bytes.
  static Future<T> http<T>(
    String url,
    Future<T> Function(void Function(int status, int bytes) report) call,
  ) async {
    if (!enabled) return call((_, _) {});
    HttpMetric? metric;
    try {
      metric = FirebasePerformance.instance.newHttpMetric(url, HttpMethod.Get);
      await metric.start();
    } catch (_) {
      metric = null;
    }
    try {
      return await call((status, bytes) {
        metric
          ?..httpResponseCode = status
          ..responsePayloadSize = bytes;
      });
    } finally {
      try {
        await metric?.stop();
      } catch (_) {}
    }
  }

  /// Records a finished measurement as a trace with numeric metrics only.
  static Future<void> record(
    String name, {
    Map<String, int> metrics = const {},
    Map<String, String> attributes = const {},
  }) async {
    if (!enabled) return;
    try {
      final t = FirebasePerformance.instance.newTrace(name);
      for (final e in attributes.entries) {
        t.putAttribute(e.key, e.value);
      }
      await t.start();
      for (final e in metrics.entries) {
        t.setMetric(e.key, e.value);
      }
      await t.stop();
    } catch (_) {}
  }

  static Future<void> _flushFrames() async {
    if (!enabled || _frames.total == 0) return;
    final snapshot = _frames.take();
    try {
      final t = FirebasePerformance.instance.newTrace('frames');
      await t.start();
      t.setMetric('total', snapshot.total);
      t.setMetric('slow', snapshot.slow);
      t.setMetric('frozen', snapshot.frozen);
      await t.stop();
    } catch (_) {}
  }
}

class _Lifecycle with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) Perf._flushFrames();
  }
}

/// Counts frames whose total time exceeded the slow (>16 ms) and frozen
/// (>700 ms) thresholds Firebase uses for its own screen-rendering metrics.
class _FrameStats {
  int total = 0, slow = 0, frozen = 0;
  void add(List<FrameTiming> timings) {
    for (final t in timings) {
      total++;
      final ms = t.totalSpan.inMilliseconds;
      if (ms > 700) {
        frozen++;
      } else if (ms > 16) {
        slow++;
      }
    }
  }

  ({int total, int slow, int frozen}) take() {
    final out = (total: total, slow: slow, frozen: frozen);
    total = slow = frozen = 0;
    return out;
  }
}
