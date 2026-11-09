#!/usr/bin/env bash
# One-time setup for a fresh checkout: creates the placeholder native Firebase
# files the Android and iOS builds expect, so the app builds and runs with no
# Firebase project (sign-in, cloud backup, crash reports and analytics are then
# unavailable). To use your own Firebase project see docs/BUILDING.md.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f android/app/google-services.json ]; then
  cat > android/app/google-services.json <<'JSON'
{"project_info":{"project_number":"0","project_id":"placeholder"},"client":[{"client_info":{"mobilesdk_app_id":"1:0:android:0","android_client_info":{"package_name":"com.andwati.castlei"}},"api_key":[{"current_key":"placeholder"}]}],"configuration_version":"1"}
JSON
  echo "created android/app/google-services.json (placeholder)"
fi

if [ ! -f ios/Runner/GoogleService-Info.plist ]; then
  cat > ios/Runner/GoogleService-Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>API_KEY</key><string>placeholder</string>
<key>GCM_SENDER_ID</key><string>0</string>
<key>BUNDLE_ID</key><string>com.andwati.castlei</string>
<key>PROJECT_ID</key><string>placeholder</string>
<key>GOOGLE_APP_ID</key><string>1:0:ios:0</string>
</dict></plist>
PLIST
  echo "created ios/Runner/GoogleService-Info.plist (placeholder)"
fi
