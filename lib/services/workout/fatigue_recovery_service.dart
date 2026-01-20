import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/workout/fatigue_models.dart';

class FatigueRecoveryService {
  FatigueRecoveryService._();
  static final FatigueRecoveryService I = FatigueRecoveryService._();

  final _db = Supabase.instance.client;

  Future<void> logFatigue(FatigueLog log) async {
    await _db.from('fatigue_logs').insert(log.toInsertJson());
  }

  Future<List<FatigueLog>> getRecentLogs({
    required String userId,
    int limit = 14,
  }) async {
    final res = await _db
        .from('fatigue_logs')
        .select()
        .eq('user_id', userId)
        .order('logged_at', ascending: false)
        .limit(limit);

    return (res as List).map((e) => FatigueLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RecoveryScore?> getRecoveryScoreForDate({
    required String userId,
    required DateTime dateLocal,
  }) async {
    final day = DateTime(dateLocal.year, dateLocal.month, dateLocal.day);
    final res = await _db
        .from('recovery_scores')
        .select()
        .eq('user_id', userId)
        .eq('date', day.toIso8601String().substring(0, 10))
        .maybeSingle();

    if (res == null) return null;
    return RecoveryScore.fromJson(res);
  }

  Future<double> calculateRecoveryFromLogs({
    required String userId,
    DateTime? dayLocal,
  }) async {
    final now = DateTime.now();
    final day = dayLocal ?? now;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final res = await _db
        .from('fatigue_logs')
        .select()
        .eq('user_id', userId)
        .gte('logged_at', start.toUtc().toIso8601String())
        .lt('logged_at', end.toUtc().toIso8601String())
        .order('logged_at', ascending: false)
        .limit(5);

    final logs = (res as List).map((e) => FatigueLog.fromJson(e as Map<String, dynamic>)).toList();
    if (logs.isEmpty) return 0.0;

    // Weighted formula (simple + stable):
    // recovery = (recoveryScore + sleepQuality + energyLevel) / 3 - (fatigueScore + stressLevel)/6
    double sum = 0.0;
    int count = 0;

    for (final l in logs) {
      final rec = (l.recoveryScore ?? 0).toDouble();
      final sleep = (l.sleepQuality ?? 0).toDouble();
      final energy = (l.energyLevel ?? 0).toDouble();
      final fat = (l.fatigueScore ?? 0).toDouble();
      final stress = (l.stressLevel ?? 0).toDouble();

      final v = ((rec + sleep + energy) / 3.0) - ((fat + stress) / 6.0);
      sum += v;
      count++;
    }

    final avg = sum / max(1, count);
    return avg.clamp(0.0, 10.0);
  }

  Future<void> upsertTodayRecoveryScore({
    required String userId,
    required double overallRecovery,
  }) async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final recommendation = _recommendationFromScore(overallRecovery);

    await _db.from('recovery_scores').upsert({
      'user_id': userId,
      'date': day.toIso8601String().substring(0, 10),
      'overall_recovery': double.parse(overallRecovery.toStringAsFixed(1)),
      'calculated_from_fatigue_logs': true,
      'recommendation': recommendation,
    }, onConflict: 'user_id,date');
  }

  Future<ReadinessIndicator> getReadinessIndicator({
    required String userId,
  }) async {
    final today = DateTime.now();
    final existing = await getRecoveryScoreForDate(userId: userId, dateLocal: today);
    final score = existing?.overallRecovery ?? await calculateRecoveryFromLogs(userId: userId, dayLocal: today);
    return ReadinessIndicator.fromScore(score);
  }

  String _recommendationFromScore(double v) {
    if (v >= 8.0) return 'Green: push performance / overload safely.';
    if (v >= 6.0) return 'Yellow: train hard but manage total volume.';
    if (v >= 4.0) return 'Orange: reduce intensity or cut sets.';
    return 'Red: deload / active recovery + focus sleep/hydration.';
  }
}
