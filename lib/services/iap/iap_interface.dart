import 'package:in_app_purchase/in_app_purchase.dart';

const kVagusProMonthly = 'vagus_pro_monthly';
const kVagusUltimateMonthly = 'vagus_ultimate_monthly';

const kIapProductIds = {kVagusProMonthly, kVagusUltimateMonthly};

enum IapStore { apple, google }

enum SubscriptionTier { free, pro, ultimate }

enum SubscriptionStatus { trialing, active, pastDue, canceled, expired }

class SubscriptionState {
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime? expiresAt;
  final IapStore? store;
  final bool isTrialing;

  const SubscriptionState({
    required this.tier,
    required this.status,
    this.expiresAt,
    this.store,
    this.isTrialing = false,
  });

  static const free = SubscriptionState(
    tier: SubscriptionTier.free,
    status: SubscriptionStatus.active,
  );

  bool get hasAccess =>
      status == SubscriptionStatus.active ||
      status == SubscriptionStatus.trialing;

  bool get isPro => tier == SubscriptionTier.pro && hasAccess;
  bool get isUltimate => tier == SubscriptionTier.ultimate && hasAccess;
}

abstract class IapService {
  /// Initialise listeners. Call once at startup.
  Future<void> init();

  /// Fetch product details for the given product IDs from the store.
  Future<List<ProductDetails>> fetchProducts(List<String> productIds);

  /// Initiate a purchase flow for [product].
  Future<void> purchase(ProductDetails product);

  /// Stream of subscription state changes (fires on purchase / restore / expiry).
  Stream<SubscriptionState> get subscriptionStream;

  /// Return the current subscription state for the signed-in user.
  Future<SubscriptionState> currentState();

  /// Restore prior purchases (required on iOS; available on Google too).
  Future<void> restorePurchases();

  /// Release stream subscriptions and resources.
  Future<void> dispose();
}
