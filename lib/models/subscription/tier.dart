// Subscription tier enum, limits, and enforcement result types.
// Server is the authority on a user's current tier — never derive it
// client-side from purchase receipts. Always call TierService.currentTier().

enum Tier { free, pro, ultimate }

Tier tierFromString(String? s) {
  switch (s) {
    case 'pro':
      return Tier.pro;
    case 'ultimate':
      return Tier.ultimate;
    default:
      return Tier.free;
  }
}

extension TierX on Tier {
  String get displayName {
    switch (this) {
      case Tier.free:
        return 'Free';
      case Tier.pro:
        return 'Pro';
      case Tier.ultimate:
        return 'Ultimate';
    }
  }

  String get price {
    switch (this) {
      case Tier.free:
        return '\$0';
      case Tier.pro:
        return '\$9.99/mo';
      case Tier.ultimate:
        return '\$19.99/mo';
    }
  }

  Tier get nextTier {
    switch (this) {
      case Tier.free:
        return Tier.pro;
      case Tier.pro:
        return Tier.ultimate;
      case Tier.ultimate:
        return Tier.ultimate;
    }
  }
}

class TierLimits {
  final int maxClients;

  /// false = watermark is mandatory on marketplace posts.
  final bool watermarkOptional;

  final bool aiInsightsEnabled;
  final bool labworkEnabled;
  final bool poseDetectionEnabled;

  /// false = only Apple Health / Health Connect allowed.
  final bool advancedWearablesEnabled;

  const TierLimits({
    required this.maxClients,
    required this.watermarkOptional,
    required this.aiInsightsEnabled,
    required this.labworkEnabled,
    required this.poseDetectionEnabled,
    required this.advancedWearablesEnabled,
  });

  static const TierLimits _free = TierLimits(
    maxClients: 2,
    watermarkOptional: false,
    aiInsightsEnabled: false,
    labworkEnabled: false,
    poseDetectionEnabled: false,
    advancedWearablesEnabled: false,
  );

  static const TierLimits _pro = TierLimits(
    maxClients: 20,
    watermarkOptional: true,
    aiInsightsEnabled: true,
    labworkEnabled: true,
    poseDetectionEnabled: true,
    advancedWearablesEnabled: true,
  );

  static const TierLimits _ultimate = TierLimits(
    maxClients: 50,
    watermarkOptional: true,
    aiInsightsEnabled: true,
    labworkEnabled: true,
    poseDetectionEnabled: true,
    advancedWearablesEnabled: true,
  );

  static TierLimits forTier(Tier tier) {
    switch (tier) {
      case Tier.free:
        return _free;
      case Tier.pro:
        return _pro;
      case Tier.ultimate:
        return _ultimate;
    }
  }
}

/// Result returned by every TierService.check* method.
class TierCheckResult {
  final bool allowed;

  /// Human-readable reason shown to the user when [allowed] is false.
  final String reason;

  /// The minimum tier required to unlock the blocked feature.
  final Tier requiredTier;

  const TierCheckResult._({
    required this.allowed,
    required this.reason,
    required this.requiredTier,
  });

  const TierCheckResult.ok()
      : allowed = true,
        reason = '',
        requiredTier = Tier.free;

  const TierCheckResult.blocked({
    required String reason,
    required Tier requiredTier,
  }) : this._(allowed: false, reason: reason, requiredTier: requiredTier);
}
