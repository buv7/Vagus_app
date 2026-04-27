import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/workout/cardio_session.dart';

/// Data model for manual cardio entry (simpler than OCR)
class ManualCardioEntry {
  final String? id;
  final String sport; // running, cycling, swimming, walking, etc.
  final DateTime startAt;
  final DateTime? endAt;
  final int? durationSeconds;
  final double? distanceMeters;
  final double? avgHeartRate;
  final double? maxHeartRate;
  final double? caloriesBurned;
  final CardioMachineType? machineType;
  final String? intensity; // Low, Medium, High
  final Map<String, dynamic>? machineSettings;
  final String? notes;
  final DateTime createdAt;

  ManualCardioEntry({
    this.id,
    required this.sport,
    required this.startAt,
    this.endAt,
    this.durationSeconds,
    this.distanceMeters,
    this.avgHeartRate,
    this.maxHeartRate,
    this.caloriesBurned,
    this.machineType,
    this.intensity,
    this.machineSettings,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toHealthWorkoutMap() {
    return {
      'sport': sport,
      'start_at': startAt.toIso8601String(),
      if (endAt != null) 'end_at': endAt!.toIso8601String(),
      if (durationSeconds != null) 'duration_s': durationSeconds,
      if (distanceMeters != null) 'distance_m': distanceMeters,
      if (avgHeartRate != null) 'avg_hr': avgHeartRate,
      if (caloriesBurned != null) 'kcal': caloriesBurned,
      'source': 'manual_entry',
      'meta': {
        if (maxHeartRate != null) 'max_hr': maxHeartRate,
        if (machineType != null) 'machine_type': machineType!.value,
        if (intensity != null) 'intensity': intensity,
        if (machineSettings != null) 'machine_settings': machineSettings,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      },
    };
  }

  factory ManualCardioEntry.fromHealthWorkoutMap(Map<String, dynamic> map) {
    final meta = map['meta'] as Map<String, dynamic>? ?? {};
    return ManualCardioEntry(
      id: map['id']?.toString(),
      sport: map['sport']?.toString() ?? 'unknown',
      startAt: DateTime.tryParse(map['start_at']?.toString() ?? '') ?? DateTime.now(),
      endAt: map['end_at'] != null ? DateTime.tryParse(map['end_at'].toString()) : null,
      durationSeconds: (map['duration_s'] as num?)?.toInt(),
      distanceMeters: (map['distance_m'] as num?)?.toDouble(),
      avgHeartRate: (map['avg_hr'] as num?)?.toDouble(),
      maxHeartRate: (meta['max_hr'] as num?)?.toDouble(),
      caloriesBurned: (map['kcal'] as num?)?.toDouble(),
      machineType: CardioMachineType.fromString(meta['machine_type']?.toString()),
      intensity: meta['intensity']?.toString(),
      machineSettings: meta['machine_settings'] as Map<String, dynamic>?,
      notes: meta['notes']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Service for manual cardio entry operations
class ManualCardioService {
  static final ManualCardioService _instance = ManualCardioService._internal();
  factory ManualCardioService() => _instance;
  ManualCardioService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Save a manual cardio entry to the health_workouts table
  Future<ManualCardioEntry?> saveManualEntry(ManualCardioEntry entry) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('ManualCardioService: No authenticated user');
        return null;
      }

      final data = entry.toHealthWorkoutMap();
      data['user_id'] = userId;

      debugPrint('ManualCardioService: Saving entry - $data');

      final response = await _supabase
          .from('health_workouts')
          .insert(data)
          .select()
          .single();

      debugPrint('ManualCardioService: Saved successfully - ${response['id']}');
      return ManualCardioEntry.fromHealthWorkoutMap(response);
    } catch (e) {
      debugPrint('ManualCardioService: Error saving entry - $e');
      return null;
    }
  }

  /// Update an existing manual cardio entry
  Future<ManualCardioEntry?> updateEntry(String id, ManualCardioEntry entry) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('ManualCardioService: No authenticated user');
        return null;
      }

      final data = entry.toHealthWorkoutMap();
      data['user_id'] = userId;

      final response = await _supabase
          .from('health_workouts')
          .update(data)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      debugPrint('ManualCardioService: Updated successfully - $id');
      return ManualCardioEntry.fromHealthWorkoutMap(response);
    } catch (e) {
      debugPrint('ManualCardioService: Error updating entry - $e');
      return null;
    }
  }

  /// Delete a manual cardio entry
  Future<bool> deleteEntry(String id) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('ManualCardioService: No authenticated user');
        return false;
      }

      await _supabase
          .from('health_workouts')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      debugPrint('ManualCardioService: Deleted entry - $id');
      return true;
    } catch (e) {
      debugPrint('ManualCardioService: Error deleting entry - $e');
      return false;
    }
  }

  /// Get all manual cardio entries for the current user
  Future<List<ManualCardioEntry>> getManualEntries({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _supabase
          .from('health_workouts')
          .select()
          .eq('user_id', userId)
          .eq('source', 'manual_entry');

      if (startDate != null) {
        query = query.gte('start_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('start_at', endDate.toIso8601String());
      }

      final response = await query
          .order('start_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => ManualCardioEntry.fromHealthWorkoutMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ManualCardioService: Error getting entries - $e');
      return [];
    }
  }

  /// Get recent cardio statistics
  Future<Map<String, dynamic>> getCardioStats({int daysBack = 30}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final startDate = DateTime.now().subtract(Duration(days: daysBack));
      
      final response = await _supabase
          .from('health_workouts')
          .select('sport, duration_s, distance_m, kcal, start_at')
          .eq('user_id', userId)
          .gte('start_at', startDate.toIso8601String())
          .order('start_at', ascending: false);

      final workouts = response as List;
      
      int totalWorkouts = workouts.length;
      int totalDurationSeconds = 0;
      double totalDistanceMeters = 0;
      double totalCalories = 0;
      Map<String, int> sportCounts = {};

      for (final workout in workouts) {
        totalDurationSeconds += (workout['duration_s'] as num?)?.toInt() ?? 0;
        totalDistanceMeters += (workout['distance_m'] as num?)?.toDouble() ?? 0;
        totalCalories += (workout['kcal'] as num?)?.toDouble() ?? 0;
        
        final sport = workout['sport']?.toString() ?? 'unknown';
        sportCounts[sport] = (sportCounts[sport] ?? 0) + 1;
      }

      return {
        'total_workouts': totalWorkouts,
        'total_duration_minutes': (totalDurationSeconds / 60).round(),
        'total_distance_km': (totalDistanceMeters / 1000),
        'total_calories': totalCalories.round(),
        'sport_breakdown': sportCounts,
        'days_analyzed': daysBack,
      };
    } catch (e) {
      debugPrint('ManualCardioService: Error getting stats - $e');
      return {};
    }
  }

  /// Convert sport name to display name
  static String getSportDisplayName(String sport) {
    switch (sport.toLowerCase()) {
      case 'running':
        return 'Running';
      case 'cycling':
        return 'Cycling';
      case 'swimming':
        return 'Swimming';
      case 'walking':
        return 'Walking';
      case 'hiking':
        return 'Hiking';
      case 'rowing':
        return 'Rowing';
      case 'elliptical':
        return 'Elliptical';
      case 'stairmaster':
        return 'Stairmaster';
      case 'jump_rope':
        return 'Jump Rope';
      case 'boxing':
        return 'Boxing';
      case 'hiit':
        return 'HIIT';
      case 'spin':
        return 'Spin Class';
      default:
        return sport.replaceAll('_', ' ').split(' ').map((w) => 
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : ''
        ).join(' ');
    }
  }

  /// Get available sport types
  static List<String> get availableSports => [
    'running',
    'cycling',
    'swimming',
    'walking',
    'hiking',
    'rowing',
    'elliptical',
    'stairmaster',
    'jump_rope',
    'boxing',
    'hiit',
    'spin',
    'other',
  ];
}
