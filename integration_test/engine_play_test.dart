import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:castlei/main.dart' as app;

Future<void> waitFor(WidgetTester t, Finder f, {int seconds = 20}) async {
  for (var i = 0; i < seconds * 5; i++) {
    await t.pump(const Duration(milliseconds: 200));
    if (f.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $f');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('play a move and receive a legal engine reply', (t) async {
    await app.main();
    await t.pumpAndSettle();
    await t.tap(find.text('Play').last);
    await t.pumpAndSettle();
    await t.tap(find.text('New engine game'));
    await t.pumpAndSettle();
    await t.tap(find.text('Create'));
    await waitFor(t, find.bySemanticsLabel(RegExp('^e2, white pawn')));
    if (find.text('Resume').evaluate().isNotEmpty) {
      await t.tap(find.text('Resume'));
      await t.pump(const Duration(milliseconds: 500));
    }
    await t.tap(find.bySemanticsLabel(RegExp('^e2, white pawn')));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.bySemanticsLabel(RegExp('^e4, empty')));
    // Engine must answer: some black pawn/knight leaves its home square.
    final replied = find.bySemanticsLabel(
      RegExp(r'^(a|b|c|d|e|f|g|h)(7|8), empty'),
    );
    await waitFor(t, replied, seconds: 15);
    expect(t.takeException(), isNull);
  });
}
