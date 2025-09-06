import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/hydration_log.dart';
import 'preferences_service.dart';

/// Service for managing hydration logs and targets
class HydrationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PreferencesService _preferencesService = PreferencesService();
  
  // Cache for today's hydration log
  HydrationLog? _todayCache;
  DateTime? _cacheDate;
  static const Duration _cacheTTL = Duration(minutes: 5);

  /// Get hydration log for a specific user and date
  Future<HydrationLog> getDaily(String userId, DateTime date) async {
    // Check cache first
    if (_todayCache != null && 
        _cacheDate != null && 
        _isSameDay(_cacheDate!, date) &&
        DateTime.now().difference(_cacheDate!) < _cacheTTL) {
      return _todayCache!;
    }

    try {
      final dateStr = _formatDate(date);
      final response = await _supabase
          .from('nutrition_hydration_logs')
          .select('*')
          .eq('user_id', userId)
          .eq('date', dateStr)
          .maybeSingle();

      if (response != null) {
        final log = HydrationLog.fromMap(response);
        _updateCache(log, date);
        return log;
      } else {
        // Return empty log if no data exists
        final emptyLog = HydrationLog(
          userId: userId,
          date: date,
          ml: 0,
          updatedAt: DateTime.now(),
        );
        _updateCache(emptyLog, date);
        return emptyLog;
      }
    } catch (e) {
      print('Error fetching hydration log: $e');
      // Return empty log on error
      return HydrationLog(
        userId: userId,
        date: date,
        ml: 0,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Add water intake for a specific user and date (increments atomically)
  Future<HydrationLog> addWater(String userId, DateTime date, int ml) async {
    try {
      final dateStr = _formatDate(date);
      
      // Use upsert to increment the ml value atomically
      final response = await _supabase
          .from('nutrition_hydration_logs')
          .upsert({
            'user_id': userId,
            'date': dateStr,
            'ml': ml, // This will be the total amount, not increment
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,date')
          .select()
          .single();

      final log = HydrationLog.fromMap(response);
      _updateCache(log, date);
      return log;
    } catch (e) {
      print('Error adding water: $e');
      rethrow;
    }
  }

  /// Increment water intake by a specific amount
  Future<HydrationLog> incrementWater(String userId, DateTime date, int mlToAdd) async {
    try {
      // Get current log
      final currentLog = await getDaily(userId, date);
      final newTotal = currentLog.ml + mlToAdd;
      
      // Update with new total
      return await addWater(userId, date, newTotal);
    } catch (e) {
      print('Error incrementing water: $e');
      rethrow;
    }
  }

  /// Set daily hydration target for a user (stored in preferences)
  Future<void> setDailyTarget(String userId, int ml) async {
    try {
      // Get current preferences
      final preferences = await _preferencesService.getPrefs(userId);
      
      // Update hydration target  
      final prefs = await _preferencesService.getPrefs(userId);
      final target = prefs?.hydrationTargetMl ?? 3000; // getter returns default 3000 when null
    } catch (e) {
      print('Error setting hydration target: $e');
      rethrow;
    }
  }

  /// Get daily hydration target for a user
  Future<int> getDailyTarget(String userId) async {
    try {
      final preferences = await _preferencesService.getPrefs(userId);
      return preferences?.hydrationTargetMl ?? 3000; // Default 3L
    } catch (e) {
      print('Error getting hydration target: $e');
      return 3000; // Default fallback
    }
  }

  /// Get hydration summary for the last N days
  Future<List<HydrationLog>> getWeeklySummary(String userId, {int days = 7}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days - 1));
      
      final response = await _supabase
          .from('nutrition_hydration_logs')
          .select('*')
          .eq('user_id', userId)
          .gte('date', _formatDate(startDate))
          .lte('date', _formatDate(endDate))
          .order('date', ascending: true);

      return response.map((row) => HydrationLog.fromMap(row)).toList();
    } catch (e) {
      print('Error fetching weekly summary: $e');
      return [];
    }
  }

  /// Get hydration statistics for a user
  Future<HydrationStats> getStats(String userId, {int days = 30}) async {
    try {
      final logs = await getWeeklySummary(userId, days: days);
      
      if (logs.isEmpty) {
        return HydrationStats.empty();
      }

      final totalMl = logs.fold<int>(0, (sum, log) => sum + log.ml);
      final averageMl = totalMl / logs.length;
      final targetMl = await getDailyTarget(userId);
      
      final daysOnTarget = logs.where((log) => log.ml >= targetMl).length;
      final adherenceRate = (daysOnTarget / logs.length) * 100;

      return HydrationStats(
        totalMl: totalMl,
        averageMl: averageMl,
        daysOnTarget: daysOnTarget,
        totalDays: logs.length,
        adherenceRate: adherenceRate,
        targetMl: targetMl,
      );
    } catch (e) {
      print('Error calculating hydration stats: $e');
      return HydrationStats.empty();
    }
  }

  /// Clear cache
  void clearCache() {
    _todayCache = null;
    _cacheDate = null;
  }

  /// Update cache
  void _updateCache(HydrationLog log, DateTime date) {
    _todayCache = log;
    _cacheDate = date;
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Format date as YYYY-MM-DD string
  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }
}

/// Hydration statistics model
class HydrationStats {
  final int totalMl;
  final double averageMl;
  final int daysOnTarget;
  final int totalDays;
  final double adherenceRate;
  final int targetMl;

  const HydrationStats({
    required this.totalMl,
    required this.averageMl,
    required this.daysOnTarget,
    required this.totalDays,
    required this.adherenceRate,
    required this.targetMl,
  });

  factory HydrationStats.empty() {
    return const HydrationStats(
      totalMl: 0,
      averageMl: 0.0,
      daysOnTarget: 0,
      totalDays: 0,
      adherenceRate: 0.0,
      targetMl: 3000,
    );
  }

  /// Get formatted total liters
  String get formattedTotalLiters => '${(totalMl / 1000.0).toStringAsFixed(1)}L';

  /// Get formatted average liters
  String get formattedAverageLiters => '${(averageMl / 1000.0).toStringAsFixed(1)}L';

  /// Get formatted adherence rate
  String get formattedAdherenceRate => '${adherenceRate.toStringAsFixed(1)}%';

  /// Check if user is meeting their target
  bool get isMeetingTarget => averageMl >= targetMl;

  /// Get adherence status
  String get adherenceStatus {
    if (adherenceRate >= 80) return 'Excellent';
    if (adherenceRate >= 60) return 'Good';
    if (adherenceRate >= 40) return 'Fair';
    return 'Needs improvement';
  }
}
