# Releasing

## Signing key (back this up now)
The Android release key was generated locally:
- `android/castlei-release.jks` (the keystore) and `android/key.properties` (its passwords). Both are gitignored.
- **Copy both to a password manager or encrypted backup.** If the key is lost you cannot publish updates to phones that already have the app installed (they would need to uninstall first).
- SHA-1/SHA-256 of this key are registered with the Firebase Android app (needed for Google sign-in).

Local release build: `flutter build apk --release --split-per-abi --target-platform android-arm64` (uses the key automatically; falls back to the debug key when `key.properties` is missing).

## Automated release (GitHub Actions)
`.github/workflows/release.yml` builds, tests and uploads to Firebase App Distribution (group `owner`) when you push a tag such as `v1.0.1`, or via "Run workflow". Add these repository secrets:

| Secret | How to create it |
|---|---|
| `KEYSTORE_BASE64` | `base64 -w0 android/castlei-release.jks` |
| `KEY_PROPERTIES_BASE64` | `base64 -w0 android/key.properties` |
| `GOOGLE_SERVICES_JSON` | `base64 -w0 android/app/google-services.json` (after running `tool/refresh_firebase_config.sh`) |
| `FIREBASE_SERVICE_ACCOUNT` | JSON key of a service account with the "Firebase App Distribution Admin" role (Project settings → Service accounts), pasted as plain JSON |

Release builds upload native (Stockfish) crash symbols automatically in CI (`ORG_GRADLE_PROJECT_uploadNativeSymbols=true`).

## Manual distribution
`firebase appdistribution:distribute build/app/outputs/flutter-apk/app-arm64-v8a-release.apk --app 1:PROJECT_NUMBER:android:REDACTED_APP_ID --groups owner --project castlei`
