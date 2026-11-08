# Castlei

Private, offline-first chess companion (Flutter, Android first). Play on-device Stockfish 18, analyse and review games, drill tactics and opening repertoires, and keep everything in local SQLite (Drift). License: GPL-3.0.

## Build
Toolchain pins are in `docs/TOOLCHAIN.md`.
```
./tool/fetch_engine.sh        # fetch pinned Stockfish + NNUE (checksums in docs/NNUE_SHA256.txt)
flutter pub get
flutter analyze && flutter test
flutter run -d <android device>
flutter build apk --release   # needs owner signing config, otherwise debug-signed test build
```
Optional: `--dart-define=CASTLEI_CATALOG_URL=...` enables puzzle pack downloads (see `catalog/README.md`). Crash reporting is opt-in and requires your own Firebase config; without it the app runs normally.

## Docs
See `docs/ARCHITECTURE.md` (modules, schema, engine protocol, backup and pack formats) and `docs/STATUS.md` (validation status and known limitations).
