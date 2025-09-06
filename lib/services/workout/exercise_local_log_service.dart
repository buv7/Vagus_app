// lib/services/workout/exercise_local_log_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum SetType { normal, drop, restPause, cluster, amrap }

// Stored as a list in SharedPreferences under key: "exlogs::<clientId>::<exerciseKey>"
class LocalSetLog {
  final DateTime date;     // when logged
  final double? weight;    // nullable, respects kg/lb label only (no convert)
  final int? reps;         // nullable
  final double? rir;       // nullable (allow half steps like 1.5)
  final String unit;       // "kg" | "lb" (label only)
  
  // Advanced set type fields (all nullable for backward compatibility)
  final SetType? setType;
  
  // Drop-set: list of drops as absolute weights or percent deltas applied sequentially
  // Choose ONE representation; store both fields but usually fill only one.
  final List<double>? dropWeights;      // e.g., [80, 70, 60]
  final List<double>? dropPercents;     // e.g., [-10, -10] meaning two sequential -10% drops from prior
  
  // Rest-Pause mini-sets: reps per burst and micro rest seconds
  final List<int>? rpBursts;            // e.g., [8, 3, 2]
  final int? rpRestSec;                 // e.g., 20
  
  // Cluster: fixed cluster size and intra-cluster rest seconds, plus total reps (or clusters)
  final int? clusterSize;               // e.g., 3
  final int? clusterRestSec;            // e.g., 15
  final int? clusterTotalReps;          // e.g., 15
  
  // AMRAP:
  final bool? amrap;                    // true if AMRAP; reps field already carries result
  
  const LocalSetLog({
    required this.date, 
    this.weight, 
    this.reps, 
    this.rir, 
    required this.unit,
    this.setType,
    this.dropWeights,
    this.dropPercents,
    this.rpBursts,
    this.rpRestSec,
    this.clusterSize,
    this.clusterRestSec,
    this.clusterTotalReps,
    this.amrap,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'date': date.toIso8601String(),
      'weight': weight,
      'reps': reps,
      'rir': rir,
      'unit': unit,
    };
    
    // Add advanced set type fields only if they're not null
    if (setType != null) json['setType'] = setType!.name;
    if (dropWeights != null) json['dropWeights'] = dropWeights;
    if (dropPercents != null) json['dropPercents'] = dropPercents;
    if (rpBursts != null) json['rpBursts'] = rpBursts;
    if (rpRestSec != null) json['rpRestSec'] = rpRestSec;
    if (clusterSize != null) json['clusterSize'] = clusterSize;
    if (clusterRestSec != null) json['clusterRestSec'] = clusterRestSec;
    if (clusterTotalReps != null) json['clusterTotalReps'] = clusterTotalReps;
    if (amrap != null) json['amrap'] = amrap;
    
    return json;
  }
  
  static LocalSetLog fromJson(Map<String, dynamic> j) {
    // Parse setType enum safely - return null on unknown strings
    SetType? parsedSetType;
    if (j['setType'] != null) {
      try {
        parsedSetType = SetType.values.firstWhere(
          (e) => e.name == j['setType'],
        );
      } catch (_) {
        parsedSetType = null; // Unknown setType, treat as normal
      }
    }
    
    // Safe type conversion for lists with mixed int/double support
    List<double>? safeDoubleList(List<dynamic>? list) {
      if (list == null) return null;
      return list
          .map((e) => (e as num?)?.toDouble())
          .where((e) => e != null)
          .cast<double>()
          .toList();
    }
    
    List<int>? safeIntList(List<dynamic>? list) {
      if (list == null) return null;
      return list
          .map((e) => (e as num?)?.toInt())
          .where((e) => e != null)
          .cast<int>()
          .toList();
    }
    
    final log = LocalSetLog(
      date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
      weight: (j['weight'] as num?)?.toDouble(),
      reps: (j['reps'] as num?)?.toInt(),
      rir: (j['rir'] as num?)?.toDouble(),
      unit: (j['unit'] as String?) == 'lb' ? 'lb' : 'kg',
      setType: parsedSetType,
      dropWeights: safeDoubleList(j['dropWeights'] as List<dynamic>?),
      dropPercents: safeDoubleList(j['dropPercents'] as List<dynamic>?),
      rpBursts: safeIntList(j['rpBursts'] as List<dynamic>?),
      rpRestSec: (j['rpRestSec'] as num?)?.toInt(),
      clusterSize: (j['clusterSize'] as num?)?.toInt(),
      clusterRestSec: (j['clusterRestSec'] as num?)?.toInt(),
      clusterTotalReps: (j['clusterTotalReps'] as num?)?.toInt(),
      amrap: j['amrap'] as bool?,
    );
    
    // Normalize advanced fields before returning
    return normalizeAdvancedFields(log);
  }

  /// Converts mixed ints/doubles, clamps negatives, trims empties.
  /// Ensures data integrity for advanced set type fields.
  static LocalSetLog normalizeAdvancedFields(LocalSetLog log) {
    // Drop-set normalization
    List<double>? normalizedDropWeights;
    if (log.dropWeights != null) {
      normalizedDropWeights = log.dropWeights!
          .where((w) => w > 0) // Remove <=0 weights
          .take(4) // Limit to 4 drops max
          .toList();
      if (normalizedDropWeights.isEmpty) normalizedDropWeights = null;
    }

    List<double>? normalizedDropPercents;
    if (log.dropPercents != null) {
      normalizedDropPercents = log.dropPercents!
          .where((p) => p < 0) // Keep only negative percents
          .take(4) // Limit to 4 drops max
          .toList();
      if (normalizedDropPercents.isEmpty) normalizedDropPercents = null;
    }

    // Rest-pause normalization
    List<int>? normalizedRpBursts;
    int? normalizedRpRestSec;
    if (log.rpBursts != null) {
      normalizedRpBursts = log.rpBursts!
          .where((b) => b > 0) // Remove nonpositive bursts
          .toList();
      if (normalizedRpBursts.isEmpty) {
        normalizedRpBursts = null;
        normalizedRpRestSec = null; // Clear rest sec if no valid bursts
      } else {
        normalizedRpRestSec = log.rpRestSec?.clamp(5, 60); // Clamp to 5-60s
      }
    }

    // Cluster normalization
    int? normalizedClusterSize;
    int? normalizedClusterRestSec;
    int? normalizedClusterTotalReps;
    if (log.clusterSize != null) {
      normalizedClusterSize = log.clusterSize!.clamp(2, 6); // Clamp to 2-6
      normalizedClusterRestSec = log.clusterRestSec?.clamp(5, 60); // Clamp to 5-60s
      normalizedClusterTotalReps = log.clusterTotalReps?.clamp(6, 50); // Clamp to 6-50
    }

    // AMRAP normalization
    bool? normalizedAmrap;
    if (log.amrap == true && log.reps != null && log.reps! <= 0) {
      normalizedAmrap = false; // Disable AMRAP if no reps
    } else {
      normalizedAmrap = log.amrap;
    }

    return LocalSetLog(
      date: log.date,
      weight: log.weight,
      reps: log.reps,
      rir: log.rir,
      unit: log.unit,
      setType: log.setType,
      dropWeights: normalizedDropWeights,
      dropPercents: normalizedDropPercents,
      rpBursts: normalizedRpBursts,
      rpRestSec: normalizedRpRestSec,
      clusterSize: normalizedClusterSize,
      clusterRestSec: normalizedClusterRestSec,
      clusterTotalReps: normalizedClusterTotalReps,
      amrap: normalizedAmrap,
    );
  }
}

class ExerciseLocalLogService {
  static final ExerciseLocalLogService instance = ExerciseLocalLogService._();
  ExerciseLocalLogService._();

  String _key(String clientId, String exKey) => 'exlogs::$clientId::$exKey';

  Future<List<LocalSetLog>> load(String clientId, String exKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key(clientId, exKey));
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => LocalSetLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Graceful fallback - return empty list if parsing fails
      return [];
    }
  }

  Future<void> add(String clientId, String exKey, LocalSetLog log, {int keepLast = 60}) async {
    try {
      final logs = await load(clientId, exKey);
      
      // Normalize the log before adding
      final normalizedLog = LocalSetLog.normalizeAdvancedFields(log);
      logs.add(normalizedLog);
      
      // Sort by date descending (newest first)
      logs.sort((a, b) => b.date.compareTo(a.date));
      
      // Keep only the last N entries
      final trimmedLogs = logs.take(keepLast).toList();
      
      // Save back to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(trimmedLogs.map((log) => log.toJson()).toList());
      await prefs.setString(_key(clientId, exKey), jsonString);
    } catch (e) {
      // Graceful fallback - silently ignore errors
    }
  }

  Future<void> clearForExercise(String clientId, String exKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(clientId, exKey));
    } catch (e) {
      // Graceful fallback - silently ignore errors
    }
  }

  Future<void> deleteLast(String clientId, String exKey) async {
    try {
      final logs = await load(clientId, exKey);
      
      if (logs.isNotEmpty) {
        // Remove the first (newest) entry
        logs.removeAt(0);
        
        // Save back to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(logs.map((log) => log.toJson()).toList());
        await prefs.setString(_key(clientId, exKey), jsonString);
      }
    } catch (e) {
      // Graceful fallback - silently ignore errors
    }
  }
}
