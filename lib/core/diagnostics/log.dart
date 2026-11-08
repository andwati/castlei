import 'dart:async';
import 'dart:convert';

import '../storage/repository.dart';
import 'crash.dart' show scrub;

/// A bounded, local-only log of scrubbed diagnostic events (screens visited,
/// handled errors). It never leaves the device unless the user shares the
/// diagnostics snapshot. Messages never contain positions, names or paths.
class DiagnosticsLog {
  static const capacity = 60;
  static final List<Map<String, Object>> _entries = [];
  static Repository? _repo;
  static Timer? _save;

  static List<Map<String, Object>> get entries => List.unmodifiable(_entries);

  static Future<void> attach(Repository repo) async {
    _repo = repo;
    try {
      final saved = await repo.preference('diagLog', <dynamic>[]) as List;
      _entries
        ..clear()
        ..addAll(
          saved.whereType<Map>().map(
            (e) => {'t': e['t'] as int, 'k': '${e['k']}', 'm': '${e['m']}'},
          ),
        );
    } catch (_) {}
  }

  static void add(String kind, String message) {
    _entries.add({
      't': DateTime.now().millisecondsSinceEpoch,
      'k': kind,
      'm': scrub(message),
    });
    while (_entries.length > capacity) {
      _entries.removeAt(0);
    }
    // Nothing to persist to (e.g. in widget tests) means no timer either.
    if (_repo == null) return;
    _save?.cancel();
    _save = Timer(const Duration(seconds: 3), _persist);
  }

  static Future<void> _persist() async {
    try {
      await _repo?.setPreference('diagLog', jsonDecode(jsonEncode(_entries)));
    } catch (_) {}
  }

  static Future<void> clear() async {
    _entries.clear();
    await _persist();
  }
}
