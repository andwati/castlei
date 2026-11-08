# Validation status

## Automated
- `flutter analyze` clean; `flutter test` unit/widget tests pass (domain, storage, backup, scheduling, repertoire, board check/last-move/promotion semantics, 200% text on a 360 dp phone).
- `integration_test/` (engine_play_test, flows_test: 9 tests) passes on the Android emulator (API 37, x86_64) and the owner phone (SM-M366B, Android 16, arm64): engine reply, takeback, hint, resign + whole-game review, puzzle reveal, repertoire/stats/settings screens, live pack catalog refresh + 5000-puzzle install, backup/restore on an on-device sqlite file.

## Owner phone (release build, manual via adb)
- 16 KB page-size compatibility: all native libraries aligned; dialog gone.
- Airplane mode: engine game passes offline.
- Process kill mid-game: game restored paused with the exact committed moves.
- Short review (2 moves, Balanced): finished in ~14 s; memory during search PSS ~535 MB / RSS ~606 MB; battery 34.6 C (USB-charging).
- Not yet done: long sustained review heat test, screen reader / large text / reduced motion, audio and haptics, pack cancel/retry/remove by hand, backup/restore via the file picker UI.

## Other
- iOS: fully configured (engine pod, Firebase, icons, Podfile, CI workflow) but **unbuilt and unverified**; see `docs/IOS.md`. Not mentioned in the app UI.
- External config still required: release signing, Firebase config (currently falls back cleanly), public catalog (default URL is live).

## Full game on the owner phone
`integration_test/full_game_test.dart` plays a complete game against the app's Medium engine purely by tapping the board (own moves from a second full-strength Stockfish): finished 1-0 by checkmate in 77 plies, including castling; check glow, last-move highlight and result card verified on screen.

## Online features (accounts, cloud backup, analytics, messaging, remote config)
- Built and running on the owner phone: Settings → Account (Google; Apple on iOS), automatic cloud backup logic (after finished games and daily, Wi-Fi only, last 5 versions, restore from cloud), usage analytics (default on, switchable), local reminders (due drills, daily puzzle, unfinished game; the system alarm for the daily puzzle was confirmed on the phone, and the test notification was delivered), FCM announcements topic, Remote Config (engine caps, kill switches, announcement card), In-App Messaging (suppressed during games), app shortcuts, predictive back.
- Google and Apple sign-in are enabled in Firebase and the configs contain the OAuth clients. Cloud backup was moved from Storage (paid plan) to **Firestore** (free): database created in `nam5`, rules deployed, chunking/integrity logic unit-tested. **Not yet exercised end to end on a device**: sign-in, cloud upload/restore, and delivery of push and analytics events (the phone was locked when I tried). Remote Config parameters and the iOS APNs key are still optional console steps.
- Release signing key generated (gitignored; back it up, see `docs/RELEASE.md`); first signed build uploaded to Firebase App Distribution (group `owner`, no testers yet); CI release workflow written (needs repository secrets).
- Unit tests cover reminder timing, backup retention, analytics bucketing, remote-config clamping.

## Engine speed
ARM NEON enabled for arm64 builds (Android and iOS). Measured on the owner phone (3 s searches, 3 positions): average 295 → 460 knps (+56%), depth 20 → 21; x86_64 unaffected. iOS speed unmeasured.

## Board, review and openings
Pieces slide between squares (disabled with reduced motion), original synthesized move/capture/check/end sounds with matching haptics (sounds off by default), evaluation graph (tap to jump) with text quality marks in the move list, opening names from the CC0 Lichess list matched by position (offline).

## Performance monitoring (Firebase Performance)
- Android and iOS configured (Gradle `firebase-perf` plugin, iOS via the Firebase SDK); on by default and switchable in Settings; debug runs never report; Firebase's automatic app-start/network traces are on natively.
- Custom traces (`lib/core/diagnostics/perf.dart`) carry only names, timings and counts: `first_frame`, `engine_init`, `engine_search` (requested vs actual ms, overhead, depth), `review_move`, `review_game`, `pgn_import`, `backup_export`, `backup_restore`, `catalog_refresh`, `pack_install`, and `frames` (total/slow/frozen frames, flushed when the app is backgrounded).
- Verified: builds and runs on the phone and the unit test confirms tracing is transparent when off. Arrival of traces in the Firebase console has not been confirmed from here.

## Crash reporting (Firebase Crashlytics)
- Android configured (`google-services.json`, kept out of git; CI uses the `GOOGLE_SERVICES_JSON` base64 secret or a placeholder). `lib/firebase_options.dart` covers Android and iOS; iOS is untested.
- **On by default (owner decision; the original plan said opt-in).** The preference key is `crashReports`, user-switchable in Settings. Restoring a backup keeps this device's own choice. Debug runs never report.
- Reports are sanitized (`lib/core/diagnostics/crash.dart`): error type plus a scrubbed message with FEN, PGN headers and file paths removed; only app and engine version are attached. Unit-tested.
- Settings has a "Send a test report" action. The app confirms the SDK accepted it; arrival in the Firebase console has not been confirmed from here, so check the Crashlytics dashboard for a "StateError: Castlei test report" non-fatal.
- Native (Stockfish) crash symbolication is opt-in: `ORG_GRADLE_PROJECT_uploadNativeSymbols=true flutter build apk --release`.

# Known limitations / findings
- Debug builds started from the launcher (not via `flutter run`) hang on the splash screen; use release/profile for standalone installs.
- Each ABI's engine library embeds the 109 MB NNUE network. Build with `flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64` (arm64 APK ~137 MB, x86_64 ~139 MB; a universal build is ~365 MB).
- Dead-position detection relies on dartchess material rules; exotic dead positions are not proven.
- Annotation extensions (`[%cal]`, `[%csl]`) are not rendered by every other app. Backups are unencrypted.
