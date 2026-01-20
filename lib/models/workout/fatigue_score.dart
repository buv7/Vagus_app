// lib/models/workout/fatigue_score.dart
/// Fatigue score with three independent channels
class FatigueScore {
  final double local;        // Target muscle exhaustion
  final double systemic;    // CNS / cardiovascular stress
  final double connective;  // Joints / tendons / passive tissue
  
  const FatigueScore({
    this.local = 0.0,
    this.systemic = 0.0,
    this.connective = 0.0,
  });
  
  /// Create from JSON
  factory FatigueScore.fromJson(Map<String, dynamic> json) {
    return FatigueScore(
      local: (json['local'] as num?)?.toDouble() ?? 0.0,
      systemic: (json['systemic'] as num?)?.toDouble() ?? 0.0,
      connective: (json['connective'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'local': local,
      'systemic': systemic,
      'connective': connective,
    };
  }
  
  /// Add two fatigue scores
  FatigueScore operator +(FatigueScore other) {
    return FatigueScore(
      local: local + other.local,
      systemic: systemic + other.systemic,
      connective: connective + other.connective,
    );
  }
  
  /// Multiply by a scalar
  FatigueScore operator *(double multiplier) {
    return FatigueScore(
      local: local * multiplier,
      systemic: systemic * multiplier,
      connective: connective * multiplier,
    );
  }
  
  /// Get total fatigue (sum of all channels)
  double get total => local + systemic + connective;
  
  /// Create zero fatigue score
  static const FatigueScore zero = FatigueScore();
  
  @override
  String toString() {
    return 'FatigueScore(local: ${local.toStringAsFixed(2)}, systemic: ${systemic.toStringAsFixed(2)}, connective: ${connective.toStringAsFixed(2)})';
  }
}

/// Execution data for a single set (input to fatigue engine)
class SetExecutionData {
  final double? weight;
  final int? reps;
  final double? rir; // Reps in reserve (lower = more fatigue)
  final String? setType; // 'normal', 'drop', 'restPause', 'cluster', 'amrap'
  
  // Intensifier-specific data
  final List<int>? rpBursts; // Rest-pause bursts
  final int? rpRestSec; // Rest-pause rest seconds
  final List<double>? dropPercents; // Drop set percentages
  final int? clusterSize; // Cluster set size
  final int? clusterRestSec; // Cluster rest seconds
  final int? clusterTotalReps; // Cluster total reps
  final bool? amrap; // AMRAP flag
  
  // Execution metadata
  final bool? failed; // Did the set fail?
  final int? actualRestSec; // Actual rest taken (vs expected)
  final int? expectedRestSec; // Expected rest time
  
  const SetExecutionData({
    this.weight,
    this.reps,
    this.rir,
    this.setType,
    this.rpBursts,
    this.rpRestSec,
    this.dropPercents,
    this.clusterSize,
    this.clusterRestSec,
    this.clusterTotalReps,
    this.amrap,
    this.failed,
    this.actualRestSec,
    this.expectedRestSec,
  });
  
  /// Create from LocalSetLog
  factory SetExecutionData.fromLocalSetLog(
    dynamic setLog, {
    bool? failed,
    int? actualRestSec,
    int? expectedRestSec,
  }) {
    // Handle both LocalSetLog and Map<String, dynamic>
    Map<String, dynamic>? json;
    if (setLog is Map<String, dynamic>) {
      json = setLog;
    } else {
      // Assume it has a toJson method
      try {
        json = setLog.toJson() as Map<String, dynamic>?;
      } catch (_) {
        json = null;
      }
    }
    
    if (json == null) {
      return const SetExecutionData();
    }
    
    return SetExecutionData(
      weight: (json['weight'] as num?)?.toDouble(),
      reps: (json['reps'] as num?)?.toInt(),
      rir: (json['rir'] as num?)?.toDouble(),
      setType: json['setType'] as String?,
      rpBursts: (json['rpBursts'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      rpRestSec: (json['rpRestSec'] as num?)?.toInt(),
      dropPercents: (json['dropPercents'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      clusterSize: (json['clusterSize'] as num?)?.toInt(),
      clusterRestSec: (json['clusterRestSec'] as num?)?.toInt(),
      clusterTotalReps: (json['clusterTotalReps'] as num?)?.toInt(),
      amrap: json['amrap'] as bool?,
      failed: failed,
      actualRestSec: actualRestSec,
      expectedRestSec: expectedRestSec,
    );
  }
}

/// Intensifier execution metadata (from Phase 4.7)
class IntensifierExecution {
  final String? intensifierName;
  final Map<String, dynamic>? rules;
  final Map<String, dynamic>? executionMetadata;
  
  const IntensifierExecution({
    this.intensifierName,
    this.rules,
    this.executionMetadata,
  });
  
  /// Create from execution state and rules
  factory IntensifierExecution.fromState(
    Map<String, dynamic>? executionMetadata,
    Map<String, dynamic>? rules,
    String? intensifierName,
  ) {
    return IntensifierExecution(
      intensifierName: intensifierName,
      rules: rules,
      executionMetadata: executionMetadata,
    );
  }
}
