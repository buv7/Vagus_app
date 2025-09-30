import '../../../models/workout/workout_plan.dart';
import '../../../models/workout/exercise.dart';

/// Comprehensive validation and safety checker for workout plans
class ValidationHelper {
  /// Validate an entire workout plan
  static ValidationResult validatePlan(WorkoutPlan plan) {
    final errors = <String>[];
    final warnings = <String>[];

    // Basic structure validation
    if (plan.name.trim().isEmpty) {
      errors.add('Plan name is required');
    }

    if (plan.weeks.isEmpty) {
      errors.add('Plan must have at least one week');
    }

    // Validate each week
    for (int i = 0; i < plan.weeks.length; i++) {
      final week = plan.weeks[i];

      if (week.days.isEmpty) {
        warnings.add('Week ${i + 1} has no training days');
        continue;
      }

      // Validate each day
      for (int j = 0; j < week.days.length; j++) {
        final day = week.days[j];

        if (day.label.trim().isEmpty) {
          warnings.add('Week ${i + 1}, Day ${j + 1} has no label');
        }

        // Validate exercises
        for (int k = 0; k < day.exercises.length; k++) {
          final exercise = day.exercises[k];
          final exerciseErrors = validateExercise(exercise);

          for (final error in exerciseErrors) {
            errors.add('Week ${i + 1}, Day ${j + 1}, Exercise ${k + 1}: $error');
          }
        }

        // Check if day is completely empty
        if (day.exercises.isEmpty && day.cardioSessions.isEmpty) {
          warnings.add('Week ${i + 1}, Day ${j + 1} has no exercises or cardio');
        }
      }
    }

    // Safety checks
    final balanceWarnings = checkMuscleBalance(plan);
    warnings.addAll(balanceWarnings.warnings);

    final restDayWarnings = checkRestDays(plan);
    warnings.addAll(restDayWarnings);

    final volumeWarnings = checkExcessiveVolume(plan);
    warnings.addAll(volumeWarnings);

    // Generate summary
    final summary = _generateSummary(errors, warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      summary: summary,
    );
  }

  /// Validate a single exercise
  static List<String> validateExercise(Exercise exercise) {
    final errors = <String>[];

    if (exercise.name.trim().isEmpty) {
      errors.add('Exercise name is required');
    }

    if (exercise.sets != null && exercise.sets! < 1) {
      errors.add('Sets must be at least 1');
    }

    if (exercise.sets != null && exercise.sets! > 20) {
      errors.add('Sets exceeds reasonable limit (20)');
    }

    if (exercise.rest != null && exercise.rest! < 0) {
      errors.add('Rest time cannot be negative');
    }

    if (exercise.rest != null && exercise.rest! > 600) {
      errors.add('Rest time exceeds 10 minutes (consider splitting workout)');
    }

    if (exercise.weight != null && exercise.weight! < 0) {
      errors.add('Weight cannot be negative');
    }

    if (exercise.percent1RM != null &&
        (exercise.percent1RM! < 0 || exercise.percent1RM! > 100)) {
      errors.add('Percent 1RM must be between 0 and 100');
    }

    if (exercise.rir != null && (exercise.rir! < 0 || exercise.rir! > 10)) {
      errors.add('RIR must be between 0 and 10');
    }

    // Validate reps format
    if (exercise.reps != null) {
      final repsValid = _validateRepsFormat(exercise.reps!);
      if (!repsValid) {
        errors.add('Invalid reps format (use "8", "8-12", or "AMRAP")');
      }
    }

    // Validate tempo format
    if (exercise.tempo != null) {
      final tempoValid = _validateTempoFormat(exercise.tempo!);
      if (!tempoValid) {
        errors.add('Invalid tempo format (use "3-0-1-0" format)');
      }
    }

    return errors;
  }

  /// Check muscle group balance
  static BalanceWarnings checkMuscleBalance(WorkoutPlan plan) {
    final warnings = <String>[];
    final muscleGroupCounts = <String, int>{};

    // Count exercises per muscle group
    for (final week in plan.weeks) {
      for (final day in week.days) {
        for (final exercise in day.exercises) {
          // Simple keyword matching for muscle groups
          _categorizeExercise(exercise.name, muscleGroupCounts);
        }
      }
    }

    // Check push/pull balance
    final pushCount = (muscleGroupCounts['chest'] ?? 0) +
        (muscleGroupCounts['shoulders'] ?? 0) +
        (muscleGroupCounts['triceps'] ?? 0);

    final pullCount = (muscleGroupCounts['back'] ?? 0) +
        (muscleGroupCounts['biceps'] ?? 0);

    if (pushCount > pullCount * 1.5) {
      warnings.add(
          'Push exercises ($pushCount) significantly outnumber pull exercises ($pullCount). Consider adding more back/bicep work.');
    } else if (pullCount > pushCount * 1.5) {
      warnings.add(
          'Pull exercises ($pullCount) significantly outnumber push exercises ($pushCount). Consider adding more chest/shoulder work.');
    }

    // Check leg training
    final legCount = (muscleGroupCounts['legs'] ?? 0) +
        (muscleGroupCounts['quads'] ?? 0) +
        (muscleGroupCounts['hamstrings'] ?? 0);

    if (legCount < (pushCount + pullCount) * 0.3) {
      warnings.add(
          'Leg training volume ($legCount exercises) is low relative to upper body. Consider adding more leg exercises.');
    }

    // Check core training
    final coreCount = (muscleGroupCounts['core'] ?? 0) +
        (muscleGroupCounts['abs'] ?? 0);

    if (coreCount == 0 && plan.weeks.length > 1) {
      warnings.add('No dedicated core/ab exercises found. Consider adding core work.');
    }

    return BalanceWarnings(
      warnings: warnings,
      muscleGroupCounts: muscleGroupCounts,
    );
  }

  /// Check for adequate rest days
  static List<String> checkRestDays(WorkoutPlan plan) {
    final warnings = <String>[];
    int consecutiveTrainingDays = 0;
    int maxConsecutiveDays = 0;
    int totalRestDays = 0;
    int totalDays = 0;

    for (final week in plan.weeks) {
      for (final day in week.days) {
        totalDays++;

        if (day.isRestDay) {
          totalRestDays++;
          maxConsecutiveDays = maxConsecutiveDays > consecutiveTrainingDays
              ? maxConsecutiveDays
              : consecutiveTrainingDays;
          consecutiveTrainingDays = 0;
        } else {
          consecutiveTrainingDays++;
        }
      }
    }

    // Check for rest days
    if (totalRestDays == 0 && totalDays > 7) {
      warnings.add(
          'No rest days scheduled. Consider adding at least 1-2 rest days per week for recovery.');
    }

    // Check for excessive consecutive training
    if (maxConsecutiveDays > 5) {
      warnings.add(
          'Up to $maxConsecutiveDays consecutive training days detected. Consider adding rest days to prevent overtraining.');
    }

    return warnings;
  }

  /// Check for excessive volume
  static List<String> checkExcessiveVolume(WorkoutPlan plan) {
    final warnings = <String>[];

    for (int i = 0; i < plan.weeks.length; i++) {
      final week = plan.weeks[i];

      for (int j = 0; j < week.days.length; j++) {
        final day = week.days[j];

        // Check exercise count
        if (day.exercises.length > 15) {
          warnings.add(
              'Week ${i + 1}, Day ${j + 1} has ${day.exercises.length} exercises. Consider splitting into multiple sessions.');
        }

        // Check total sets
        final totalSets =
            day.exercises.fold(0, (sum, ex) => sum + (ex.sets ?? 0));

        if (totalSets > 30) {
          warnings.add(
              'Week ${i + 1}, Day ${j + 1} has $totalSets total sets. High volume may impair recovery.');
        }

        // Check session duration estimate
        final summary = day.getDaySummary();
        if (summary.estimatedDuration > 120) {
          warnings.add(
              'Week ${i + 1}, Day ${j + 1} estimated duration: ${summary.getDurationDisplay()}. Consider shortening the session.');
        }
      }
    }

    return warnings;
  }

  /// Validate exercise name and suggest corrections
  static ExerciseNameValidation validateExerciseName(String name) {
    if (name.trim().isEmpty) {
      return ExerciseNameValidation(
        isValid: false,
        suggestion: null,
        message: 'Exercise name cannot be empty',
      );
    }

    // Check against common exercise database
    final commonExercises = _getCommonExercises();
    final nameLower = name.toLowerCase().trim();

    // Exact match
    if (commonExercises.contains(nameLower)) {
      return ExerciseNameValidation(
        isValid: true,
        suggestion: null,
        message: 'Valid exercise name',
      );
    }

    // Fuzzy match for suggestions
    final suggestions = commonExercises
        .where((ex) => _levenshteinDistance(ex, nameLower) < 3)
        .take(3)
        .toList();

    if (suggestions.isNotEmpty) {
      return ExerciseNameValidation(
        isValid: true,
        suggestion: suggestions.first,
        message: 'Did you mean "${suggestions.first}"?',
      );
    }

    return ExerciseNameValidation(
      isValid: true,
      suggestion: null,
      message: 'Custom exercise name',
    );
  }

  // Helper methods

  static bool _validateRepsFormat(String reps) {
    // Valid formats: "8", "8-12", "AMRAP", "max", "failure"
    final patterns = [
      RegExp(r'^\d+$'), // Single number
      RegExp(r'^\d+-\d+$'), // Range
      RegExp(r'^(amrap|max|failure)$', caseSensitive: false), // Special
    ];

    return patterns.any((pattern) => pattern.hasMatch(reps.trim()));
  }

  static bool _validateTempoFormat(String tempo) {
    // Valid format: "X-X-X-X" where X is 0-9
    final pattern = RegExp(r'^\d-\d-\d-\d$');
    return pattern.hasMatch(tempo.trim());
  }

  static void _categorizeExercise(
      String exerciseName, Map<String, int> counts) {
    final nameLower = exerciseName.toLowerCase();

    // Chest
    if (nameLower.contains('bench') ||
        nameLower.contains('chest') ||
        nameLower.contains('press') && nameLower.contains('chest') ||
        nameLower.contains('fly') ||
        nameLower.contains('dip')) {
      counts['chest'] = (counts['chest'] ?? 0) + 1;
    }

    // Back
    if (nameLower.contains('row') ||
        nameLower.contains('pull') ||
        nameLower.contains('lat') ||
        nameLower.contains('back') ||
        nameLower.contains('deadlift')) {
      counts['back'] = (counts['back'] ?? 0) + 1;
    }

    // Shoulders
    if (nameLower.contains('shoulder') ||
        nameLower.contains('overhead') ||
        nameLower.contains('military') ||
        nameLower.contains('raise') ||
        nameLower.contains('delt')) {
      counts['shoulders'] = (counts['shoulders'] ?? 0) + 1;
    }

    // Arms
    if (nameLower.contains('curl') || nameLower.contains('bicep')) {
      counts['biceps'] = (counts['biceps'] ?? 0) + 1;
    }

    if (nameLower.contains('tricep') ||
        nameLower.contains('extension') ||
        nameLower.contains('pushdown')) {
      counts['triceps'] = (counts['triceps'] ?? 0) + 1;
    }

    // Legs
    if (nameLower.contains('squat') ||
        nameLower.contains('leg') ||
        nameLower.contains('lunge')) {
      counts['legs'] = (counts['legs'] ?? 0) + 1;
    }

    if (nameLower.contains('quad')) {
      counts['quads'] = (counts['quads'] ?? 0) + 1;
    }

    if (nameLower.contains('hamstring') || nameLower.contains('curl')) {
      counts['hamstrings'] = (counts['hamstrings'] ?? 0) + 1;
    }

    if (nameLower.contains('calf')) {
      counts['calves'] = (counts['calves'] ?? 0) + 1;
    }

    // Core
    if (nameLower.contains('ab') ||
        nameLower.contains('core') ||
        nameLower.contains('plank') ||
        nameLower.contains('crunch')) {
      counts['core'] = (counts['core'] ?? 0) + 1;
    }
  }

  static String _generateSummary(List<String> errors, List<String> warnings) {
    if (errors.isEmpty && warnings.isEmpty) {
      return '✅ Plan looks good! No issues detected.';
    }

    final parts = <String>[];

    if (errors.isNotEmpty) {
      parts.add('${errors.length} error${errors.length > 1 ? 's' : ''}');
    }

    if (warnings.isNotEmpty) {
      parts.add('${warnings.length} warning${warnings.length > 1 ? 's' : ''}');
    }

    return '⚠️ ${parts.join(' and ')} detected.';
  }

  static List<String> _getCommonExercises() {
    return [
      'bench press',
      'squat',
      'deadlift',
      'overhead press',
      'barbell row',
      'pull-up',
      'chin-up',
      'lat pulldown',
      'bicep curl',
      'tricep extension',
      'leg press',
      'leg curl',
      'leg extension',
      'calf raise',
      'plank',
      'crunch',
      'lunge',
      'romanian deadlift',
      'incline press',
      'dumbbell press',
      'lateral raise',
      'face pull',
      'cable fly',
      'seated row',
      'hammer curl',
    ];
  }

  static int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;
    final dp = List.generate(len1 + 1, (i) => List.filled(len2 + 1, 0));

    for (int i = 0; i <= len1; i++) {
      dp[i][0] = i;
    }

    for (int j = 0; j <= len2; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[len1][len2];
  }
}

/// Validation result containing errors and warnings
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final String summary;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.summary,
  });
}

/// Balance check result
class BalanceWarnings {
  final List<String> warnings;
  final Map<String, int> muscleGroupCounts;

  BalanceWarnings({
    required this.warnings,
    required this.muscleGroupCounts,
  });
}

/// Exercise name validation result
class ExerciseNameValidation {
  final bool isValid;
  final String? suggestion;
  final String message;

  ExerciseNameValidation({
    required this.isValid,
    this.suggestion,
    required this.message,
  });
}