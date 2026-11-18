import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../diagnostics/analytics.dart';
import '../storage/repository.dart';
import 'entitlements.dart';

/// The Play Console in-app product (one-time, non-consumable).
const plusProductId = 'castlei_plus';

enum BillingState { idle, loading, ready, unavailable, purchasing, pending }

/// Google Play billing for Castlei Plus (one-time unlock).
///
/// Client-side only: the result is written to [Entitlements] as a device-local
/// flag (see its notes on why that is acceptable here).
class PlusBilling extends ChangeNotifier {
  PlusBilling._();
  static final instance = PlusBilling._();

  BillingState state = BillingState.idle;
  ProductDetails? product;
  String? message;

  /// Whether Google Play answered. False when the app isn't from Play.
  bool storeReachable = false;

  Repository? _repo;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  String? get price => product?.price;

  /// Starts listening for purchases. Safe to call more than once.
  Future<void> start(Repository repo) async {
    if (_sub != null) return;
    _repo = repo;
    try {
      final iap = InAppPurchase.instance;
      _sub = iap.purchaseStream.listen(
        handle,
        onError: (Object e) => _fail('Purchase failed. Try again later.'),
      );
      storeReachable = await iap.isAvailable();
      if (!storeReachable) {
        _set(BillingState.unavailable);
        return;
      }
      await _loadProduct();
      await syncWithStore();
    } catch (e) {
      debugPrint('Billing unavailable: $e');
      _set(BillingState.unavailable);
    }
  }

  Future<void> _loadProduct() async {
    _set(BillingState.loading);
    final r = await InAppPurchase.instance.queryProductDetails({plusProductId});
    product = r.productDetails.isEmpty ? null : r.productDetails.first;
    _set(product == null ? BillingState.unavailable : BillingState.ready);
  }

  Future<void> buy() async {
    final p = product;
    if (p == null) {
      message = 'Purchases are not available right now.';
      notifyListeners();
      return;
    }
    message = null;
    _set(BillingState.purchasing);
    try {
      final started = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: p),
      );
      if (!started) _set(BillingState.ready);
    } catch (_) {
      _fail('Could not start the purchase.');
    }
  }

  /// Re-delivers past purchases through the purchase stream.
  Future<void> restore() async {
    message = null;
    _set(BillingState.loading);
    try {
      await InAppPurchase.instance.restorePurchases();
      await syncWithStore(userInitiated: true);
    } catch (_) {
      _fail('Could not restore purchases.');
    }
    _set(product == null ? BillingState.unavailable : BillingState.ready);
  }

  /// Checks what the store says we own. Grants when owned; revokes (refund)
  /// only on a successful, definitive answer that does not include Plus.
  Future<void> syncWithStore({bool userInitiated = false}) async {
    final repo = _repo;
    if (repo == null) return;
    try {
      final addition = InAppPurchase.instance
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final r = await addition.queryPastPurchases();
      if (r.error != null) return; // offline or store error: change nothing
      final owned = r.pastPurchases.any(
        (p) =>
            p.productID == plusProductId &&
            p.status != PurchaseStatus.pending &&
            p.status != PurchaseStatus.error,
      );
      await applyOwnership(repo, owned);
      if (userInitiated && !owned) {
        message = 'No previous purchase found for this Google account.';
        notifyListeners();
      }
    } catch (_) {
      // Leave the current entitlement untouched.
    }
  }

  @visibleForTesting
  Future<void> applyOwnership(Repository repo, bool owned) async {
    final e = Entitlements.instance;
    if (e.storePurchase != owned) await e.setStorePurchase(repo, owned);
  }

  /// Handles purchase updates from the store.
  @visibleForTesting
  Future<void> handle(List<PurchaseDetails> updates) async {
    final repo = _repo;
    for (final p in updates) {
      if (p.productID != plusProductId) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          _set(BillingState.pending);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (repo != null) {
            await Entitlements.instance.setStorePurchase(repo, true);
          }
          Analytics.log('plus_purchased');
          message = null;
          _set(BillingState.ready);
        case PurchaseStatus.error:
          Analytics.log('plus_purchase_error');
          _fail('Purchase failed. You were not charged.');
        case PurchaseStatus.canceled:
          _set(BillingState.ready);
      }
      // Unacknowledged purchases are refunded by Play after 3 days.
      if (p.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(p);
        } catch (_) {}
      }
    }
  }

  void _fail(String text) {
    message = text;
    _set(product == null ? BillingState.unavailable : BillingState.ready);
  }

  void _set(BillingState s) {
    state = s;
    notifyListeners();
  }
}
