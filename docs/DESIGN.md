# Design system — "Parchment & Pine"

Warm paper surfaces by day, deep pine by night. Teal leads, coral nudges, brass marks the last move. A soft serif (Fraunces, SIL OFL, bundled) carries display text; the platform sans stays on body copy.

## Tokens (`lib/core/ui/theme.dart`)
- `buildTheme(Brightness)` builds the full Material 3 theme; `CastleiTokens` (ThemeExtension) holds board, highlight, hero and status colors. Access via `context.tokens`, `context.colors`, `context.text`.
- Light: surface `#F6F1E7`, primary `#0F6B63`, secondary (coral) `#B8492F`, tertiary (brass) `#8A6416`. Dark: surface `#0F1A18`, primary `#7FD1C4`, secondary `#F2927A`, tertiary `#E3B85C`.
- Board: light squares `#EEE6D2`/`#D9D2BF`, dark squares `#7B9A8B`/`#5F8274`; last move = brass wash, selected = coral wash + ring, check = red radial glow on the king (also announced to screen readers).
- Spacing `Space.*`, radii `Corner.*` (12/18/28), pill-shaped buttons with 48+ dp targets.

## Components (`lib/core/ui/widgets.dart`)
`HeroCard` + `HeroButton` (pine card with a battlement crown), `ActionTile`, `SectionLabel`, `StatusChip` (always icon + text), `FeedbackCard` (tinted banner with icon), `ToolButton`, `StatTile`, `GroupCard`, `MoveChip`, `Battlements` (signature motif).

## App icon
Original castle on pine (`design/icon.svg`, `design/icon_foreground.svg`). Android uses an adaptive icon (foreground + `#0F4F49` background, monochrome layer for themed icons); iOS PNGs are exported without alpha from the same source.

## Board (`lib/core/ui/board.dart`)
Last-move and check indicators, capture rings vs. move dots, filled-head arrows, promotion bottom sheet with piece buttons, per-square semantics including last-move/check state.

## Rules
Never rely on color alone (chips and status cards pair icon + text); display serif only for titles/headlines; respect reduced motion (no decorative animation is used).
