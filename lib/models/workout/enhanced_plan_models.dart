import 'enhanced_exercise.dart';

/// Enhanced Week Model with Advanced Programming Features
class EnhancedWorkoutWeek {
  final String? id;
  final String planId;
  final int weekNumber;

  // === WEEK PROGRAMMING ===
  final String? weekName; // "Accumulation Week", "Deload Week", etc.
  final WeekTemplate template;
  final PlanPhase phase;
  final double difficultyRating; // RPE 1-10 for entire week
  final String? focusNote;

  // === PROGRESSION SETTINGS ===
  final double? weightProgressionPercent; // % increase from previous week
  final double? volumeProgressionPercent;
  final ProgressionStrategy progressionStrategy;

  // === PERIODIZATION ===
  final MicrocyclePattern? microcyclePattern; // 3:1, 5:1, etc.
  final bool isDeloadWeek;
  final bool isTestingWeek;
  final bool isRecoveryWeek;

  // === VOLUME METRICS ===
  final double? targetVolume; // Total volume target for the week
  final double? actualVolume; // Actual completed volume
  final int? targetSets;
  final int? actualSets;

  // === ENERGY SYSTEMS ===
  final Map<String, double>? energySystemTargets; // ATP-PC: 20%, Glycolytic: 60%, Oxidative: 20%

  // === METADATA ===
  final String? notes;
  final String? coachInstructions;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested days
  final List<EnhancedWorkoutDay> days;

  EnhancedWorkoutWeek({
    this.id,
    required this.planId,
    required this.weekNumber,
    this.weekName,
    this.template = WeekTemplate.standard,
    this.phase = PlanPhase.accumulation,
    this.difficultyRating = 7.0,
    this.focusNote,
    this.weightProgressionPercent,
    this.volumeProgressionPercent,
    this.progressionStrategy = ProgressionStrategy.linear,
    this.microcyclePattern,
    this.isDeloadWeek = false,
    this.isTestingWeek = false,
    this.isRecoveryWeek = false,
    this.targetVolume,
    this.actualVolume,
    this.targetSets,
    this.actualSets,
    this.energySystemTargets,
    this.notes,
    this.coachInstructions,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.days,
  })  : attachments = attachments ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plan_id': planId,
      'week_number': weekNumber,
      if (weekName != null) 'week_name': weekName,
      'template': template.value,
      'phase': phase.value,
      'difficulty_rating': difficultyRating,
      if (focusNote != null) 'focus_note': focusNote,
      if (weightProgressionPercent != null) 'weight_progression_percent': weightProgressionPercent,
      if (volumeProgressionPercent != null) 'volume_progression_percent': volumeProgressionPercent,
      'progression_strategy': progressionStrategy.value,
      if (microcyclePattern != null) 'microcycle_pattern': microcyclePattern!.value,
      'is_deload_week': isDeloadWeek,
      'is_testing_week': isTestingWeek,
      'is_recovery_week': isRecoveryWeek,
      if (targetVolume != null) 'target_volume': targetVolume,
      if (actualVolume != null) 'actual_volume': actualVolume,
      if (targetSets != null) 'target_sets': targetSets,
      if (actualSets != null) 'actual_sets': actualSets,
      if (energySystemTargets != null) 'energy_system_targets': energySystemTargets,
      if (notes != null) 'notes': notes,
      if (coachInstructions != null) 'coach_instructions': coachInstructions,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'days': days.map((day) => day.toMap()).toList(),
    };
  }

  EnhancedWorkoutWeek copyWith({
    String? id,
    String? planId,
    int? weekNumber,
    String? weekName,
    WeekTemplate? template,
    PlanPhase? phase,
    double? difficultyRating,
    String? focusNote,
    double? weightProgressionPercent,
    double? volumeProgressionPercent,
    ProgressionStrategy? progressionStrategy,
    MicrocyclePattern? microcyclePattern,
    bool? isDeloadWeek,
    bool? isTestingWeek,
    bool? isRecoveryWeek,
    double? targetVolume,
    double? actualVolume,
    int? targetSets,
    int? actualSets,
    Map<String, double>? energySystemTargets,
    String? notes,
    String? coachInstructions,
    List<String>? attachments,
    List<EnhancedWorkoutDay>? days,
  }) {
    return EnhancedWorkoutWeek(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      weekNumber: weekNumber ?? this.weekNumber,
      weekName: weekName ?? this.weekName,
      template: template ?? this.template,
      phase: phase ?? this.phase,
      difficultyRating: difficultyRating ?? this.difficultyRating,
      focusNote: focusNote ?? this.focusNote,
      weightProgressionPercent: weightProgressionPercent ?? this.weightProgressionPercent,
      volumeProgressionPercent: volumeProgressionPercent ?? this.volumeProgressionPercent,
      progressionStrategy: progressionStrategy ?? this.progressionStrategy,
      microcyclePattern: microcyclePattern ?? this.microcyclePattern,
      isDeloadWeek: isDeloadWeek ?? this.isDeloadWeek,
      isTestingWeek: isTestingWeek ?? this.isTestingWeek,
      isRecoveryWeek: isRecoveryWeek ?? this.isRecoveryWeek,
      targetVolume: targetVolume ?? this.targetVolume,
      actualVolume: actualVolume ?? this.actualVolume,
      targetSets: targetSets ?? this.targetSets,
      actualSets: actualSets ?? this.actualSets,
      energySystemTargets: energySystemTargets ?? this.energySystemTargets,
      notes: notes ?? this.notes,
      coachInstructions: coachInstructions ?? this.coachInstructions,
      attachments: attachments ?? this.attachments,
      days: days ?? this.days,
    );
  }
}

/// Enhanced Day Model with Advanced Features
class EnhancedWorkoutDay {
  final String? id;
  final String weekId;
  final int dayNumber;
  final String label;

  // === DAY PROGRAMMING ===
  final DayTemplate dayTemplate;
  final String? dayFocus; // "Push", "Pull", "Legs", "Upper", "Lower", etc.
  final double targetRPE; // Day-specific RPE target

  // === MUSCLE GROUP TARGETING ===
  final Map<String, int>? muscleGroupTargets; // {"chest": 12, "triceps": 8} sets
  final List<String>? primaryMuscleGroups;
  final List<String>? secondaryMuscleGroups;

  // === TIME ESTIMATES ===
  final int? estimatedDurationMinutes;
  final int? actualDurationMinutes;

  // === ENERGY SYSTEMS ===
  final EnergySystemFocus energySystemFocus;

  // === PRE/POST PROTOCOLS ===
  final PreWorkoutProtocol? preworkoutProtocol;
  final List<String>? warmupExercises;
  final List<String>? cooldownExercises;
  final List<String>? stretchingProtocol;
  final List<String>? mobilityWork;

  // === NUTRITION ===
  final DayNutritionPlan? nutritionPlan;

  // === COACHING ===
  final String? dayNote;
  final String? clientComment;
  final List<String>? coachingCues;

  // === METADATA ===
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested exercises
  final List<EnhancedExercise> exercises;

  EnhancedWorkoutDay({
    this.id,
    required this.weekId,
    required this.dayNumber,
    required this.label,
    this.dayTemplate = DayTemplate.standard,
    this.dayFocus,
    this.targetRPE = 7.5,
    this.muscleGroupTargets,
    this.primaryMuscleGroups,
    this.secondaryMuscleGroups,
    this.estimatedDurationMinutes,
    this.actualDurationMinutes,
    this.energySystemFocus = EnergySystemFocus.glycolytic,
    this.preworkoutProtocol,
    this.warmupExercises,
    this.cooldownExercises,
    this.stretchingProtocol,
    this.mobilityWork,
    this.nutritionPlan,
    this.dayNote,
    this.clientComment,
    this.coachingCues,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<EnhancedExercise>? exercises,
  })  : attachments = attachments ?? [],
        exercises = exercises ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'week_id': weekId,
      'day_number': dayNumber,
      'label': label,
      'day_template': dayTemplate.value,
      if (dayFocus != null) 'day_focus': dayFocus,
      'target_rpe': targetRPE,
      if (muscleGroupTargets != null) 'muscle_group_targets': muscleGroupTargets,
      if (primaryMuscleGroups != null) 'primary_muscle_groups': primaryMuscleGroups,
      if (secondaryMuscleGroups != null) 'secondary_muscle_groups': secondaryMuscleGroups,
      if (estimatedDurationMinutes != null) 'estimated_duration_minutes': estimatedDurationMinutes,
      if (actualDurationMinutes != null) 'actual_duration_minutes': actualDurationMinutes,
      'energy_system_focus': energySystemFocus.value,
      if (preworkoutProtocol != null) 'preworkout_protocol': preworkoutProtocol!.toMap(),
      if (warmupExercises != null) 'warmup_exercises': warmupExercises,
      if (cooldownExercises != null) 'cooldown_exercises': cooldownExercises,
      if (stretchingProtocol != null) 'stretching_protocol': stretchingProtocol,
      if (mobilityWork != null) 'mobility_work': mobilityWork,
      if (nutritionPlan != null) 'nutrition_plan': nutritionPlan!.toMap(),
      if (dayNote != null) 'day_note': dayNote,
      if (clientComment != null) 'client_comment': clientComment,
      if (coachingCues != null) 'coaching_cues': coachingCues,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'exercises': exercises.map((ex) => ex.toMap()).toList(),
    };
  }

  bool get isRestDay => exercises.isEmpty;
}

// === SUPPORTING CLASSES ===

class PreWorkoutProtocol {
  final String? caffeine;
  final String? supplements;
  final String? hydration;
  final int? arriveEarlyMinutes;

  PreWorkoutProtocol({
    this.caffeine,
    this.supplements,
    this.hydration,
    this.arriveEarlyMinutes,
  });

  Map<String, dynamic> toMap() => {
    if (caffeine != null) 'caffeine': caffeine,
    if (supplements != null) 'supplements': supplements,
    if (hydration != null) 'hydration': hydration,
    if (arriveEarlyMinutes != null) 'arrive_early_minutes': arriveEarlyMinutes,
  };
}

class DayNutritionPlan {
  final String? preworkoutMeal;
  final String? intraworkoutNutrition;
  final String? postworkoutMeal;
  final Map<String, double>? macros; // {"protein": 40, "carbs": 50, "fat": 20}
  final int? targetCalories;
  final String? hydrationTarget;

  DayNutritionPlan({
    this.preworkoutMeal,
    this.intraworkoutNutrition,
    this.postworkoutMeal,
    this.macros,
    this.targetCalories,
    this.hydrationTarget,
  });

  Map<String, dynamic> toMap() => {
    if (preworkoutMeal != null) 'preworkout_meal': preworkoutMeal,
    if (intraworkoutNutrition != null) 'intraworkout_nutrition': intraworkoutNutrition,
    if (postworkoutMeal != null) 'postworkout_meal': postworkoutMeal,
    if (macros != null) 'macros': macros,
    if (targetCalories != null) 'target_calories': targetCalories,
    if (hydrationTarget != null) 'hydration_target': hydrationTarget,
  };
}

// === ENUMS ===

enum WeekTemplate {
  standard,
  strength,
  volume,
  deload,
  testing,
  recovery,
  intensification,
  accumulation,
  ;

  String get value => name;
  String get displayName {
    switch (this) {
      case WeekTemplate.standard:
        return 'Standard Week';
      case WeekTemplate.strength:
        return 'Strength Week';
      case WeekTemplate.volume:
        return 'Volume Week';
      case WeekTemplate.deload:
        return 'Deload Week';
      case WeekTemplate.testing:
        return 'Testing Week';
      case WeekTemplate.recovery:
        return 'Recovery Week';
      case WeekTemplate.intensification:
        return 'Intensification Week';
      case WeekTemplate.accumulation:
        return 'Accumulation Week';
    }
  }

  static WeekTemplate fromString(String? value) {
    return WeekTemplate.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WeekTemplate.standard,
    );
  }
}

enum PlanPhase {
  accumulation,
  intensification,
  realization,
  deload,
  transition,
  competition,
  ;

  String get value => name;
  String get displayName {
    switch (this) {
      case PlanPhase.accumulation:
        return 'Accumulation (Building Volume)';
      case PlanPhase.intensification:
        return 'Intensification (Increasing Intensity)';
      case PlanPhase.realization:
        return 'Realization (Peaking)';
      case PlanPhase.deload:
        return 'Deload (Recovery)';
      case PlanPhase.transition:
        return 'Transition';
      case PlanPhase.competition:
        return 'Competition';
    }
  }

  static PlanPhase fromString(String? value) {
    return PlanPhase.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PlanPhase.accumulation,
    );
  }
}

enum ProgressionStrategy {
  linear,
  undulating,
  block,
  conjugate,
  autoregulated,
  ;

  String get value => name;
  String get displayName {
    switch (this) {
      case ProgressionStrategy.linear:
        return 'Linear Progression';
      case ProgressionStrategy.undulating:
        return 'Daily Undulating Periodization (DUP)';
      case ProgressionStrategy.block:
        return 'Block Periodization';
      case ProgressionStrategy.conjugate:
        return 'Conjugate Method';
      case ProgressionStrategy.autoregulated:
        return 'Autoregulated (RIR/RPE based)';
    }
  }

  static ProgressionStrategy fromString(String? value) {
    return ProgressionStrategy.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProgressionStrategy.linear,
    );
  }
}

enum MicrocyclePattern {
  threeToOne, // 3 weeks on, 1 week deload
  fourToOne,
  fiveToOne,
  twoToOne,
  ;

  String get value => name;
  String get displayName {
    switch (this) {
      case MicrocyclePattern.threeToOne:
        return '3:1 (3 weeks on, 1 deload)';
      case MicrocyclePattern.fourToOne:
        return '4:1 (4 weeks on, 1 deload)';
      case MicrocyclePattern.fiveToOne:
        return '5:1 (5 weeks on, 1 deload)';
      case MicrocyclePattern.twoToOne:
        return '2:1 (2 weeks on, 1 deload)';
    }
  }

  static MicrocyclePattern fromString(String? value) {
    return MicrocyclePattern.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MicrocyclePattern.threeToOne,
    );
  }
}

enum DayTemplate {
  standard,
  pushPullLegs,
  upperLower,
  fullBody,
  push,
  pull,
  legs,
  upper,
  lower,
  chest,
  back,
  shoulders,
  arms,
  cardio,
  rest,
  ;

  String get value => name;
  String get displayName {
    switch (this) {
      case DayTemplate.standard:
        return 'Standard';
      case DayTemplate.pushPullLegs:
        return 'Push/Pull/Legs';
      case DayTemplate.upperLower:
        return 'Upper/Lower';
      case DayTemplate.fullBody:
        return 'Full Body';
      case DayTemplate.push:
        return 'Push Day';
      case DayTemplate.pull:
        return 'Pull Day';
      case DayTemplate.legs:
        return 'Legs Day';
      case DayTemplate.upper:
        return 'Upper Body';
      case DayTemplate.lower:
        return 'Lower Body';
      case DayTemplate.chest:
        return 'Chest Focus';
      case DayTemplate.back:
        return 'Back Focus';
      case DayTemplate.shoulders:
        return 'Shoulders Focus';
      case DayTemplate.arms:
        return 'Arms Focus';
      case DayTemplate.cardio:
        return 'Cardio Day';
      case DayTemplate.rest:
        return 'Rest Day';
    }
  }

  static DayTemplate fromString(String? value) {
    return DayTemplate.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DayTemplate.standard,
    );
  }
}

enum EnergySystemFocus {
  atpPc, // ATP-PC system (power, strength)
  glycolytic, // Glycolytic (hypertrophy, strength-endurance)
  oxidative, // Oxidative (endurance, recovery)
  mixed,
  ;

  String get value => name;
  String get displayName {
    switch (this) {
      case EnergySystemFocus.atpPc:
        return 'ATP-PC (Power/Strength)';
      case EnergySystemFocus.glycolytic:
        return 'Glycolytic (Hypertrophy)';
      case EnergySystemFocus.oxidative:
        return 'Oxidative (Endurance)';
      case EnergySystemFocus.mixed:
        return 'Mixed Energy Systems';
    }
  }

  static EnergySystemFocus fromString(String? value) {
    return EnergySystemFocus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EnergySystemFocus.glycolytic,
    );
  }
}
