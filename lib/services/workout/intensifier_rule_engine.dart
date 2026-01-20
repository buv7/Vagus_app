// lib/services/workout/intensifier_rule_engine.dart
import '../../models/workout/intensifier_models.dart';
import '../../services/workout/exercise_local_log_service.dart';

/// Pure Dart rule engine for interpreting and applying intensifier rules
/// NO UI LOGIC - Deterministic output only
class IntensifierRuleEngine {
  final Map<String, dynamic> rules;
  final String applyScope; // 'off' | 'last_set' | 'all_sets'
  final int totalSets;
  final String? intensifierName;
  
  IntensifierRuleEngine({
    required this.rules,
    required this.applyScope,
    required this.totalSets,
    this.intensifierName,
  });
  
  /// Get directive for a specific set based on rules and current state
  /// Returns null if no directive applies (scope='off', user overridden, etc.)
  IntensifierSetDirective? getDirectiveForSet({
    required int setIndex, // 0-based
    required SetExecutionState state,
    bool userOverridden = false,
  }) {
    // Check apply scope
    if (applyScope == 'off') {
      return null;
    }
    
    if (applyScope == 'last_set') {
      final isLastSet = setIndex == totalSets - 1;
      if (!isLastSet) return null;
    }
    
    // If user has overridden this set, disengage
    if (userOverridden || state.isUserOverridden(setIndex)) {
      return null;
    }
    
    // Interpret rules and generate directive
    return _interpretRules(setIndex: setIndex, state: state);
  }
  
  /// Interpret rules and generate directive
  IntensifierSetDirective? _interpretRules({
    required int setIndex,
    required SetExecutionState state,
  }) {
    // Priority order: Rest-Pause > Cluster > Drop > Myo-Reps
    // (First matching rule wins)
    
    if (rules.containsKey('rest_pause')) {
      return _interpretRestPause(setIndex: setIndex, state: state);
    }
    
    if (rules.containsKey('cluster_set') || rules.containsKey('cluster')) {
      return _interpretClusterSet(setIndex: setIndex, state: state);
    }
    
    if (rules.containsKey('drop_set') || rules.containsKey('drop')) {
      return _interpretDropSet(setIndex: setIndex, state: state);
    }
    
    if (rules.containsKey('myo_reps') || rules.containsKey('myo-reps')) {
      return _interpretMyoReps(setIndex: setIndex, state: state);
    }
    
    // Tempo, Isometrics, Partials are handled separately (not set type changes)
    // They modify behavior but don't change SetType
    
    return null;
  }
  
  /// Interpret Rest-Pause rule
  IntensifierSetDirective? _interpretRestPause({
    required int setIndex,
    required SetExecutionState state,
  }) {
    final rp = rules['rest_pause'] as Map<String, dynamic>?;
    if (rp == null) return null;
    
    final restSec = (rp['rest_seconds'] as num?)?.toInt() ?? 20;
    final miniSets = (rp['mini_sets'] as num?)?.toInt() ?? 3;
    final repsPerMini = (rp['reps_per_mini_set'] as num?)?.toInt() ?? 2;
    
    // Generate bursts pattern
    final bursts = <int>[repsPerMini * 2]; // Initial estimate
    for (int i = 1; i < miniSets; i++) {
      bursts.add(repsPerMini);
    }
    
    return IntensifierSetDirective(
      setType: SetType.restPause,
      fields: {
        'rpRestSec': restSec,
        'rpBursts': bursts,
      },
      lockStructure: false, // User can override
      ruleName: intensifierName ?? 'Rest-Pause',
      metadata: {
        'mini_sets': miniSets,
        'reps_per_mini_set': repsPerMini,
      },
    );
  }
  
  /// Interpret Cluster Set rule
  IntensifierSetDirective? _interpretClusterSet({
    required int setIndex,
    required SetExecutionState state,
  }) {
    final cluster = rules['cluster_set'] ?? rules['cluster'] as Map<String, dynamic>?;
    if (cluster == null) return null;
    
    final restSec = (cluster['rest_between_clusters'] as num?)?.toInt() ?? 
                   (cluster['rest_seconds'] as num?)?.toInt() ?? 15;
    final repsPerCluster = (cluster['reps_per_cluster'] as num?)?.toInt() ?? 3;
    final clusters = (cluster['clusters'] as num?)?.toInt() ?? 4;
    final totalReps = (cluster['total_target_reps'] as num?)?.toInt() ?? 
                     (repsPerCluster * clusters);
    
    return IntensifierSetDirective(
      setType: SetType.cluster,
      fields: {
        'clusterSize': repsPerCluster,
        'clusterRestSec': restSec,
        'clusterTotalReps': totalReps,
      },
      lockStructure: false,
      ruleName: intensifierName ?? 'Cluster Sets',
      metadata: {
        'clusters': clusters,
        'reps_per_cluster': repsPerCluster,
      },
    );
  }
  
  /// Interpret Drop Set rule
  IntensifierSetDirective? _interpretDropSet({
    required int setIndex,
    required SetExecutionState state,
  }) {
    final drop = rules['drop_set'] ?? rules['drop'] as Map<String, dynamic>?;
    if (drop == null) return null;
    
    final drops = (drop['drops'] as num?)?.toInt() ?? 1;
    final reductionPercent = (drop['weight_reduction_percent'] as num?)?.toDouble() ?? 
                            (drop['reduction_percent'] as num?)?.toDouble() ?? 25.0;
    
    final dropPercents = List.generate(drops, (_) => -reductionPercent);
    
    return IntensifierSetDirective(
      setType: SetType.drop,
      fields: {
        'dropPercents': dropPercents,
      },
      lockStructure: false,
      ruleName: intensifierName ?? 'Drop Set',
      metadata: {
        'drops': drops,
        'reduction_percent': reductionPercent,
      },
    );
  }
  
  /// Interpret Myo-Reps rule
  IntensifierSetDirective? _interpretMyoReps({
    required int setIndex,
    required SetExecutionState state,
  }) {
    final myo = rules['myo_reps'] ?? rules['myo-reps'] as Map<String, dynamic>?;
    if (myo == null) return null;
    
    final restSec = (myo['rest_seconds'] as num?)?.toInt() ?? 7;
    final activationReps = (myo['activation_reps'] as num?)?.toInt() ?? 20;
    final miniSetReps = (myo['mini_set_reps'] as num?)?.toInt() ?? 
                       (myo['reps_per_mini_set'] as num?)?.toInt() ?? 4;
    final targetMiniSets = (myo['target_mini_sets'] as num?)?.toInt() ?? 4;
    
    // Myo-reps: activation set, then mini-sets until failure
    if (!state.activationSetCompleted) {
      // First set: activation set
      return IntensifierSetDirective(
        setType: SetType.restPause, // Uses rest-pause flow
        fields: {
          'rpRestSec': restSec,
          'rpBursts': [activationReps], // Single activation burst
        },
        lockStructure: false,
        ruleName: intensifierName ?? 'Myo-Reps',
        metadata: {
          'phase': 'activation',
          'activation_reps': activationReps,
        },
      );
    } else {
      // Subsequent sets: mini-sets
      final bursts = <int>[];
      for (int i = 0; i < targetMiniSets; i++) {
        bursts.add(miniSetReps);
      }
      
      return IntensifierSetDirective(
        setType: SetType.restPause,
        fields: {
          'rpRestSec': restSec,
          'rpBursts': bursts,
        },
        lockStructure: false,
        ruleName: intensifierName ?? 'Myo-Reps',
        metadata: {
          'phase': 'mini_sets',
          'mini_set_reps': miniSetReps,
        },
      );
    }
  }
  
  /// Check if tempo rule exists (doesn't change SetType, but enforces tempo)
  bool hasTempoRule() {
    return rules.containsKey('tempo');
  }
  
  /// Get tempo from rules (if not in Exercise.tempo)
  String? getTempoFromRules() {
    final tempo = rules['tempo'];
    if (tempo is Map<String, dynamic>) {
      // Format: {eccentric: 3, pause_bottom: 1, concentric: 1, pause_top: 0}
      final e = (tempo['eccentric'] as num?)?.toInt() ?? 0;
      final pb = (tempo['pause_bottom'] as num?)?.toInt() ?? 0;
      final c = (tempo['concentric'] as num?)?.toInt() ?? 0;
      final pt = (tempo['pause_top'] as num?)?.toInt() ?? 0;
      return '$e-$pb-$c-$pt';
    } else if (tempo is String) {
      return tempo;
    }
    return null;
  }
  
  /// Check if isometric rule exists
  bool hasIsometricRule() {
    return rules.containsKey('isometric') || 
           rules.containsKey('yielding_isometric') ||
           rules.containsKey('overcoming_isometric');
  }
  
  /// Get isometric hold seconds from rules
  int? getIsometricHoldSeconds() {
    final iso = rules['isometric'] ?? 
                rules['yielding_isometric'] ?? 
                rules['overcoming_isometric'] as Map<String, dynamic>?;
    if (iso == null) return null;
    return (iso['hold_seconds'] as num?)?.toInt();
  }
  
  /// Check if partials rule exists
  bool hasPartialsRule() {
    return rules.containsKey('partials') ||
           rules.containsKey('lengthened_partials') ||
           rules.containsKey('partial_top') ||
           rules.containsKey('partial_bottom');
  }
  
  /// Get partials ROM percent from rules
  double? getPartialsROMPercent() {
    final partial = rules['partials'] ??
                    rules['lengthened_partials'] ??
                    rules['partial_top'] ??
                    rules['partial_bottom'] as Map<String, dynamic>?;
    if (partial == null) return null;
    return (partial['rom_percent'] as num?)?.toDouble();
  }
}
