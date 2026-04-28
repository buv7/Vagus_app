import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/subscription/tier.dart';
import 'tier_service.dart';

class AppleIAPService {
  static const String _proId = 'vagus_pro_monthly';
  static const String _ultimateId = 'vagus_ultimate_monthly';
  static const Set<String> productIds = {_proId, _ultimateId};

  static final AppleIAPService instance = AppleIAPService._();
  AppleIAPService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  // Publicly readable stream of purchase results for UI feedback
  final _purchaseResultController =
      StreamController<IAPPurchaseResult>.broadcast();
  Stream<IAPPurchaseResult> get purchaseResultStream =>
      _purchaseResultController.stream;

  /// Call once from main() after WidgetsFlutterBinding.ensureInitialized().
  Future<void> init() async {
    if (!Platform.isIOS && !Platform.isMacOS) return;

    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('IAP: StoreKit not available');
      return;
    }

    // Present app-store sheet for incomplete transactions on cold start.
    await _iap
        .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>()
        .setDelegate(VagusPaymentQueueDelegate.instance);

    _purchaseSub = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object e) =>
          debugPrint('IAP: purchase stream error: $e'),
    );
  }

  /// Returns available products from the App Store.
  Future<List<ProductDetails>> fetchProducts() async {
    final response =
        await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      debugPrint('IAP: product query error: ${response.error}');
    }
    return response.productDetails;
  }

  /// Initiates a subscription purchase. Throws on invalid state.
  Future<void> buy(ProductDetails product) async {
    if (!productIds.contains(product.id)) {
      throw ArgumentError('Unknown product: ${product.id}');
    }
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Restores previous purchases (required by App Store guidelines).
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _purchaseSub?.cancel();
    _purchaseResultController.close();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndSync(purchase);

        case PurchaseStatus.error:
          _purchaseResultController.add(IAPPurchaseResult.error(
            purchase.error?.message ?? 'Purchase failed',
          ));
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }

        case PurchaseStatus.canceled:
          _purchaseResultController
              .add(const IAPPurchaseResult.cancelled());
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }

        case PurchaseStatus.pending:
          // Waiting on family-sharing approval / Ask-to-Buy — do nothing.
          break;
      }
    }
  }

  Future<void> _verifyAndSync(PurchaseDetails purchase) async {
    try {
      // Retrieve the raw App Store receipt (base64).
      final receiptData = await SKReceiptManager.retrieveReceiptData();

      if (receiptData == null || receiptData.isEmpty) {
        _purchaseResultController.add(
            const IAPPurchaseResult.error('Empty receipt — cannot verify'));
        return;
      }

      // Server-side validation (server is authority — never grant access
      // based on client-side receipt alone).
      final response = await Supabase.instance.client.functions.invoke(
        'validate-apple-receipt',
        body: {
          'receipt_data': receiptData,
          'product_id': purchase.productID,
        },
      );

      if (response.status != 200) {
        final msg =
            (response.data as Map?)?['error'] ?? 'Validation failed';
        _purchaseResultController
            .add(IAPPurchaseResult.error(msg.toString()));
        return;
      }

      // Refresh local tier state.
      await TierService.instance.refresh();

      final tier = TierService.instance.currentState.tier;
      _purchaseResultController
          .add(IAPPurchaseResult.success(tier, purchase.status));
    } catch (e) {
      _purchaseResultController
          .add(IAPPurchaseResult.error('Verification error: $e'));
    } finally {
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// StoreKit payment queue delegate — required for promoted in-app purchases
// ---------------------------------------------------------------------------

class VagusPaymentQueueDelegate
    implements SKPaymentQueueDelegateWrapper {
  VagusPaymentQueueDelegate._();
  static final VagusPaymentQueueDelegate instance =
      VagusPaymentQueueDelegate._();

  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction,
      SKStorefrontWrapper storefront) =>
      true;

  @override
  bool shouldShowPriceConsent() => false;
}

// ---------------------------------------------------------------------------
// Purchase result value type — public so UI can pattern-match on it
// ---------------------------------------------------------------------------

class IAPPurchaseResult {
  final bool success;
  final bool cancelled;
  final String? error;
  final SubscriptionTier? tier;
  final PurchaseStatus? status;

  const IAPPurchaseResult._({
    required this.success,
    required this.cancelled,
    this.error,
    this.tier,
    this.status,
  });

  const IAPPurchaseResult.success(SubscriptionTier t, PurchaseStatus s)
      : this._(
          success: true,
          cancelled: false,
          tier: t,
          status: s,
        );

  const IAPPurchaseResult.cancelled()
      : this._(success: false, cancelled: true);

  const IAPPurchaseResult.error(String msg)
      : this._(success: false, cancelled: false, error: msg);
}

