import 'dart:async';

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../diagnostics/perf.dart';

class EngineLine {
  const EngineLine({
    required this.depth,
    required this.score,
    required this.mate,
    required this.pv,
    this.index = 1,
    this.bounded = false,
    this.nodes = 0,
    this.nps = 0,
  });
  final int depth, score, index, nodes, nps;
  final bool mate, bounded;
  final List<String> pv;
  static EngineLine? parse(String s) {
    final score = RegExp(r'score (cp|mate) (-?\d+)').firstMatch(s);
    if (score == null) return null;
    int value(String key, int fallback) =>
        int.tryParse(RegExp('$key (\\d+)').firstMatch(s)?.group(1) ?? '') ??
        fallback;
    return EngineLine(
      depth: value('depth', 0),
      score: int.parse(score.group(2)!),
      mate: score.group(1) == 'mate',
      index: value('multipv', 1),
      bounded: s.contains('bound'),
      nodes: value('nodes', 0),
      nps: value(
        'nps',
        value('time', 0) > 0 ? value('nodes', 0) * 1000 ~/ value('time', 0) : 0,
      ),
      pv: s.contains(' pv ') ? s.split(' pv ').last.trim().split(' ') : [],
    );
  }

  String label(bool whiteTurn) => mate
      ? 'M${score * (whiteTurn ? 1 : -1)}'
      : (score * (whiteTurn ? 1 : -1) / 100).toStringAsFixed(2);
  Map<String, dynamic> toJson() => {
    'depth': depth,
    'score': score,
    'mate': mate,
    'pv': pv,
    'bounded': bounded,
  };
}

/// Records [line] as the current answer for its variation and returns the line
/// now held. A bound line (`lowerbound`/`upperbound`) is what the engine prints
/// while it re-searches after a surprise, so when the clock stops a search the
/// last line received is often one. It must not replace an exact score for the
/// same variation, or nearly every reviewed move would read as uncertain.
EngineLine mergeLine(Map<int, EngineLine> lines, EngineLine line) {
  final previous = lines[line.index];
  if (line.bounded && previous != null && !previous.bounded) return previous;
  lines[line.index] = line;
  return line;
}

class SearchResult {
  SearchResult(this.bestmove, this.lines);
  final String bestmove;
  final List<EngineLine> lines;
}

class SearchCanceled implements Exception {}

class EngineClient {
  int threads = 1, hashMb = 64;
  SendPort? _commands;
  Isolate? _isolate;
  ReceivePort? _port;
  final _messages = StreamController<String>.broadcast();
  Future<void>? _initialization;
  Future<void> _tail = Future.value();
  int _generation = 0;
  bool _disposed = false;
  Future<void> initialize() => _initialization ??= () async {
    final sw = Stopwatch()..start();
    await _initialize();
    Perf.record('engine_init', metrics: {'ms': sw.elapsedMilliseconds});
  }();
  Future<void> _initialize() async {
    final ready = Completer<SendPort>();
    _port = ReceivePort();
    _port!.listen((m) {
      if (m is SendPort) {
        ready.complete(m);
      } else if (m is String) {
        _messages.add(m);
      }
    });
    _isolate = await Isolate.spawn(_worker, [
      _port!.sendPort,
      Platform.isAndroid
          ? 'libcastlei_engine.so'
          : Platform.isIOS
          ? 'process'
          : '${Directory.current.path}/build/native/libcastlei_engine.so',
    ]);
    _commands = await ready.future.timeout(const Duration(seconds: 15));
    final uci = _messages.stream.firstWhere((s) => s == 'uciok');
    send('uci');
    await uci.timeout(const Duration(seconds: 20));
    send('setoption name Threads value 1');
    send('setoption name Hash value 64');
    await barrier();
  }

  void send(String cmd) => _commands?.send(cmd);
  Future<void> barrier() async {
    final ready = _messages.stream.firstWhere((s) => s == 'readyok');
    send('isready');
    await ready.timeout(const Duration(seconds: 15));
  }

  void cancel() {
    _generation++;
    send('stop');
  }

  Future<SearchResult> search({
    required String fen,
    List<String> moves = const [],
    int milliseconds = 3000,
    int skill = 20,
    int multiPv = 1,
    String? onlyMove,
    void Function(EngineLine)? onLine,
  }) {
    final generation = _generation;
    final result = Completer<SearchResult>();
    _tail = _tail.catchError((_) {}).then((_) async {
      StreamSubscription<String>? sub;
      try {
        await initialize();
        if (generation != _generation || _disposed) throw SearchCanceled();
        final done = Completer<String>();
        final lines = <int, EngineLine>{};
        sub = _messages.stream.listen((s) {
          if (s.startsWith('error ')) {
            if (!done.isCompleted) done.completeError(StateError(s));
          } else if (s.startsWith('bestmove ')) {
            if (!done.isCompleted) done.complete(s.split(' ')[1]);
          } else {
            final line = EngineLine.parse(s);
            if (line != null) {
              final kept = mergeLine(lines, line);
              if (generation == _generation) onLine?.call(kept);
            }
          }
        });
        send('ucinewgame');
        send('setoption name Threads value $threads');
        send('setoption name Hash value $hashMb');
        send('setoption name Skill Level value $skill');
        send('setoption name MultiPV value $multiPv');
        await barrier();
        if (generation != _generation) throw SearchCanceled();
        send(
          'position fen $fen${moves.isEmpty ? '' : ' moves ${moves.join(' ')}'}',
        );
        final searchTimer = Stopwatch()..start();
        send(
          'go movetime $milliseconds${onlyMove == null ? '' : ' searchmoves $onlyMove'}',
        );
        final best = await done.future.timeout(
          Duration(milliseconds: milliseconds + 15000),
        );
        Perf.record(
          'engine_search',
          attributes: {
            'budget': milliseconds <= 1000
                ? 'le1s'
                : milliseconds <= 3000
                ? 'le3s'
                : 'gt3s',
            'lines': '$multiPv',
          },
          metrics: {
            'requested_ms': milliseconds,
            'actual_ms': searchTimer.elapsedMilliseconds,
            'overhead_ms': searchTimer.elapsedMilliseconds - milliseconds,
            'depth': lines.values.fold<int>(
              0,
              (m, l) => l.depth > m ? l.depth : m,
            ),
            'knps':
                lines.values.fold<int>(0, (m, l) => l.nps > m ? l.nps : m) ~/
                1000,
          },
        );
        if (generation != _generation) throw SearchCanceled();
        final sorted = lines.values.toList()
          ..sort((a, b) => a.index.compareTo(b.index));
        result.complete(SearchResult(best, sorted));
      } catch (e, st) {
        send('stop');
        result.completeError(e, st);
      } finally {
        await sub?.cancel();
      }
    });
    return result.future;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    cancel();
    await _tail;
    _commands?.send('dispose');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _port?.close();
    await _messages.close();
    _isolate?.kill();
  }
}

/// iOS: the engine pod is linked into the app. Look it up in the running
/// process first, then fall back to the dynamic framework CocoaPods builds.
DynamicLibrary _openIosLibrary() {
  final process = DynamicLibrary.process();
  if (process.providesSymbol('castlei_create')) return process;
  return DynamicLibrary.open('castlei_native.framework/castlei_native');
}

void _worker(List<Object> args) {
  final output = args[0] as SendPort;
  final path = args[1] as String;
  final input = ReceivePort();
  output.send(input.sendPort);
  try {
    final lib = path == 'process'
        ? _openIosLibrary()
        : DynamicLibrary.open(path);
    final create = lib
        .lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>(
          'castlei_create',
        );
    final send = lib
        .lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Utf8>),
          int Function(Pointer<Void>, Pointer<Utf8>)
        >('castlei_send');
    final poll = lib
        .lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32),
          int Function(Pointer<Void>, Pointer<Utf8>, int)
        >('castlei_poll');
    final dispose = lib
        .lookupFunction<
          Void Function(Pointer<Void>),
          void Function(Pointer<Void>)
        >('castlei_dispose');
    final handle = create();
    if (handle == nullptr) throw StateError('Engine allocation failed');
    final buffer = calloc<Uint8>(65536).cast<Utf8>();
    final timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      for (var i = 0; i < 128; i++) {
        final n = poll(handle, buffer, 65536);
        if (n <= 0) break;
        output.send(buffer.toDartString());
      }
    });
    input.listen((m) {
      if (m == 'dispose') {
        timer.cancel();
        dispose(handle);
        calloc.free(buffer);
        input.close();
        return;
      }
      final c = (m as String).toNativeUtf8();
      try {
        send(handle, c);
      } finally {
        calloc.free(c);
      }
    });
  } catch (e) {
    output.send('error $e');
    input.close();
  }
}

String classify(EngineLine best, EngineLine played, {bool sameMove = false}) {
  if (sameMove) return 'Engine best';
  if (best.bounded || played.bounded) return 'Uncertain';
  if (best.mate && best.score > 0 && (!played.mate || played.score <= 0)) {
    return 'Missed Forced Mate';
  }
  if (played.mate && played.score < 0 && (!best.mate || best.score >= 0)) {
    return 'Allowed Forced Mate';
  }
  if (best.mate || played.mate) return 'Forced mate';
  final loss = best.score - played.score;
  return loss >= 200
      ? 'Blunder'
      : loss >= 100
      ? 'Mistake'
      : loss >= 50
      ? 'Inaccuracy'
      : 'Good';
}
