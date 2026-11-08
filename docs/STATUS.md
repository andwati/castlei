# Validation status
- Automated: `flutter analyze` clean; `flutter test` (domain, storage, backup, scheduling, repertoire, widget).
- Android phone: debug build installed on SM-M366B (Android 16); manual checklist pending owner use.
- Android emulator + phone: `integration_test/engine_play_test.dart` passes (play e4, engine replies; emulator API 37 x86_64, SM-M366B arm64).
- iOS: configuration present, **unverified** (no Mac/iPhone).
- External config still required: release signing, Firebase config, public catalog URL.

# Known limitations
- Dead-position detection relies on dartchess material rules; exotic dead positions are not proven.
- Annotation extensions (`[%cal]`, `[%csl]`) are not rendered by every other app.
- Backups are unencrypted.
- Performance/heat on long reviews not yet measured on device.
