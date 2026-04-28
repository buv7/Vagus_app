import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/models/subscription/tier.dart';

/// Pure-logic tests for enforcement rules that don't require Supabase.
/// TierService network calls are exercised in integration tests; here we
/// verify the limit arithmetic and TierCheckResult contract directly.

void main() {
  group('client count enforcement logic', () {
    // Simulate what TierService.checkCanAddClient does, using limits directly.
    TierCheckResult _check(Tier tier, int currentCount) {
      final limits = TierLimits.forTier(tier);
      if (currentCount < limits.maxClients) return const TierCheckResult.ok();
      return TierCheckResult.blocked(
        reason: 'Limit reached',
        requiredTier: tier.nextTier,
      );
    }

    test('free: adding client 1 is allowed', () {
      expect(_check(Tier.free, 0).allowed, isTrue);
    });

    test('free: adding client 2 is allowed', () {
      expect(_check(Tier.free, 1).allowed, isTrue);
    });

    test('free: adding client 3 is blocked', () {
      final r = _check(Tier.free, 2);
      expect(r.allowed, isFalse);
      expect(r.requiredTier, Tier.pro);
    });

    test('pro: adding client 20 is allowed', () {
      expect(_check(Tier.pro, 19).allowed, isTrue);
    });

    test('pro: adding client 21 is blocked and suggests ultimate', () {
      final r = _check(Tier.pro, 20);
      expect(r.allowed, isFalse);
      expect(r.requiredTier, Tier.ultimate);
    });

    test('ultimate: adding client 50 is allowed', () {
      expect(_check(Tier.ultimate, 49).allowed, isTrue);
    });

    test('ultimate: adding client 51 is blocked (stays ultimate)', () {
      final r = _check(Tier.ultimate, 50);
      expect(r.allowed, isFalse);
      expect(r.requiredTier, Tier.ultimate);
    });
  });

  group('feature flag gates', () {
    bool _canAi(Tier t) => TierLimits.forTier(t).aiInsightsEnabled;
    bool _canLab(Tier t) => TierLimits.forTier(t).labworkEnabled;
    bool _canPose(Tier t) => TierLimits.forTier(t).poseDetectionEnabled;
    bool _canWear(Tier t) => TierLimits.forTier(t).advancedWearablesEnabled;
    bool _noWatermark(Tier t) => TierLimits.forTier(t).watermarkOptional;

    test('free blocks AI, lab, pose, wearable; mandates watermark', () {
      expect(_canAi(Tier.free), isFalse);
      expect(_canLab(Tier.free), isFalse);
      expect(_canPose(Tier.free), isFalse);
      expect(_canWear(Tier.free), isFalse);
      expect(_noWatermark(Tier.free), isFalse);
    });

    test('pro enables all features and removes watermark', () {
      expect(_canAi(Tier.pro), isTrue);
      expect(_canLab(Tier.pro), isTrue);
      expect(_canPose(Tier.pro), isTrue);
      expect(_canWear(Tier.pro), isTrue);
      expect(_noWatermark(Tier.pro), isTrue);
    });

    test('ultimate enables all features and removes watermark', () {
      expect(_canAi(Tier.ultimate), isTrue);
      expect(_canLab(Tier.ultimate), isTrue);
      expect(_canPose(Tier.ultimate), isTrue);
      expect(_canWear(Tier.ultimate), isTrue);
      expect(_noWatermark(Tier.ultimate), isTrue);
    });
  });
}
