# Releasing

Releases are built locally. The CI and Release workflows are parked in `.github/disabled-workflows/` (GitHub only runs `.github/workflows/`); move them back to re-enable them. They need the repository secrets `KEYSTORE_BASE64`, `KEY_PROPERTIES_BASE64`, `GOOGLE_SERVICES_JSON` and `FIREBASE_ENV_JSON`.

## Signing key
The Android release key lives at `android/castlei-release.jks` with its passwords in `android/key.properties` (both gitignored). **Keep a copy in a password manager.** With Play App Signing this is the **upload** key; Google holds the app-signing key.

- Upload certificate SHA-256: `F2:85:EE:48:CF:32:1D:24:38:B1:5A:A9:AD:D2:6B:31:9F:69:11:DE:35:CA:E0:5F:6C:4A:74:BD:57:A0:0D:6A`
- Register the **app-signing** certificate's SHA-1/SHA-256 (Play Console > Test and release > App signing) with the Firebase Android app, or Google sign-in fails in Play-installed builds.
- Without `key.properties` a release build silently falls back to the debug key; always check the fingerprint below.

## Building for Google Play
1. Set the version in `pubspec.yaml` (`version: 1.1.0+5`: the name, then an increasing build number). **Every upload needs a build number higher than any used before**, in any track. Bundles use the plain number (no ABI offset).
2. Build:
   ```
   ./tool/fetch_engine.sh   # once
   flutter build appbundle --release --target-platform android-arm64,android-x64 --dart-define-from-file=firebase.env.json
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab` (about 500 MB, mostly native debug symbols; users download about 100 MB).
3. Check the signature: `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep SHA256` must equal the upload fingerprint above.
4. Play Console > Testing > Closed testing (or Production) > Create new release > upload the `.aab`, paste the notes from `play/whatsnew/whatsnew-en-US` inside `<en-US>` tags, review, roll out.
5. Tag the release and push: `git tag -a v1.1.1 -m "Castlei 1.1.1" && git push origin main v1.1.1`.

Store listing text and the content-declaration answers are drafted in `play/listing/en-US.md`.

Personal developer accounts must run a closed test with at least 12 testers opted in for 14 continuous days before applying for production access. Internal testing does not count.

## Permissions
Only `INTERNET`, `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED` are declared by the app. Libraries add network state, wake lock, vibrate and the push-message permissions. The advertising-ID, ad-services, install-referrer and biometric permissions that Firebase and other libraries add are removed in `android/app/src/main/AndroidManifest.xml` (`tools:node="remove"`), so answer **No** to the Advertising ID declaration in Play Console. Check the merged list in Play Console > App bundle explorer after each upload.

## Website
`python3 tool/build_site.py && firebase deploy --only hosting --project castlei`

## Sideloaded builds
Phones that installed the earlier GitHub APKs (version codes 2001-2005, a different signing key) cannot update to the Play build; they must uninstall first (export a backup).

## What a release does not include yet
- **iOS** is prepared but not built on a Mac (see `docs/IOS.md`).
- **Native (Stockfish) crash symbols** are not uploaded to Crashlytics automatically: `ORG_GRADLE_PROJECT_uploadNativeSymbols=true flutter build appbundle --release ...`.

## Open-source obligations
Releases contain GPL-licensed software (Stockfish). Keep the written source offer (website, Terms and the in-app Open-source screen) accurate, and provide the corresponding source for the exact release to anyone who asks.
