import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/logger.dart';
import 'iap_interface.dart';

class GoogleIapService implements IapService {
  static const _tag = 'GoogleIapService';

  final InAppPurchase _iap = InAppPurchase.instance;
  final SupabaseClient _supabase;

  final _stateController = StreamController<SubscriptionState>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  GoogleIapService(this._supabase);

  @override
  Stream<SubscriptionState> get subscriptionStream => _stateController.stream;

  @override
  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) {
      Logger.warning('$_tag: Google Play Billing not available on this device');
      _stateController.add(SubscriptionState.free);
      return;
    }

    _purchaseSub = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object e, StackTrace st) =>
          Logger.error('$_tag: purchaseStream error', error: e, stackTrace: st),
    );

    _stateController.add(await currentState());
  }

  @override
  Future<List<ProductDetails>> fetchProducts(List<String> productIds) async {
    final response = await _iap.queryProductDetails(productIds.toSet());
    if (response.error != null) {
      Logger.error('$_tag: queryProductDetails failed',
          error: response.error, data: {'ids': productIds});
    }
    return response.productDetails;
  }

  @override
  Future<void> purchase(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    // Subscriptions are non-consumable from the app's perspective
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  @override
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  @override
  Future<SubscriptionState> currentState() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return SubscriptionState.free;

    try {
      final row = await _supabase
          .from('subscriptions')
          .select('plan_code, status, period_end')
          .eq('user_id', userId)
          .eq('store', 'google')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null) return SubscriptionState.free;

      final status = _parseStatus(row['status'] as String?);
      final tier = _parseTier(row['plan_code'] as String?);
      final expiresAt = row['period_end'] != null
          ? DateTime.tryParse(row['period_end'] as String)
          : null;

      // Treat as expired if past period_end regardless of stored status
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        return SubscriptionState(
          tier: SubscriptionTier.free,
          status: SubscriptionStatus.expired,
          expiresAt: expiresAt,
          store: IapStore.google,
        );
      }

      return SubscriptionState(
        tier: tier,
        status: status,
        expiresAt: expiresAt,
        store: IapStore.google,
        isTrialing: status == SubscriptionStatus.trialing,
      );
    } catch (e, st) {
      Logger.error('$_tag: currentState failed', error: e, stackTrace: st);
      return SubscriptionState.free;
    }
  }

  @override
  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    await _stateController.close();
  }

  // ---------------------------------------------------------------------------

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _validateAndSync(purchase);
        case PurchaseStatus.pending:
          Logger.info('$_tag: purchase pending',
              data: {'productId': purchase.productID});
        case PurchaseStatus.error:
          Logger.error('$_tag: purchase error', error: purchase.error);
          _stateController.add(SubscriptionState.free);
        case PurchaseStatus.canceled:
          Logger.info('$_tag: purchase cancelled');
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _validateAndSync(PurchaseDetails purchase) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (purchase is! GooglePlayPurchaseDetails) {
      Logger.warning('$_tag: unexpected non-Google purchase on Android');
      return;
    }

    final token = purchase.billingClientPurchase.purchaseToken;
    final packageName = purchase.billingClientPurchase.packageName;

    try {
      await _supabase.functions.invoke(
        'validate-google-receipt',
        body: {
          'userId': userId,
          'purchaseToken': token,
          'productId': purchase.productID,
          'packageName': packageName,
        },
      );

      final state = await currentState();
      _stateController.add(state);
      Logger.info('$_tag: subscription synced',
          data: {'tier': state.tier.name, 'status': state.status.name});
    } on FunctionException catch (e, st) {
      Logger.error('$_tag: validation edge function failed',
          error: e, stackTrace: st);
    } catch (e, st) {
      Logger.error('$_tag: _validateAndSync failed', error: e, stackTrace: st);
    }
  }

  SubscriptionStatus _parseStatus(String? raw) => switch (raw) {
        'active' => SubscriptionStatus.active,
        'trialing' => SubscriptionStatus.trialing,
        'past_due' => SubscriptionStatus.pastDue,
        'canceled' => SubscriptionStatus.canceled,
        'expired' => SubscriptionStatus.expired,
        _ => SubscriptionStatus.expired,
      };

  SubscriptionTier _parseTier(String? planCode) => switch (planCode) {
        kVagusProMonthly => SubscriptionTier.pro,
        kVagusUltimateMonthly => SubscriptionTier.ultimate,
        _ => SubscriptionTier.free,
      };
}
