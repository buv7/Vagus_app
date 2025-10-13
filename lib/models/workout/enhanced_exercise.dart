/// Enhanced Exercise Model with Advanced Training Methods
/// Supports all modern training techniques and programming methods
class EnhancedExercise {
  final String? id;
  final String dayId;
  final int orderIndex;

  // === BASIC INFORMATION ===
  final String name;
  final ExerciseCategory category;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String equipmentRequired;
  final DifficultyLevel difficulty;

  // === STANDARD PARAMETERS ===
  final int? sets;
  final String? reps; // Can be "8-12", "AMRAP", "8", etc.
  final double? weight;
  final String weightUnit; // kg, lbs, bodyweight, band
  final int? rest; // Rest in seconds

  // === INTENSITY MARKERS ===
  final String? tempo; // "3-1-2-0" format (eccentric-pause-concentric-pause)
  final int? rir; // Reps in Reserve (0-5)
  final double? rpe; // Rate of Perceived Exertion (1-10)
  final int? percent1RM; // Percentage of 1RM (0-100)

  // === ADVANCED TRAINING METHODS ===
  // Drop Sets
  final List<DropSet>? dropSets;

  // Rest-Pause
  final bool restPause;
  final RestPauseConfig? restPauseConfig;

  // Cluster Sets
  final bool clusterSets;
  final ClusterSetConfig? clusterSetConfig;

  // Mechanical Drop Sets (exercise variations)
  final List<String>? mechanicalDropsetExercises;

  // Isometric Holds
  final int? isometricHoldSeconds;
  final IsometricPosition? isometricPosition; // top, mid, bottom

  // Partial Reps
  final PartialRepsConfig? partialReps;

  // Forced Reps
  final int? forcedReps;

  // Negative Reps (eccentric focus)
  final NegativeRepsConfig? negativeReps;

  // 21s Method (7+7+7)
  final bool twentyOneMethod;

  // Pyramid Scheme
  final PyramidScheme? pyramidScheme;

  // Wave Loading
  final WaveLoadingConfig? waveLoading;

  // === GROUPING & PROGRAMMING ===
  final String? groupId; // For supersets, circuits, etc.
  final TrainingMethod trainingMethod;
  final int? groupOrder; // Order within the group

  // === CARDIO/METABOLIC ===
  final bool isCardio;
  final CardioType? cardioType;
  final int? targetHeartRate;
  final String? heartRateZone; // Z1, Z2, Z3, Z4, Z5
  final int? durationMinutes;
  final double? distance;
  final String? distanceUnit; // km, miles, meters

  // === RECOVERY & MOBILITY ===
  final bool isMobility;
  final bool isWarmup;
  final bool isCooldown;
  final String? mobilityType; // static stretch, dynamic stretch, PNF, foam roll

  // === COACHING & MEDIA ===
  final String? exerciseNote; // Coach's note for this specific instance
  final String? techniqueVideo; // URL to technique video
  final List<String>? setupInstructions;
  final List<String>? formCues;
  final List<String>? safetyConsiderations;
  final List<String>? commonMistakes;

  // === ALTERNATIVES & SUBSTITUTIONS ===
  final List<String>? alternativeExercises;
  final String? substitutionReason; // injury, equipment, preference

  // === TRACKING & HISTORY ===
  final double? previousBest; // Previous best weight/reps
  final DateTime? lastPerformed;
  final double? estimated1RM;
  final double? tonnage;

  // === NUTRITION TIMING ===
  final NutritionTiming? nutritionTiming;

  // === METADATA ===
  final List<String>? mediaUrls;
  final Map<String, dynamic>? customData;
  final DateTime createdAt;
  final DateTime updatedAt;

  EnhancedExercise({
    this.id,
    required this.dayId,
    required this.orderIndex,
    required this.name,
    this.category = ExerciseCategory.compound,
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
    this.equipmentRequired = 'Barbell',
    this.difficulty = DifficultyLevel.intermediate,
    this.sets,
    this.reps,
    this.weight,
    this.weightUnit = 'kg',
    this.rest,
    this.tempo,
    this.rir,
    this.rpe,
    this.percent1RM,
    this.dropSets,
    this.restPause = false,
    this.restPauseConfig,
    this.clusterSets = false,
    this.clusterSetConfig,
    this.mechanicalDropsetExercises,
    this.isometricHoldSeconds,
    this.isometricPosition,
    this.partialReps,
    this.forcedReps,
    this.negativeReps,
    this.twentyOneMethod = false,
    this.pyramidScheme,
    this.waveLoading,
    this.groupId,
    this.trainingMethod = TrainingMethod.straightSets,
    this.groupOrder,
    this.isCardio = false,
    this.cardioType,
    this.targetHeartRate,
    this.heartRateZone,
    this.durationMinutes,
    this.distance,
    this.distanceUnit,
    this.isMobility = false,
    this.isWarmup = false,
    this.isCooldown = false,
    this.mobilityType,
    this.exerciseNote,
    this.techniqueVideo,
    this.setupInstructions,
    this.formCues,
    this.safetyConsiderations,
    this.commonMistakes,
    this.alternativeExercises,
    this.substitutionReason,
    this.previousBest,
    this.lastPerformed,
    this.estimated1RM,
    this.tonnage,
    this.nutritionTiming,
    this.mediaUrls,
    this.customData,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : primaryMuscles = primaryMuscles ?? [],
        secondaryMuscles = secondaryMuscles ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'day_id': dayId,
      'order_index': orderIndex,
      'name': name,
      'category': category.value,
      'primary_muscles': primaryMuscles,
      'secondary_muscles': secondaryMuscles,
      'equipment_required': equipmentRequired,
      'difficulty': difficulty.value,
      if (sets != null) 'sets': sets,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      'weight_unit': weightUnit,
      if (rest != null) 'rest': rest,
      if (tempo != null) 'tempo': tempo,
      if (rir != null) 'rir': rir,
      if (rpe != null) 'rpe': rpe,
      if (percent1RM != null) 'percent_1rm': percent1RM,
      if (dropSets != null) 'drop_sets': dropSets!.map((d) => d.toMap()).toList(),
      'rest_pause': restPause,
      if (restPauseConfig != null) 'rest_pause_config': restPauseConfig!.toMap(),
      'cluster_sets': clusterSets,
      if (clusterSetConfig != null) 'cluster_set_config': clusterSetConfig!.toMap(),
      if (mechanicalDropsetExercises != null) 'mechanical_dropset_exercises': mechanicalDropsetExercises,
      if (isometricHoldSeconds != null) 'isometric_hold_seconds': isometricHoldSeconds,
      if (isometricPosition != null) 'isometric_position': isometricPosition!.value,
      if (partialReps != null) 'partial_reps': partialReps!.toMap(),
      if (forcedReps != null) 'forced_reps': forcedReps,
      if (negativeReps != null) 'negative_reps': negativeReps!.toMap(),
      'twenty_one_method': twentyOneMethod,
      if (pyramidScheme != null) 'pyramid_scheme': pyramidScheme!.value,
      if (waveLoading != null) 'wave_loading': waveLoading!.toMap(),
      if (groupId != null) 'group_id': groupId,
      'training_method': trainingMethod.value,
      if (groupOrder != null) 'group_order': groupOrder,
      'is_cardio': isCardio,
      if (cardioType != null) 'cardio_type': cardioType!.value,
      if (targetHeartRate != null) 'target_heart_rate': targetHeartRate,
      if (heartRateZone != null) 'heart_rate_zone': heartRateZone,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (distance != null) 'distance': distance,
      if (distanceUnit != null) 'distance_unit': distanceUnit,
      'is_mobility': isMobility,
      'is_warmup': isWarmup,
      'is_cooldown': isCooldown,
      if (mobilityType != null) 'mobility_type': mobilityType,
      if (exerciseNote != null) 'exercise_note': exerciseNote,
      if (techniqueVideo != null) 'technique_video': techniqueVideo,
      if (setupInstructions != null) 'setup_instructions': setupInstructions,
      if (formCues != null) 'form_cues': formCues,
      if (safetyConsiderations != null) 'safety_considerations': safetyConsiderations,
      if (commonMistakes != null) 'common_mistakes': commonMistakes,
      if (alternativeExercises != null) 'alternative_exercises': alternativeExercises,
      if (substitutionReason != null) 'substitution_reason': substitutionReason,
      if (previousBest != null) 'previous_best': previousBest,
      if (lastPerformed != null) 'last_performed': lastPerformed!.toIso8601String(),
      if (estimated1RM != null) 'estimated_1rm': estimated1RM,
      if (tonnage != null) 'tonnage': tonnage,
      if (nutritionTiming != null) 'nutrition_timing': nutritionTiming!.toMap(),
      if (mediaUrls != null) 'media_urls': mediaUrls,
      if (customData != null) 'custom_data': customData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EnhancedExercise copyWith({
    String? id,
    String? dayId,
    int? orderIndex,
    String? name,
    ExerciseCategory? category,
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
    String? equipmentRequired,
    DifficultyLevel? difficulty,
    int? sets,
    String? reps,
    double? weight,
    String? weightUnit,
    int? rest,
    String? tempo,
    int? rir,
    double? rpe,
    int? percent1RM,
    List<DropSet>? dropSets,
    bool? restPause,
    RestPauseConfig? restPauseConfig,
    bool? clusterSets,
    ClusterSetConfig? clusterSetConfig,
    List<String>? mechanicalDropsetExercises,
    int? isometricHoldSeconds,
    IsometricPosition? isometricPosition,
    PartialRepsConfig? partialReps,
    int? forcedReps,
    NegativeRepsConfig? negativeReps,
    bool? twentyOneMethod,
    PyramidScheme? pyramidScheme,
    WaveLoadingConfig? waveLoading,
    String? groupId,
    TrainingMethod? trainingMethod,
    int? groupOrder,
    bool? isCardio,
    CardioType? cardioType,
    int? targetHeartRate,
    String? heartRateZone,
    int? durationMinutes,
    double? distance,
    String? distanceUnit,
    bool? isMobility,
    bool? isWarmup,
    bool? isCooldown,
    String? mobilityType,
    String? exerciseNote,
    String? techniqueVideo,
    List<String>? setupInstructions,
    List<String>? formCues,
    List<String>? safetyConsiderations,
    List<String>? commonMistakes,
    List<String>? alternativeExercises,
    String? substitutionReason,
    double? previousBest,
    DateTime? lastPerformed,
    double? estimated1RM,
    double? tonnage,
    NutritionTiming? nutritionTiming,
    List<String>? mediaUrls,
    Map<String, dynamic>? customData,
  }) {
    return EnhancedExercise(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      orderIndex: orderIndex ?? this.orderIndex,
      name: name ?? this.name,
      category: category ?? this.category,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipmentRequired: equipmentRequired ?? this.equipmentRequired,
      difficulty: difficulty ?? this.difficulty,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      rest: rest ?? this.rest,
      tempo: tempo ?? this.tempo,
      rir: rir ?? this.rir,
      rpe: rpe ?? this.rpe,
      percent1RM: percent1RM ?? this.percent1RM,
      dropSets: dropSets ?? this.dropSets,
      restPause: restPause ?? this.restPause,
      restPauseConfig: restPauseConfig ?? this.restPauseConfig,
      clusterSets: clusterSets ?? this.clusterSets,
      clusterSetConfig: clusterSetConfig ?? this.clusterSetConfig,
      mechanicalDropsetExercises: mechanicalDropsetExercises ?? this.mechanicalDropsetExercises,
      isometricHoldSeconds: isometricHoldSeconds ?? this.isometricHoldSeconds,
      isometricPosition: isometricPosition ?? this.isometricPosition,
      partialReps: partialReps ?? this.partialReps,
      forcedReps: forcedReps ?? this.forcedReps,
      negativeReps: negativeReps ?? this.negativeReps,
      twentyOneMethod: twentyOneMethod ?? this.twentyOneMethod,
      pyramidScheme: pyramidScheme ?? this.pyramidScheme,
      waveLoading: waveLoading ?? this.waveLoading,
      groupId: groupId ?? this.groupId,
      trainingMethod: trainingMethod ?? this.trainingMethod,
      groupOrder: groupOrder ?? this.groupOrder,
      isCardio: isCardio ?? this.isCardio,
      cardioType: cardioType ?? this.cardioType,
      targetHeartRate: targetHeartRate ?? this.targetHeartRate,
      heartRateZone: heartRateZone ?? this.heartRateZone,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      distance: distance ?? this.distance,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      isMobility: isMobility ?? this.isMobility,
      isWarmup: isWarmup ?? this.isWarmup,
      isCooldown: isCooldown ?? this.isCooldown,
      mobilityType: mobilityType ?? this.mobilityType,
      exerciseNote: exerciseNote ?? this.exerciseNote,
      techniqueVideo: techniqueVideo ?? this.techniqueVideo,
      setupInstructions: setupInstructions ?? this.setupInstructions,
      formCues: formCues ?? this.formCues,
      safetyConsiderations: safetyConsiderations ?? this.safetyConsiderations,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      alternativeExercises: alternativeExercises ?? this.alternativeExercises,
      substitutionReason: substitutionReason ?? this.substitutionReason,
      previousBest: previousBest ?? this.previousBest,
      lastPerformed: lastPerformed ?? this.lastPerformed,
      estimated1RM: estimated1RM ?? this.estimated1RM,
      tonnage: tonnage ?? this.tonnage,
      nutritionTiming: nutritionTiming ?? this.nutritionTiming,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      customData: customData ?? this.customData,
    );
  }
}

// === SUPPORTING CLASSES ===

class DropSet {
  final int setNumber;
  final double weightReduction; // Percentage or absolute
  final int reps;

  DropSet({required this.setNumber, required this.weightReduction, required this.reps});

  Map<String, dynamic> toMap() => {
    'set_number': setNumber,
    'weight_reduction': weightReduction,
    'reps': reps,
  };
}

class RestPauseConfig {
  final int activationReps;
  final int restSeconds;
  final int miniSets;
  final int repsPerMiniSet;

  RestPauseConfig({
    required this.activationReps,
    required this.restSeconds,
    required this.miniSets,
    required this.repsPerMiniSet,
  });

  Map<String, dynamic> toMap() => {
    'activation_reps': activationReps,
    'rest_seconds': restSeconds,
    'mini_sets': miniSets,
    'reps_per_mini_set': repsPerMiniSet,
  };
}

class ClusterSetConfig {
  final int repsPerCluster;
  final int clusters;
  final int restBetweenClusters;

  ClusterSetConfig({
    required this.repsPerCluster,
    required this.clusters,
    required this.restBetweenClusters,
  });

  Map<String, dynamic> toMap() => {
    'reps_per_cluster': repsPerCluster,
    'clusters': clusters,
    'rest_between_clusters': restBetweenClusters,
  };
}

class PartialRepsConfig {
  final String rangeOfMotion; // "top half", "bottom half", "full"
  final int reps;

  PartialRepsConfig({required this.rangeOfMotion, required this.reps});

  Map<String, dynamic> toMap() => {
    'range_of_motion': rangeOfMotion,
    'reps': reps,
  };
}

class NegativeRepsConfig {
  final int eccentricDurationSeconds;
  final int reps;
  final bool assistedConcentric;

  NegativeRepsConfig({
    required this.eccentricDurationSeconds,
    required this.reps,
    this.assistedConcentric = false,
  });

  Map<String, dynamic> toMap() => {
    'eccentric_duration_seconds': eccentricDurationSeconds,
    'reps': reps,
    'assisted_concentric': assistedConcentric,
  };
}

class WaveLoadingConfig {
  final List<int> wave; // e.g., [3, 2, 1] reps
  final int totalWaves;

  WaveLoadingConfig({required this.wave, required this.totalWaves});

  Map<String, dynamic> toMap() => {
    'wave': wave,
    'total_waves': totalWaves,
  };
}

class NutritionTiming {
  final String? preworkout; // "30g carbs"
  final String? intraworkout; // "15g EAAs"
  final String? postworkout; // "30g protein, 50g carbs"

  NutritionTiming({this.preworkout, this.intraworkout, this.postworkout});

  Map<String, dynamic> toMap() => {
    if (preworkout != null) 'preworkout': preworkout,
    if (intraworkout != null) 'intraworkout': intraworkout,
    if (postworkout != null) 'postworkout': postworkout,
  };
}

// === ENUMS ===

enum ExerciseCategory {
  compound,
  isolation,
  power,
  olympic,
  plyometric,
  stabilization,
  ;

  String get value => name;

  static ExerciseCategory fromString(String? value) {
    return ExerciseCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExerciseCategory.compound,
    );
  }
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  expert,
  ;

  String get value => name;

  static DifficultyLevel fromString(String? value) {
    return DifficultyLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DifficultyLevel.intermediate,
    );
  }
}

enum TrainingMethod {
  straightSets,
  superset,
  triset,
  giantSet,
  circuit,
  dropSet,
  restPause,
  pyramidSet,
  waveLoading,
  emom,
  amrap,
  myoReps,
  twentyOnes,
  tempoTraining,
  clusterSet,
  ;

  String get value => name;
  String get displayName {
    switch (this) {
      case TrainingMethod.straightSets:
        return 'Straight Sets';
      case TrainingMethod.superset:
        return 'Superset';
      case TrainingMethod.triset:
        return 'Tri-set';
      case TrainingMethod.giantSet:
        return 'Giant Set';
      case TrainingMethod.circuit:
        return 'Circuit';
      case TrainingMethod.dropSet:
        return 'Drop Set';
      case TrainingMethod.restPause:
        return 'Rest-Pause';
      case TrainingMethod.pyramidSet:
        return 'Pyramid Set';
      case TrainingMethod.waveLoading:
        return 'Wave Loading';
      case TrainingMethod.emom:
        return 'EMOM';
      case TrainingMethod.amrap:
        return 'AMRAP';
      case TrainingMethod.myoReps:
        return 'Myo-Reps';
      case TrainingMethod.twentyOnes:
        return '21s Method';
      case TrainingMethod.tempoTraining:
        return 'Tempo Training';
      case TrainingMethod.clusterSet:
        return 'Cluster Set';
    }
  }

  static TrainingMethod fromString(String? value) {
    return TrainingMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TrainingMethod.straightSets,
    );
  }
}

enum PyramidScheme {
  ascending,
  descending,
  triangle,
  ;

  String get value => name;

  static PyramidScheme fromString(String? value) {
    return PyramidScheme.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PyramidScheme.ascending,
    );
  }
}

enum IsometricPosition {
  top,
  mid,
  bottom,
  ;

  String get value => name;

  static IsometricPosition fromString(String? value) {
    return IsometricPosition.values.firstWhere(
      (e) => e.value == value,
      orElse: () => IsometricPosition.mid,
    );
  }
}

enum CardioType {
  liss,
  miss,
  hiit,
  sprintIntervals,
  tempo,
  steadyState,
  ;

  String get value => name;
  String get displayName {
    switch (this) {
      case CardioType.liss:
        return 'LISS (Low Intensity)';
      case CardioType.miss:
        return 'MISS (Moderate Intensity)';
      case CardioType.hiit:
        return 'HIIT';
      case CardioType.sprintIntervals:
        return 'Sprint Intervals';
      case CardioType.tempo:
        return 'Tempo';
      case CardioType.steadyState:
        return 'Steady State';
    }
  }

  static CardioType fromString(String? value) {
    return CardioType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CardioType.steadyState,
    );
  }
}
