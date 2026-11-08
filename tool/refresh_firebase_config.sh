#!/usr/bin/env bash
# Re-downloads the Firebase client configs after you enable Google / Apple sign-in
# (or change any Firebase setting) so the apps pick up the new OAuth client IDs.
# Requires: firebase login (firebase-tools), run from anywhere.
set -euo pipefail
cd "$(dirname "$0")/.."
PROJECT=castlei
ANDROID_APP=1:PROJECT_NUMBER:android:REDACTED_APP_ID
IOS_APP=1:PROJECT_NUMBER:ios:REDACTED_APP_ID

rm -f android/app/google-services.json
firebase apps:sdkconfig android "$ANDROID_APP" --out android/app/google-services.json --project "$PROJECT"
rm -f ios/Runner/GoogleService-Info.plist
firebase apps:sdkconfig ios "$IOS_APP" --out ios/Runner/GoogleService-Info.plist --project "$PROJECT"

python3 - <<'PY'
import json, plistlib
a = json.load(open('android/app/google-services.json'))['client'][0]
kinds = [o.get('client_type') for o in a.get('oauth_client', [])]
print('Android OAuth clients:', kinds or 'none (is Google sign-in enabled in Authentication?)')

path = 'ios/Runner/GoogleService-Info.plist'
plist = plistlib.load(open(path, 'rb'))
reversed_id = plist.get('REVERSED_CLIENT_ID')
if not reversed_id:
    print('iOS: no REVERSED_CLIENT_ID yet (enable Google sign-in, then rerun).')
else:
    info_path = 'ios/Runner/Info.plist'
    info = plistlib.load(open(info_path, 'rb'))
    types = [t for t in info.get('CFBundleURLTypes', []) if t.get('CFBundleURLSchemes') != [reversed_id]]
    types.append({'CFBundleTypeRole': 'Editor', 'CFBundleURLSchemes': [reversed_id]})
    info['CFBundleURLTypes'] = types
    plistlib.dump(info, open(info_path, 'wb'))
    print('iOS: Google sign-in URL scheme added to Info.plist')
PY
