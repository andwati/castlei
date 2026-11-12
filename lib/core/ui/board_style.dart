import 'package:flutter/material.dart';

import '../storage/repository.dart';

/// A pair of square colours for the board.
class BoardPalette {
  const BoardPalette(this.id, this.name, this.light, this.dark);
  final String id, name;
  final Color light, dark;
}

/// The board's look and helpers, shared by every board in the app. Changed
/// on the Board settings page and read when a board is built.
class BoardStyle {
  static const palettes = [
    BoardPalette('pine', 'Pine', Color(0xffeee6d2), Color(0xff7b9a8b)),
    BoardPalette('walnut', 'Walnut', Color(0xfff0d9b5), Color(0xffb58863)),
    BoardPalette('slate', 'Slate', Color(0xffdee3e6), Color(0xff8ca2ad)),
    BoardPalette('plum', 'Plum', Color(0xffefe6f0), Color(0xff9b7fa6)),
    BoardPalette('sand', 'Sand', Color(0xfff6ecd0), Color(0xffc9a96b)),
    BoardPalette('ink', 'Ink', Color(0xffc9ced6), Color(0xff4a5568)),
  ];

  static String palette = 'pine';
  static bool legalMoves = true, highlightLast = true;

  /// Slightly larger pieces, and stronger piece contrast.
  static bool magnify = false, contrast = false;

  /// Castle by moving the king two squares (otherwise onto the rook), and
  /// promote to a queen without asking. Moves are shown as piece letters
  /// unless [figurine] is on.
  static bool castleTwoSquares = true, autoQueen = false, figurine = false;

  /// Analysis helpers.
  static bool evalBar = true, suggestionArrow = true, threatArrow = false;

  /// Bumped on every change so open boards can repaint.
  static final changes = ValueNotifier<int>(0);

  static BoardPalette get current =>
      palettes.firstWhere((p) => p.id == palette, orElse: () => palettes.first);

  static Future<void> load(Repository repo) async {
    palette = await repo.preference('boardPalette', 'pine') as String;
    legalMoves = await repo.preference('legalMoves', true) as bool;
    highlightLast = await repo.preference('highlightLast', true) as bool;
    magnify = await repo.preference('magnifyPieces', false) as bool;
    contrast = await repo.preference('pieceContrast', false) as bool;
    castleTwoSquares = await repo.preference('castleTwo', true) as bool;
    autoQueen = await repo.preference('autoQueen', false) as bool;
    figurine = await repo.preference('figurine', false) as bool;
    evalBar = await repo.preference('evalBar', true) as bool;
    suggestionArrow = await repo.preference('suggestionArrow', true) as bool;
    threatArrow = await repo.preference('threatArrow', false) as bool;
    changes.value++;
  }

  static Future<void> save(
    Repository repo, {
    String? palette,
    bool? legalMoves,
    bool? highlightLast,
    bool? magnify,
    bool? contrast,
    bool? castleTwoSquares,
    bool? autoQueen,
    bool? figurine,
    bool? evalBar,
    bool? suggestionArrow,
    bool? threatArrow,
  }) async {
    if (palette != null) {
      BoardStyle.palette = palette;
      await repo.setPreference('boardPalette', palette);
    }
    if (legalMoves != null) {
      BoardStyle.legalMoves = legalMoves;
      await repo.setPreference('legalMoves', legalMoves);
    }
    if (highlightLast != null) {
      BoardStyle.highlightLast = highlightLast;
      await repo.setPreference('highlightLast', highlightLast);
    }
    if (magnify != null) {
      BoardStyle.magnify = magnify;
      await repo.setPreference('magnifyPieces', magnify);
    }
    if (contrast != null) {
      BoardStyle.contrast = contrast;
      await repo.setPreference('pieceContrast', contrast);
    }
    Future<void> flag(String key, bool? v, void Function(bool) apply) async {
      if (v == null) return;
      apply(v);
      await repo.setPreference(key, v);
    }

    await flag(
      'castleTwo',
      castleTwoSquares,
      (v) => BoardStyle.castleTwoSquares = v,
    );
    await flag('autoQueen', autoQueen, (v) => BoardStyle.autoQueen = v);
    await flag('figurine', figurine, (v) => BoardStyle.figurine = v);
    await flag('evalBar', evalBar, (v) => BoardStyle.evalBar = v);
    await flag(
      'suggestionArrow',
      suggestionArrow,
      (v) => BoardStyle.suggestionArrow = v,
    );
    await flag('threatArrow', threatArrow, (v) => BoardStyle.threatArrow = v);
    changes.value++;
  }

  /// "Nf3" as "♘f3" when figurine notation is on.
  static String san(String san) {
    if (!figurine || san.isEmpty) return san;
    const glyphs = {'K': '♔', 'Q': '♕', 'R': '♖', 'B': '♗', 'N': '♘'};
    final g = glyphs[san[0]];
    return g == null ? san : '$g${san.substring(1)}';
  }
}
