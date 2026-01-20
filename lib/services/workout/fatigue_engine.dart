// lib/services/workout/fatigue_engine.dart
import '../../models/workout/fatigue_score.dart';

/// Pure Dart fatigue accumulation engine
/// NO UI logic, NO BuildContext, NO DB calls
class FatigueEngine {
  // =====================================================
  // FATIGUE MULTIPLIERS (Constants - No Magic Numbers)
  // =====================================================
  
  // Base set cost multipliers
  static const double _baseLocalMultiplier = 1.0;
  static const double _baseSystemicMultiplier = 0.5;
  static const double _baseConnectiveMultiplier = 0.3;
  
  // RIR-based fatigue scaling (lower RIR = higher fatigue)
  static const double _rirBaseMultiplier = 1.0;
  
  // Intensifier fatigue multipliers
  static const double _restPauseLocalMultiplier = 1.8;
  static const double _restPauseSystemicMultiplier = 1.5;
  static const double _restPauseConnectiveMultiplier = 0.8;
  
  static const double _myoRepsLocalMultiplier = 2.5; // Extreme local
  static const double _myoRepsSystemicMultiplier = 1.2;
  static const double _myoRepsConnectiveMultiplier = 0.5;
  
  static const double _dropSetLocalMultiplier = 1.6;
  static const double _dropSetSystemicMultiplier = 1.0;
  static const double _dropSetConnectiveMultiplier = 1.4; // High connective stress
  
  static const double _clusterLocalMultiplier = 1.2;
  static const double _clusterSystemicMultiplier = 1.3; // Moderate systemic
  static const double _clusterConnectiveMultiplier = 0.9;
  
  static const double _tempoLocalMultiplier = 1.1;
  static const double _tempoSystemicMultiplier = 0.9;
  static const double _tempoConnectiveMultiplier = 1.3; // Connective dominant
  
  static const double _isometricLocalMultiplier = 0.8;
  static const double _isometricSystemicMultiplier = 0.7;
  static const double _isometricConnectiveMultiplier = 1.8; // Connective dominant
  
  static const double _partialsLocalMultiplier = 1.2;
  static const double _partialsSystemicMultiplier = 0.8;
  static const double _partialsConnectiveMultiplier = 1.2;
  
  // Failure penalty
  static const double _failureLocalPenalty = 2.0;
  static const double _failureSystemicPenalty = 3.0;
  static const double _failureConnectivePenalty = 1.5;
  
  // Density penalty (insufficient rest)
  static const double _densitySystemicMultiplier = 1.5; // Only affects systemic
  
  // =====================================================
  // CORE METHODS
  // =====================================================
  
  /// Score a single set
  FatigueScore scoreSet({
    required SetExecutionData set,
    IntensifierExecution? intensifier,
  }) {
    // Start with base set cost
    FatigueScore base = _scoreBaseSet(set);
    
    // Apply intensifier multipliers
    if (intensifier != null) {
      base = base + _scoreIntensifier(set, intensifier);
    }
    
    // Apply failure penalty
    if (set.failed == true) {
      base = base + _scoreFailurePenalty(set);
    }
    
    // Apply density penalty (insufficient rest)
    if (set.actualRestSec != null && set.expectedRestSec != null) {
      if (set.actualRestSec! < set.expectedRestSec!) {
        base = base + _scoreDensityPenalty(set);
      }
    }
    
    return base;
  }
  
  /// Score an exercise (sum of all sets)
  FatigueScore scoreExercise(List<FatigueScore> sets) {
    return sets.fold(FatigueScore.zero, (sum, score) => sum + score);
  }
  
  /// Score a session (sum of all exercises)
  FatigueScore scoreSession(List<FatigueScore> exercises) {
    return exercises.fold(FatigueScore.zero, (sum, score) => sum + score);
  }
  
  // =====================================================
  // PRIVATE HELPER METHODS
  // =====================================================
  
  /// Calculate base set cost from load, reps, and RIR
  FatigueScore _scoreBaseSet(SetExecutionData set) {
    if (set.reps == null || set.reps! <= 0) {
      return FatigueScore.zero;
    }
    
    // Base cost scales with reps
    double baseCost = set.reps!.toDouble();
    
    // RIR scaling: lower RIR = exponentially higher fatigue
    double rirMultiplier = 1.0;
    if (set.rir != null && set.rir! >= 0) {
      // RIR 0 = max fatigue, RIR 5 = minimal fatigue
      // Formula: multiplier = (6 - RIR) / 6, then raised to exponent
      double normalizedRir = (6.0 - set.rir!.clamp(0.0, 5.0)) / 6.0;
      rirMultiplier = _rirBaseMultiplier * 
          (normalizedRir > 0 ? 
            (normalizedRir * normalizedRir * normalizedRir) : // Cubic scaling
            0.1); // Minimum 10% even at RIR 5
    }
    
    // Weight scaling (if available, use %1RM estimate)
    // For now, assume weight contributes linearly (can be enhanced with 1RM data)
    double weightMultiplier = 1.0;
    if (set.weight != null && set.weight! > 0) {
      // Rough estimate: heavier weights = more fatigue
      // Normalize to ~100kg as baseline (adjustable)
      weightMultiplier = 1.0 + (set.weight! / 100.0) * 0.3;
    }
    
    double totalCost = baseCost * rirMultiplier * weightMultiplier;
    
    return FatigueScore(
      local: totalCost * _baseLocalMultiplier,
      systemic: totalCost * _baseSystemicMultiplier,
      connective: totalCost * _baseConnectiveMultiplier,
    );
  }
  
  /// Score intensifier cost
  FatigueScore _scoreIntensifier(
    SetExecutionData set,
    IntensifierExecution intensifier,
  ) {
    FatigueScore base = _scoreBaseSet(set);
    
    // Determine intensifier type from set type or rules
    String? intensifierType = intensifier.intensifierName?.toLowerCase();
    Map<String, dynamic>? rules = intensifier.rules;
    
    // Check set type first
    if (set.setType == 'restPause' || set.rpBursts != null) {
      return FatigueScore(
        local: base.local * (_restPauseLocalMultiplier - 1.0),
        systemic: base.systemic * (_restPauseSystemicMultiplier - 1.0),
        connective: base.connective * (_restPauseConnectiveMultiplier - 1.0),
      );
    }
    
    if (set.setType == 'drop' || set.dropPercents != null) {
      // Drop sets: additional cost per drop
      double dropMultiplier = 1.0 + (set.dropPercents?.length ?? 0) * 0.2;
      return FatigueScore(
        local: base.local * (_dropSetLocalMultiplier * dropMultiplier - 1.0),
        systemic: base.systemic * (_dropSetSystemicMultiplier - 1.0),
        connective: base.connective * (_dropSetConnectiveMultiplier * dropMultiplier - 1.0),
      );
    }
    
    if (set.setType == 'cluster' || set.clusterSize != null) {
      return FatigueScore(
        local: base.local * (_clusterLocalMultiplier - 1.0),
        systemic: base.systemic * (_clusterSystemicMultiplier - 1.0),
        connective: base.connective * (_clusterConnectiveMultiplier - 1.0),
      );
    }
    
    // Check rules for intensifier type
    if (rules != null) {
      if (rules.containsKey('myo_reps') || rules.containsKey('myo-reps') ||
          intensifierType?.contains('myo') == true) {
        return FatigueScore(
          local: base.local * (_myoRepsLocalMultiplier - 1.0),
          systemic: base.systemic * (_myoRepsSystemicMultiplier - 1.0),
          connective: base.connective * (_myoRepsConnectiveMultiplier - 1.0),
        );
      }
      
      if (rules.containsKey('tempo') || intensifierType?.contains('tempo') == true) {
        return FatigueScore(
          local: base.local * (_tempoLocalMultiplier - 1.0),
          systemic: base.systemic * (_tempoSystemicMultiplier - 1.0),
          connective: base.connective * (_tempoConnectiveMultiplier - 1.0),
        );
      }
      
      if (rules.containsKey('isometric') || 
          rules.containsKey('yielding_isometric') ||
          rules.containsKey('overcoming_isometric') ||
          intensifierType?.contains('isometric') == true) {
        return FatigueScore(
          local: base.local * (_isometricLocalMultiplier - 1.0),
          systemic: base.systemic * (_isometricSystemicMultiplier - 1.0),
          connective: base.connective * (_isometricConnectiveMultiplier - 1.0),
        );
      }
      
      if (rules.containsKey('partials') ||
          rules.containsKey('lengthened_partials') ||
          intensifierType?.contains('partial') == true) {
        return FatigueScore(
          local: base.local * (_partialsLocalMultiplier - 1.0),
          systemic: base.systemic * (_partialsSystemicMultiplier - 1.0),
          connective: base.connective * (_partialsConnectiveMultiplier - 1.0),
        );
      }
    }
    
    // No intensifier match
    return FatigueScore.zero;
  }
  
  /// Score failure penalty
  FatigueScore _scoreFailurePenalty(SetExecutionData set) {
    FatigueScore base = _scoreBaseSet(set);
    
    return FatigueScore(
      local: base.local * _failureLocalPenalty,
      systemic: base.systemic * _failureSystemicPenalty,
      connective: base.connective * _failureConnectivePenalty,
    );
  }
  
  /// Score density penalty (insufficient rest)
  FatigueScore _scoreDensityPenalty(SetExecutionData set) {
    if (set.actualRestSec == null || set.expectedRestSec == null) {
      return FatigueScore.zero;
    }
    
    int restDeficit = set.expectedRestSec! - set.actualRestSec!;
    if (restDeficit <= 0) {
      return FatigueScore.zero;
    }
    
    // Penalty scales with rest deficit
    double deficitRatio = restDeficit / set.expectedRestSec!;
    FatigueScore base = _scoreBaseSet(set);
    
    // Only affects systemic fatigue
    return FatigueScore(
      local: 0.0,
      systemic: base.systemic * _densitySystemicMultiplier * deficitRatio,
      connective: 0.0,
    );
  }
}
