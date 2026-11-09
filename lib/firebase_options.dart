// Firebase client configuration, read from build-time environment values so no
// project identifiers live in the repository.
//
// Pass them with `--dart-define-from-file=firebase.env.json` (gitignored; see
// firebase.env.example.json and docs/BUILDING.md). When they are absent the app
// still works: sign-in, cloud backup, crash reports and analytics are simply
// unavailable.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.andwati.castlei',
  );

  /// True when this build was given Firebase values for the current platform.
  static bool get isConfigured {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidApiKey.isNotEmpty &&
            _androidAppId.isNotEmpty &&
            _projectId.isNotEmpty;
      case TargetPlatform.iOS:
        return _iosApiKey.isNotEmpty &&
            _iosAppId.isNotEmpty &&
            _projectId.isNotEmpty;
      default:
        return false;
    }
  }

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw UnsupportedError('Firebase is not configured for this build.');
    }
    return defaultTargetPlatform == TargetPlatform.iOS ? ios : android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _androidApiKey,
    appId: _androidAppId,
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _iosApiKey,
    appId: _iosAppId,
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: _iosBundleId,
  );
}
