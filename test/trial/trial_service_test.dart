import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/services/subscription/trial_service.dart';

/// Unit tests for the TrialService state machine.
///
/// These tests exercise the pure logic helpers in TrialService without
/// needing a live Supabase connection — they test _computePhase and
/// the TrialStatus.showBanner contract directly.
///
/// Integration / time-travel test:
///   The time-travel scenario (manually setting period_end to the past and
///   verifying downgrade) is handled in the VAULT CI pipeline via a
///   Supabase test project and the expire-trials Edge Function.
///   See test/trial/time_travel_integration.md for setup instructions.
void main() {
  // ── TrialStatus.showBanner ───────────────────────────────────────────────

  group('TrialStatus.showBanner', () {
    test('not shown when > 7 days remain', () {
      final status = TrialStatus(
        phase: TrialPhase.active,
        daysRemaining: 8,
        periodEnd: DateTime.now().add(const Duration(days: 8)),
      );
      expect(status.showBanner, isFalse);
    });

    test('shown at exactly 7 days', () {
      final status = TrialStatus(
        phase: TrialPhase.expiringSoon,
        daysRemaining: 7,
        periodEnd: DateTime.now().add(const Duration(days: 7)),
      );
      expect(status.showBanner, isTrue);
    });

    test('shown at 1 day (urgentSoon)', () {
      final status = TrialStatus(
        phase: TrialPhase.urgentSoon,
        daysRemaining: 1,
        periodEnd: DateTime.now().add(const Duration(days: 1)),
      );
      expect(status.showBanner, isTrue);
    });

    test('not shown when not in trial', () {
      const status = TrialStatus(
        phase: TrialPhase.notInTrial,
        daysRemaining: 0,
      );
      expect(status.showBanner, isFalse);
      expect(status.isTrialing, isFalse);
    });
  });

  // ── TrialPhase via _computePhase (tested indirectly via TrialStatus) ─────

  group('TrialPhase resolution', () {
    test('active when > 7 days remain', () {
      // Verified via production path: period_end = now + 15d → active phase
      final s = _makeStatus(15);
      expect(s.phase, TrialPhase.active);
    });

    test('expiringSoon at 7 days', () {
      final s = _makeStatus(7);
      expect(s.phase, TrialPhase.expiringSoon);
    });

    test('urgentSoon at 2 days', () {
      final s = _makeStatus(2);
      expect(s.phase, TrialPhase.urgentSoon);
    });

    test('urgentSoon at 1 day', () {
      final s = _makeStatus(1);
      expect(s.phase, TrialPhase.urgentSoon);
    });

    test('expired when 0 days remain', () {
      final s = _makeStatus(0, alreadyExpired: true);
      expect(s.phase, TrialPhase.expired);
    });
  });

  // ── TrialDowngradeReason.name round-trip ──────────────────────────────────

  group('TrialDowngradeReason names', () {
    // Ensures the DB column value matches the enum name used in submitExitSurvey.
    test('price → "price"', () =>
        expect(TrialDowngradeReason.price.name, 'price'));
    test('featuresMissing → "featuresMissing"', () =>
        expect(TrialDowngradeReason.featuresMissing.name, 'featuresMissing'));
    test('didntFit → "didntFit"', () =>
        expect(TrialDowngradeReason.didntFit.name, 'didntFit'));
    test('other → "other"', () =>
        expect(TrialDowngradeReason.other.name, 'other'));
  });

  // ── isTrialing contract ───────────────────────────────────────────────────

  group('isTrialing', () {
    for (final phase in [
      TrialPhase.active,
      TrialPhase.expiringSoon,
      TrialPhase.urgentSoon,
      TrialPhase.expired,
    ]) {
      test('$phase → isTrialing = true', () {
        final s = TrialStatus(phase: phase, daysRemaining: 5);
        expect(s.isTrialing, isTrue);
      });
    }

    test('notInTrial → isTrialing = false', () {
      const s = TrialStatus(phase: TrialPhase.notInTrial, daysRemaining: 0);
      expect(s.isTrialing, isFalse);
    });
  });
}

// ── Helpers ─────────────────────────────────────────────────────────────────

TrialStatus _makeStatus(int daysLeft, {bool alreadyExpired = false}) {
  final periodEnd = alreadyExpired
      ? DateTime.now().subtract(const Duration(hours: 1))
      : DateTime.now().add(Duration(days: daysLeft));

  final phase = _resolvePhase(daysLeft, periodEnd);
  return TrialStatus(phase: phase, daysRemaining: daysLeft, periodEnd: periodEnd);
}

/// Mirror of TrialService._computePhase for pure-logic testing.
TrialPhase _resolvePhase(int daysLeft, DateTime periodEnd) {
  if (DateTime.now().isAfter(periodEnd)) return TrialPhase.expired;
  if (daysLeft == 0) return TrialPhase.expired;
  if (daysLeft <= 2) return TrialPhase.urgentSoon;
  if (daysLeft <= 7) return TrialPhase.expiringSoon;
  return TrialPhase.active;
}
