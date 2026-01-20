import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/retention/mission_models.dart';
import '../streaks/streak_service.dart';

class DopamineService {
  DopamineService._();
  static final DopamineService I = DopamineService._();

  final _db = Supabase.instance.client;

  /// Trigger dopamine on dashboard open (check for streaks, PRs, messages, etc.)
  Future<String?> triggerDopamineOnOpen({
    required String userId,
  }) async {
    try {
      // Check for various dopamine triggers
      final streakInfo = await StreakService.instance.getStreakInfo(userId: userId);
      final currentStreak = streakInfo['current_count'] as int? ?? 0;

      String? trigger;
      Map<String, dynamic>? triggerData;

      // Streak milestones
      if (currentStreak > 0 && currentStreak % 7 == 0) {
        trigger = 'streak_milestone';
        triggerData = {
          'streak_count': currentStreak,
          'message': '🔥 $currentStreak-day streak! You\'re unstoppable.',
        };
      } else if (currentStreak > 0 && currentStreak % 3 == 0) {
        trigger = 'streak_progress';
        triggerData = {
          'streak_count': currentStreak,
          'message': 'Great momentum! $currentStreak days strong.',
        };
      }

      // TODO: Check for PRs, new messages, completed missions, etc.

      if (trigger != null) {
        await logDopamineEvent(
          userId: userId,
          dopamineTrigger: trigger,
          triggerData: triggerData,
        );
        return triggerData?['message'] as String?;
      }

      return null;
    } catch (e) {
      debugPrint('Failed to trigger dopamine: $e');
      return null;
    }
  }

  /// Log a dopamine event
  Future<void> logDopamineEvent({
    required String userId,
    String? dopamineTrigger,
    Map<String, dynamic>? triggerData,
    int? engagementDurationSeconds,
  }) async {
    try {
      final event = DopamineOpenEvent(
        id: 'temp',
        userId: userId,
        openedAt: DateTime.now(),
        dopamineTrigger: dopamineTrigger,
        triggerData: triggerData,
        engagementDurationSeconds: engagementDurationSeconds,
      );

      await _db.from('dopamine_open_events').insert(event.toInsertJson());
    } catch (e) {
      debugPrint('Failed to log dopamine event: $e');
    }
  }

  /// Get dopamine triggers for analytics
  Future<List<Map<String, dynamic>>> getDopamineTriggers({
    required String userId,
    int days = 7,
  }) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final res = await _db
          .from('dopamine_open_events')
          .select()
          .eq('user_id', userId)
          .gte('opened_at', cutoff.toUtc().toIso8601String())
          .order('opened_at', ascending: false);

      return (res as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Failed to get dopamine triggers: $e');
      return [];
    }
  }
}
