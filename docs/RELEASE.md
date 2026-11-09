# Releasing

## Signing key
The Android release key lives at `android/castlei-release.jks` with its passwords in `android/key.properties` (both gitignored). **Keep a copy in a password manager.** If it is lost you cannot publish updates to phones that already have the app installed.

- The key's SHA-1/SHA-256 are registered with the Firebase Android app (needed for Google sign-in).
- Release certificate SHA-256: `F2:85:EE:48:CF:32:1D:24:38:B1:5A:A9:AD:D2:6B:31:9F:69:11:DE:35:CA:E0:5F:6C:4A:74:BD:57:A0:0D:6A`
- Local release build: `flutter build apk --release --split-per-abi --target-platform android-arm64` (uses the key automatically and falls back to the debug key if `key.properties` is missing).

## Cutting a release
A GitHub Release is created by `.github/workflows/release.yml` whenever a `v*` tag is pushed.

1. Set the version in `pubspec.yaml` (`version: 1.0.1+2`: the name before `+`, an increasing build number after it). Keep the build number below 1000.
2. Commit, then create an **annotated** tag that matches the version, and push it:
   ```
   git tag -a v1.0.1 -m "Castlei 1.0.1" -m "What changed in this release"
   git push origin main v1.0.1
   ```
   A suffix such as `v1.0.1-rc.1` publishes a pre-release.
3. The workflow then: checks the tag against `pubspec.yaml`, restores the signing key from secrets, runs analyze and the tests, builds the arm64-v8a and x86_64 release APKs (with retries), **verifies both are signed with the Castlei release key**, and publishes the Release with the APKs, `SHA256SUMS.txt` and generated notes.

Dry run (builds and uploads the APKs as a workflow artifact, publishes nothing): Actions → Release → Run workflow.

If a release run fails before publishing, fix the problem and either re-run the job or delete and recreate the tag: `git push origin :refs/tags/v1.0.1`, then tag again.

Note on installing: Flutter adds an offset to the Android version code per CPU type (arm64-v8a +2000, x86_64 +4000), so build 1 installs as 2001 or 4001. The app shows the plain build number.

## Repository secrets
| Secret | Purpose | How to (re)create |
|---|---|---|
| `KEYSTORE_BASE64` | the release keystore | `base64 -w0 android/castlei-release.jks \| gh secret set KEYSTORE_BASE64` |
| `KEY_PROPERTIES_BASE64` | keystore passwords and alias | `base64 -w0 android/key.properties \| gh secret set KEY_PROPERTIES_BASE64` |
| `GOOGLE_SERVICES_JSON` | Firebase Android config (also used by the CI build) | `base64 -w0 android/app/google-services.json \| gh secret set GOOGLE_SERVICES_JSON` |
| `FIREBASE_ENV_JSON` | the Firebase values the app is built with (`firebase.env.json`) | `base64 -w0 firebase.env.json \| gh secret set FIREBASE_ENV_JSON` |
| `FIREBASE_SERVICE_ACCOUNT` (optional) | uploads each release to Firebase App Distribution (group `owner`) | JSON key of a service account with "Firebase App Distribution Admin"; the step is skipped when the secret is absent |

Run `./tool/refresh_firebase_config.sh` (see the script header) and reset `GOOGLE_SERVICES_JSON` and `FIREBASE_ENV_JSON` whenever the Firebase configuration changes. None of these files are in git.

## Repository variables (not secrets)
Values that change over time are Actions **variables**, editable in GitHub: Settings → Secrets and variables → Actions → Variables. Each workflow has the same value as a default (`vars.NAME || 'default'`), so nothing breaks if a variable is missing.

| Variable | Default | Used by | Meaning |
|---|---|---|---|
| `FLUTTER_VERSION` | `3.47.9` | CI, Release | Flutter SDK version |
| `FLUTTER_CHANNEL` | `stable` | CI, Release | Flutter channel |
| `JAVA_VERSION` | `17` | CI, Release | JDK for Gradle |
| `CI_ANDROID_PLATFORM` | `android-arm64` | CI | CPU target of the CI release build |
| `ANDROID_TARGET_PLATFORMS` | `android-arm64,android-x64` | Release | CPU targets of the published APKs |
| `RELEASE_CERT_SHA256` | the current key's fingerprint | Release | Public SHA-256 of the signing certificate; the build fails if APKs are signed with anything else. Change it only when you rotate the key |
| `FIREBASE_ANDROID_APP_ID` | (none; set it) | Release | App Distribution target |
| `FIREBASE_TEST_GROUP` | `owner` | Release | App Distribution group |

## What a release does not include yet
- **Google Play:** Play requires an Android App Bundle. Each CPU architecture embeds the 110 MB Stockfish network, so a bundle with two architectures is large; check Play's size limits before the first upload (`flutter build appbundle --release --target-platform android-arm64,android-x64`).
- **iOS** is prepared but not built on a Mac (see `docs/IOS.md`).
- **Native (Stockfish) crash symbols** are not uploaded automatically. To upload them for a local release build: `ORG_GRADLE_PROJECT_uploadNativeSymbols=true flutter build apk --release ...`.

## Open-source obligations
Releases contain GPL-licensed software (Stockfish). Keep the written source offer (website, Terms and the in-app Open-source screen) accurate, and provide the corresponding source for the exact release to anyone who asks.

## Manual distribution
`firebase appdistribution:distribute build/app/outputs/flutter-apk/app-arm64-v8a-release.apk --app "$FIREBASE_ANDROID_APP_ID" --groups owner --project "$FIREBASE_PROJECT_ID"`
