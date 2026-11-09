#!/usr/bin/env bash
# Downloads your Firebase client configs (after you enable sign-in providers or
# change a setting) and writes the three local, gitignored files the build uses:
#   android/app/google-services.json, ios/Runner/GoogleService-Info.plist, firebase.env.json
# Requires: firebase login. Configure with environment variables, nothing is hardcoded:
#   FIREBASE_PROJECT_ID  FIREBASE_ANDROID_APP_ID  FIREBASE_IOS_APP_ID
# Afterwards, for CI/release secrets, see docs/RELEASE.md.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${FIREBASE_PROJECT_ID:?set FIREBASE_PROJECT_ID}"
: "${FIREBASE_ANDROID_APP_ID:?set FIREBASE_ANDROID_APP_ID}"
: "${FIREBASE_IOS_APP_ID:?set FIREBASE_IOS_APP_ID}"

rm -f android/app/google-services.json ios/Runner/GoogleService-Info.plist
firebase apps:sdkconfig android "$FIREBASE_ANDROID_APP_ID" --out android/app/google-services.json --project "$FIREBASE_PROJECT_ID"
firebase apps:sdkconfig ios "$FIREBASE_IOS_APP_ID" --out ios/Runner/GoogleService-Info.plist --project "$FIREBASE_PROJECT_ID"

python3 - <<'PY'
import json, plistlib
a = json.load(open('android/app/google-services.json'))
c = a['client'][0]
kinds = [o.get('client_type') for o in c.get('oauth_client', [])]
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
    print('iOS: Google sign-in URL scheme added to Info.plist (do not commit that change)')

env = {
    'FIREBASE_PROJECT_ID': a['project_info']['project_id'],
    'FIREBASE_MESSAGING_SENDER_ID': a['project_info']['project_number'],
    'FIREBASE_STORAGE_BUCKET': a['project_info'].get('storage_bucket', ''),
    'FIREBASE_ANDROID_API_KEY': c['api_key'][0]['current_key'],
    'FIREBASE_ANDROID_APP_ID': c['client_info']['mobilesdk_app_id'],
    'FIREBASE_IOS_API_KEY': plist['API_KEY'],
    'FIREBASE_IOS_APP_ID': plist['GOOGLE_APP_ID'],
    'FIREBASE_IOS_BUNDLE_ID': plist.get('BUNDLE_ID', ''),
}
json.dump(env, open('firebase.env.json', 'w'), indent=2)
print('wrote firebase.env.json; build with --dart-define-from-file=firebase.env.json')
PY
