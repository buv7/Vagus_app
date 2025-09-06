// lib/utils/progression_rules.dart
import '../services/workout/exercise_local_log_service.dart';

class ProgressionAdvice {
  final String title;      // e.g., "Add +2.5 kg next time"
  final String rationale;  // short sentence explaining why
  final double? delta;     // positive/negative change suggested
  const ProgressionAdvice({required this.title, required this.rationale, this.delta});
}

class ProgressionRules {
  /// Enhanced rules using last log, RIR, and advanced set types:
  /// - If reps met and RIR≤2 → +2.5kg (kg) / +5lb (lb)
  /// - If reps missed or RIR≥4 → -2.5kg / -5lb
  /// - AMRAP: if reps ≥ (target + 2) and RIR ≤ 2 → increase; if reps very low or RIR ≥ 4 → decrease
  /// - Drop/Rest-Pause/Cluster: use total reps for progression
  /// - Else → keep same
  static ProgressionAdvice suggest({
    required int? targetReps,
    required double? lastWeight,
    required int? lastReps,
    required double? lastRir,
    required bool useKg,
    SetType? setType,
    bool? amrap,
  }) {
    if (lastWeight == null) {
      return const ProgressionAdvice(title: 'No change', rationale: 'No prior weight recorded.');
    }
    
    final inc = useKg ? 2.5 : 5.0;
    
    // Handle AMRAP sets with special logic
    if (setType == SetType.amrap || amrap == true) {
      return _suggestAmrapProgression(targetReps, lastWeight, lastReps, lastRir, useKg, inc);
    }
    
    // For drop sets, rest-pause, and cluster sets, use total reps for progression
    if (setType == SetType.drop || setType == SetType.restPause || setType == SetType.cluster) {
      return _suggestAdvancedSetProgression(targetReps, lastWeight, lastReps, lastRir, useKg, inc, setType!);
    }
    
    // Standard progression for normal sets
    return _suggestStandardProgression(targetReps, lastWeight, lastReps, lastRir, useKg, inc);
  }

  static ProgressionAdvice _suggestAmrapProgression(
    int? targetReps, 
    double lastWeight, 
    int? lastReps, 
    double? lastRir, 
    bool useKg, 
    double inc
  ) {
    if (targetReps != null && lastReps != null) {
      // AMRAP bias: if reps ≥ (target + 2) and RIR ≤ 2, bias toward increase
      if (lastReps >= (targetReps + 2) && (lastRir == null || lastRir <= 2)) {
        return ProgressionAdvice(
          title: 'Add +$inc ${useKg ? 'kg' : 'lb'}', 
          rationale: 'AMRAP exceeded target by 2+ reps with good RIR.', 
          delta: inc
        );
      }
      // If AMRAP reps very low or RIR ≥ 4, bias toward reduce
      if (lastReps < targetReps || (lastRir != null && lastRir >= 4)) {
        return ProgressionAdvice(
          title: 'Reduce -$inc ${useKg ? 'kg' : 'lb'}', 
          rationale: 'AMRAP reps low or RIR high.', 
          delta: -inc
        );
      }
    }
    return const ProgressionAdvice(title: 'Keep same', rationale: 'AMRAP performance within target range.');
  }

  static ProgressionAdvice _suggestAdvancedSetProgression(
    int? targetReps, 
    double lastWeight, 
    int? lastReps, 
    double? lastRir, 
    bool useKg, 
    double inc,
    SetType setType
  ) {
    if (targetReps != null && lastReps != null) {
      if (lastReps >= targetReps && (lastRir == null || lastRir <= 2)) {
        return ProgressionAdvice(
          title: 'Add +$inc ${useKg ? 'kg' : 'lb'}', 
          rationale: '${_getSetTypeName(setType)} total reps achieved with acceptable RIR.', 
          delta: inc
        );
      }
      if (lastReps < targetReps || (lastRir != null && lastRir >= 4)) {
        return ProgressionAdvice(
          title: 'Reduce -$inc ${useKg ? 'kg' : 'lb'}', 
          rationale: '${_getSetTypeName(setType)} total reps not achieved or RIR high.', 
          delta: -inc
        );
      }
    }
    return ProgressionAdvice(
      title: 'Keep same', 
      rationale: '${_getSetTypeName(setType)} performance within target range.'
    );
  }

  static ProgressionAdvice _suggestStandardProgression(
    int? targetReps, 
    double lastWeight, 
    int? lastReps, 
    double? lastRir, 
    bool useKg, 
    double inc
  ) {
    if (targetReps != null && lastReps != null) {
      if (lastReps >= targetReps && (lastRir == null || lastRir <= 2)) {
        return ProgressionAdvice(
          title: 'Add +$inc ${useKg ? 'kg' : 'lb'}', 
          rationale: 'Target reps achieved with acceptable RIR.', 
          delta: inc
        );
      }
      if (lastReps < targetReps || (lastRir == null || lastRir >= 4)) {
        return ProgressionAdvice(
          title: 'Reduce -$inc ${useKg ? 'kg' : 'lb'}', 
          rationale: 'Reps not achieved or RIR high.', 
          delta: -inc
        );
      }
    }
    return const ProgressionAdvice(title: 'Keep same', rationale: 'Maintain for consistency.');
  }

  static String _getSetTypeName(SetType setType) {
    switch (setType) {
      case SetType.drop:
        return 'Drop-set';
      case SetType.restPause:
        return 'Rest-pause';
      case SetType.cluster:
        return 'Cluster';
      case SetType.amrap:
        return 'AMRAP';
      default:
        return 'Set';
    }
  }
}
