enum SubscriptionTier { free, pro, ultimate }

extension SubscriptionTierX on SubscriptionTier {
  String get productId => switch (this) {
        SubscriptionTier.pro => 'vagus_pro_monthly',
        SubscriptionTier.ultimate => 'vagus_ultimate_monthly',
        SubscriptionTier.free => '',
      };

  String get displayName => switch (this) {
        SubscriptionTier.free => 'Free',
        SubscriptionTier.pro => 'Pro',
        SubscriptionTier.ultimate => 'Ultimate',
      };

  /// Max coached clients. -1 = unlimited.
  int get maxClients => switch (this) {
        SubscriptionTier.free => 3,
        SubscriptionTier.pro => 20,
        SubscriptionTier.ultimate => -1,
      };

  bool get isPaid => this != SubscriptionTier.free;

  static SubscriptionTier fromProductId(String productId) => switch (productId) {
        'vagus_pro_monthly' => SubscriptionTier.pro,
        'vagus_ultimate_monthly' => SubscriptionTier.ultimate,
        _ => SubscriptionTier.free,
      };

  static SubscriptionTier fromString(String? s) => switch (s) {
        'pro' => SubscriptionTier.pro,
        'ultimate' => SubscriptionTier.ultimate,
        _ => SubscriptionTier.free,
      };

  String toJson() => name;
}

class SubscriptionState {
  final SubscriptionTier tier;
  final String status; // active | trialing | expired | cancelled
  final DateTime? expiresAt;
  final DateTime? trialEndsAt;
  final bool isTrial;
  final String? platform; // apple | google | manual

  const SubscriptionState({
    required this.tier,
    required this.status,
    this.expiresAt,
    this.trialEndsAt,
    this.isTrial = false,
    this.platform,
  });

  bool get isActive => status == 'active' || status == 'trialing';

  static const free = SubscriptionState(
    tier: SubscriptionTier.free,
    status: 'active',
  );

  factory SubscriptionState.fromMap(Map<String, dynamic> m) {
    // Column names align with TRIAL's schema: plan_code, period_end, is_trial.
    final expiresAt = m['period_end'] != null
        ? DateTime.tryParse(m['period_end'] as String)
        : m['apple_expires_at'] != null
            ? DateTime.tryParse(m['apple_expires_at'] as String)
            : null;
    return SubscriptionState(
      tier: SubscriptionTierX.fromString(m['plan_code'] as String?),
      status: m['status'] as String? ?? 'active',
      expiresAt: expiresAt,
      trialEndsAt: m['is_trial'] == true ? expiresAt : null,
      isTrial: m['is_trial'] as bool? ?? false,
      platform: m['platform'] as String?,
    );
  }
}
