# Contributing to Castlei

Thanks for helping. Castlei is a private-by-design chess app: no ads, no tracking beyond the optional crash and usage reports, and it must keep working fully offline. Contributions should respect that.

## Before you start
- For anything bigger than a small fix, open an issue first so we can agree on the approach.
- Security problems: do **not** open an issue; see [SECURITY.md](SECURITY.md).
- By taking part you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Set up
Follow [docs/BUILDING.md](docs/BUILDING.md). You do not need a Firebase project; without one, sign-in, cloud backup and reports are simply off. **Never commit** `firebase.env.json`, `google-services.json`, `GoogleService-Info.plist`, `key.properties`, keystores or any token. They are gitignored; CI also scans for secrets.

## Making a change
1. Fork, then branch from `main` (`fix/short-name` or `feat/short-name`).
2. Keep changes focused. Match the existing style; the code is formatted with `dart format`.
3. Before opening a pull request, run:
   ```
   dart format lib test tool
   flutter analyze
   flutter test
   ```
   Changes to the engine adapter (`native/`) should also pass `python3 tool/native_smoke.py`.
4. Add or update tests for behaviour you change. UI changes: include a screenshot (light and dark if relevant).
5. User-facing data handling (what is stored or sent) must be reflected in `docs/PRIVACY.md` and, if it changes, flagged in the PR so the privacy policy can be updated.

## Commits and pull requests
- Write commit messages in the imperative, one subject line (under about 72 characters) and a body explaining why.
- **Sign off** each commit (`git commit -s`) to certify the [Developer Certificate of Origin](https://developercertificate.org/). There is no CLA.
- Contributions are licensed under GPL-3.0, like the rest of the project. Only submit code you have the right to submit, and note the license of anything you copy.
- One CI run at a time is used for the whole repository; a new push cancels the previous run. Expect to wait a few minutes.

## Good first areas
Accessibility, translations, test coverage, documentation, and puzzle/opening data quality.

## Dependencies
Update packages with `./tool/update_deps.sh` (Flutter's `pub` tooling; it keeps the change only if format, analyze and tests pass). Please do not hand-edit `pubspec.lock`. Automated bots are not used.
