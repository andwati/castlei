import 'package:flutter/foundation.dart';

import '../storage/repository.dart';

/// What cloud backup does for free and with Castlei Plus.
///  - Free: manual "Back up now" only, the latest backup is kept.
///  - Plus: automatic backups (after finished games and daily) and 5 versions.
class BackupPolicy {
  const BackupPolicy({required this.keep, required this.automatic});
  final int keep;
  final bool automatic;
}

BackupPolicy backupPolicy({required bool plus}) => plus
    ? const BackupPolicy(keep: 5, automatic: true)
    : const BackupPolicy(keep: 1, automatic: false);

/// Whether this install has Castlei Plus.
///
/// Today the app checks this itself (an app that is open source cannot hide a
/// check from a modified copy, so the security rules also cap backup size).
/// Store purchases are not connected yet; a hidden test unlock (tap the
/// version in Settings seven times) lets the paid features be exercised.
/// These flags are device-local and deliberately excluded from backups.
class Entitlements extends ChangeNotifier {
  Entitlements._();
  static final instance = Entitlements._();

  bool _store = false, _test = false;
  bool get plus => _store || _test;
  bool get testUnlock => _test;
  bool get storePurchase => _store;
  BackupPolicy get backup => backupPolicy(plus: plus);

  Future<void> load(Repository repo) async {
    _store = await repo.preference('plusStore', false) == true;
    _test = await repo.preference('plusTest', false) == true;
    notifyListeners();
  }

  Future<void> setTestUnlock(Repository repo, bool value) async {
    _test = value;
    await repo.setPreference('plusTest', value);
    notifyListeners();
  }

  /// Called by store billing once it exists.
  Future<void> setStorePurchase(Repository repo, bool value) async {
    _store = value;
    await repo.setPreference('plusStore', value);
    notifyListeners();
  }
}
