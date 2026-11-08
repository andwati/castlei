import 'package:castlei/core/engine/engine.dart';

import 'dart:io';

Future<void> main() async {
  final e = EngineClient();
  try {
    await e.initialize();
    final result = await e.search(
      fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      milliseconds: 150,
    );
    if (result.bestmove.length < 4 || result.lines.isEmpty) {
      throw StateError('No result');
    }
    final interrupted = e
        .search(
          fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          milliseconds: 10000,
        )
        .then<void>(
          (_) => throw StateError('Expected cancellation'),
          onError: (Object error) {
            if (error is! SearchCanceled) throw error;
          },
        );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    e.cancel();
    await interrupted;
    final next = await e.search(
      fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
      moves: ['e1g1'],
      milliseconds: 100,
    );
    if (next.bestmove.length < 4) throw StateError('Castling failed');
    stdout.writeln(
      'Dart isolate UCI handshake, search, cancellation, and castling passed',
    );
  } finally {
    await e.dispose();
  }
}
