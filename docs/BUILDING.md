# Building Castlei

Castlei builds and runs **without any Firebase project**. In that mode sign-in, cloud backup, crash reports, analytics, push and Remote Config are simply unavailable; everything else works.

## Requirements
Flutter (version in the `FLUTTER_VERSION` default of `.github/disabled-workflows/ci.yml`), a JDK 17, Android SDK with NDK 28.2 and CMake, Python 3, and about 6 GB free for the engine and build output.

## First build
```
./tool/fetch_engine.sh     # downloads the pinned Stockfish source and its network files (checked against SHA-256)
./tool/dev_setup.sh        # creates placeholder Firebase files for the native builds
flutter pub get
flutter run                # or: flutter build apk --release --target-platform android-arm64
```
Run `flutter test` for the unit tests; `python3 tool/native_smoke.py` checks the engine adapter.

## Using your own Firebase project (optional)
1. Create a Firebase project and register an Android app with package `com.andwati.castlei` or your own application id (change it in `android/app/build.gradle.kts`). Enable the services you want (Authentication, Firestore, and so on; rules are in `firestore.rules`).
2. `firebase login`, then
   ```
   FIREBASE_PROJECT_ID=... FIREBASE_ANDROID_APP_ID=... FIREBASE_IOS_APP_ID=... ./tool/refresh_firebase_config.sh
   ```
   This writes three local files, all gitignored: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` and `firebase.env.json`.
3. Build with `flutter run --dart-define-from-file=firebase.env.json`.

`firebase.env.example.json` shows the keys. Never commit these files.

## Release signing
Release builds use `android/key.properties` and a keystore you create yourself (both gitignored); without them the build falls back to the debug key. See `docs/RELEASE.md` for the maintainer's release process.
