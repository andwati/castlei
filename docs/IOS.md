# iOS: build, sign, install

Everything is configured for iOS 16+, iPhone only, portrait.

**Verified in CI (GitHub macOS runner, Apple silicon):** the app builds for the iOS simulator (CocoaPods integration, the forwarder-based engine pod, embedded Stockfish networks), the real Stockfish engine plays a move on an iPhone simulator, and the core-flow integration tests pass. The CI workflow (`ci.yml`, job `ios`) repeats this on every push to `main` and on pull requests, after the Android job passes.

**Still unverified (needs a Mac and an iPhone):** device builds and signing, performance on device, Firebase on iOS (Crashlytics dSYM upload, push, Performance), Google/Apple sign-in, the iOS document picker and share sheet, VoiceOver, haptics. Treat the first Mac build as the validation of those.

## What is prepared
- Bundle ID `com.andwati.castlei`, iPhone only, iOS 16.0, original app icon set (no alpha), portrait orientation.
- `ios/Podfile` (platform 16.0) and xcconfig includes for CocoaPods; Flutter plugins also use Swift Package Manager where supported.
- Engine: `packages/castlei_native` pod. `Classes/*.cpp` are forwarders that compile the pinned Stockfish and `native/adapter.cpp` in place; NNUE networks are embedded with `.incbin` through the header search path. Regenerate forwarders with `tool/gen_ios_forwarders.sh`. The Dart side looks the C ABI up in the running process and falls back to `castlei_native.framework`.
- Firebase: `lib/firebase_options.dart` reads build-time values (`firebase.env.json`, see `docs/BUILDING.md`); `ios/Runner/GoogleService-Info.plist` is local and gitignored (`tool/dev_setup.sh` makes a placeholder, `tool/refresh_firebase_config.sh` the real one), Crashlytics and Performance collection on by default (user can switch both off in Settings), and an Xcode build phase "Upload Crashlytics Symbols" that finds the script for both CocoaPods and SPM layouts.
- `ITSAppUsesNonExemptEncryption = false`.

## Accounts, push and Apple sign-in on iOS
- Sign in with Apple and push notifications need a **paid Apple Developer Program** membership. The entitlements file `ios/Runner/Runner.entitlements` is wired in behind a switch that is **off by default** so a free-account build works. To enable: edit `ios/Flutter/Signing.xcconfig` and set `CASTLEI_ENTITLEMENTS = Runner/Runner.entitlements`, then in Xcode confirm the Push Notifications and Sign in with Apple capabilities under Signing & Capabilities.
- Google sign-in on iOS: enable Google in Firebase Authentication, then run `tool/refresh_firebase_config.sh` (downloads the real `GoogleService-Info.plist` with the client ID and adds the URL scheme to `Info.plist`).
- Apple sign-in: enable the Apple provider in Firebase Authentication.
- Push (announcements): upload an APNs auth key in Firebase (Project settings → Cloud Messaging).
- Local reminders (drills, daily puzzle, unfinished game) need no paid account.

## First build on a Mac
```
brew install --cask flutter   # or your usual Flutter 3.47.9 install; Xcode 16+ and CocoaPods required
./tool/fetch_engine.sh        # pinned Stockfish + NNUE (macOS-safe checksum)
flutter pub get
flutter build ios --simulator --no-codesign   # first compile of Stockfish takes several minutes
open ios/Runner.xcworkspace   # set your Team under Runner > Signing & Capabilities
flutter run -d <your iPhone>  # or Product > Archive for TestFlight
```
Free Apple IDs work for installing on your own phone; builds expire after 7 days.

## Things to check on the first run (unverified)
1. ~~`pod install` succeeds with the forwarder-based `castlei_native` pod.~~ Verified in CI.
2. ~~The engine initializes.~~ Verified on the simulator in CI (the pod stages the downloaded NNUE files into `Pods/` before compiling, because Apple's assembler resolves `.incbin` relative to the compile directory). Check it again on a device.
3. Release builds keep the exported `castlei_*` symbols (if not, set Build Settings > Deployment > Strip Style to "Non-Global Symbols" for Runner).
4. Crashlytics dSYM upload phase runs in Release archives; check the Crashlytics dashboard after a release run (and a deliberate test crash if needed).
5. Performance and Crashlytics appear for the iOS app in the console after a release run.
6. Safe areas, large text and VoiceOver on a real iPhone; haptics.
7. Reminders: the notification permission prompt appears after your first finished game or when you enable a reminder; check that scheduled reminders fire.
8. File export/import (backup, PGN) through the iOS document picker and share sheet.
