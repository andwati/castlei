import 'package:flutter/material.dart';

/// Castlei design tokens — "Parchment & Pine".
///
/// Warm paper surfaces by day, deep pine by night. Teal leads, coral nudges,
/// brass marks the last move. Fraunces (a soft serif) carries display text;
/// the platform sans stays on body copy for legibility.
@immutable
class CastleiTokens extends ThemeExtension<CastleiTokens> {
  const CastleiTokens({
    required this.boardLight,
    required this.boardDark,
    required this.lastMove,
    required this.selected,
    required this.check,
    required this.hero,
    required this.onHero,
    required this.heroAccent,
    required this.good,
    required this.warn,
    required this.bad,
  });
  final Color boardLight, boardDark, lastMove, selected, check;
  final Color hero, onHero, heroAccent;
  final Color good, warn, bad;

  static const light = CastleiTokens(
    boardLight: Color(0xffeee6d2),
    boardDark: Color(0xff7b9a8b),
    lastMove: Color(0xffe6c565),
    selected: Color(0xffd8664b),
    check: Color(0xffd8433a),
    hero: Color(0xff0f4f49),
    onHero: Color(0xfff6f1e7),
    heroAccent: Color(0xffe98a70),
    good: Color(0xff2f7d4f),
    warn: Color(0xff9a6a00),
    bad: Color(0xffb3352b),
  );
  static const dark = CastleiTokens(
    boardLight: Color(0xffd9d2bf),
    boardDark: Color(0xff5f8274),
    lastMove: Color(0xffd7b24f),
    selected: Color(0xfff2927a),
    check: Color(0xffee5d52),
    hero: Color(0xff14504a),
    onHero: Color(0xffe8efea),
    heroAccent: Color(0xfff2927a),
    good: Color(0xff7fd09b),
    warn: Color(0xffe3b85c),
    bad: Color(0xffff8f84),
  );

  @override
  CastleiTokens copyWith() => this;
  @override
  CastleiTokens lerp(ThemeExtension<CastleiTokens>? other, double t) =>
      t < .5 ? this : (other as CastleiTokens? ?? this);
}

extension CastleiContext on BuildContext {
  CastleiTokens get tokens => Theme.of(this).extension<CastleiTokens>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Spacing and radius scale.
class Space {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32;
}

class Corner {
  static const double sm = 12, md = 18, lg = 28;
}

TextStyle _display(double size, {double h = 1.1, int weight = 600}) =>
    TextStyle(
      fontFamily: 'Fraunces',
      fontSize: size,
      height: h,
      fontVariations: [
        FontVariation('wght', weight.toDouble()),
        const FontVariation('SOFT', 100),
        FontVariation('opsz', size.clamp(9, 144).toDouble()),
      ],
    );

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = dark
      ? const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xff7fd1c4),
          onPrimary: Color(0xff00352f),
          primaryContainer: Color(0xff14504a),
          onPrimaryContainer: Color(0xffbdeee6),
          secondary: Color(0xfff2927a),
          onSecondary: Color(0xff4a1708),
          secondaryContainer: Color(0xff6a2e1e),
          onSecondaryContainer: Color(0xffffdbd1),
          tertiary: Color(0xffe3b85c),
          onTertiary: Color(0xff3e2e00),
          error: Color(0xffff8f84),
          onError: Color(0xff561009),
          surface: Color(0xff0f1a18),
          onSurface: Color(0xffe8efea),
          onSurfaceVariant: Color(0xffa9bbb5),
          outline: Color(0xff56706a),
          outlineVariant: Color(0xff2c423e),
          surfaceContainerLowest: Color(0xff0b1412),
          surfaceContainerLow: Color(0xff132220),
          surfaceContainer: Color(0xff182927),
          surfaceContainerHigh: Color(0xff1e302d),
          surfaceContainerHighest: Color(0xff253a36),
        )
      : const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xff0f6b63),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffcde9e2),
          onPrimaryContainer: Color(0xff00201c),
          secondary: Color(0xffb8492f),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xfffadbd1),
          onSecondaryContainer: Color(0xff3b0d02),
          tertiary: Color(0xff8a6416),
          onTertiary: Colors.white,
          error: Color(0xffb3352b),
          onError: Colors.white,
          surface: Color(0xfff6f1e7),
          onSurface: Color(0xff1c2a27),
          onSurfaceVariant: Color(0xff56645f),
          outline: Color(0xff8a958f),
          outlineVariant: Color(0xffd8cfbb),
          surfaceContainerLowest: Color(0xffffffff),
          surfaceContainerLow: Color(0xfffbf7ef),
          surfaceContainer: Color(0xfffffbf3),
          surfaceContainerHigh: Color(0xffefe8d8),
          surfaceContainerHighest: Color(0xffe8dfcb),
        );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: b,
    visualDensity: VisualDensity.standard,
  );
  final t = base.textTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  final textTheme = t.copyWith(
    displayLarge: t.displayLarge?.merge(_display(52)),
    displayMedium: t.displayMedium?.merge(_display(42)),
    displaySmall: t.displaySmall?.merge(_display(34)),
    headlineLarge: t.headlineLarge?.merge(_display(32)),
    headlineMedium: t.headlineMedium?.merge(_display(28)),
    headlineSmall: t.headlineSmall?.merge(_display(24)),
    titleLarge: t.titleLarge?.merge(_display(21, weight: 560)),
    labelLarge: t.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: .3,
      color: scheme.onSurfaceVariant,
    ),
  );
  final stadium = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [dark ? CastleiTokens.dark : CastleiTokens.light],
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corner.md),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corner.md),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.all(12),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: stadium,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: stadium,
        side: BorderSide(color: scheme.outline),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: stadium,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurface,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: stadium,
      side: BorderSide(color: scheme.outlineVariant),
      selectedColor: scheme.primaryContainer,
      labelStyle: textTheme.labelLarge?.copyWith(letterSpacing: 0),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corner.lg),
      ),
      titleTextStyle: textTheme.headlineSmall,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Corner.lg)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corner.sm),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corner.sm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corner.sm),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corner.sm),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 24),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      linearMinHeight: 8,
    ),
  );
}

/// Page padding that also clears the system navigation bar / gesture area.
/// Use for every scrolling page body so content is never hidden behind the
/// system bars (the app draws edge-to-edge).
EdgeInsets pagePadding(BuildContext context, [double base = 20]) {
  final inset = MediaQuery.paddingOf(context);
  final width = MediaQuery.sizeOf(context).width;
  final horizontal = width > 800 ? (width - 760) / 2 : base;
  return EdgeInsets.fromLTRB(
    horizontal + inset.left,
    base,
    horizontal + inset.right,
    base + inset.bottom,
  );
}
