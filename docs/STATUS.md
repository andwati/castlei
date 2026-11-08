# Validation status

## Automated
- `flutter analyze` clean; `flutter test` 9 unit/widget tests pass.
- `integration_test/` (engine_play_test, flows_test: 9 tests) passes on the Android emulator (API 37, x86_64) and the owner phone (SM-M366B, Android 16, arm64): engine reply, takeback, hint, resign + whole-game review, puzzle reveal, repertoire/stats/settings screens, live pack catalog refresh + 5000-puzzle install, backup/restore on an on-device sqlite file.

## Owner phone (release build, manual via adb)
- 16 KB page-size compatibility: all native libraries aligned; dialog gone.
- Airplane mode: engine game passes offline.
- Process kill mid-game: game restored paused with the exact committed moves.
- Short review (2 moves, Balanced): finished in ~14 s; memory during search PSS ~535 MB / RSS ~606 MB; battery 34.6 C (USB-charging).
- Not yet done: long sustained review heat test, screen reader / large text / reduced motion, audio and haptics, pack cancel/retry/remove by hand, backup/restore via the file picker UI.

## Other
- iOS: configuration present, **unverified** (no Mac/iPhone).
- External config still required: release signing, Firebase config (currently falls back cleanly), public catalog (default URL is live).

# Known limitations / findings
- Debug builds started from the launcher (not via `flutter run`) hang on the splash screen; use release/profile for standalone installs.
- Each ABI's engine library embeds the 109 MB NNUE network. Build with `flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64` (arm64 APK ~137 MB, x86_64 ~139 MB; a universal build is ~365 MB).
- Dead-position detection relies on dartchess material rules; exotic dead positions are not proven.
- Annotation extensions (`[%cal]`, `[%csl]`) are not rendered by every other app. Backups are unencrypted.
