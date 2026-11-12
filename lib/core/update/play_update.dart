import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Optional update prompt via Google Play's In-App Updates API.
///
/// Play shows its own "Update / No thanks" dialog. If the user accepts, the
/// update downloads in the background and a snackbar offers a restart once it
/// is ready. Nothing is ever forced. No-op off Android or when the app was not
/// installed from Play (debug/sideloaded builds).
class PlayUpdate {
  static bool _checked = false;
  static StreamSubscription<InstallStatus>? _sub;

  static Future<void> check(ScaffoldMessengerState messenger) async {
    if (_checked || !io.Platform.isAndroid) return;
    _checked = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable ||
          !info.flexibleUpdateAllowed) {
        return;
      }
      _sub = InAppUpdate.installUpdateListener.listen((status) {
        if (status == InstallStatus.downloaded) {
          _sub?.cancel();
          _sub = null;
          _showRestart(messenger);
        }
      });
      // Throws if the user declines.
      await InAppUpdate.startFlexibleUpdate();
    } catch (_) {
      _sub?.cancel();
      _sub = null;
    }
  }

  static void _showRestart(ScaffoldMessengerState messenger) {
    if (!messenger.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Update ready'),
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: 'Restart',
          onPressed: InAppUpdate.completeFlexibleUpdate,
        ),
      ),
    );
  }
}
