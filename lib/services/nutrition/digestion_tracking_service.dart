import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/digestion_models.dart';

class DigestionTrackingService {
  DigestionTrackingService._();
  static final DigestionTrackingService I = DigestionTrackingService._();

  final _db = Supabase.instance.client;

  Future<void> logDigestion(DigestionLog log) async {
    await _db.from('digestion_logs').upsert(
      log.toInsertJson(),
      onConflict: 'user_id,date',
    );
  }

  Future<DigestionLog?> getLatestForDate({
    required String userId,
    required DateTime dateLocal,
  }) async {
    final day = DateTime(dateLocal.year, dateLocal.month, dateLocal.day);
    final res = await _db
        .from('digestion_logs')
        .select()
        .eq('user_id', userId)
        .eq('date', day.toIso8601String().substring(0, 10))
        .maybeSingle();

    if (res == null) return null;
    return DigestionLog.fromJson(res);
  }

  Future<List<DigestionLog>> getDigestionHistory({
    required String userId,
    int limit = 30,
  }) async {
    final res = await _db
        .from('digestion_logs')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(limit);

    return (res as List)
        .map((e) => DigestionLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getBloatTrends({
    required String userId,
    int days = 14,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final res = await _db
        .from('digestion_logs')
        .select()
        .eq('user_id', userId)
        .gte('date', cutoff.toIso8601String().substring(0, 10))
        .order('date', ascending: false);

    final logs = (res as List)
        .map((e) => DigestionLog.fromJson(e as Map<String, dynamic>))
        .toList();

    if (logs.isEmpty) {
      return {
        'avgBloat': 0.0,
        'avgCompliance': 0.0,
        'commonFactors': <String>[],
        'trend': 'stable',
      };
    }

    final avgBloat = logs
            .where((l) => l.bloatLevel != null)
            .map((l) => l.bloatLevel!)
            .fold(0.0, (a, b) => a + b) /
        logs.where((l) => l.bloatLevel != null).length;

    final avgCompliance = logs
            .where((l) => l.complianceScore != null)
            .map((l) => l.complianceScore!)
            .fold(0.0, (a, b) => a + b) /
        logs.where((l) => l.complianceScore != null).length;

    final factorCounts = <String, int>{};
    for (final log in logs) {
      for (final factor in log.bloatingFactors) {
        factorCounts[factor.name] = (factorCounts[factor.name] ?? 0) + 1;
      }
    }

    final commonFactors = factorCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    final topFactors = commonFactors.take(3).map((e) => e.key).toList();

    String trend = 'stable';
    if (logs.length >= 2) {
      final recent = logs.take(7).where((l) => l.bloatLevel != null).toList();
      final older = logs.skip(7).take(7).where((l) => l.bloatLevel != null).toList();
      if (recent.isNotEmpty && older.isNotEmpty) {
        final recentAvg = recent.map((l) => l.bloatLevel!).fold(0.0, (a, b) => a + b) / recent.length;
        final olderAvg = older.map((l) => l.bloatLevel!).fold(0.0, (a, b) => a + b) / older.length;
        if (recentAvg > olderAvg + 1) {
          trend = 'increasing';
        } else if (recentAvg < olderAvg - 1) {
          trend = 'decreasing';
        }
      }
    }

    return {
      'avgBloat': avgBloat,
      'avgCompliance': avgCompliance,
      'commonFactors': topFactors,
      'trend': trend,
    };
  }
}
