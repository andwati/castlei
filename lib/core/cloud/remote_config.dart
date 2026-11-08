import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Server-tunable values with safe in-app defaults. Works offline: the app
/// always has defaults and uses the last fetched values when they exist.
class RemoteSettings {
  static bool available = false;

  static const defaults = <String, Object>{
    'engine_max_ms_untimed': 1000,
    'engine_max_ms_timed': 2000,
    'cloud_backup_enabled': true,
    'reminders_enabled': true,
    // Off until the Apple Developer account and Apple devices exist.
    'apple_sign_in_enabled': false,
    'announcement_id': '',
    'announcement_text': '',
  };

  static Future<void> start() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 12),
        ),
      );
      await rc.setDefaults(defaults);
      available = true;
      // Never block startup on the network.
      rc.fetchAndActivate().catchError((_) => false);
    } catch (e) {
      available = false;
    }
  }

  static int _int(String key) => available
      ? FirebaseRemoteConfig.instance.getInt(key)
      : defaults[key] as int;
  static bool _bool(String key) => available
      ? FirebaseRemoteConfig.instance.getBool(key)
      : defaults[key] as bool;
  static String _string(String key) => available
      ? FirebaseRemoteConfig.instance.getString(key)
      : defaults[key] as String;

  /// Engine thinking-time caps, clamped so a bad value cannot break play.
  static int get engineMaxMsUntimed =>
      _int('engine_max_ms_untimed').clamp(200, 5000);
  static int get engineMaxMsTimed =>
      _int('engine_max_ms_timed').clamp(200, 5000);
  static bool get cloudBackupEnabled => _bool('cloud_backup_enabled');
  static bool get remindersEnabled => _bool('reminders_enabled');
  static bool get appleSignInEnabled => _bool('apple_sign_in_enabled');
  static String get announcementId => _string('announcement_id');
  static String get announcementText => _string('announcement_text');
}
