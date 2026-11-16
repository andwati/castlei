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

  /// The score from White's side: "+0.35", "-1.20", "+M3" (White mates in 3),
  /// "-M3" (Black mates in 3).
  String label(bool whiteTurn) {
    final white = score * (whiteTurn ? 1 : -1);
    if (mate) return mateText(white);
    return '${white > 0 ? '+' : ''}${(white / 100).toStringAsFixed(2)}';
  }

  Map<String, dynamic> toJson() => {
    'depth': depth,
    'score': score,
    'mate': mate,
    'pv': pv,
    'bounded': bounded,
  };
}

/// A forced mate in [whiteMate] moves, signed for White: "+M3" when White
/// mates, "-M3" when Black does, "#" for checkmate on the board.
String mateText(int whiteMate) =>
    whiteMate == 0 ? '#' : '${whiteMate > 0 ? '+' : '-'}M${whiteMate.abs()}';

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

/// Search threads used when the person has not chosen. The engine caps this to
/// the number of fast cores in the phone, so it is safe on small devices.
const defaultEngineThreads = 4;

/// Hash size in MB that goes with a thread count.
int hashFor(int threads) => threads <= 1 ? 64 : 128;

class EngineClient {
  int threads = defaultEngineThreads, hashMb = hashFor(defaultEngineThreads);
  // Options last sent to the engine: unchanged ones are not sent again, because
  // resizing the hash table for a same-size value costs time on every search.
  final _sent = <String, Object>{};
  void _option(String name, Object value) {
    if (_sent[name] == value) return;
    _sent[name] = value;
    send('setoption name $name value $value');
  }

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
    try {
      await _initialize();
    } catch (_) {
      // Let the next search start the engine again instead of failing for the
      // rest of the session.
      _port?.close();
      _isolate?.kill();
      _commands = null;
      _sent.clear();
      _initialization = null;
      rethrow;
    }
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
    // Listen before the worker starts: a library that fails to load reports
    // "error ..." straight away and nothing more.
    final uci = _messages.stream.firstWhere(
      (s) => s == 'uciok' || s.startsWith('error '),
    );
    // Not reached when the worker never answers; that is reported below.
    uci.ignore();
    _isolate = await Isolate.spawn(_worker, [
      _port!.sendPort,
      Platform.isAndroid
          ? 'libcastlei_engine.so'
          : Platform.isIOS
          ? 'process'
          : '${Directory.current.path}/build/native/libcastlei_engine.so',
    ]);
    _commands = await ready.future.timeout(const Duration(seconds: 15));
    send('uci');
    final answer = await uci.timeout(const Duration(seconds: 20));
    if (answer != 'uciok') throw StateError(answer);
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

    /// False keeps the hash table and history from the previous search, which
    /// speeds up a run of related positions such as a game review.
    bool newGame = true,
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
        if (newGame) send('ucinewgame');
        _option('Threads', threads);
        _option('Hash', hashMb);
        _option('Skill Level', skill);
        _option('MultiPV', multiPv);
        await barrier();
        if (generation != _generation) throw SearchCanceled();
        send(
          'position fen $fen${moves.isEmpty ? '' : ' moves ${moves.join(' ')}'}',
        );
        final searchTimer = Stopwatch()..start();
        send(
          'go movetime $milliseconds${onlyMove == null ? '' : ' searchmoves $onlyMove'}',
        );
        final String best;
        try {
          best = await done.future.timeout(
            Duration(milliseconds: milliseconds + 15000),
          );
        } on TimeoutException {
          // Stop the search and wait for its `bestmove`, so that a late one is
          // not read as the answer to the next search.
          send('stop');
          await done.future
              .timeout(const Duration(seconds: 5))
              .then<void>((_) {}, onError: (_) {});
          rethrow;
        }
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
  String graded(int lost) => lost <= 0
      ? 'Forced mate'
      : lost <= 2
      ? 'Good'
      : 'Inaccuracy';
  if (played.mate && played.score > 0) {
    if (!best.mate || best.score < 0) return 'Forced mate';
    // Both lines mate: grade the moves given away. [best] counts from before
    // the move. [played] comes from the search of the position after it, where
    // the mate is one move closer, unless the move itself was checkmate
    // (depth 0, stored as mate in 1).
    final delivered = played.depth == 0 && played.score == 1;
    return graded(played.score + (delivered ? 0 : 1) - best.score);
  }
  if (best.mate && best.score < 0) {
    // Lost whatever is played. A move that holds out as long as the best one
    // is as good as it gets; one that is mated sooner gives moves away.
    return played.mate ? graded(played.score - best.score) : 'Good';
  }
  final loss = best.score - played.score;
  return loss >= 200
      ? 'Blunder'
      : loss >= 100
      ? 'Mistake'
      : loss >= 50
      ? 'Inaccuracy'
      : 'Good';
}
