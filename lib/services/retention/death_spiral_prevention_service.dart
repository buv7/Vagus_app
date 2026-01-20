import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/retention/mission_models.dart';
import '../streaks/streak_service.dart';

class DeathSpiralPreventionService {
  DeathSpiralPreventionService._();
  static final DeathSpiralPreventionService I = DeathSpiralPreventionService._();

  final _db = Supabase.instance.client;

  /// Detect if a day was missed and trigger prevention
  Future<void> detectMissedDay({
    required String userId,
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final day = DateTime(targetDate.year, targetDate.month, targetDate.day);

      // Check if day is compliant
      final isCompliant = await StreakService.instance.isDayCompliant(
        date: day,
        userId: userId,
      );

      if (isCompliant) return; // No action needed

      // Check if prevention already logged for this date
      final existing = await _db
          .from('death_spiral_prevention_logs')
          .select()
          .eq('user_id', userId)
          .eq('missed_date', day.toIso8601String().substring(0, 10))
          .maybeSingle();

      if (existing != null) return; // Already handled

      // Get streak info
      final streakInfo = await StreakService.instance.getStreakInfo(userId: userId);
      final currentStreak = streakInfo['current_count'] as int? ?? 0;

      // Determine prevention action based on streak
      PreventionAction action;
      Map<String, dynamic> actionData;

      if (currentStreak >= 7) {
        // High streak - use streak protection
        action = PreventionAction.streakProtection;
        actionData = {
          'message': 'You\'ve built a $currentStreak-day streak. Don\'t let one missed day break it. Come back tomorrow!',
          'streak_count': currentStreak,
        };
      } else if (currentStreak >= 3) {
        // Medium streak - encouragement
        action = PreventionAction.encouragement;
        actionData = {
          'message': 'You\'re on a $currentStreak-day streak. One day off is fine—just come back tomorrow!',
          'streak_count': currentStreak,
        };
      } else {
        // Low streak - reminder
        action = PreventionAction.reminder;
        actionData = {
          'message': 'Missed today? No worries. Small steps build big habits. Try again tomorrow!',
        };
      }

      // Log prevention action
      await logPreventionAction(
        userId: userId,
        missedDate: day,
        preventionAction: action,
        actionData: actionData,
      );
    } catch (e) {
      debugPrint('Failed to detect missed day: $e');
    }
  }

  /// Log a prevention action
  Future<void> logPreventionAction({
    required String userId,
    required DateTime missedDate,
    required PreventionAction preventionAction,
    Map<String, dynamic>? actionData,
  }) async {
    try {
      final log = DeathSpiralPreventionLog(
        id: 'temp',
        userId: userId,
        missedDate: missedDate,
        preventionAction: preventionAction,
        actionData: actionData,
        actionTakenAt: DateTime.now(),
        success: null,
        createdAt: DateTime.now(),
      );

      await _db.from('death_spiral_prevention_logs').insert(log.toInsertJson());
    } catch (e) {
      debugPrint('Failed to log prevention action: $e');
    }
  }

  /// Get prevention actions for a user
  Future<List<DeathSpiralPreventionLog>> getPreventionActions({
    required String userId,
    int limit = 30,
  }) async {
    try {
      final res = await _db
          .from('death_spiral_prevention_logs')
          .select()
          .eq('user_id', userId)
          .order('missed_date', ascending: false)
          .limit(limit);

      return (res as List)
          .map((e) => DeathSpiralPreventionLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to get prevention actions: $e');
      return [];
    }
  }
}
