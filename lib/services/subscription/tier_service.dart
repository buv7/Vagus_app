import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/subscription/tier.dart';

export '../../models/subscription/tier.dart' show TierCheckResult;

/// Server-authoritative tier resolver.
///
/// Always call [currentTier] rather than reading purchase receipts on the
/// client. The server's `get_user_tier` RPC is the single source of truth.
///
/// Enforcement pattern (use everywhere — no `if (user.tier == 'pro')` literals):
/// ```dart
/// final check = await TierService.instance.checkLabwork();
/// if (!check.allowed) {
///   UpgradePromptSheet.show(context, check);
///   return;
/// }
/// // … proceed with lab work
/// ```
class TierService {
  TierService._();
  static final TierService instance = TierService._();

  final _supabase = Supabase.instance.client;

  Tier? _cachedTier;
  DateTime? _cacheExpiry;
  static const _cacheDuration = Duration(minutes: 5);

  void invalidateCache() {
    _cachedTier = null;
    _cacheExpiry = null;
  }

  Future<Tier> currentTier() async {
    if (_cachedTier != null &&
        _cacheExpiry != null &&
        DateTime.now().isBefore(_cacheExpiry!)) {
      return _cachedTier!;
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return Tier.free;

      final result = await _supabase.rpc(
        'get_user_tier',
        params: {'p_user_id': user.id},
      ) as String?;

      final tier = tierFromString(result);
      _cachedTier = tier;
      _cacheExpiry = DateTime.now().add(_cacheDuration);
      return tier;
    } catch (e) {
      debugPrint('TierService: tier resolution failed, defaulting to free. $e');
      return Tier.free;
    }
  }

  Future<TierLimits> currentLimits() async {
    return TierLimits.forTier(await currentTier());
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Enforcement checks — call these at every gate, never inline tier comparisons
  // ────────────────────────────────────────────────────────────────────────────

  /// Returns [TierCheckResult.blocked] when [currentClientCount] is at or above
  /// the tier's client cap.
  Future<TierCheckResult> checkCanAddClient(int currentClientCount) async {
    final limits = await currentLimits();
    if (currentClientCount < limits.maxClients) {
      return const TierCheckResult.ok();
    }
    final tier = await currentTier();
    return TierCheckResult.blocked(
      reason:
          "You've reached the ${limits.maxClients}-client limit on the ${tier.displayName} plan.",
      requiredTier: tier.nextTier,
    );
  }

  /// Gate for AI-generated program insights (BRAIN, WorkoutAI, WeeklyAIInsights).
  Future<TierCheckResult> checkAiInsights() async {
    final limits = await currentLimits();
    if (limits.aiInsightsEnabled) return const TierCheckResult.ok();
    return const TierCheckResult.blocked(
      reason: 'AI program generation is available on Pro and Ultimate plans.',
      requiredTier: Tier.pro,
    );
  }

  /// Gate for lab work file uploads. Called by LABKIT agent.
  Future<TierCheckResult> checkLabwork() async {
    final limits = await currentLimits();
    if (limits.labworkEnabled) return const TierCheckResult.ok();
    return const TierCheckResult.blocked(
      reason: 'Lab work uploads are available on Pro and Ultimate plans.',
      requiredTier: Tier.pro,
    );
  }

  /// Gate for pose detection analysis. Called by POSEKIT agent.
  Future<TierCheckResult> checkPoseDetection() async {
    final limits = await currentLimits();
    if (limits.poseDetectionEnabled) return const TierCheckResult.ok();
    return const TierCheckResult.blocked(
      reason: 'Pose detection is available on Pro and Ultimate plans.',
      requiredTier: Tier.pro,
    );
  }

  /// Gate for advanced wearable connections (Garmin, Whoop, Oura).
  /// Apple Health and Health Connect are always allowed regardless of tier.
  /// Called by WEARABLE-HUB agent.
  Future<TierCheckResult> checkAdvancedWearables() async {
    final limits = await currentLimits();
    if (limits.advancedWearablesEnabled) return const TierCheckResult.ok();
    return const TierCheckResult.blocked(
      reason:
          'Garmin, Whoop, and Oura integrations are available on Pro and Ultimate plans.',
      requiredTier: Tier.pro,
    );
  }

  /// Returns true when the current coach's marketplace posts must carry a
  /// Vagus watermark (i.e., on the Free plan).
  Future<bool> requiresMarketplaceWatermark() async {
    final limits = await currentLimits();
    return !limits.watermarkOptional;
  }
}
