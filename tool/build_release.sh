#!/usr/bin/env bash
# Builds the Google Play bundle exactly as docs/RELEASE.md describes, and refuses
# to produce a bundle that would ship with accounts, backup and feedback disabled.
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f firebase.env.json ] || { echo "firebase.env.json is missing: this bundle would ship without accounts, backup, feedback or analytics." >&2; exit 1; }
[ -f android/key.properties ] || { echo "android/key.properties is missing: the bundle would be signed with the debug key." >&2; exit 1; }

flutter build appbundle --release \
  --target-platform android-arm64,android-x64 \
  --dart-define-from-file=firebase.env.json

aab=build/app/outputs/bundle/release/app-release.aab
echo
echo "Built $aab ($(du -h "$aab" | cut -f1))"
echo "Signing certificate:"
keytool -printcert -jarfile "$aab" | grep SHA256
echo "Compare with the upload fingerprint in docs/RELEASE.md."
