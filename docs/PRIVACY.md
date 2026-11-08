# Privacy summary

Castlei keeps your games, studies, drills and statistics in a local database on your device. An account is optional.

| Data | When | Where | Control |
|---|---|---|---|
| Full backup archive (games, analysis, repertoires, history, preferences) | Only if you sign in and automatic backup is on, or you tap "Back up now" | Your private folder in Firebase Storage, last 5 versions, readable only by you | Settings → Account: switch off, sign out, or delete the account and all cloud backups |
| Sign-in identity (Google / Apple account id, email) | If you sign in | Firebase Authentication | Delete account |
| Crash reports (app and engine version, error type, scrubbed message, stack trace) | Default on | Firebase Crashlytics | Settings → Privacy and diagnostics |
| Performance timings (startup, engine speed, import/backup durations, frame counts) | Default on | Firebase Performance | same |
| Usage analytics (screens, feature use, game results as categories) and in-app announcements | Default on | Firebase Analytics / In-App Messaging | same |
| Push announcements | Default on | Firebase Cloud Messaging topic `announcements` | Settings → Notifications |

Never collected: positions (FEN), moves, PGN, comments, game titles, names, file names or contents. Error messages are scrubbed of FEN strings, PGN headers and file paths before they are sent, and event values are short categories or bucketed counts. Advertising IDs are not collected. Local reminders are scheduled on the device and send nothing.
