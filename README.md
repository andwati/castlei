# Castlei

Private chess companion (Flutter; Android validated, iOS prepared). Play on-device Stockfish 18, analyse and review games with an evaluation graph, drill tactics and opening repertoires, and keep everything in local SQLite (Drift); everything core works offline. Optional account for automatic cloud backup, reminders and announcements. License: GPL-3.0.

## Build
Toolchain pins are in `docs/TOOLCHAIN.md`.
```
./tool/fetch_engine.sh        # fetch pinned Stockfish + NNUE (checksums in docs/NNUE_SHA256.txt)
flutter pub get
flutter analyze && flutter test
flutter run -d <android device>
flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64   # debug-signed unless you add a signing config
```
Optional: `--dart-define=CASTLEI_CATALOG_URL=...` enables puzzle pack downloads (see `catalog/README.md`). Crash reporting is opt-in and requires your own Firebase config; without it the app runs normally.

## Docs
See `docs/FIREBASE_SETUP.md` (console checklist), `docs/RELEASE.md` (signing, CI, distribution), `docs/PRIVACY.md`, `docs/IOS.md`, `docs/ARCHITECTURE.md` (modules, schema, engine protocol, backup and pack formats) and `docs/STATUS.md` (validation status and known limitations).
