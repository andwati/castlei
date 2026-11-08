# Firebase setup checklist (project `castlei`)

Done from the command line already: Android app registered with the release + debug SHA fingerprints, storage rules written (`storage.rules`), App Distribution group `owner` created and the first signed build uploaded.

## Already done
- Google and Apple sign-in providers enabled; the current `google-services.json` / `GoogleService-Info.plist` contain the OAuth clients (refresh any time with `./tool/refresh_firebase_config.sh`, which also adds the iOS Google URL scheme).
- Apple on Android uses Firebase's web flow with the Services ID return URL `https://castlei.firebaseapp.com/__/auth/handler`; on iOS it uses the native flow.
- **Cloud backup uses Firestore** (free plan; Storage needs a paid plan). Database `(default)` created in `nam5`, security rules deployed from `firestore.rules`: each user can only read/write `users/{uid}/backups/**`. Backups are split into ~700 KB chunks (max 12 MB per backup), the metadata document is written last, restore verifies size and SHA-256. Redeploy rules with `firebase deploy --only firestore --project castlei`.
- App Distribution group `owner` exists and you are a tester.

## Still to do in the Firebase console
1. **Apple provider (iOS):** make sure the Apple Services ID, Team ID and key are saved in Authentication → Sign-in method → Apple.
2. **App Check / API key restrictions** (optional hardening, see item 8 below).
3. *(Storage is no longer used; no billing needed.)*
4. **Remote Config:** add these parameters (the app works with the defaults if you skip this) and publish:

| Parameter | Default | Effect |
|---|---|---|
| `engine_max_ms_untimed` | 1000 | Engine thinking cap, untimed games (200–5000) |
| `engine_max_ms_timed` | 2000 | Engine thinking cap, timed games (200–5000) |
| `cloud_backup_enabled` | true | Kill switch for automatic cloud backup |
| `reminders_enabled` | true | Kill switch for local reminders |
| `apple_sign_in_enabled` | false | Shows "Continue with Apple" in Settings. Keep false until the Apple provider is enabled in Authentication (Apple Developer account + Apple devices). |
| `announcement_id` / `announcement_text` | empty | Dismissible card on the Home tab (change the id to show it again) |

5. **Cloud Messaging:** announcements use the topic `announcements` (Notifications composer → target topic). Android works as is. For iOS upload an APNs auth key (Project settings → Cloud Messaging).
6. **In-App Messaging:** create a campaign in the console. Messages are suppressed during games and follow the Usage analytics switch.
7. **Alerts:** Crashlytics and Performance → turn on email alerts (crash-free users, regressions).
8. **Harden the API keys** (Google Cloud console → APIs & Services → Credentials): restrict the Android key to package `com.andwati.castlei` with your SHA-1s and the iOS key to the bundle ID.

## What the app sends
See `docs/PRIVACY.md`. Everything is switchable in Settings; nothing contains positions, moves, comments, titles or names.

## Analytics events
`app_open`, `game_started` (difficulty, timed, custom_position), `game_finished` (result, reason, assisted, length bucket, difficulty), `hint_used`, `takeback_used`, `review_started`, `puzzle_completed`, `drill_completed`, `study_created`, `cloud_backup` (result, reason), `backup_restored`, `notifications_permission`, `notification_opened`, `setting_changed`, plus screen views.
