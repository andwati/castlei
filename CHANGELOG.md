# Changelog

Release notes for each Google Play release, newest first. The bullets under each version are
what goes into `play/whatsnew/whatsnew-en-US` for that release. Add an entry here every time
the version in `pubspec.yaml` is bumped.

## 1.1.3 — 2026-11-12

A guided review of every game.

- Review a finished game step by step: it analyses on its own with a progress bar and a live board.
- A short summary first: a plain sentence about your game, accuracy for you and Stockfish, and a graph.
- Walk through your mistakes with Next: each one is marked on the board and explained in plain words.
- Show the better move as an arrow, or try again and find it yourself.
- Reviews keep going if another screen uses the engine, and say so clearly if one is interrupted.
- Your full analysis workspace is still one tap away under Explore this game.
- Puzzles: a wrong move is marked on the board with a Retry button, hints come in two steps (the piece, then the arrow), and Reveal draws the solution.
- Lessons: feedback now sits above the board, wrong answers are crossed out, the right one gets a tick, and the lesson text folds under "The idea".
- Coordinate training: the 30-second challenge is on by default with a countdown bar, and the tapped square flashes green or red.

Android build 11 (1.1.3+11).

## 1.1.2 — 2026-11-12

A calmer game screen and smarter updates.

- Cleaner game screen: the board comes first, with captures, turn and clocks on the player bars.
- Your game's moves in a one-line strip; tap it to see them all.
- Review is now the main button when a game ends.
- Fairer game reviews: fewer moves wrongly marked uncertain.
- Reminders are only offered after you finish a game or puzzle, with an explanation first.
- Castlei can now offer you an update through Google Play.

Android build 10 (1.1.2+10). Build 9 was never released: it was built without the Firebase
configuration, so accounts, backup and feedback were switched off.

## 1.1.0 — 2026-11-09

- Add 24 offline guided lessons with 72 exercises, demonstrations, hints, and saved progress.
- Add coordinate training: find or name squares, practice from either side, and try 30-second challenges.
- Expand local performance insights with results by opening, color, and engine difficulty, review coverage, mistake trends, and training strengths and weaknesses.
- Give each Stockfish difficulty a distinct illustrated human avatar in the picker, game screen, and progress cards.
- Improve gameplay with explicit White/Black turn cues, player identities, clearer clocks and results, draggable pieces, puzzle solution playback, and readable engine variations.
- Improve navigation, responsive board layouts, button spacing, large-text behavior, and system navigation-bar insets.
- Generate game and study titles automatically; saved titles can still be renamed in Library.
- Preserve existing games and progress with the same local database and backup format.

Android build 5 produces phone version code 2005, allowing updates over the local 2001–2004 test builds.

## 1.0.0

Initial Android release.
