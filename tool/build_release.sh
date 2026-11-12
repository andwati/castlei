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

built=build/app/outputs/bundle/release/app-release.aab

# Gradle always writes app-release.aab; keep a copy named after the version so it is
# obvious which release a file is (castlei-1.1.2+10.aab).
version=$(sed -n 's/^version: *//p' pubspec.yaml | head -1 | tr -d '[:space:]')
mkdir -p build/release
aab="build/release/castlei-${version}.aab"
cp -f "$built" "$aab"

echo
echo "Version $version"
echo "Built $aab ($(du -h "$aab" | cut -f1))"
echo "Signing certificate:"
keytool -printcert -jarfile "$aab" | grep SHA256
echo "Compare with the upload fingerprint in docs/RELEASE.md."
