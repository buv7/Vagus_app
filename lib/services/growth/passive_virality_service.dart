import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../streaks/streak_service.dart';
import '../config/feature_flags.dart';

enum ShareableMoment {
  streakMilestone,
  prAchievement,
  weightTrend,
  missionCompletion,
  workoutCompletion,
}

class ShareableMomentData {
  final ShareableMoment type;
  final String title;
  final String subtitle;
  final Map<String, dynamic> metrics;
  final String? imagePath;

  const ShareableMomentData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.metrics,
    this.imagePath,
  });
}

class PassiveViralityService {
  PassiveViralityService._();
  static final PassiveViralityService I = PassiveViralityService._();

  final _db = Supabase.instance.client;

  /// Detect if there's a shareable moment for the user
  Future<ShareableMomentData?> detectShareableMoments({
    required String userId,
  }) async {
    try {
      final isEnabled = await FeatureFlags.instance.isEnabled(FeatureFlags.passiveVirality);
      if (!isEnabled) return null;

      // Check streak milestones
      final streakInfo = await StreakService.instance.getStreakInfo(userId: userId);
      final currentStreak = streakInfo['current_count'] as int? ?? 0;

      if (currentStreak > 0 && (currentStreak % 7 == 0 || currentStreak == 1)) {
        return ShareableMomentData(
          type: ShareableMoment.streakMilestone,
          title: '$currentStreak-Day Streak! 🔥',
          subtitle: 'Consistency is key',
          metrics: {'streak': currentStreak},
        );
      }

      // TODO: Check for PR achievements, weight trends, mission completions
      // For now, return null if no moment detected

      return null;
    } catch (e) {
      debugPrint('Failed to detect shareable moments: $e');
      return null;
    }
  }

  /// Trigger passive share suggestion (does NOT auto-open share sheet)
  Future<void> triggerPassiveShare({
    required String userId,
    required ShareableMomentData moment,
    String? source,
  }) async {
    try {
      // Log the viral event
      await logViralEvent(
        userId: userId,
        eventType: 'share',
        eventData: {
          'moment_type': moment.type.name,
          'title': moment.title,
          'subtitle': moment.subtitle,
          'metrics': moment.metrics,
        },
        source: source ?? 'passive_detection',
      );
    } catch (e) {
      debugPrint('Failed to trigger passive share: $e');
    }
  }

  /// Log a viral event
  Future<void> logViralEvent({
    required String userId,
    required String eventType,
    required Map<String, dynamic> eventData,
    String? source,
  }) async {
    try {
      await _db.from('viral_events').insert({
        'user_id': userId,
        'event_type': eventType,
        'event_data': eventData,
        'source': source,
      });
    } catch (e) {
      debugPrint('Failed to log viral event: $e');
    }
  }
}
