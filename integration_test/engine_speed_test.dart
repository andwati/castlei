import 'package:castlei/core/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Measures raw engine speed (kilo-nodes/second) on the device.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('engine speed benchmark', (t) async {
    final engine = EngineClient();
    final speeds = <int>[];
    var depth = 0;
    const fens = [
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      'r1bq1rk1/pp2bppp/2n1pn2/2pp4/3P1B2/2PBPN2/PP1N1PPP/R2QK2R w KQ - 0 8',
      '8/5pk1/6p1/8/3R4/6P1/5PK1/3r4 w - - 0 1',
    ];
    for (final fen in fens) {
      final result = await t.runAsync(
        () => engine.search(fen: fen, milliseconds: 3000),
      );
      final best = result!.lines.last;
      speeds.add(best.nps ~/ 1000);
      depth += best.depth;
    }
    // ignore: avoid_print
    print(
      'ENGINE SPEED knps=$speeds avg=${speeds.reduce((a, b) => a + b) ~/ speeds.length} avgDepth=${depth ~/ fens.length}',
    );
    await engine.dispose();
    expect(speeds.every((s) => s > 0), isTrue);
  });
}
