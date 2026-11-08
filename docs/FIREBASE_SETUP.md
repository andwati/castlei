# Firebase setup checklist (project `castlei`)

Done from the command line already: Android app registered with the release + debug SHA fingerprints, storage rules written (`storage.rules`), App Distribution group `owner` created and the first signed build uploaded.

## You still need to do these in the Firebase console
1. **Authentication → Sign-in method:** enable **Google** (and **Apple** for iOS). Then run `./tool/refresh_firebase_config.sh` and rebuild. This pulls the OAuth client IDs into `google-services.json` and `GoogleService-Info.plist` and adds the iOS URL scheme.
2. **Storage → Get started:** choose a location (cannot be changed later) and the pay-as-you-go plan that Firebase now requires for Storage buckets. Then deploy the rules: `firebase deploy --only storage --project castlei`. Until this is done "Back up now" reports that cloud storage is not set up.
3. **App Distribution:** add yourself to the `owner` group (Testers & groups) and install the tester app / open the invite on your phone.
4. **Remote Config:** add these parameters (the app works with the defaults if you skip this) and publish:

| Parameter | Default | Effect |
|---|---|---|
| `engine_max_ms_untimed` | 1000 | Engine thinking cap, untimed games (200–5000) |
| `engine_max_ms_timed` | 2000 | Engine thinking cap, timed games (200–5000) |
| `cloud_backup_enabled` | true | Kill switch for automatic cloud backup |
| `reminders_enabled` | true | Kill switch for local reminders |
| `announcement_id` / `announcement_text` | empty | Dismissible card on the Home tab (change the id to show it again) |

5. **Cloud Messaging:** announcements use the topic `announcements` (Notifications composer → target topic). Android works as is. For iOS upload an APNs auth key (Project settings → Cloud Messaging).
6. **In-App Messaging:** create a campaign in the console. Messages are suppressed during games and follow the Usage analytics switch.
7. **Alerts:** Crashlytics and Performance → turn on email alerts (crash-free users, regressions).
8. **Harden the API keys** (Google Cloud console → APIs & Services → Credentials): restrict the Android key to package `com.andwati.castlei` with your SHA-1s and the iOS key to the bundle ID.

## What the app sends
See `docs/PRIVACY.md`. Everything is switchable in Settings; nothing contains positions, moves, comments, titles or names.

## Analytics events
`app_open`, `game_started` (difficulty, timed, custom_position), `game_finished` (result, reason, assisted, length bucket, difficulty), `hint_used`, `takeback_used`, `review_started`, `puzzle_completed`, `drill_completed`, `study_created`, `cloud_backup` (result, reason), `backup_restored`, `notifications_permission`, `notification_opened`, `setting_changed`, plus screen views.
