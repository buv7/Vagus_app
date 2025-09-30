import 'exercise.dart';
import 'cardio_session.dart';

class WorkoutSummary {
  final double totalVolume; // Total tonnage (sets × reps × weight)
  final double totalTonnage; // Alias for totalVolume
  final int totalSets;
  final int totalExercises;
  final int estimatedDuration; // In minutes
  final int totalCardioMinutes;
  final Map<ExerciseGroupType, int> groupTypeCounts;

  WorkoutSummary({
    required this.totalVolume,
    required this.totalSets,
    required this.totalExercises,
    required this.estimatedDuration,
    required this.totalCardioMinutes,
    Map<ExerciseGroupType, int>? groupTypeCounts,
  })  : totalTonnage = totalVolume,
        groupTypeCounts = groupTypeCounts ?? {};

  factory WorkoutSummary.fromMap(Map<String, dynamic> map) {
    return WorkoutSummary(
      totalVolume: (map['total_volume'] as num?)?.toDouble() ?? 0.0,
      totalSets: (map['total_sets'] as num?)?.toInt() ?? 0,
      totalExercises: (map['total_exercises'] as num?)?.toInt() ?? 0,
      estimatedDuration: (map['estimated_duration'] as num?)?.toInt() ?? 0,
      totalCardioMinutes: (map['total_cardio_minutes'] as num?)?.toInt() ?? 0,
      groupTypeCounts: map['group_type_counts'] != null
          ? (map['group_type_counts'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                ExerciseGroupType.fromString(key),
                (value as num).toInt(),
              ),
            )
          : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_volume': totalVolume,
      'total_tonnage': totalTonnage,
      'total_sets': totalSets,
      'total_exercises': totalExercises,
      'estimated_duration': estimatedDuration,
      'total_cardio_minutes': totalCardioMinutes,
      'group_type_counts': groupTypeCounts.map(
        (key, value) => MapEntry(key.value, value),
      ),
    };
  }

  /// Calculate summary from a list of exercises and cardio sessions
  static WorkoutSummary calculate({
    required List<Exercise> exercises,
    required List<CardioSession> cardioSessions,
  }) {
    double totalVolume = 0.0;
    int totalSets = 0;
    int totalExercises = exercises.length;
    int estimatedDuration = 0;
    int totalCardioMinutes = 0;
    final groupTypeCounts = <ExerciseGroupType, int>{};

    // Calculate exercise metrics
    for (final exercise in exercises) {
      // Add to volume
      final volume = exercise.calculateVolume();
      if (volume != null) {
        totalVolume += volume;
      }

      // Add to total sets
      if (exercise.sets != null) {
        totalSets += exercise.sets!;
      }

      // Estimate time: sets × 30 seconds per set + rest time
      if (exercise.sets != null && exercise.rest != null) {
        final exerciseTime = exercise.sets! * 30 + exercise.rest! * (exercise.sets! - 1);
        estimatedDuration += (exerciseTime / 60).ceil(); // Convert to minutes
      }

      // Count group types
      groupTypeCounts[exercise.groupType] =
          (groupTypeCounts[exercise.groupType] ?? 0) + 1;
    }

    // Calculate cardio metrics
    for (final cardio in cardioSessions) {
      if (cardio.durationMinutes != null) {
        totalCardioMinutes += cardio.durationMinutes!;
        estimatedDuration += cardio.durationMinutes!;
      }
    }

    return WorkoutSummary(
      totalVolume: totalVolume,
      totalSets: totalSets,
      totalExercises: totalExercises,
      estimatedDuration: estimatedDuration,
      totalCardioMinutes: totalCardioMinutes,
      groupTypeCounts: groupTypeCounts,
    );
  }

  /// Get display text for total volume
  String getVolumeDisplay({String unit = 'kg'}) {
    if (totalVolume == 0) return '0 $unit';
    if (totalVolume >= 1000) {
      return '${(totalVolume / 1000).toStringAsFixed(1)}k $unit';
    }
    return '${totalVolume.toStringAsFixed(0)} $unit';
  }

  /// Get display text for duration
  String getDurationDisplay() {
    if (estimatedDuration == 0) return '0 min';
    if (estimatedDuration >= 60) {
      final hours = estimatedDuration ~/ 60;
      final minutes = estimatedDuration % 60;
      if (minutes == 0) {
        return '${hours}h';
      }
      return '${hours}h ${minutes}m';
    }
    return '$estimatedDuration min';
  }

  /// Get a brief summary text
  String getBriefSummary({String unit = 'kg'}) {
    final parts = <String>[];

    if (totalExercises > 0) {
      parts.add('$totalExercises exercises');
    }

    if (totalVolume > 0) {
      parts.add(getVolumeDisplay(unit: unit));
    }

    if (estimatedDuration > 0) {
      parts.add(getDurationDisplay());
    }

    return parts.isEmpty ? 'No data' : parts.join(' • ');
  }

  /// Get detailed summary text
  String getDetailedSummary({String unit = 'kg'}) {
    final lines = <String>[];

    lines.add('Total Volume: ${getVolumeDisplay(unit: unit)}');
    lines.add('Total Sets: $totalSets');
    lines.add('Total Exercises: $totalExercises');

    if (totalCardioMinutes > 0) {
      lines.add('Cardio: $totalCardioMinutes min');
    }

    lines.add('Estimated Duration: ${getDurationDisplay()}');

    // Add group type breakdown if there are any
    final nonStandardGroups = groupTypeCounts.entries
        .where((entry) => entry.key != ExerciseGroupType.none && entry.value > 0)
        .toList();

    if (nonStandardGroups.isNotEmpty) {
      lines.add('');
      lines.add('Training Methods:');
      for (final entry in nonStandardGroups) {
        lines.add('  ${entry.key.displayName}: ${entry.value}');
      }
    }

    return lines.join('\n');
  }

  /// Check if this is a rest day (no exercises and no cardio)
  bool get isRestDay => totalExercises == 0 && totalCardioMinutes == 0;

  /// Check if this workout includes cardio
  bool get hasCardio => totalCardioMinutes > 0;

  /// Check if this workout includes resistance training
  bool get hasResistanceTraining => totalExercises > 0;

  /// Get intensity score (0-10) based on volume and duration
  double getIntensityScore() {
    if (isRestDay) return 0.0;

    // Simple intensity calculation
    // Volume per minute is a reasonable proxy for intensity
    if (estimatedDuration == 0) return 0.0;

    final volumePerMinute = totalVolume / estimatedDuration;

    // Normalize to 0-10 scale (adjust these thresholds as needed)
    if (volumePerMinute >= 200) return 10.0;
    if (volumePerMinute >= 150) return 8.0;
    if (volumePerMinute >= 100) return 6.0;
    if (volumePerMinute >= 50) return 4.0;
    if (volumePerMinute >= 25) return 2.0;
    return 1.0;
  }
}

class WeeklySummary {
  final List<WorkoutSummary> dailySummaries;
  final int weekNumber;

  WeeklySummary({
    required this.dailySummaries,
    required this.weekNumber,
  });

  /// Calculate total weekly volume
  double get totalWeeklyVolume {
    return dailySummaries.fold(
      0.0,
      (sum, day) => sum + day.totalVolume,
    );
  }

  /// Calculate total weekly sets
  int get totalWeeklySets {
    return dailySummaries.fold(
      0,
      (sum, day) => sum + day.totalSets,
    );
  }

  /// Calculate total weekly cardio
  int get totalWeeklyCardio {
    return dailySummaries.fold(
      0,
      (sum, day) => sum + day.totalCardioMinutes,
    );
  }

  /// Calculate total training days (non-rest days)
  int get trainingDays {
    return dailySummaries.where((day) => !day.isRestDay).length;
  }

  /// Get average intensity for the week
  double get averageIntensity {
    final trainingSessions = dailySummaries.where((day) => !day.isRestDay).toList();
    if (trainingSessions.isEmpty) return 0.0;

    final totalIntensity = trainingSessions.fold(
      0.0,
      (sum, day) => sum + day.getIntensityScore(),
    );

    return totalIntensity / trainingSessions.length;
  }

  /// Get brief weekly summary
  String getBriefSummary({String unit = 'kg'}) {
    return '$trainingDays training days • ${(totalWeeklyVolume / 1000).toStringAsFixed(1)}k $unit • ${totalWeeklyCardio}min cardio';
  }

  /// Get detailed weekly summary
  String getDetailedSummary({String unit = 'kg'}) {
    final lines = <String>[];

    lines.add('Week $weekNumber Summary:');
    lines.add('Training Days: $trainingDays / ${dailySummaries.length}');
    lines.add('Total Volume: ${(totalWeeklyVolume / 1000).toStringAsFixed(1)}k $unit');
    lines.add('Total Sets: $totalWeeklySets');
    lines.add('Total Cardio: ${totalWeeklyCardio}min');
    lines.add('Average Intensity: ${averageIntensity.toStringAsFixed(1)}/10');

    return lines.join('\n');
  }
}