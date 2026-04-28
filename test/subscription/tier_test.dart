import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/models/subscription/tier.dart';
// TierCheckResult is defined in tier.dart alongside the other model types

void main() {
  group('tierFromString', () {
    test('returns free for null', () {
      expect(tierFromString(null), Tier.free);
    });

    test('returns free for unknown string', () {
      expect(tierFromString('enterprise'), Tier.free);
    });

    test('returns free for empty string', () {
      expect(tierFromString(''), Tier.free);
    });

    test('returns pro for "pro"', () {
      expect(tierFromString('pro'), Tier.pro);
    });

    test('returns ultimate for "ultimate"', () {
      expect(tierFromString('ultimate'), Tier.ultimate);
    });
  });

  group('TierX.displayName', () {
    test('free displays Free', () => expect(Tier.free.displayName, 'Free'));
    test('pro displays Pro', () => expect(Tier.pro.displayName, 'Pro'));
    test('ultimate displays Ultimate', () => expect(Tier.ultimate.displayName, 'Ultimate'));
  });

  group('TierX.price', () {
    test('free is \$0', () => expect(Tier.free.price, '\$0'));
    test('pro is \$9.99/mo', () => expect(Tier.pro.price, '\$9.99/mo'));
    test('ultimate is \$19.99/mo', () => expect(Tier.ultimate.price, '\$19.99/mo'));
  });

  group('TierX.nextTier', () {
    test('free upgrades to pro', () => expect(Tier.free.nextTier, Tier.pro));
    test('pro upgrades to ultimate', () => expect(Tier.pro.nextTier, Tier.ultimate));
    test('ultimate stays ultimate', () => expect(Tier.ultimate.nextTier, Tier.ultimate));
  });

  group('TierLimits.forTier', () {
    test('free limits', () {
      final l = TierLimits.forTier(Tier.free);
      expect(l.maxClients, 2);
      expect(l.watermarkOptional, isFalse);
      expect(l.aiInsightsEnabled, isFalse);
      expect(l.labworkEnabled, isFalse);
      expect(l.poseDetectionEnabled, isFalse);
      expect(l.advancedWearablesEnabled, isFalse);
    });

    test('pro limits', () {
      final l = TierLimits.forTier(Tier.pro);
      expect(l.maxClients, 20);
      expect(l.watermarkOptional, isTrue);
      expect(l.aiInsightsEnabled, isTrue);
      expect(l.labworkEnabled, isTrue);
      expect(l.poseDetectionEnabled, isTrue);
      expect(l.advancedWearablesEnabled, isTrue);
    });

    test('ultimate limits', () {
      final l = TierLimits.forTier(Tier.ultimate);
      expect(l.maxClients, 50);
      expect(l.watermarkOptional, isTrue);
      expect(l.aiInsightsEnabled, isTrue);
      expect(l.labworkEnabled, isTrue);
      expect(l.poseDetectionEnabled, isTrue);
      expect(l.advancedWearablesEnabled, isTrue);
    });

    test('pro has strictly more clients than free', () {
      expect(
        TierLimits.forTier(Tier.pro).maxClients,
        greaterThan(TierLimits.forTier(Tier.free).maxClients),
      );
    });

    test('ultimate has strictly more clients than pro', () {
      expect(
        TierLimits.forTier(Tier.ultimate).maxClients,
        greaterThan(TierLimits.forTier(Tier.pro).maxClients),
      );
    });
  });

  group('TierCheckResult', () {
    test('ok result is allowed', () {
      const r = TierCheckResult.ok();
      expect(r.allowed, isTrue);
      expect(r.reason, isEmpty);
    });

    test('blocked result is not allowed and carries reason + requiredTier', () {
      const r = TierCheckResult.blocked(
        reason: 'Need Pro',
        requiredTier: Tier.pro,
      );
      expect(r.allowed, isFalse);
      expect(r.reason, 'Need Pro');
      expect(r.requiredTier, Tier.pro);
    });
  });
}
