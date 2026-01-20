import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/retention/mission_models.dart';

class DailyMissionsService {
  DailyMissionsService._();
  static final DailyMissionsService I = DailyMissionsService._();

  final _db = Supabase.instance.client;

  /// Generate daily missions for a user (rule-based templates)
  Future<List<DailyMission>> generateDailyMissions({
    required String userId,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final day = DateTime(targetDate.year, targetDate.month, targetDate.day);

    // Check if missions already exist for this date
    final existing = await getTodayMissions(userId: userId, date: day);
    if (existing.isNotEmpty) return existing;

    // Generate default missions (can be enhanced with AI later)
    final missions = <DailyMission>[
      DailyMission(
        id: 'temp',
        userId: userId,
        date: day,
        missionType: MissionType.workout,
        missionTitle: 'Complete your workout',
        missionDescription: 'Finish today\'s scheduled workout session',
        xpReward: 50,
        completed: false,
        createdAt: DateTime.now(),
      ),
      DailyMission(
        id: 'temp',
        userId: userId,
        date: day,
        missionType: MissionType.nutrition,
        missionTitle: 'Log your meals',
        missionDescription: 'Track at least 2 meals today',
        xpReward: 30,
        completed: false,
        createdAt: DateTime.now(),
      ),
      DailyMission(
        id: 'temp',
        userId: userId,
        date: day,
        missionType: MissionType.checkin,
        missionTitle: 'Check in with your coach',
        missionDescription: 'Send a quick update or message',
        xpReward: 20,
        completed: false,
        createdAt: DateTime.now(),
      ),
    ];

    // Insert missions
    for (final mission in missions) {
      await _db.from('daily_missions').insert(mission.toInsertJson());
    }

    return await getTodayMissions(userId: userId, date: day);
  }

  /// Get today's missions
  Future<List<DailyMission>> getTodayMissions({
    required String userId,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final day = DateTime(targetDate.year, targetDate.month, targetDate.day);

    final res = await _db
        .from('daily_missions')
        .select()
        .eq('user_id', userId)
        .eq('date', day.toIso8601String().substring(0, 10))
        .order('created_at', ascending: true);

    return (res as List)
        .map((e) => DailyMission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Complete a mission
  Future<void> completeMission(String missionId) async {
    try {
      await _db.from('daily_missions').update({
        'completed': true,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', missionId);
    } catch (e) {
      debugPrint('Failed to complete mission: $e');
      rethrow;
    }
  }

  /// Get mission history
  Future<List<DailyMission>> getMissionHistory({
    required String userId,
    int limit = 30,
  }) async {
    final res = await _db
        .from('daily_missions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(limit);

    return (res as List)
        .map((e) => DailyMission.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
