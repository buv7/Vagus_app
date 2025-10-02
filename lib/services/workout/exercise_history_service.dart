// lib/services/workout/exercise_history_service.dart
import 'exercise_local_log_service.dart';

class ExerciseSetLog {
  final DateTime date;       // session date (local)
  final double? weight;      // working/top set weight (if any)
  final int? reps;           // best reps for that day (if any)
  final double? rir;         // best/lowest RIR found
  final double? est1rm;      // computed Epley from weight/reps if available
  final String source;       // which table or method
  
  // Advanced set type fields (from LocalSetLog)
  final SetType? setType;
  final List<double>? dropWeights;
  final List<double>? dropPercents;
  final List<int>? rpBursts;
  final int? rpRestSec;
  final int? clusterSize;
  final int? clusterRestSec;
  final int? clusterTotalReps;
  final bool? amrap;
  
  const ExerciseSetLog({
    required this.date, 
    this.weight, 
    this.reps, 
    this.rir, 
    this.est1rm, 
    required this.source,
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
}

class ExercisePRs {
  final double? bestWeight;  // heaviest working set
  final int? bestReps;       // max reps on any logged weight
  final double? bestEst1RM;  // highest estimated 1RM
  const ExercisePRs({this.bestWeight, this.bestReps, this.bestEst1RM});
}

class ExerciseHistoryService {
  static final ExerciseHistoryService instance = ExerciseHistoryService._();
  ExerciseHistoryService._();


  /// Fetch last N logs for an exercise name (or id if available).
  Future<List<ExerciseSetLog>> lastLogs({
    required String clientId,
    required String exerciseName, // if you have an id, prefer it; fall back to name
    int limit = 3,
  }) async {
    try {
      // Get local logs first
      final localLogs = await ExerciseLocalLogService.instance.load(
        clientId, 
        exerciseName.toLowerCase().trim(),
      );
      
      // Convert LocalSetLog to ExerciseSetLog
      final convertedLogs = localLogs.map((localLog) => ExerciseSetLog(
        date: localLog.date,
        weight: localLog.weight,
        reps: localLog.reps,
        rir: localLog.rir,
        est1rm: estimate1RM(localLog.weight, localLog.reps),
        source: 'local',
        setType: localLog.setType,
        dropWeights: localLog.dropWeights,
        dropPercents: localLog.dropPercents,
        rpBursts: localLog.rpBursts,
        rpRestSec: localLog.rpRestSec,
        clusterSize: localLog.clusterSize,
        clusterRestSec: localLog.clusterRestSec,
        clusterTotalReps: localLog.clusterTotalReps,
        amrap: localLog.amrap,
      )).toList();
      
      // Sort by date descending (newest first)
      convertedLogs.sort((a, b) => b.date.compareTo(a.date));
      
      // Return top N entries
      return convertedLogs.take(limit).toList();
    } catch (e) {
      // Graceful fallback - return empty list
      return [];
    }
  }

  ExercisePRs computePRs(List<ExerciseSetLog> logs) {
    double? bestW;
    int?    bestR;
    double? bestE;
    for (final l in logs) {
      if (l.weight != null) {
        if (bestW == null || l.weight! > bestW) bestW = l.weight;
      }
      if (l.reps != null) {
        if (bestR == null || l.reps! > bestR) bestR = l.reps;
      }
      if (l.est1rm != null) {
        if (bestE == null || l.est1rm! > bestE) bestE = l.est1rm;
      }
    }
    return ExercisePRs(bestWeight: bestW, bestReps: bestR, bestEst1RM: bestE);
  }

  /// Epley estimate; guard reps 1..12
  /// Clamps reps to <= 12 to avoid unrealistic e1RM from very long rest-pause/cluster totals
  double? estimate1RM(double? w, int? reps) {
    if (w == null || reps == null || reps <= 0 || reps > 12) return null;
    return w * (1.0 + reps / 30.0);
  }
}
