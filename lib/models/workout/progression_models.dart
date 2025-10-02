/// Progression Models and Enums
///
/// Data models for intelligent workout progression
library;

/// Progression type
enum ProgressionType {
  linear,           // Add weight each week (e.g., +2.5kg)
  waveUndulating,   // Vary intensity week to week
  blockPeriodization, // Focus on different qualities in blocks
  dup,              // Daily Undulating Periodization
  percentageBased,  // Based on % of 1RM
  custom,           // Custom progression pattern
}

/// Progression result
class ProgressionResult {
  final bool success;
  final String message;
  final double? suggestedWeightIncrease;
  final bool needsDeload;
  final int? deloadWeekNumber;
  final List<String> recommendations;

  ProgressionResult({
    required this.success,
    required this.message,
    this.suggestedWeightIncrease,
    this.needsDeload = false,
    this.deloadWeekNumber,
    this.recommendations = const [],
  });
}

/// Plateau detection result
class PlateauDetection {
  final bool isPlateaued;
  final String reason;
  final int weeksStagnant;
  final List<String> suggestions;
  final double confidenceScore; // 0.0 to 1.0

  PlateauDetection({
    required this.isPlateaued,
    required this.reason,
    this.weeksStagnant = 0,
    this.suggestions = const [],
    this.confidenceScore = 0.0,
  });
}

/// Progression rate
class ProgressionRate {
  final String exerciseName;
  final double weeklyGainPercentage;
  final double totalGainPercentage;
  final int weeksTracked;
  final String trend; // 'improving', 'stable', 'declining'
  final Map<String, double> metrics;

  ProgressionRate({
    required this.exerciseName,
    required this.weeklyGainPercentage,
    required this.totalGainPercentage,
    required this.weeksTracked,
    required this.trend,
    this.metrics = const {},
  });
}

/// Volume landmark (PR celebration)
class VolumeLandmark {
  final String type; // 'weight_pr', 'volume_pr', 'reps_pr', 'tonnage_pr'
  final String exerciseName;
  final double previousValue;
  final double newValue;
  final double improvement;
  final DateTime achievedAt;
  final String description;

  VolumeLandmark({
    required this.type,
    required this.exerciseName,
    required this.previousValue,
    required this.newValue,
    required this.improvement,
    required this.achievedAt,
    required this.description,
  });

  String get celebrationMessage {
    switch (type) {
      case 'weight_pr':
        return '🎉 New Weight PR! $exerciseName: ${newValue.toStringAsFixed(1)}kg (${improvement.toStringAsFixed(1)}% increase)';
      case 'volume_pr':
        return '💪 New Volume PR! $exerciseName: ${newValue.toStringAsFixed(0)}kg total volume';
      case 'reps_pr':
        return '🔥 New Reps PR! $exerciseName: ${newValue.toInt()} reps';
      case 'tonnage_pr':
        return '🏋️ New Tonnage PR! Total lifted: ${(newValue / 1000).toStringAsFixed(1)} tons';
      default:
        return '✨ New PR! $exerciseName';
    }
  }
}

/// Deload recommendation
class DeloadRecommendation {
  final bool shouldDeload;
  final int recommendedWeekNumber;
  final String reason;
  final double intensityReduction; // 0.4 to 0.7 (40-70% reduction)
  final List<String> signs;

  DeloadRecommendation({
    required this.shouldDeload,
    required this.recommendedWeekNumber,
    required this.reason,
    this.intensityReduction = 0.5, // 50% reduction by default
    this.signs = const [],
  });
}

/// Progression settings
class ProgressionSettings {
  final ProgressionType type;
  final double linearIncreasePercentage; // e.g., 2.5% per week
  final double minimumWeightIncrement; // e.g., 2.5kg
  final int deloadFrequency; // e.g., every 4-6 weeks
  final double deloadIntensity; // e.g., 0.5 (50% reduction)
  final bool autoDetectPlateau;
  final double targetRPE; // e.g., 7-8
  final Map<String, dynamic> customSettings;

  ProgressionSettings({
    this.type = ProgressionType.linear,
    this.linearIncreasePercentage = 2.5,
    this.minimumWeightIncrement = 2.5,
    this.deloadFrequency = 4,
    this.deloadIntensity = 0.5,
    this.autoDetectPlateau = true,
    this.targetRPE = 7.5,
    this.customSettings = const {},
  });

  ProgressionSettings copyWith({
    ProgressionType? type,
    double? linearIncreasePercentage,
    double? minimumWeightIncrement,
    int? deloadFrequency,
    double? deloadIntensity,
    bool? autoDetectPlateau,
    double? targetRPE,
    Map<String, dynamic>? customSettings,
  }) {
    return ProgressionSettings(
      type: type ?? this.type,
      linearIncreasePercentage: linearIncreasePercentage ?? this.linearIncreasePercentage,
      minimumWeightIncrement: minimumWeightIncrement ?? this.minimumWeightIncrement,
      deloadFrequency: deloadFrequency ?? this.deloadFrequency,
      deloadIntensity: deloadIntensity ?? this.deloadIntensity,
      autoDetectPlateau: autoDetectPlateau ?? this.autoDetectPlateau,
      targetRPE: targetRPE ?? this.targetRPE,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

/// Wave progression pattern (for undulating periodization)
class WavePattern {
  final String name;
  final List<double> intensityMultipliers; // e.g., [1.0, 0.9, 1.1, 0.85]
  final String description;

  WavePattern({
    required this.name,
    required this.intensityMultipliers,
    required this.description,
  });

  static WavePattern get standard => WavePattern(
    name: 'Standard Wave',
    intensityMultipliers: [1.0, 0.9, 1.05, 0.85],
    description: 'Medium → Light → Heavy → Deload',
  );

  static WavePattern get aggressive => WavePattern(
    name: 'Aggressive Wave',
    intensityMultipliers: [1.0, 1.05, 1.1, 0.8],
    description: 'Medium → Heavy → Very Heavy → Deload',
  );

  static WavePattern get conservative => WavePattern(
    name: 'Conservative Wave',
    intensityMultipliers: [1.0, 0.95, 1.0, 0.9],
    description: 'Medium → Light-Medium → Medium → Light',
  );
}

/// Block periodization phase
enum TrainingPhase {
  accumulation,  // High volume, moderate intensity
  intensification, // Moderate volume, high intensity
  realization,   // Low volume, peak intensity
  deload,        // Recovery phase
}

/// Block periodization settings
class BlockSettings {
  final TrainingPhase phase;
  final int durationWeeks;
  final double volumeMultiplier;
  final double intensityMultiplier;

  BlockSettings({
    required this.phase,
    required this.durationWeeks,
    required this.volumeMultiplier,
    required this.intensityMultiplier,
  });

  static List<BlockSettings> get standardCycle => [
    BlockSettings(
      phase: TrainingPhase.accumulation,
      durationWeeks: 4,
      volumeMultiplier: 1.2,
      intensityMultiplier: 0.85,
    ),
    BlockSettings(
      phase: TrainingPhase.intensification,
      durationWeeks: 3,
      volumeMultiplier: 0.9,
      intensityMultiplier: 1.1,
    ),
    BlockSettings(
      phase: TrainingPhase.realization,
      durationWeeks: 2,
      volumeMultiplier: 0.7,
      intensityMultiplier: 1.2,
    ),
    BlockSettings(
      phase: TrainingPhase.deload,
      durationWeeks: 1,
      volumeMultiplier: 0.5,
      intensityMultiplier: 0.6,
    ),
  ];
}

/// DUP (Daily Undulating Periodization) template
class DUPTemplate {
  final String dayType; // 'heavy', 'moderate', 'light'
  final double intensityMultiplier;
  final double volumeMultiplier;

  DUPTemplate({
    required this.dayType,
    required this.intensityMultiplier,
    required this.volumeMultiplier,
  });

  static List<DUPTemplate> get standardWeek => [
    DUPTemplate(
      dayType: 'heavy',
      intensityMultiplier: 1.0,
      volumeMultiplier: 0.8,
    ),
    DUPTemplate(
      dayType: 'moderate',
      intensityMultiplier: 0.85,
      volumeMultiplier: 1.0,
    ),
    DUPTemplate(
      dayType: 'light',
      intensityMultiplier: 0.7,
      volumeMultiplier: 1.2,
    ),
  ];
}

/// Auto-progression decision
class ProgressionDecision {
  final bool shouldProgress;
  final String reason;
  final double suggestedWeightChange;
  final int? suggestedRepsChange;
  final int? suggestedSetsChange;
  final double confidence; // 0.0 to 1.0

  ProgressionDecision({
    required this.shouldProgress,
    required this.reason,
    this.suggestedWeightChange = 0.0,
    this.suggestedRepsChange,
    this.suggestedSetsChange,
    this.confidence = 0.0,
  });

  bool get isHighConfidence => confidence >= 0.8;
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.8;
  bool get isLowConfidence => confidence < 0.5;
}