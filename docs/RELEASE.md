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
| `PLAY_SERVICE_ACCOUNT_JSON` (optional) | uploads the signed App Bundle to Google Play; the Play steps are skipped when absent | JSON key of a Google Cloud service account invited in Play Console > Users and permissions with release permissions for Castlei: `gh secret set PLAY_SERVICE_ACCOUNT_JSON < key.json` |
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
| `PLAY_TRACK` | `alpha` | Release | Play track: `internal`, `alpha` (closed testing), `beta`, `production`. A manual run can override it |
| `PLAY_RELEASE_STATUS` | `draft` | Release | `draft` until the app has been published once, then `completed` (or `inProgress` with `PLAY_USER_FRACTION`, for example `0.2`) |
| `PLAY_USER_FRACTION` | (none) | Release | Staged rollout share when the status is `inProgress` |
| `FIREBASE_ANDROID_APP_ID` | (none; set it) | Release | App Distribution target |
| `FIREBASE_TEST_GROUP` | `owner` | Release | App Distribution group |

## What a release does not include yet
- **iOS** is prepared but not built on a Mac (see `docs/IOS.md`).
- **Native (Stockfish) crash symbols** are not uploaded automatically. To upload them for a local release build: `ORG_GRADLE_PROJECT_uploadNativeSymbols=true flutter build apk --release ...`.

## Google Play
Tag pushes (not pre-release tags such as `-rc.1`) also build an `.aab`, check it is signed with the release key and upload it to `PLAY_TRACK`. Release notes come from `play/whatsnew/whatsnew-en-US` (max 500 characters; update it for every release). Store listing text and the content-declaration answers are drafted in `play/listing/en-US.md`; the API upload does not change the listing.

One-time setup:
1. Play Console: create the app (`com.andwati.castlei`), complete App content (privacy policy, Data safety, content rating, target audience, account deletion URL) and the store listing.
2. Enrol in Play App Signing. Your `castlei-release.jks` is the **upload** key; Google holds the app-signing key. Register the **app-signing** certificate's SHA-1/SHA-256 (Play Console > Test and release > App signing) with the Firebase Android app, otherwise Google sign-in fails in Play-installed builds.
3. Create the service account (Google Cloud > IAM > Service accounts, enable the Google Play Android Developer API), invite it in Play Console, and store its key as `PLAY_SERVICE_ACCOUNT_JSON`.
4. The very first bundle must be uploaded by hand (Play Console > Closed testing > Create release). After that CI can upload.
5. Personal developer accounts must run a closed test with at least 12 testers opted in for 14 continuous days before applying for production access. Upload to `alpha` (the default) while testing; when production access is granted set `PLAY_TRACK=production` and, after the first live release, `PLAY_RELEASE_STATUS=completed`.

Version codes: Play bundles use the plain build number from `pubspec.yaml` (no ABI offset), and each upload needs a higher one than any before it. Phones that sideloaded the GitHub APKs (version codes 2001 and up) will not be offered Play updates until the build number passes theirs, and cannot install over them anyway because Play re-signs with a different key; they must uninstall first (export a backup).

## Open-source obligations
Releases contain GPL-licensed software (Stockfish). Keep the written source offer (website, Terms and the in-app Open-source screen) accurate, and provide the corresponding source for the exact release to anyone who asks.

## Manual distribution
`firebase appdistribution:distribute build/app/outputs/flutter-apk/app-arm64-v8a-release.apk --app "$FIREBASE_ANDROID_APP_ID" --groups owner --project "$FIREBASE_PROJECT_ID"`
