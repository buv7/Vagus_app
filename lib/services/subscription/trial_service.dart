import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Where in the 30-day trial the coach currently sits.
enum TrialPhase {
  /// > 7 days remaining — no banner shown yet.
  active,

  /// 3–7 days remaining — banner appears, yellow urgency.
  expiringSoon,

  /// 1–2 days remaining — banner red, more prominent CTA.
  urgentSoon,

  /// Trial period has ended (period_end < now).
  expired,

  /// User is not on a trial (no trialing subscription).
  notInTrial,
}

enum TrialDowngradeReason { price, featuresMissing, didntFit, other }

class TrialStatus {
  final TrialPhase phase;
  final int daysRemaining;
  final DateTime? periodEnd;

  const TrialStatus({
    required this.phase,
    required this.daysRemaining,
    this.periodEnd,
  });

  bool get isTrialing => phase != TrialPhase.notInTrial;

  /// True when the persistent banner should be shown in the coach home UI.
  bool get showBanner =>
      phase == TrialPhase.expiringSoon || phase == TrialPhase.urgentSoon;
}

/// Trial state machine for the 30-day coach onboarding trial.
///
/// Responsibilities:
///  - Activate trial on coach approval.
///  - Surface live status (phase + days remaining).
///  - Downgrade coach to Free — never auto-deletes client relationships.
///  - Capture anonymous exit-survey responses.
///  - Send start/post-downgrade push notifications (SIGNAL stub).
///    Days-23 and days-28 notifications are sent by the expire-trials Edge Fn.
class TrialService {
  TrialService._();
  static final TrialService instance = TrialService._();

  static const int _bannerThresholdDays = 7; // day 23 onward (30 - 7)
  static const int _urgentThresholdDays = 2;
  static const int _freeClientLimit = 2;

  final _sb = Supabase.instance.client;

  // ── Activation ──────────────────────────────────────────────────────────────

  /// Activate a 30-day Pro trial for the currently signed-in coach.
  /// Safe to call multiple times — the RPC is a no-op if a subscription exists.
  Future<void> activateTrial() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _sb.rpc('activate_coach_trial', params: {'p_user_id': uid});
      await _sendPush(uid,
          title: 'Your 30-day Pro trial has started!',
          message:
              'Full Pro access — no card needed. Explore everything for 30 days free.',
          screen: 'billing');
    } catch (e) {
      debugPrint('TrialService.activateTrial: $e');
    }
  }

  // ── Status query ─────────────────────────────────────────────────────────────

  /// Returns current trial status for the signed-in user.
  Future<TrialStatus> getStatus() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) {
      return const TrialStatus(phase: TrialPhase.notInTrial, daysRemaining: 0);
    }

    try {
      final row = await _sb
          .from('subscriptions')
          .select('status, period_end')
          .eq('user_id', uid)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null || row['status'] != 'trialing') {
        return const TrialStatus(
            phase: TrialPhase.notInTrial, daysRemaining: 0);
      }

      final periodEnd =
          DateTime.parse(row['period_end'] as String).toLocal();
      final daysLeft =
          periodEnd.difference(DateTime.now()).inDays.clamp(0, 30);
      final phase = _computePhase(daysLeft, periodEnd);

      return TrialStatus(
          phase: phase, daysRemaining: daysLeft, periodEnd: periodEnd);
    } catch (e) {
      debugPrint('TrialService.getStatus: $e');
      return const TrialStatus(
          phase: TrialPhase.notInTrial, daysRemaining: 0);
    }
  }

  // ── Client-limit helpers ─────────────────────────────────────────────────────

  /// Returns all coach-client rows when the coach exceeds the free-tier limit.
  /// Returns an empty list when the coach is within limit (no intervention needed).
  Future<List<Map<String, dynamic>>> getClientsExceedingFreeLimit() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return [];
    try {
      final rows = await _sb
          .from('coach_clients')
          .select(
              'client_id, profiles!coach_clients_client_id_fkey(id, name, email)')
          .eq('coach_id', uid);

      if ((rows as List).length <= _freeClientLimit) return [];
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('TrialService.getClientsExceedingFreeLimit: $e');
      return [];
    }
  }

  // ── Downgrade ────────────────────────────────────────────────────────────────

  /// Downgrade the coach to the Free tier.
  ///
  /// [clientIdsToRemove] must be supplied when the coach exceeds [_freeClientLimit].
  /// This method will NEVER remove a client that is not in [clientIdsToRemove].
  Future<bool> downgradeToFree({
    List<String> clientIdsToRemove = const [],
  }) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return false;

    try {
      // Remove only the clients the coach explicitly chose to release.
      for (final cid in clientIdsToRemove) {
        await _sb
            .from('coach_clients')
            .delete()
            .eq('coach_id', uid)
            .eq('client_id', cid);
      }

      await _sb.from('subscriptions').update({
        'plan_code': 'free',
        'status': 'canceled',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', uid).eq('status', 'trialing');

      await _sendPush(uid,
          title: 'Your trial has ended',
          message:
              "You're now on the Free plan. Upgrade anytime to restore Pro features.",
          screen: 'billing');

      return true;
    } catch (e) {
      debugPrint('TrialService.downgradeToFree: $e');
      return false;
    }
  }

  // ── Exit survey ──────────────────────────────────────────────────────────────

  /// Persist an anonymous exit survey. No user ID is stored.
  Future<void> submitExitSurvey({
    required TrialDowngradeReason reason,
    String? whatMissing,
    String? otherText,
  }) async {
    try {
      await _sb.from('trial_survey_responses').insert({
        'reason': reason.name,
        'what_missing': whatMissing,
        'other_text': otherText,
      });
    } catch (e) {
      debugPrint('TrialService.submitExitSurvey: $e');
    }
  }

  // ── Internals ────────────────────────────────────────────────────────────────

  TrialPhase _computePhase(int daysLeft, DateTime periodEnd) {
    if (DateTime.now().isAfter(periodEnd)) return TrialPhase.expired;
    if (daysLeft == 0) return TrialPhase.expired;
    if (daysLeft <= _urgentThresholdDays) return TrialPhase.urgentSoon;
    if (daysLeft <= _bannerThresholdDays) return TrialPhase.expiringSoon;
    return TrialPhase.active;
  }

  /// Push notification via the existing send-notification Edge Function.
  /// When SIGNAL ships, replace this body with a SIGNAL call.
  Future<void> _sendPush(String userId,
      {required String title,
      required String message,
      required String screen}) async {
    try {
      await _sb.functions.invoke('send-notification', body: {
        'type': 'user',
        'userId': userId,
        'title': title,
        'message': message,
        'screen': screen,
      });
    } catch (e) {
      debugPrint('TrialService._sendPush: $e');
    }
  }
}
