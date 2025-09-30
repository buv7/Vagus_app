import '../../models/workout/workout_plan.dart';
import '../../models/workout/exercise.dart';
import '../../models/workout/progression_models.dart';
import 'workout_service.dart';

/// Intelligent Workout Progression Service
///
/// Automates workout progression using multiple periodization models:
/// - Linear progression
/// - Wave/undulating periodization
/// - Block periodization
/// - DUP (Daily Undulating Periodization)
/// - Percentage-based progression
class ProgressionService {
  final WorkoutService _workoutService = WorkoutService();

  // =====================================================
  // CORE PROGRESSION ALGORITHMS
  // =====================================================

  /// Calculate next week's workout with automatic progression
  Future<WorkoutWeek> calculateNextWeekProgression(
    WorkoutWeek currentWeek, {
    String? clientId,
    ProgressionSettings? settings,
  }) async {
    settings ??= ProgressionSettings();

    // Get exercise history for intelligent progression
    final historyMap = <String, List<ExerciseHistoryEntry>>{};
    if (clientId != null) {
      for (final day in currentWeek.days) {
        for (final exercise in day.exercises) {
          final history = await _workoutService.fetchExerciseHistory(
            clientId: clientId,
            exerciseName: exercise.name,
            limit: 10,
          );
          historyMap[exercise.name] = history;
        }
      }
    }

    // Apply progression based on type
    switch (settings.type) {
      case ProgressionType.linear:
        return _applyLinearProgressionToWeek(currentWeek, settings, historyMap);
      case ProgressionType.waveUndulating:
        // For wave, need multiple weeks - return next wave week
        return _applyWaveProgressionToWeek(currentWeek, settings);
      case ProgressionType.blockPeriodization:
        return _applyBlockProgressionToWeek(currentWeek, settings);
      case ProgressionType.dup:
        return _applyDUPProgressionToWeek(currentWeek, settings);
      case ProgressionType.percentageBased:
        return _applyPercentageProgressionToWeek(currentWeek, settings, historyMap);
      case ProgressionType.custom:
        return _applyCustomProgressionToWeek(currentWeek, settings);
    }
  }

  /// Suggest weight increase based on exercise history
  Future<double> suggestWeightIncrease(
    List<ExerciseHistoryEntry> exerciseHistory, {
    ProgressionSettings? settings,
  }) async {
    if (exerciseHistory.isEmpty) return 0.0;

    settings ??= ProgressionSettings();

    // Analyze recent performance
    final recent = exerciseHistory.take(3).toList();

    // Check if all recent sessions completed successfully
    final allCompleted = recent.every((entry) {
      final completedSets = entry.completedSets;
      final targetSets = entry.sets ?? 0;
      return completedSets >= targetSets;
    });

    if (!allCompleted) {
      return 0.0; // No increase if not completing sets
    }

    // Check RPE if available
    final avgRpe = _calculateAverageRPE(recent);
    if (avgRpe != null && avgRpe >= 9.0) {
      return 0.0; // Too hard, don't increase
    }

    // Calculate suggested increase
    final currentWeight = recent.first.weightUsed;
    final suggestedIncrease = currentWeight * (settings.linearIncreasePercentage / 100);

    // Round to nearest increment
    final increment = settings.minimumWeightIncrement;
    return (suggestedIncrease / increment).ceil() * increment;
  }

  /// Detect if athlete has plateaued
  Future<PlateauDetection> detectPlateau(
    List<ExerciseHistoryEntry> exerciseHistory,
  ) async {
    if (exerciseHistory.length < 4) {
      return PlateauDetection(
        isPlateaued: false,
        reason: 'Insufficient data',
        confidenceScore: 0.0,
      );
    }

    // Sort by date
    final sorted = List<ExerciseHistoryEntry>.from(exerciseHistory)
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    // Check weight progression
    final weights = sorted.map((e) => e.weightUsed).toList();
    final hasWeightIncrease = _hasProgression(weights);

    // Check volume progression
    final volumes = sorted.map((e) => e.volume ?? 0).toList();
    final hasVolumeIncrease = _hasProgression(volumes);

    // Check for failed sets
    final recentFailures = sorted.take(4).where((entry) {
      final completedSets = entry.completedSets;
      final targetSets = entry.sets ?? 0;
      return completedSets < targetSets;
    }).length;

    // Determine if plateaued
    final isPlateaued = !hasWeightIncrease && !hasVolumeIncrease;
    final weeksStagnant = isPlateaued ? _countStagnantWeeks(sorted) : 0;

    final suggestions = <String>[];
    if (isPlateaued) {
      if (recentFailures >= 2) {
        suggestions.add('Consider a deload week to recover');
      }
      suggestions.add('Try exercise variations (e.g., different grip, tempo)');
      suggestions.add('Increase training frequency');
      suggestions.add('Check nutrition and sleep quality');
      if (!hasVolumeIncrease) {
        suggestions.add('Add more sets or exercises for this muscle group');
      }
    }

    final confidence = _calculatePlateauConfidence(
      hasWeightIncrease,
      hasVolumeIncrease,
      weeksStagnant,
      recentFailures,
    );

    return PlateauDetection(
      isPlateaued: isPlateaued,
      reason: isPlateaued
          ? 'No progression in weight or volume for $weeksStagnant weeks'
          : 'Normal progression observed',
      weeksStagnant: weeksStagnant,
      suggestions: suggestions,
      confidenceScore: confidence,
    );
  }

  /// Suggest when to schedule deload week
  Future<DeloadRecommendation> suggestDeloadTiming(
    List<WorkoutWeek> weekHistory, {
    ProgressionSettings? settings,
  }) async {
    settings ??= ProgressionSettings();

    final weeksCount = weekHistory.length;

    // Check if due for scheduled deload
    final weeksSinceLastDeload = _weeksSinceLastDeload(weekHistory);
    final isDueForDeload = weeksSinceLastDeload >= settings.deloadFrequency;

    // Check for signs of overtraining
    final signs = <String>[];

    // Analyze recent volume
    if (weeksCount >= 3) {
      final recentVolume = _calculateWeekVolume(weekHistory.last);
      final avgVolume = weekHistory
          .take(weeksCount - 1)
          .map(_calculateWeekVolume)
          .reduce((a, b) => a + b) / (weeksCount - 1);

      if (recentVolume > avgVolume * 1.3) {
        signs.add('Volume spike detected');
      }
    }

    // Check for accumulating fatigue
    final hasHighFatigue = _detectFatigueSigns(weekHistory);
    if (hasHighFatigue) {
      signs.add('Signs of accumulating fatigue');
    }

    final shouldDeload = isDueForDeload || signs.isNotEmpty;
    final recommendedWeek = shouldDeload ? weeksCount + 1 : settings.deloadFrequency;

    return DeloadRecommendation(
      shouldDeload: shouldDeload,
      recommendedWeekNumber: recommendedWeek,
      reason: isDueForDeload
          ? 'Scheduled deload after $weeksSinceLastDeload weeks'
          : signs.isNotEmpty
              ? 'Fatigue indicators present'
              : 'No deload needed yet',
      intensityReduction: settings.deloadIntensity,
      signs: signs,
    );
  }

  /// Apply linear progression to an exercise
  Exercise applyLinearProgression(
    Exercise exercise,
    double percentage, {
    double minimumIncrement = 2.5,
  }) {
    if (exercise.weight == null) return exercise;

    final increase = exercise.weight! * (percentage / 100);
    final rounded = (increase / minimumIncrement).ceil() * minimumIncrement;
    final newWeight = exercise.weight! + rounded;

    return exercise.copyWith(weight: newWeight);
  }

  /// Apply wave progression to multiple weeks
  List<WorkoutWeek> applyWaveProgression(
    List<WorkoutWeek> weeks, {
    WavePattern? pattern,
  }) {
    pattern ??= WavePattern.standard;

    final progressedWeeks = <WorkoutWeek>[];

    for (int i = 0; i < weeks.length; i++) {
      final multiplier = pattern.intensityMultipliers[i % pattern.intensityMultipliers.length];
      final week = weeks[i];

      final progressedDays = week.days.map((day) {
        final progressedExercises = day.exercises.map((exercise) {
          if (exercise.weight == null) return exercise;

          final baseWeight = exercise.weight!;
          final newWeight = baseWeight * multiplier;

          return exercise.copyWith(weight: newWeight);
        }).toList();

        return day.copyWith(exercises: progressedExercises);
      }).toList();

      progressedWeeks.add(week.copyWith(days: progressedDays));
    }

    return progressedWeeks;
  }

  /// Generate deload week from normal week
  WorkoutWeek generateDeloadWeek(
    WorkoutWeek normalWeek, {
    double intensityReduction = 0.5,
  }) {
    final deloadDays = normalWeek.days.map((day) {
      final deloadExercises = day.exercises.map((exercise) {
        Exercise deloadedExercise = exercise;

        // Reduce weight
        if (exercise.weight != null) {
          deloadedExercise = deloadedExercise.copyWith(
            weight: exercise.weight! * (1 - intensityReduction),
          );
        }

        // Reduce sets
        if (exercise.sets != null) {
          final newSets = (exercise.sets! * 0.7).ceil();
          deloadedExercise = deloadedExercise.copyWith(sets: newSets);
        }

        // Lower RIR (more reps in reserve)
        if (exercise.rir != null) {
          deloadedExercise = deloadedExercise.copyWith(
            rir: (exercise.rir! + 2).clamp(0, 10),
          );
        }

        return deloadedExercise;
      }).toList();

      return day.copyWith(exercises: deloadExercises);
    }).toList();

    return normalWeek.copyWith(
      days: deloadDays,
      notes: '${normalWeek.notes ?? ''}\n\n⚡ DELOAD WEEK - Reduced intensity for recovery',
    );
  }

  // =====================================================
  // AUTO-PROGRESSION RULES
  // =====================================================

  /// Make auto-progression decision based on performance
  Future<ProgressionDecision> makeProgressionDecision(
    Exercise exercise,
    List<ExerciseHistoryEntry> history,
  ) async {
    if (history.isEmpty) {
      return ProgressionDecision(
        shouldProgress: false,
        reason: 'No history available',
        confidence: 0.0,
      );
    }

    final recent = history.take(2).toList();
    final latest = recent.first;

    // Check if completed all sets and reps
    final completedAllSets = latest.completedSets >= (exercise.sets ?? 0);
    final avgRpe = _calculateAverageRPE(recent);

    // Rule 1: Completed all sets at RPE < 8 → increase weight
    if (completedAllSets && avgRpe != null && avgRpe < 8.0) {
      final currentWeight = latest.weightUsed;
      final increase = currentWeight * 0.025; // 2.5%

      return ProgressionDecision(
        shouldProgress: true,
        reason: 'Completed all sets at RPE $avgRpe (target: <8)',
        suggestedWeightChange: (increase / 2.5).ceil() * 2.5,
        confidence: 0.9,
      );
    }

    // Rule 2: Failed multiple sets → suggest deload
    final failedSets = (exercise.sets ?? 0) - latest.completedSets;
    if (failedSets >= 2) {
      return ProgressionDecision(
        shouldProgress: false,
        reason: 'Failed $failedSets sets - consider deload',
        suggestedWeightChange: -latest.weightUsed * 0.1, // 10% reduction
        confidence: 0.85,
      );
    }

    // Rule 3: Completed but high RPE → maintain
    if (completedAllSets && avgRpe != null && avgRpe >= 9.0) {
      return ProgressionDecision(
        shouldProgress: false,
        reason: 'Completed but at high RPE ($avgRpe) - maintain weight',
        confidence: 0.8,
      );
    }

    // Rule 4: Check for stagnation
    if (history.length >= 4) {
      final weights = history.take(4).map((e) => e.weightUsed).toList();
      final noProgress = weights.toSet().length == 1;

      if (noProgress) {
        return ProgressionDecision(
          shouldProgress: true,
          reason: 'Weight stagnant for 4+ sessions - try small increase or variation',
          suggestedWeightChange: latest.weightUsed * 0.025,
          confidence: 0.7,
        );
      }
    }

    return ProgressionDecision(
      shouldProgress: false,
      reason: 'Continue with current programming',
      confidence: 0.6,
    );
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  WorkoutWeek _applyLinearProgressionToWeek(
    WorkoutWeek week,
    ProgressionSettings settings,
    Map<String, List<ExerciseHistoryEntry>> historyMap,
  ) {
    final progressedDays = week.days.map((day) {
      final progressedExercises = day.exercises.map((exercise) {
        if (exercise.weight == null) return exercise;

        // Check history for this exercise
        final history = historyMap[exercise.name] ?? [];
        if (history.isEmpty) {
          // No history, apply small increase
          return applyLinearProgression(
            exercise,
            settings.linearIncreasePercentage,
            minimumIncrement: settings.minimumWeightIncrement,
          );
        }

        // Has history, make intelligent decision
        // For now, apply linear if recent performance good
        final recent = history.first;
        if (recent.completedSets >= (exercise.sets ?? 0)) {
          return applyLinearProgression(
            exercise,
            settings.linearIncreasePercentage,
            minimumIncrement: settings.minimumWeightIncrement,
          );
        }

        return exercise; // Don't progress if not completing sets
      }).toList();

      return day.copyWith(exercises: progressedExercises);
    }).toList();

    return week.copyWith(days: progressedDays);
  }

  WorkoutWeek _applyWaveProgressionToWeek(
    WorkoutWeek week,
    ProgressionSettings settings,
  ) {
    // Get wave multiplier for this week
    final pattern = WavePattern.standard;
    final weekNumber = week.weekNumber ?? 1;
    final multiplier = pattern.intensityMultipliers[
      (weekNumber - 1) % pattern.intensityMultipliers.length
    ];

    final progressedDays = week.days.map((day) {
      final progressedExercises = day.exercises.map((exercise) {
        if (exercise.weight == null) return exercise;

        final newWeight = exercise.weight! * multiplier;
        return exercise.copyWith(weight: newWeight);
      }).toList();

      return day.copyWith(exercises: progressedExercises);
    }).toList();

    return week.copyWith(days: progressedDays);
  }

  WorkoutWeek _applyBlockProgressionToWeek(
    WorkoutWeek week,
    ProgressionSettings settings,
  ) {
    // Determine current block phase
    final blockCycle = BlockSettings.standardCycle;
    final weekNumber = week.weekNumber ?? 1;

    BlockSettings currentBlock = blockCycle.first;
    int weeksInCycle = 0;
    for (final block in blockCycle) {
      if (weekNumber <= weeksInCycle + block.durationWeeks) {
        currentBlock = block;
        break;
      }
      weeksInCycle += block.durationWeeks;
    }

    // Apply block multipliers
    final progressedDays = week.days.map((day) {
      final progressedExercises = day.exercises.map((exercise) {
        Exercise progressed = exercise;

        // Adjust weight based on intensity
        if (exercise.weight != null) {
          progressed = progressed.copyWith(
            weight: exercise.weight! * currentBlock.intensityMultiplier,
          );
        }

        // Adjust sets based on volume
        if (exercise.sets != null) {
          final newSets = (exercise.sets! * currentBlock.volumeMultiplier).round();
          progressed = progressed.copyWith(sets: newSets.clamp(1, 10));
        }

        return progressed;
      }).toList();

      return day.copyWith(exercises: progressedExercises);
    }).toList();

    return week.copyWith(days: progressedDays);
  }

  WorkoutWeek _applyDUPProgressionToWeek(
    WorkoutWeek week,
    ProgressionSettings settings,
  ) {
    final dupTemplates = DUPTemplate.standardWeek;

    final progressedDays = <WorkoutDay>[];
    for (int i = 0; i < week.days.length; i++) {
      final day = week.days[i];
      final template = dupTemplates[i % dupTemplates.length];

      final progressedExercises = day.exercises.map((exercise) {
        Exercise progressed = exercise;

        // Adjust weight based on intensity
        if (exercise.weight != null) {
          progressed = progressed.copyWith(
            weight: exercise.weight! * template.intensityMultiplier,
          );
        }

        // Adjust sets based on volume
        if (exercise.sets != null) {
          final newSets = (exercise.sets! * template.volumeMultiplier).round();
          progressed = progressed.copyWith(sets: newSets.clamp(1, 10));
        }

        return progressed;
      }).toList();

      progressedDays.add(day.copyWith(exercises: progressedExercises));
    }

    return week.copyWith(days: progressedDays);
  }

  WorkoutWeek _applyPercentageProgressionToWeek(
    WorkoutWeek week,
    ProgressionSettings settings,
    Map<String, List<ExerciseHistoryEntry>> historyMap,
  ) {
    final progressedDays = week.days.map((day) {
      final progressedExercises = day.exercises.map((exercise) {
        if (exercise.percent1RM == null) return exercise;

        // Calculate weight from 1RM if available
        final history = historyMap[exercise.name] ?? [];
        if (history.isNotEmpty) {
          final latest = history.first;
          final estimated1RM = latest.estimated1RM;

          if (estimated1RM != null) {
            final targetWeight = estimated1RM * (exercise.percent1RM! / 100);
            return exercise.copyWith(weight: targetWeight);
          }
        }

        return exercise;
      }).toList();

      return day.copyWith(exercises: progressedExercises);
    }).toList();

    return week.copyWith(days: progressedDays);
  }

  WorkoutWeek _applyCustomProgressionToWeek(
    WorkoutWeek week,
    ProgressionSettings settings,
  ) {
    // Custom progression logic can be implemented based on settings
    return week;
  }

  double? _calculateAverageRPE(List<ExerciseHistoryEntry> entries) {
    final rpeValues = entries
        .where((e) => e.rpeRating != null)
        .map((e) => e.rpeRating!.toDouble())
        .toList();

    if (rpeValues.isEmpty) return null;

    return rpeValues.reduce((a, b) => a + b) / rpeValues.length;
  }

  bool _hasProgression(List<double> values) {
    if (values.length < 2) return false;

    // Check if there's an upward trend
    int increases = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > values[i - 1]) increases++;
    }

    return increases >= (values.length / 2).floor();
  }

  int _countStagnantWeeks(List<ExerciseHistoryEntry> sorted) {
    if (sorted.length < 2) return 0;

    final latestWeight = sorted.last.weightUsed;
    int weeks = 0;

    for (int i = sorted.length - 2; i >= 0; i--) {
      if (sorted[i].weightUsed == latestWeight) {
        weeks++;
      } else {
        break;
      }
    }

    return weeks + 1; // Include latest week
  }

  double _calculatePlateauConfidence(
    bool hasWeightIncrease,
    bool hasVolumeIncrease,
    int weeksStagnant,
    int recentFailures,
  ) {
    double confidence = 0.0;

    if (!hasWeightIncrease) confidence += 0.3;
    if (!hasVolumeIncrease) confidence += 0.3;
    if (weeksStagnant >= 3) confidence += 0.2;
    if (recentFailures >= 2) confidence += 0.2;

    return confidence.clamp(0.0, 1.0);
  }

  int _weeksSinceLastDeload(List<WorkoutWeek> weeks) {
    // Simple heuristic: check for notes indicating deload
    int count = 0;
    for (int i = weeks.length - 1; i >= 0; i--) {
      final notes = weeks[i].notes?.toLowerCase() ?? '';
      if (notes.contains('deload')) {
        return count;
      }
      count++;
    }
    return count;
  }

  double _calculateWeekVolume(WorkoutWeek week) {
    double total = 0;
    for (final day in week.days) {
      for (final exercise in day.exercises) {
        final volume = exercise.calculateVolume();
        if (volume != null) total += volume;
      }
    }
    return total;
  }

  bool _detectFatigueSigns(List<WorkoutWeek> weeks) {
    // Simple fatigue detection: check for increasing volume trend
    if (weeks.length < 3) return false;

    final volumes = weeks.map(_calculateWeekVolume).toList();
    final recent = volumes.take(3).reduce((a, b) => a + b) / 3;
    final previous = volumes.skip(3).take(3).reduce((a, b) => a + b) / 3;

    return recent > previous * 1.4; // 40% increase
  }
}