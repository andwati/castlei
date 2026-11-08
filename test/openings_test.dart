import 'package:castlei/core/chess/model.dart';
import 'package:castlei/core/chess/openings.dart';
import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('names openings by position, including transpositions', () async {
    await Openings.load();
    final italian = ChessGame.importPgn(
      PgnGame.parsePgn('1. e4 e5 2. Nf3 Nc6 3. Bc4 *'),
    );
    final a = Openings.forLine(italian, italian.mainline.last.id)!;
    expect(a.$2, contains('Italian'));
    // The same position reached by a different move order gets the same name.
    final transposed = ChessGame.importPgn(
      PgnGame.parsePgn('1. Nf3 Nc6 2. e4 e5 3. Bc4 *'),
    );
    expect(Openings.forLine(transposed, transposed.mainline.last.id)!.$2, a.$2);
    // Past book, the deepest known opening is still reported.
    final deep = ChessGame.importPgn(
      PgnGame.parsePgn(
        '1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. d3 h6 5. a3 a6 6. h3 *',
      ),
    );
    expect(Openings.forLine(deep, deep.mainline.last.id), isNotNull);
    // A start position has no opening.
    final empty = ChessGame.importPgn(PgnGame.parsePgn('*'));
    expect(Openings.forLine(empty, null), isNull);
  });
}
