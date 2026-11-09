#!/usr/bin/env bash
# Updates the Dart/Flutter dependencies with Flutter's own tooling and keeps the
# result only if everything still passes; otherwise it restores pubspec.yaml and
# pubspec.lock. Review the diff, then commit.
#   ./tool/update_deps.sh          # newest versions allowed by pubspec.yaml
#   ./tool/update_deps.sh --major  # also raise the version constraints (major bumps)
# The Flutter SDK itself is changed through the FLUTTER_VERSION repository variable
# (docs/TOOLCHAIN.md); Gradle and the Android plugin follow the Flutter template.
set -euo pipefail
cd "$(dirname "$0")/.."

git diff --quiet -- pubspec.yaml pubspec.lock || { echo "pubspec.yaml/pubspec.lock have uncommitted changes; commit or stash first."; exit 2; }

echo "== Outdated before"
flutter pub outdated || true

if [ "${1:-}" = "--major" ]; then flutter pub upgrade --major-versions; else flutter pub upgrade; fi

restore() { git checkout -- pubspec.yaml pubspec.lock; flutter pub get >/dev/null; echo "Update rejected; pubspec.yaml and pubspec.lock restored."; }
trap 'restore' ERR

dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
python3 tool/native_smoke.py >/dev/null 2>&1 || true   # engine adapter is unaffected by pub packages

trap - ERR
echo "== Updated and verified. Changes:"
git diff --stat -- pubspec.yaml pubspec.lock
echo "Now build a release APK on a device to be safe, then commit."
