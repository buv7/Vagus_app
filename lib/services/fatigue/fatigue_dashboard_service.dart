// lib/services/fatigue/fatigue_dashboard_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../workout/fatigue_engine.dart';
import '../../models/workout/fatigue_score.dart';

/// Service for managing fatigue snapshots and dashboards
/// Computes fatigue from workout logs and stores daily snapshots
class FatigueDashboardService {
  FatigueDashboardService._();
  static final FatigueDashboardService instance = FatigueDashboardService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FatigueEngine _fatigueEngine = FatigueEngine();

  // In-memory cache (TTL: 5 minutes)
  final Map<String, _CacheEntry> _cache = {};
  static const _cacheTTL = Duration(minutes: 5);

  // =====================================================
  // SNAPSHOT MANAGEMENT
  // =====================================================

  /// Get snapshot for a specific date (or today if not specified)
  Future<Map<String, dynamic>?> getSnapshot({
    required String userId,
    DateTime? date,
  }) async {
    final snapshotDate = date ?? DateTime.now();
    final dateStr = _formatDate(snapshotDate);

    // Check cache
    final cacheKey = '$userId:$dateStr';
    if (_cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (DateTime.now().difference(entry.timestamp) < _cacheTTL) {
        return entry.data;
      }
      _cache.remove(cacheKey);
    }

    try {
      final response = await _supabase
          .from('fatigue_snapshots')
          .select()
          .eq('user_id', userId)
          .eq('snapshot_date', dateStr)
          .maybeSingle();

      if (response == null) return null;

      final snapshot = Map<String, dynamic>.from(response);
      _cache[cacheKey] = _CacheEntry(snapshot, DateTime.now());
      return snapshot;
    } catch (e) {
      debugPrint('❌ Error getting snapshot: $e');
      return null;
    }
  }

  /// Get snapshots for a date range
  Future<List<Map<String, dynamic>>> getRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final fromStr = _formatDate(from);
      final toStr = _formatDate(to);

      final response = await _supabase
          .from('fatigue_snapshots')
          .select()
          .eq('user_id', userId)
          .gte('snapshot_date', fromStr)
          .lte('snapshot_date', toStr)
          .order('snapshot_date', ascending: false);

      return (response as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting range: $e');
      return [];
    }
  }

  /// Refresh (compute and store) snapshot for a date
  /// This is the main computation function
  Future<Map<String, dynamic>> refreshSnapshot({
    required String userId,
    DateTime? date,
  }) async {
    final snapshotDate = date ?? DateTime.now();
    final dateStr = _formatDate(snapshotDate);

    try {
      // Step 1: Fetch workout data for the date
      final workoutData = await _fetchWorkoutDataForDate(userId, snapshotDate);

      // Step 2: Compute fatigue using existing engine
      final computed = await _computeFatigueSnapshot(workoutData, snapshotDate);

      // Step 3: Store via RPC
      final result = await _supabase.rpc(
        'refresh_fatigue_snapshot',
        params: {
          'p_user_id': userId,
          'p_date': dateStr,
          'p_fatigue_score': computed['fatigue_score'] as int,
          'p_cns_score': computed['cns_score'] as int,
          'p_local_score': computed['local_score'] as int,
          'p_joint_score': computed['joint_score'] as int,
          'p_volume_load': computed['volume_load'] as num,
          'p_hard_sets': computed['hard_sets'] as int,
          'p_near_failure_sets': computed['near_failure_sets'] as int,
          'p_high_fatigue_intensifier_uses': computed['high_fatigue_intensifier_uses'] as int,
          'p_muscle_fatigue': jsonEncode(computed['muscle_fatigue']),
          'p_intensifier_fatigue': jsonEncode(computed['intensifier_fatigue']),
          'p_notes': jsonEncode(computed['notes']),
        },
      );

      // Step 4: Update cache
      final cacheKey = '$userId:$dateStr';
      final snapshot = (result['snapshot'] as Map<String, dynamic>);
      _cache[cacheKey] = _CacheEntry(snapshot, DateTime.now());

      return snapshot;
    } catch (e) {
      debugPrint('❌ Error refreshing snapshot: $e');
      rethrow;
    }
  }

  /// Get snapshot for a coach's client
  Future<Map<String, dynamic>?> getCoachClientSnapshot({
    required String clientId,
    DateTime? date,
  }) async {
    return getSnapshot(userId: clientId, date: date);
  }

  // =====================================================
  // PRIVATE: DATA FETCHING
  // =====================================================

  /// Fetch workout data for a specific date
  /// Returns list of exercise logs with session metadata
  Future<List<Map<String, dynamic>>> _fetchWorkoutDataForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Query workout_sessions for the date
      final sessions = await _supabase
          .from('workout_sessions')
          .select('id, started_at, completed_at')
          .eq('user_id', userId)
          .gte('started_at', startOfDay.toUtc().toIso8601String())
          .lt('started_at', endOfDay.toUtc().toIso8601String());

      if (sessions.isEmpty) return [];

      final sessionIds = (sessions as List)
          .map((s) => s['id'] as String)
          .toList();

      // Query exercise_logs for these sessions
      final logs = await _supabase
          .from('exercise_logs')
          .select('''
            id,
            session_id,
            exercise_id,
            set_number,
            reps,
            weight,
            rpe,
            rest_seconds,
            notes,
            completed_at,
            exercises!inner(id, name, notes, primary_muscles, secondary_muscles)
          ''')
          .inFilter('session_id', sessionIds)
          .order('completed_at', ascending: true);

      return (logs as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('⚠️ Error fetching workout data: $e');
      // Fallback: try workout_logs table (older structure)
      return await _fetchWorkoutLogsForDate(userId, date);
    }
  }

  /// Fallback: Fetch from workout_logs table (older structure)
  Future<List<Map<String, dynamic>>> _fetchWorkoutLogsForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final dateStr = _formatDate(date);
      final logs = await _supabase
          .from('workout_logs')
          .select()
          .eq('client_id', userId)
          .eq('date', dateStr)
          .order('created_at', ascending: true);

      return (logs as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('⚠️ Error fetching workout_logs: $e');
      return [];
    }
  }

  // =====================================================
  // PRIVATE: FATIGUE COMPUTATION
  // =====================================================

  /// Compute fatigue snapshot from workout data
  Future<Map<String, dynamic>> _computeFatigueSnapshot(
    List<Map<String, dynamic>> workoutData,
    DateTime date,
  ) async {
    if (workoutData.isEmpty) {
      return _emptySnapshot();
    }

    // Aggregate fatigue scores
    final allSetFatigue = <FatigueScore>[];
    final muscleFatigue = <String, double>{};
    final intensifierFatigue = <String, double>{};
    double totalVolume = 0.0;
    int hardSets = 0;
    int nearFailureSets = 0;
    int highFatigueIntensifierUses = 0;

    // Process each exercise log
    for (final log in workoutData) {
      try {
        // Extract set execution data
        final setData = _extractSetExecutionData(log);
        if (setData == null) continue;

        // Extract intensifier execution (from exercise notes)
        final intensifierExec = _extractIntensifierExecution(log);

        // Compute fatigue for this set
        final setFatigue = _fatigueEngine.scoreSet(
          set: setData,
          intensifier: intensifierExec,
        );

        allSetFatigue.add(setFatigue);

        // Aggregate volume
        final weight = setData.weight ?? 0.0;
        final reps = setData.reps ?? 0;
        totalVolume += weight * reps;

        // Count hard sets (RIR <= 2)
        if (setData.rir != null && setData.rir! <= 2) {
          hardSets++;
        }

        // Count near-failure sets (RIR <= 1)
        if (setData.rir != null && setData.rir! <= 1) {
          nearFailureSets++;
        }

        // Track muscle fatigue
        final muscles = _extractMuscles(log);
        for (final muscle in muscles) {
          muscleFatigue[muscle] = (muscleFatigue[muscle] ?? 0.0) + setFatigue.local;
        }

        // Track intensifier fatigue
        if (intensifierExec?.intensifierName != null) {
          final intensifierName = intensifierExec!.intensifierName!;
          intensifierFatigue[intensifierName] =
              (intensifierFatigue[intensifierName] ?? 0.0) +
              setFatigue.total;

          // Count high-fatigue intensifiers
          if (_isHighFatigueIntensifier(intensifierName)) {
            highFatigueIntensifierUses++;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error processing log: $e');
        continue;
      }
    }

    // Aggregate session fatigue
    final sessionFatigue = allSetFatigue.fold(
      FatigueScore.zero,
      (sum, score) => sum + score,
    );

    // Normalize scores to 0-100 scale
    // Use a reasonable max: ~100 total fatigue per day = 100 score
    const maxDailyFatigue = 100.0;
    final normalizedTotal = (sessionFatigue.total / maxDailyFatigue * 100).clamp(0.0, 100.0);
    final normalizedCNS = (sessionFatigue.systemic / maxDailyFatigue * 100).clamp(0.0, 100.0);
    final normalizedLocal = (sessionFatigue.local / maxDailyFatigue * 100).clamp(0.0, 100.0);
    final normalizedJoint = (sessionFatigue.connective / maxDailyFatigue * 100).clamp(0.0, 100.0);

    // Normalize muscle fatigue (same scale)
    final normalizedMuscleFatigue = <String, int>{};
    for (final entry in muscleFatigue.entries) {
      normalizedMuscleFatigue[entry.key] =
          ((entry.value / maxDailyFatigue) * 100).clamp(0.0, 100.0).round();
    }

    // Normalize intensifier fatigue
    final normalizedIntensifierFatigue = <String, int>{};
    for (final entry in intensifierFatigue.entries) {
      normalizedIntensifierFatigue[entry.key] =
          ((entry.value / maxDailyFatigue) * 100).clamp(0.0, 100.0).round();
    }

    return {
      'fatigue_score': normalizedTotal.round(),
      'cns_score': normalizedCNS.round(),
      'local_score': normalizedLocal.round(),
      'joint_score': normalizedJoint.round(),
      'volume_load': totalVolume,
      'hard_sets': hardSets,
      'near_failure_sets': nearFailureSets,
      'high_fatigue_intensifier_uses': highFatigueIntensifierUses,
      'muscle_fatigue': normalizedMuscleFatigue,
      'intensifier_fatigue': normalizedIntensifierFatigue,
      'notes': {
        'computed_at': DateTime.now().toIso8601String(),
        'sets_processed': allSetFatigue.length,
      },
    };
  }

  /// Extract SetExecutionData from log entry
  SetExecutionData? _extractSetExecutionData(Map<String, dynamic> log) {
    try {
      // Try exercise_logs structure first
      if (log.containsKey('reps') && log.containsKey('weight')) {
        // Convert RPE to RIR if needed (rough approximation: RPE 10 = RIR 0, RPE 5 = RIR 5)
        double? rir;
        if (log['rpe'] != null) {
          final rpe = (log['rpe'] as num).toDouble();
          rir = (10.0 - rpe).clamp(0.0, 5.0);
        } else if (log['rir'] != null) {
          rir = (log['rir'] as num).toDouble();
        }

        return SetExecutionData(
          weight: (log['weight'] as num?)?.toDouble(),
          reps: (log['reps'] as num?)?.toInt(),
          rir: rir,
          setType: _extractSetType(log),
          actualRestSec: (log['rest_seconds'] as num?)?.toInt(),
          // expectedRestSec not available in logs
        );
      }

      // Fallback: workout_logs structure
      if (log.containsKey('sets') && log.containsKey('reps')) {
        // This is aggregated data, estimate per-set
        final reps = (log['reps'] as num?)?.toInt() ?? 0;
        final weight = (log['weight'] as num?)?.toDouble() ?? 0.0;
        final rir = (log['rir'] as num?)?.toDouble();

        // Return first set as representative (approximation)
        return SetExecutionData(
          weight: weight,
          reps: reps,
          rir: rir,
        );
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ Error extracting set data: $e');
      return null;
    }
  }

  /// Extract set type from log notes or metadata
  String? _extractSetType(Map<String, dynamic> log) {
    final notes = log['notes'] as String?;
    if (notes == null) return null;

    final lowerNotes = notes.toLowerCase();
    if (lowerNotes.contains('rest-pause') || lowerNotes.contains('rest pause')) {
      return 'restPause';
    }
    if (lowerNotes.contains('drop')) return 'drop';
    if (lowerNotes.contains('cluster')) return 'cluster';
    if (lowerNotes.contains('amrap')) return 'amrap';
    return null;
  }

  /// Extract IntensifierExecution from exercise notes
  IntensifierExecution? _extractIntensifierExecution(Map<String, dynamic> log) {
    try {
      // Try to get exercise notes (may be nested)
      Map<String, dynamic>? exerciseData;
      if (log['exercises'] != null) {
        exerciseData = log['exercises'] as Map<String, dynamic>?;
      }

      final notes = exerciseData?['notes'] as String?;
      if (notes == null || notes.isEmpty) return null;

      // Try to parse as JSON
      try {
        final notesJson = jsonDecode(notes) as Map<String, dynamic>?;
        if (notesJson == null) return null;

        // Look for intensifier rules
        final rules = notesJson['intensifier_rules'] as Map<String, dynamic>?;
        final intensifierName = notesJson['intensifier_name'] as String?;

        if (rules != null || intensifierName != null) {
          return IntensifierExecution(
            intensifierName: intensifierName,
            rules: rules,
          );
        }
      } catch (_) {
        // Not JSON, try text parsing
        final lowerNotes = notes.toLowerCase();
        String? intensifierName;
        if (lowerNotes.contains('rest-pause') || lowerNotes.contains('rest pause')) {
          intensifierName = 'rest_pause';
        } else if (lowerNotes.contains('drop')) {
          intensifierName = 'drop_sets';
        } else if (lowerNotes.contains('cluster')) {
          intensifierName = 'cluster_sets';
        } else if (lowerNotes.contains('myo')) {
          intensifierName = 'myo_reps';
        } else if (lowerNotes.contains('tempo')) {
          intensifierName = 'tempo';
        } else if (lowerNotes.contains('isometric')) {
          intensifierName = 'isometric';
        } else if (lowerNotes.contains('partial')) {
          intensifierName = 'partials';
        }

        if (intensifierName != null) {
          return IntensifierExecution(intensifierName: intensifierName);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error extracting intensifier: $e');
    }
    return null;
  }

  /// Extract muscle groups from log
  List<String> _extractMuscles(Map<String, dynamic> log) {
    final muscles = <String>[];

    try {
      // Try exercise_logs structure
      if (log['exercises'] != null) {
        final exercise = log['exercises'] as Map<String, dynamic>?;
        if (exercise != null) {
          final primary = exercise['primary_muscles'] as List<dynamic>?;
          final secondary = exercise['secondary_muscles'] as List<dynamic>?;

          if (primary != null) {
            muscles.addAll(primary.map((e) => e.toString()));
          }
          if (secondary != null) {
            muscles.addAll(secondary.map((e) => e.toString()));
          }
        }
      }

      // Fallback: workout_logs structure (may have muscle_group field)
      if (muscles.isEmpty && log['muscle_group'] != null) {
        muscles.add(log['muscle_group'].toString());
      }
    } catch (e) {
      debugPrint('⚠️ Error extracting muscles: $e');
    }

    return muscles.isEmpty ? ['unknown'] : muscles;
  }

  /// Check if intensifier is high-fatigue
  bool _isHighFatigueIntensifier(String name) {
    final lower = name.toLowerCase();
    return lower.contains('myo') ||
        lower.contains('rest-pause') ||
        lower.contains('rest_pause') ||
        lower.contains('drop');
  }

  /// Create empty snapshot
  Map<String, dynamic> _emptySnapshot() {
    return {
      'fatigue_score': 0,
      'cns_score': 0,
      'local_score': 0,
      'joint_score': 0,
      'volume_load': 0.0,
      'hard_sets': 0,
      'near_failure_sets': 0,
      'high_fatigue_intensifier_uses': 0,
      'muscle_fatigue': <String, int>{},
      'intensifier_fatigue': <String, int>{},
      'notes': {},
    };
  }

  // =====================================================
  // HELPERS
  // =====================================================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Cache entry for in-memory caching
class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  _CacheEntry(this.data, this.timestamp);
}
