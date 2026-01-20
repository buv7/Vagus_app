// lib/models/workout/intensifier_models.dart
import '../../services/workout/exercise_local_log_service.dart';

/// Directive from intensifier rule engine for a specific set
class IntensifierSetDirective {
  final SetType setType;
  final Map<String, dynamic> fields;
  final bool lockStructure; // If true, user cannot change set type
  final String? ruleName; // Name of intensifier for UI display
  final Map<String, dynamic>? metadata; // Additional rule-specific metadata

  const IntensifierSetDirective({
    required this.setType,
    required this.fields,
    this.lockStructure = false,
    this.ruleName,
    this.metadata,
  });

  /// Create LocalSetLog from directive
  LocalSetLog toLocalSetLog({required String unit}) {
    return LocalSetLog(
      date: DateTime.now(),
      unit: unit,
      setType: setType,
      // Rest-Pause fields
      rpRestSec: fields['rpRestSec'] as int?,
      rpBursts: fields['rpBursts'] as List<int>?,
      // Cluster fields
      clusterSize: fields['clusterSize'] as int?,
      clusterRestSec: fields['clusterRestSec'] as int?,
      clusterTotalReps: fields['clusterTotalReps'] as int?,
      // Drop set fields
      dropWeights: fields['dropWeights'] as List<double>?,
      dropPercents: fields['dropPercents'] as List<double>?,
      // AMRAP
      amrap: fields['amrap'] as bool?,
    );
  }
}

/// Execution state tracking across sets for an exercise
class SetExecutionState {
  // Rest-Pause state
  int completedBursts = 0;
  
  /// Default constructor
  SetExecutionState();
  int currentBurstIndex = 0;
  
  // Cluster state
  int completedClusters = 0;
  int currentClusterIndex = 0;
  
  // Myo-Reps state
  bool activationSetCompleted = false;
  int completedMiniSets = 0;
  
  // Drop set state
  int dropsUsed = 0;
  List<double> dropWeightsUsed = [];
  
  // General runtime metadata
  Map<String, dynamic> runtime = {};
  
  // User override tracking (per set)
  final Map<int, bool> userOverrides = {}; // setIndex -> true if user overrode
  
  /// Check if user has overridden a specific set
  bool isUserOverridden(int setIndex) {
    return userOverrides[setIndex] == true;
  }
  
  /// Mark a set as user-overridden
  void markUserOverride(int setIndex) {
    userOverrides[setIndex] = true;
  }
  
  /// Reset state (when exercise restarts)
  void reset() {
    completedBursts = 0;
    currentBurstIndex = 0;
    completedClusters = 0;
    currentClusterIndex = 0;
    activationSetCompleted = false;
    completedMiniSets = 0;
    dropsUsed = 0;
    dropWeightsUsed.clear();
    runtime.clear();
    userOverrides.clear();
  }
  
  /// Export execution metadata for persistence
  Map<String, dynamic> toExecutionMetadata() {
    return {
      'completed_bursts': completedBursts,
      'completed_clusters': completedClusters,
      'activation_set_completed': activationSetCompleted,
      'completed_mini_sets': completedMiniSets,
      'drops_used': dropsUsed,
      'drop_weights_used': dropWeightsUsed,
      'runtime': runtime,
    };
  }
  
  /// Load execution metadata from persistence
  factory SetExecutionState.fromExecutionMetadata(Map<String, dynamic>? metadata) {
    final state = SetExecutionState();
    if (metadata == null) return state;
    
    state.completedBursts = (metadata['completed_bursts'] as num?)?.toInt() ?? 0;
    state.completedClusters = (metadata['completed_clusters'] as num?)?.toInt() ?? 0;
    state.activationSetCompleted = metadata['activation_set_completed'] as bool? ?? false;
    state.completedMiniSets = (metadata['completed_mini_sets'] as num?)?.toInt() ?? 0;
    state.dropsUsed = (metadata['drops_used'] as num?)?.toInt() ?? 0;
    state.dropWeightsUsed = (metadata['drop_weights_used'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble())
        .toList() ?? [];
    state.runtime = Map<String, dynamic>.from(metadata['runtime'] as Map? ?? {});
    
    return state;
  }
}
