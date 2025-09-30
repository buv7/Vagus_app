import '../../models/workout/progression_models.dart';
import 'workout_service.dart';

/// Progression Analytics Service
///
/// Provides analytics and tracking for workout progression:
/// - Progression rate tracking
/// - Volume progression graphs
/// - Estimated strength gains
/// - Plateau detection alerts
/// - PR (Personal Record) detection and celebration
class ProgressionAnalyticsService {
  final WorkoutService _workoutService = WorkoutService();

  // =====================================================
  // PROGRESSION RATE TRACKING
  // =====================================================

  /// Calculate progression rate for an exercise
  Future<ProgressionRate> calculateProgressionRate({
    required String clientId,
    required String exerciseName,
    int weeksToAnalyze = 12,
  }) async {
    final history = await _workoutService.fetchExerciseHistory(
      clientId,
      exerciseName,
    );

    if (history.length < 2) {
      return ProgressionRate(
        exerciseName: exerciseName,
        weeklyGainPercentage: 0.0,
        totalGainPercentage: 0.0,
        weeksTracked: 0,
        trend: 'insufficient_data',
        metrics: {},
      );
    }

    // Sort by date (oldest first)
    final sorted = List<ExerciseHistoryEntry>.from(history)
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    // Calculate weight progression
    final firstWeight = sorted.first.weightUsed;
    final lastWeight = sorted.last.weightUsed;
    final totalGain = ((lastWeight - firstWeight) / firstWeight) * 100;

    // Calculate weeks tracked
    final firstDate = sorted.first.completedAt;
    final lastDate = sorted.last.completedAt;
    final weeksTracked = lastDate.difference(firstDate).inDays / 7;

    // Calculate weekly gain
    final weeklyGain = weeksTracked > 0 ? totalGain / weeksTracked : 0;

    // Determine trend
    final recentWeights = sorted.reversed.take(6).map((e) => e.weightUsed).toList();
    final trend = _determineTrend(recentWeights);

    // Calculate additional metrics
    final metrics = {
      'max_weight': sorted.map((e) => e.weightUsed).reduce((a, b) => a > b ? a : b),
      'max_volume': sorted.map((e) => (e.volume ?? 0).toDouble()).reduce((a, b) => a > b ? a : b),
      'total_sessions': sorted.length.toDouble(),
      'avg_rpe': _calculateAverageRPE(sorted),
      'consistency_score': _calculateConsistency(sorted),
    };

    return ProgressionRate(
      exerciseName: exerciseName,
      weeklyGainPercentage: weeklyGain.toDouble(),
      totalGainPercentage: totalGain,
      weeksTracked: weeksTracked.toInt(),
      trend: trend,
      metrics: metrics,
    );
  }

  /// Get progression rates for all exercises
  Future<List<ProgressionRate>> getAllProgressionRates({
    required String clientId,
    int weeksToAnalyze = 12,
  }) async {
    // Get unique exercise names from history
    // Note: Fetching all exercises without exerciseName parameter
    // This will need to be updated once the method signature supports it
    final allHistory = <ExerciseHistoryEntry>[];

    // TODO: ExerciseHistoryEntry has exerciseId not exerciseName
    // Need to map exerciseId to exerciseName using exercise library
    final uniqueExercises = allHistory
        .map((e) => e.exerciseId) // Using exerciseId as placeholder
        .toSet()
        .toList();

    final rates = <ProgressionRate>[];
    for (final exerciseName in uniqueExercises) {
      final rate = await calculateProgressionRate(
        clientId: clientId,
        exerciseName: exerciseName,
        weeksToAnalyze: weeksToAnalyze,
      );
      if (rate.weeksTracked > 0) {
        rates.add(rate);
      }
    }

    // Sort by total gain percentage (best first)
    rates.sort((a, b) => b.totalGainPercentage.compareTo(a.totalGainPercentage));

    return rates;
  }

  // =====================================================
  // VOLUME PROGRESSION ANALYSIS
  // =====================================================

  /// Get volume progression data for charting
  Future<Map<String, dynamic>> getVolumeProgressionData({
    required String clientId,
    String? exerciseName,
    int weeksToShow = 12,
  }) async {
    final history = exerciseName != null
        ? await _workoutService.fetchExerciseHistory(
            clientId,
            exerciseName,
          )
        : <ExerciseHistoryEntry>[]; // Method requires exerciseName parameter

    // Sort by date
    final sorted = List<ExerciseHistoryEntry>.from(history)
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    // Group by week
    final weeklyData = <int, List<ExerciseHistoryEntry>>{};
    for (final entry in sorted) {
      final weekNumber = _getWeekNumber(entry.completedAt, sorted.first.completedAt);
      weeklyData.putIfAbsent(weekNumber, () => []).add(entry);
    }

    // Calculate weekly metrics
    final chartData = <Map<String, dynamic>>[];
    weeklyData.forEach((week, entries) {
      final totalVolume = entries
          .map((e) => e.volume ?? 0)
          .fold(0.0, (a, b) => a + b);

      final avgWeight = entries
          .map((e) => e.weightUsed)
          .fold(0.0, (a, b) => a + b) / entries.length;

      final totalSets = entries
          .map((e) => e.completedSets)
          .fold(0, (a, b) => a + b);

      chartData.add({
        'week': week,
        'volume': totalVolume,
        'avg_weight': avgWeight,
        'total_sets': totalSets,
        'sessions': entries.length,
      });
    });

    return {
      'chart_data': chartData,
      'total_volume': chartData.map((d) => d['volume']).fold(0.0, (a, b) => a + b),
      'avg_weekly_volume': chartData.isNotEmpty
          ? chartData.map((d) => d['volume']).fold(0.0, (a, b) => a + b) / chartData.length
          : 0.0,
      'weeks_tracked': chartData.length,
    };
  }

  // =====================================================
  // STRENGTH GAINS ESTIMATION
  // =====================================================

  /// Estimate strength gains based on 1RM progression
  Future<Map<String, dynamic>> estimateStrengthGains({
    required String clientId,
    required String exerciseName,
    int weeksToAnalyze = 12,
  }) async {
    final history = await _workoutService.fetchExerciseHistory(
      clientId,
      exerciseName,
    );

    if (history.length < 2) {
      return {
        'success': false,
        'message': 'Insufficient data',
      };
    }

    // Sort by date
    final sorted = List<ExerciseHistoryEntry>.from(history)
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    // Calculate 1RM progression
    final first1RM = sorted.first.estimated1RM;
    final last1RM = sorted.last.estimated1RM;

    if (first1RM == null || last1RM == null) {
      return {
        'success': false,
        'message': 'Unable to estimate 1RM',
      };
    }

    final gainKg = last1RM - first1RM;
    final gainPercentage = (gainKg / first1RM) * 100;

    // Project future gains (assuming linear progression continues)
    final weeksTracked = sorted.last.completedAt
        .difference(sorted.first.completedAt).inDays / 7;
    final weeklyGain = gainKg / weeksTracked;

    return {
      'success': true,
      'exercise_name': exerciseName,
      'starting_1rm': first1RM,
      'current_1rm': last1RM,
      'gain_kg': gainKg,
      'gain_percentage': gainPercentage,
      'weekly_gain_kg': weeklyGain,
      'weeks_tracked': weeksTracked.round(),
      'projected_1rm_4weeks': last1RM + (weeklyGain * 4),
      'projected_1rm_8weeks': last1RM + (weeklyGain * 8),
      'projected_1rm_12weeks': last1RM + (weeklyGain * 12),
    };
  }

  // =====================================================
  // PR DETECTION AND CELEBRATION
  // =====================================================

  /// Detect new PRs in recent workout
  Future<List<VolumeLandmark>> detectNewPRs({
    required String clientId,
    DateTime? sinceDate,
  }) async {
    sinceDate ??= DateTime.now().subtract(const Duration(days: 7));

    // Note: Method requires exerciseName parameter, returning empty list
    // This will need to be updated to fetch all exercises
    final history = <ExerciseHistoryEntry>[];

    // Group by exercise
    final byExercise = <String, List<ExerciseHistoryEntry>>{};
    for (final entry in history) {
      byExercise.putIfAbsent(entry.exerciseId, () => []).add(entry);
    }

    final prs = <VolumeLandmark>[];

    // Check each exercise for PRs
    byExercise.forEach((exerciseName, entries) {
      // Sort by date
      entries.sort((a, b) => a.completedAt.compareTo(b.completedAt));

      // Get recent entries
      final recent = entries.where((e) => e.completedAt.isAfter(sinceDate!)).toList();
      if (recent.isEmpty) return;

      // Get previous best
      final previous = entries.where((e) => e.completedAt.isBefore(sinceDate!)).toList();
      if (previous.isEmpty) return;

      // Check weight PR
      final recentMaxWeight = recent.map((e) => e.weightUsed).reduce((a, b) => a > b ? a : b);
      final previousMaxWeight = previous.map((e) => e.weightUsed).reduce((a, b) => a > b ? a : b);
      if (recentMaxWeight > previousMaxWeight) {
        final improvement = ((recentMaxWeight - previousMaxWeight) / previousMaxWeight) * 100;
        prs.add(VolumeLandmark(
          type: 'weight_pr',
          exerciseName: exerciseName,
          previousValue: previousMaxWeight,
          newValue: recentMaxWeight,
          improvement: improvement,
          achievedAt: recent.last.completedAt,
          description: 'New weight PR on $exerciseName',
        ));
      }

      // Check volume PR
      final recentMaxVolume = recent.map((e) => e.volume ?? 0).reduce((a, b) => a > b ? a : b);
      final previousMaxVolume = previous.map((e) => e.volume ?? 0).reduce((a, b) => a > b ? a : b);
      if (recentMaxVolume > previousMaxVolume) {
        final improvement = ((recentMaxVolume - previousMaxVolume) / previousMaxVolume) * 100;
        prs.add(VolumeLandmark(
          type: 'volume_pr',
          exerciseName: exerciseName,
          previousValue: previousMaxVolume,
          newValue: recentMaxVolume,
          improvement: improvement,
          achievedAt: recent.last.completedAt,
          description: 'New volume PR on $exerciseName',
        ));
      }

      // Check 1RM PR
      final recent1RMs = recent.where((e) => e.estimated1RM != null).toList();
      final previous1RMs = previous.where((e) => e.estimated1RM != null).toList();
      if (recent1RMs.isNotEmpty && previous1RMs.isNotEmpty) {
        final recentMax1RM = recent1RMs.map((e) => e.estimated1RM!).reduce((a, b) => a > b ? a : b);
        final previousMax1RM = previous1RMs.map((e) => e.estimated1RM!).reduce((a, b) => a > b ? a : b);
        if (recentMax1RM > previousMax1RM) {
          final improvement = ((recentMax1RM - previousMax1RM) / previousMax1RM) * 100;
          prs.add(VolumeLandmark(
            type: '1rm_pr',
            exerciseName: exerciseName,
            previousValue: previousMax1RM,
            newValue: recentMax1RM,
            improvement: improvement,
            achievedAt: recent.last.completedAt,
            description: 'New estimated 1RM PR on $exerciseName',
          ));
        }
      }
    });

    return prs;
  }

  /// Calculate total tonnage lifted (for PR tracking)
  Future<double> calculateTotalTonnage({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Note: Method requires exerciseName parameter, returning empty list
    // This will need to be updated to fetch all exercises
    final history = <ExerciseHistoryEntry>[];

    final filtered = history.where((entry) {
      if (startDate != null && entry.completedAt.isBefore(startDate)) return false;
      if (endDate != null && entry.completedAt.isAfter(endDate)) return false;
      return true;
    });

    return filtered
        .map((e) => e.volume ?? 0.0)
        .fold<double>(0.0, (a, b) => a + b);
  }

  // =====================================================
  // PLATEAU ALERTS
  // =====================================================

  /// Get plateau alerts for client
  Future<List<PlateauDetection>> getPlateauAlerts({
    required String clientId,
  }) async {
    // Note: Method requires exerciseName parameter, returning empty list
    // This will need to be updated to fetch all exercises
    final allHistory = <ExerciseHistoryEntry>[];

    // Group by exercise
    final byExercise = <String, List<ExerciseHistoryEntry>>{};
    for (final entry in allHistory) {
      byExercise.putIfAbsent(entry.exerciseId, () => []).add(entry);
    }

    final plateaus = <PlateauDetection>[];

    // Check each exercise for plateau
    for (final exerciseName in byExercise.keys) {
      final history = byExercise[exerciseName]!;
      if (history.length < 4) continue;

      // Sort by date
      history.sort((a, b) => a.completedAt.compareTo(b.completedAt));

      // Check for plateau
      final plateau = await _detectPlateauForExercise(history);
      if (plateau.isPlateaued && plateau.confidenceScore >= 0.6) {
        plateaus.add(plateau);
      }
    }

    return plateaus;
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  String _determineTrend(List<double> recentValues) {
    if (recentValues.length < 3) return 'insufficient_data';

    // Calculate simple moving average trend
    final firstHalf = recentValues.take(recentValues.length ~/ 2).toList();
    final secondHalf = recentValues.skip(recentValues.length ~/ 2).toList();

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final change = ((secondAvg - firstAvg) / firstAvg) * 100;

    if (change > 2.0) return 'improving';
    if (change < -2.0) return 'declining';
    return 'stable';
  }

  double _calculateAverageRPE(List<ExerciseHistoryEntry> entries) {
    final rpeValues = entries
        .where((e) => e.rirActual != null)
        .map((e) => e.rirActual!.toDouble())
        .toList();

    if (rpeValues.isEmpty) return 0.0;

    return rpeValues.reduce((a, b) => a + b) / rpeValues.length;
  }

  double _calculateConsistency(List<ExerciseHistoryEntry> entries) {
    if (entries.length < 2) return 0.0;

    // Calculate based on regularity of training
    final dates = entries.map((e) => e.completedAt).toList();
    dates.sort();

    final intervals = <int>[];
    for (int i = 1; i < dates.length; i++) {
      intervals.add(dates[i].difference(dates[i - 1]).inDays);
    }

    // Lower variance = higher consistency
    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals
        .map((i) => (i - avgInterval) * (i - avgInterval))
        .reduce((a, b) => a + b) / intervals.length;

    // Score from 0 to 1 (1 = perfect consistency)
    return (1 / (1 + variance)).clamp(0.0, 1.0);
  }

  int _getWeekNumber(DateTime date, DateTime startDate) {
    return date.difference(startDate).inDays ~/ 7;
  }

  Future<PlateauDetection> _detectPlateauForExercise(
    List<ExerciseHistoryEntry> history,
  ) async {
    // Check weight progression
    final weights = history.map((e) => e.weightUsed).toList();
    final hasWeightIncrease = _hasProgression(weights);

    // Check volume progression
    final volumes = history.map((e) => e.volume ?? 0).toList();
    final hasVolumeIncrease = _hasProgression(volumes);

    final isPlateaued = !hasWeightIncrease && !hasVolumeIncrease;
    final weeksStagnant = isPlateaued ? _countStagnantWeeks(history) : 0;

    final suggestions = <String>[];
    if (isPlateaued) {
      suggestions.add('Try a deload week');
      suggestions.add('Change exercise variation');
      suggestions.add('Increase training frequency');
      suggestions.add('Check recovery (sleep, nutrition)');
    }

    return PlateauDetection(
      isPlateaued: isPlateaued,
      reason: isPlateaued
          ? 'No progression for $weeksStagnant weeks'
          : 'Normal progression',
      weeksStagnant: weeksStagnant,
      suggestions: suggestions,
      confidenceScore: isPlateaued ? 0.8 : 0.0,
    );
  }

  bool _hasProgression(List<double> values) {
    if (values.length < 2) return false;

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

    return weeks + 1;
  }
}