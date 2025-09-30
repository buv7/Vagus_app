import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/workout/analytics_models.dart';
import '../../models/workout/workout_plan.dart';

/// Comprehensive workout analytics service
///
/// Provides detailed analytics for coaches and clients including:
/// - Volume metrics and trends
/// - Muscle group distribution analysis
/// - Strength gains tracking
/// - Training pattern detection
/// - Progress reports generation
/// - Plan comparisons
/// - Future progress predictions
class WorkoutAnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Calculate weekly volume metrics
  ///
  /// Returns comprehensive volume data including total volume, sets, reps,
  /// and breakdown by muscle group and exercise
  Future<VolumeMetrics> calculateWeeklyVolume(
    String planId,
    int weekNumber,
  ) async {
    try {
      // Fetch week data with exercises
      final weekData = await _supabase
          .from('workout_weeks')
          .select('''
            *,
            workout_days(
              *,
              exercises(
                id,
                name,
                muscle_group,
                sets,
                target_reps_min,
                target_reps_max,
                target_weight
              )
            )
          ''')
          .eq('plan_id', planId)
          .eq('week_number', weekNumber)
          .single();

      double totalVolume = 0;
      int totalSets = 0;
      int totalReps = 0;
      Map<String, double> volumeByMuscleGroup = {};
      Map<String, double> volumeByExercise = {};

      final days = weekData['workout_days'] as List<dynamic>;

      for (final day in days) {
        final exercises = day['exercises'] as List<dynamic>;

        for (final exercise in exercises) {
          final sets = exercise['sets'] as int;
          final repsMin = exercise['target_reps_min'] as int?;
          final repsMax = exercise['target_reps_max'] as int?;
          final weight = exercise['target_weight'] as double?;

          if (weight != null && repsMin != null) {
            final avgReps = repsMax != null ? (repsMin + repsMax) / 2 : repsMin.toDouble();
            final volume = weight * avgReps * sets;

            totalVolume += volume;
            totalSets += sets;
            totalReps += (avgReps * sets).toInt();

            // By muscle group
            final muscleGroup = exercise['muscle_group'] as String;
            volumeByMuscleGroup[muscleGroup] =
                (volumeByMuscleGroup[muscleGroup] ?? 0) + volume;

            // By exercise
            final exerciseName = exercise['name'] as String;
            volumeByExercise[exerciseName] =
                (volumeByExercise[exerciseName] ?? 0) + volume;
          }
        }
      }

      final sessionCount = days.length;
      final avgVolumePerSession = sessionCount > 0 ? totalVolume / sessionCount : 0;

      return VolumeMetrics(
        totalVolume: totalVolume,
        avgVolumePerSession: avgVolumePerSession,
        totalSets: totalSets,
        totalReps: totalReps,
        volumeByMuscleGroup: volumeByMuscleGroup,
        volumeByExercise: volumeByExercise,
        startDate: DateTime.parse(weekData['start_date']),
        endDate: DateTime.parse(weekData['end_date']),
      );
    } catch (e) {
      throw Exception('Failed to calculate weekly volume: $e');
    }
  }

  /// Analyze muscle group distribution
  ///
  /// Returns distribution report with percentages, balance analysis,
  /// and recommendations for balanced training
  Future<DistributionReport> analyzeMuscleGroupDistribution(
    String planId,
  ) async {
    try {
      // Fetch all exercises in the plan
      final planData = await _supabase
          .from('workout_plans')
          .select('''
            *,
            workout_weeks(
              *,
              workout_days(
                *,
                exercises(
                  muscle_group,
                  sets
                )
              )
            )
          ''')
          .eq('id', planId)
          .single();

      Map<String, double> volumeByMuscleGroup = {};
      Map<String, int> exerciseCountByMuscleGroup = {};
      Map<String, int> setsByMuscleGroup = {};

      final weeks = planData['workout_weeks'] as List<dynamic>;

      for (final week in weeks) {
        final days = week['workout_days'] as List<dynamic>;

        for (final day in days) {
          final exercises = day['exercises'] as List<dynamic>;

          for (final exercise in exercises) {
            final muscleGroup = exercise['muscle_group'] as String;
            final sets = exercise['sets'] as int;

            setsByMuscleGroup[muscleGroup] =
                (setsByMuscleGroup[muscleGroup] ?? 0) + sets;
            exerciseCountByMuscleGroup[muscleGroup] =
                (exerciseCountByMuscleGroup[muscleGroup] ?? 0) + 1;
          }
        }
      }

      // Calculate percentages
      final totalSets = setsByMuscleGroup.values.fold(0, (a, b) => a + b);
      Map<String, double> percentageByMuscleGroup = {};

      setsByMuscleGroup.forEach((muscle, sets) {
        percentageByMuscleGroup[muscle] = (sets / totalSets) * 100;
      });

      // Analyze balance
      final List<String> overdeveloped = [];
      final List<String> underdeveloped = [];
      final List<String> recommendations = [];

      // Check for imbalances (>25% is overdeveloped, <5% is underdeveloped)
      percentageByMuscleGroup.forEach((muscle, percentage) {
        if (percentage > 25) {
          overdeveloped.add(muscle);
          recommendations.add('Consider reducing volume for $muscle (${percentage.toStringAsFixed(1)}%)');
        } else if (percentage < 5) {
          underdeveloped.add(muscle);
          recommendations.add('Consider increasing volume for $muscle (${percentage.toStringAsFixed(1)}%)');
        }
      });

      // Calculate ratios
      final pushVolume = (setsByMuscleGroup['chest'] ?? 0) +
                        (setsByMuscleGroup['shoulders'] ?? 0) +
                        (setsByMuscleGroup['triceps'] ?? 0);
      final pullVolume = (setsByMuscleGroup['back'] ?? 0) +
                        (setsByMuscleGroup['biceps'] ?? 0);
      final pushPullRatio = pullVolume > 0 ? pushVolume / pullVolume : 0;

      if (pushPullRatio > 1.5) {
        recommendations.add('Push/Pull ratio is imbalanced (${pushPullRatio.toStringAsFixed(2)}:1). Add more pulling exercises.');
      } else if (pushPullRatio < 0.67) {
        recommendations.add('Push/Pull ratio is imbalanced (${pushPullRatio.toStringAsFixed(2)}:1). Add more pushing exercises.');
      }

      final upperVolume = pushVolume + pullVolume;
      final lowerVolume = (setsByMuscleGroup['quads'] ?? 0) +
                         (setsByMuscleGroup['hamstrings'] ?? 0) +
                         (setsByMuscleGroup['glutes'] ?? 0) +
                         (setsByMuscleGroup['calves'] ?? 0);
      final upperLowerRatio = lowerVolume > 0 ? upperVolume / lowerVolume : 0;

      if (upperLowerRatio > 2.0) {
        recommendations.add('Upper/Lower ratio is imbalanced (${upperLowerRatio.toStringAsFixed(2)}:1). Add more leg exercises.');
      } else if (upperLowerRatio < 0.5) {
        recommendations.add('Upper/Lower ratio is imbalanced (${upperLowerRatio.toStringAsFixed(2)}:1). Add more upper body exercises.');
      }

      return DistributionReport(
        percentageByMuscleGroup: percentageByMuscleGroup,
        exerciseCountByMuscleGroup: exerciseCountByMuscleGroup,
        overdevelopedGroups: overdeveloped,
        underdevelopedGroups: underdeveloped,
        pushPullRatio: pushPullRatio,
        upperLowerRatio: upperLowerRatio,
        recommendations: recommendations,
      );
    } catch (e) {
      throw Exception('Failed to analyze muscle group distribution: $e');
    }
  }

  /// Calculate strength gains over time
  ///
  /// Returns comprehensive gains report with per-exercise analysis,
  /// overall trends, and PR count
  Future<GainsReport> calculateStrengthGains(
    String clientId,
    String timeframe, // '4weeks', '12weeks', '6months', '1year'
  ) async {
    try {
      // Calculate date range
      final endDate = DateTime.now();
      final startDate = _calculateStartDate(endDate, timeframe);

      // Fetch exercise history
      final historyData = await _supabase
          .from('exercise_history')
          .select('*')
          .eq('user_id', clientId)
          .gte('completed_at', startDate.toIso8601String())
          .lte('completed_at', endDate.toIso8601String())
          .order('completed_at', ascending: true);

      // Group by exercise
      Map<String, List<Map<String, dynamic>>> exerciseGroups = {};
      for (final entry in historyData) {
        final exerciseName = entry['exercise_name'] as String;
        exerciseGroups.putIfAbsent(exerciseName, () => []).add(entry);
      }

      // Calculate gains for each exercise
      Map<String, ExerciseGains> gainsByExercise = {};
      double totalGainPercentage = 0;
      int exerciseCount = 0;
      int totalPRs = 0;

      exerciseGroups.forEach((exerciseName, entries) {
        if (entries.length < 2) return; // Need at least 2 entries

        final firstEntry = entries.first;
        final lastEntry = entries.last;

        final startingWeight = firstEntry['weight'] as double;
        final currentWeight = lastEntry['weight'] as double;
        final gainKg = currentWeight - startingWeight;
        final gainPercentage = (gainKg / startingWeight) * 100;

        // Calculate 1RM using Brzycki formula
        final starting1RM = _calculate1RM(
          startingWeight,
          firstEntry['reps'] as int,
        );
        final current1RM = _calculate1RM(
          currentWeight,
          lastEntry['reps'] as int,
        );

        // Determine trend
        final recentEntries = entries.length > 4 ? entries.sublist(entries.length - 4) : entries;
        final trend = _determineTrend(recentEntries);

        // Check if it's a PR
        if (currentWeight > startingWeight) {
          totalPRs++;
        }

        gainsByExercise[exerciseName] = ExerciseGains(
          exerciseName: exerciseName,
          startingWeight: startingWeight,
          currentWeight: currentWeight,
          gainKg: gainKg,
          gainPercentage: gainPercentage,
          starting1RM: starting1RM,
          current1RM: current1RM,
          trend: trend,
        );

        totalGainPercentage += gainPercentage;
        exerciseCount++;
      });

      final overallGainPercentage = exerciseCount > 0 ? totalGainPercentage / exerciseCount : 0;

      // Find best and slowest gaining exercises
      String bestGaining = '';
      String slowestGaining = '';
      double maxGain = double.negativeInfinity;
      double minGain = double.infinity;

      gainsByExercise.forEach((name, gains) {
        if (gains.gainPercentage > maxGain) {
          maxGain = gains.gainPercentage;
          bestGaining = name;
        }
        if (gains.gainPercentage < minGain) {
          minGain = gains.gainPercentage;
          slowestGaining = name;
        }
      });

      return GainsReport(
        gainsByExercise: gainsByExercise,
        overallGainPercentage: overallGainPercentage,
        bestGainingExercise: bestGaining,
        slowestGainingExercise: slowestGaining,
        totalPRs: totalPRs,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to calculate strength gains: $e');
    }
  }

  /// Detect training patterns from client history
  ///
  /// Returns pattern analysis including session frequency, consistency,
  /// preferred training days, and behavioral insights
  Future<PatternAnalysis> detectTrainingPatterns(
    String clientId, {
    int weeksToAnalyze = 12,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: weeksToAnalyze * 7));

      // Fetch completed sessions
      final sessionsData = await _supabase
          .from('workout_sessions')
          .select('*')
          .eq('user_id', clientId)
          .gte('completed_at', startDate.toIso8601String())
          .lte('completed_at', endDate.toIso8601String())
          .order('completed_at', ascending: true);

      if (sessionsData.isEmpty) {
        return PatternAnalysis(
          avgSessionsPerWeek: 0,
          totalWeeks: weeksToAnalyze,
          consistencyScore: 0,
          preferredTrainingDays: [],
          avgSessionDuration: 0,
          exerciseFrequency: {},
          patterns: ['No training data available'],
        );
      }

      // Calculate sessions per week
      final totalSessions = sessionsData.length;
      final avgSessionsPerWeek = totalSessions / weeksToAnalyze;

      // Calculate consistency score (0-100)
      // Based on variance in weekly session count
      Map<int, int> sessionsByWeek = {};
      for (final session in sessionsData) {
        final date = DateTime.parse(session['completed_at']);
        final weekNumber = date.difference(startDate).inDays ~/ 7;
        sessionsByWeek[weekNumber] = (sessionsByWeek[weekNumber] ?? 0) + 1;
      }

      final weekCounts = sessionsByWeek.values.toList();
      final avgWeeklyCount = weekCounts.fold(0, (a, b) => a + b) / weeksToAnalyze;
      final variance = weekCounts.fold(0.0, (sum, count) =>
        sum + ((count - avgWeeklyCount) * (count - avgWeeklyCount))
      ) / weeksToAnalyze;
      final consistencyScore = (100 - (variance * 10)).clamp(0, 100).toInt();

      // Detect preferred training days (0=Monday, 6=Sunday)
      Map<int, int> dayFrequency = {};
      for (final session in sessionsData) {
        final date = DateTime.parse(session['completed_at']);
        final dayOfWeek = date.weekday - 1; // Convert to 0-6
        dayFrequency[dayOfWeek] = (dayFrequency[dayOfWeek] ?? 0) + 1;
      }

      final preferredDays = dayFrequency.entries
          .where((e) => e.value > totalSessions * 0.15) // Days with >15% of sessions
          .map((e) => e.key)
          .toList()
        ..sort();

      // Calculate average session duration
      final durations = sessionsData
          .where((s) => s['duration_minutes'] != null)
          .map((s) => s['duration_minutes'] as int)
          .toList();
      final avgDuration = durations.isNotEmpty
          ? durations.fold(0, (a, b) => a + b) / durations.length
          : 0.0;

      // Exercise frequency
      final exerciseHistoryData = await _supabase
          .from('exercise_history')
          .select('exercise_name')
          .eq('user_id', clientId)
          .gte('completed_at', startDate.toIso8601String())
          .lte('completed_at', endDate.toIso8601String());

      Map<String, int> exerciseFrequency = {};
      for (final entry in exerciseHistoryData) {
        final name = entry['exercise_name'] as String;
        exerciseFrequency[name] = (exerciseFrequency[name] ?? 0) + 1;
      }

      // Generate patterns
      List<String> patterns = [];

      if (avgSessionsPerWeek >= 4) {
        patterns.add('Trains frequently (${avgSessionsPerWeek.toStringAsFixed(1)} sessions/week)');
      } else if (avgSessionsPerWeek < 2) {
        patterns.add('Low training frequency (${avgSessionsPerWeek.toStringAsFixed(1)} sessions/week)');
      }

      if (consistencyScore >= 80) {
        patterns.add('Highly consistent training schedule');
      } else if (consistencyScore < 50) {
        patterns.add('Inconsistent training schedule - consider setting reminders');
      }

      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      if (preferredDays.isNotEmpty) {
        final preferredDayNames = preferredDays.map((d) => dayNames[d]).join(', ');
        patterns.add('Prefers training on $preferredDayNames');
      }

      if (avgDuration < 45) {
        patterns.add('Short sessions (${avgDuration.toStringAsFixed(0)} min avg) - efficient training');
      } else if (avgDuration > 90) {
        patterns.add('Long sessions (${avgDuration.toStringAsFixed(0)} min avg) - consider splitting workouts');
      }

      return PatternAnalysis(
        avgSessionsPerWeek: avgSessionsPerWeek,
        totalWeeks: weeksToAnalyze,
        consistencyScore: consistencyScore,
        preferredTrainingDays: preferredDays,
        avgSessionDuration: avgDuration,
        exerciseFrequency: exerciseFrequency,
        patterns: patterns,
      );
    } catch (e) {
      throw Exception('Failed to detect training patterns: $e');
    }
  }

  /// Generate comprehensive progress report
  ///
  /// Returns full progress report combining volume, gains, distribution,
  /// patterns, compliance, and PRs with AI-generated summary
  Future<ComprehensiveReport> generateProgressReport(
    String clientId, {
    String timeframe = '12weeks',
  }) async {
    try {
      // Fetch client info
      final clientData = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', clientId)
          .single();

      final clientName = clientData['full_name'] as String? ?? 'Client';

      // Get client's current plan
      final planData = await _supabase
          .from('workout_plans')
          .select('id')
          .eq('user_id', clientId)
          .eq('is_active', true)
          .maybeSingle();

      if (planData == null) {
        throw Exception('No active workout plan found for client');
      }

      final planId = planData['id'] as String;
      final endDate = DateTime.now();
      final startDate = _calculateStartDate(endDate, timeframe);

      // Gather all metrics
      final volumeMetrics = await calculateWeeklyVolume(planId, 1); // Current week
      final gainsReport = await calculateStrengthGains(clientId, timeframe);
      final distribution = await analyzeMuscleGroupDistribution(planId);
      final patterns = await detectTrainingPatterns(clientId);
      final compliance = await _calculateCompliance(clientId, startDate, endDate);
      final personalRecords = await _fetchRecentPRs(clientId, startDate);

      // Generate achievements
      List<String> achievements = [];
      if (gainsReport.totalPRs > 0) {
        achievements.add('${gainsReport.totalPRs} new personal records');
      }
      if (gainsReport.overallGainPercentage > 10) {
        achievements.add('${gainsReport.overallGainPercentage.toStringAsFixed(1)}% overall strength gain');
      }
      if (compliance.completionRate >= 0.9) {
        achievements.add('${compliance.completionRateDisplay} workout completion rate');
      }
      if (patterns.consistencyScore >= 80) {
        achievements.add('Excellent training consistency (${patterns.consistencyScore}/100)');
      }
      if (distribution.isBalanced) {
        achievements.add('Well-balanced muscle development');
      }

      // Generate areas for improvement
      List<String> areasForImprovement = [];
      if (compliance.completionRate < 0.7) {
        areasForImprovement.add('Improve workout adherence (currently ${compliance.completionRateDisplay})');
      }
      if (patterns.consistencyScore < 60) {
        areasForImprovement.add('Work on training consistency');
      }
      if (distribution.recommendations.isNotEmpty) {
        areasForImprovement.addAll(distribution.recommendations.take(2));
      }
      if (gainsReport.overallGainPercentage < 2) {
        areasForImprovement.add('Consider progressive overload strategies to increase gains');
      }

      // Generate summary
      final summary = _generateSummary(
        clientName: clientName,
        timeframe: timeframe,
        gains: gainsReport,
        compliance: compliance,
        patterns: patterns,
      );

      return ComprehensiveReport(
        clientId: clientId,
        clientName: clientName,
        reportDate: DateTime.now(),
        periodStart: startDate,
        periodEnd: endDate,
        volumeMetrics: volumeMetrics,
        gainsReport: gainsReport,
        distribution: distribution,
        patterns: patterns,
        compliance: compliance,
        personalRecords: personalRecords,
        summary: summary,
        achievements: achievements,
        areasForImprovement: areasForImprovement,
      );
    } catch (e) {
      throw Exception('Failed to generate progress report: $e');
    }
  }

  /// Compare two workout plans
  ///
  /// Returns comparison report highlighting differences in volume,
  /// intensity, frequency, and recommendations
  Future<ComparisonReport> comparePlans(
    String plan1Id,
    String plan2Id,
  ) async {
    try {
      // Fetch both plans
      final plan1Data = await _supabase
          .from('workout_plans')
          .select('name')
          .eq('id', plan1Id)
          .single();

      final plan2Data = await _supabase
          .from('workout_plans')
          .select('name')
          .eq('id', plan2Id)
          .single();

      final plan1Name = plan1Data['name'] as String;
      final plan2Name = plan2Data['name'] as String;

      // Get distribution for both plans
      final dist1 = await analyzeMuscleGroupDistribution(plan1Id);
      final dist2 = await analyzeMuscleGroupDistribution(plan2Id);

      // Calculate total volume for both plans (week 1)
      final volume1 = await calculateWeeklyVolume(plan1Id, 1);
      final volume2 = await calculateWeeklyVolume(plan2Id, 1);

      final volumeDifference = ((volume2.totalVolume - volume1.totalVolume) / volume1.totalVolume) * 100;

      // Compare intensity (using average weight across exercises)
      final intensityDiff = 0.0; // Placeholder - would need exercise-level comparison

      // Compare frequency (sessions per week)
      final freq1Data = await _supabase
          .from('workout_days')
          .select('id')
          .eq('week_id', (await _supabase.from('workout_weeks').select('id').eq('plan_id', plan1Id).eq('week_number', 1).single())['id'])
          .count();

      final freq2Data = await _supabase
          .from('workout_days')
          .select('id')
          .eq('week_id', (await _supabase.from('workout_weeks').select('id').eq('plan_id', plan2Id).eq('week_number', 1).single())['id'])
          .count();

      final frequencyDifference = freq2Data.count - freq1Data.count;

      // Identify key differences
      Map<String, String> differences = {};

      if (volumeDifference.abs() > 10) {
        differences['Volume'] = volumeDifference > 0
            ? '$plan2Name has ${volumeDifference.toStringAsFixed(1)}% more volume'
            : '$plan1Name has ${(-volumeDifference).toStringAsFixed(1)}% more volume';
      }

      if (frequencyDifference != 0) {
        differences['Frequency'] = frequencyDifference > 0
            ? '$plan2Name has $frequencyDifference more sessions per week'
            : '$plan1Name has ${-frequencyDifference} more sessions per week';
      }

      // Compare muscle group focus
      final plan1Focus = dist1.percentageByMuscleGroup.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final plan2Focus = dist2.percentageByMuscleGroup.entries
          .reduce((a, b) => a.value > b.value ? a : b);

      if (plan1Focus.key != plan2Focus.key) {
        differences['Focus'] = '$plan1Name focuses on ${plan1Focus.key} (${plan1Focus.value.toStringAsFixed(1)}%), '
                               '$plan2Name focuses on ${plan2Focus.key} (${plan2Focus.value.toStringAsFixed(1)}%)';
      }

      // Identify similarities
      List<String> similarities = [];

      if (volumeDifference.abs() < 5) {
        similarities.add('Similar total volume');
      }

      if (frequencyDifference == 0) {
        similarities.add('Same training frequency');
      }

      // Generate recommendation
      String recommendation;
      if (volumeDifference > 20) {
        recommendation = '$plan2Name is significantly higher volume. Consider using it during accumulation phases.';
      } else if (volumeDifference < -20) {
        recommendation = '$plan1Name is significantly higher volume. Consider using it during accumulation phases.';
      } else if (dist1.isBalanced && !dist2.isBalanced) {
        recommendation = '$plan1Name has better muscle balance. Recommended for overall development.';
      } else if (!dist1.isBalanced && dist2.isBalanced) {
        recommendation = '$plan2Name has better muscle balance. Recommended for overall development.';
      } else {
        recommendation = 'Both plans are similar. Choose based on personal preference and current goals.';
      }

      return ComparisonReport(
        plan1Id: plan1Id,
        plan2Id: plan2Id,
        plan1Name: plan1Name,
        plan2Name: plan2Name,
        volumeDifference: volumeDifference,
        intensityDifference: intensityDiff,
        frequencyDifference: frequencyDifference,
        differences: differences,
        similarities: similarities,
        recommendation: recommendation,
      );
    } catch (e) {
      throw Exception('Failed to compare plans: $e');
    }
  }

  /// Predict future progress based on current trends
  ///
  /// Returns projection data with predicted weights for exercises
  /// over the next 4-12 weeks using linear regression
  Future<ProjectionData> predictFutureProgress(
    String clientId,
    String exerciseName, {
    int weeksToProject = 8,
  }) async {
    try {
      // Fetch historical data
      final historyData = await _supabase
          .from('exercise_history')
          .select('*')
          .eq('user_id', clientId)
          .eq('exercise_name', exerciseName)
          .order('completed_at', ascending: true)
          .limit(50);

      if (historyData.length < 3) {
        throw Exception('Insufficient data for projection (need at least 3 data points)');
      }

      // Convert to data points for regression
      List<MapEntry<int, double>> dataPoints = [];
      final firstDate = DateTime.parse(historyData.first['completed_at']);

      for (final entry in historyData) {
        final date = DateTime.parse(entry['completed_at']);
        final daysSinceStart = date.difference(firstDate).inDays;
        final weight = entry['weight'] as double;
        dataPoints.add(MapEntry(daysSinceStart, weight));
      }

      // Simple linear regression
      final n = dataPoints.length;
      final sumX = dataPoints.fold(0.0, (sum, p) => sum + p.key);
      final sumY = dataPoints.fold(0.0, (sum, p) => sum + p.value);
      final sumXY = dataPoints.fold(0.0, (sum, p) => sum + (p.key * p.value));
      final sumX2 = dataPoints.fold(0.0, (sum, p) => sum + (p.key * p.key));

      final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
      final intercept = (sumY - slope * sumX) / n;

      // Calculate R² for confidence score
      final meanY = sumY / n;
      final ssRes = dataPoints.fold(0.0, (sum, p) {
        final predicted = slope * p.key + intercept;
        return sum + ((p.value - predicted) * (p.value - predicted));
      });
      final ssTot = dataPoints.fold(0.0, (sum, p) {
        return sum + ((p.value - meanY) * (p.value - meanY));
      });
      final rSquared = 1 - (ssRes / ssTot);
      final confidenceScore = rSquared.clamp(0, 1);

      // Generate projections
      final lastDate = DateTime.parse(historyData.last['completed_at']);
      final lastDaysSinceStart = dataPoints.last.key;

      List<ProjectionPoint> projections = [];
      for (int week = 1; week <= weeksToProject; week++) {
        final futureDays = lastDaysSinceStart + (week * 7);
        final projectedWeight = slope * futureDays + intercept;

        // Calculate confidence interval (±5% * (1 - confidence))
        final uncertainty = projectedWeight * 0.05 * (1 - confidenceScore);

        projections.add(ProjectionPoint(
          date: lastDate.add(Duration(days: week * 7)),
          projectedWeight: projectedWeight,
          lowerBound: projectedWeight - uncertainty,
          upperBound: projectedWeight + uncertainty,
        ));
      }

      Map<String, List<ProjectionPoint>> exerciseProjections = {
        exerciseName: projections,
      };

      return ProjectionData(
        exerciseProjections: exerciseProjections,
        confidenceScore: confidenceScore,
        methodology: 'linear',
        projectionDate: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to predict future progress: $e');
    }
  }

  // Helper methods

  DateTime _calculateStartDate(DateTime endDate, String timeframe) {
    switch (timeframe) {
      case '4weeks':
        return endDate.subtract(const Duration(days: 28));
      case '12weeks':
        return endDate.subtract(const Duration(days: 84));
      case '6months':
        return endDate.subtract(const Duration(days: 180));
      case '1year':
        return endDate.subtract(const Duration(days: 365));
      default:
        return endDate.subtract(const Duration(days: 84));
    }
  }

  double _calculate1RM(double weight, int reps) {
    // Brzycki formula: 1RM = weight × (36 / (37 - reps))
    if (reps == 1) return weight;
    if (reps > 36) return weight; // Formula not valid for >36 reps
    return weight * (36 / (37 - reps));
  }

  String _determineTrend(List<Map<String, dynamic>> recentEntries) {
    if (recentEntries.length < 2) return 'stable';

    final weights = recentEntries.map((e) => e['weight'] as double).toList();

    int increases = 0;
    int decreases = 0;

    for (int i = 1; i < weights.length; i++) {
      if (weights[i] > weights[i - 1]) increases++;
      if (weights[i] < weights[i - 1]) decreases++;
    }

    if (increases > decreases) return 'improving';
    if (decreases > increases) return 'declining';
    return 'stable';
  }

  Future<ComplianceMetrics> _calculateCompliance(
    String clientId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Fetch planned sessions
    final plannedData = await _supabase
        .from('workout_days')
        .select('id')
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String());

    // Fetch completed sessions
    final completedData = await _supabase
        .from('workout_sessions')
        .select('id, completed_at')
        .eq('user_id', clientId)
        .gte('completed_at', startDate.toIso8601String())
        .lte('completed_at', endDate.toIso8601String());

    final plannedCount = plannedData.length;
    final completedCount = completedData.length;
    final completionRate = plannedCount > 0 ? completedCount / plannedCount : 0.0;
    final missedCount = plannedCount - completedCount;

    // Calculate trend (comparing first half vs second half)
    final midDate = startDate.add(Duration(days: endDate.difference(startDate).inDays ~/ 2));
    final firstHalfCompleted = completedData.where((s) =>
      DateTime.parse(s['completed_at']).isBefore(midDate)
    ).length;
    final secondHalfCompleted = completedCount - firstHalfCompleted;

    String trend;
    if (secondHalfCompleted > firstHalfCompleted * 1.1) {
      trend = 'improving';
    } else if (secondHalfCompleted < firstHalfCompleted * 0.9) {
      trend = 'declining';
    } else {
      trend = 'stable';
    }

    return ComplianceMetrics(
      plannedSessions: plannedCount,
      completedSessions: completedCount,
      completionRate: completionRate,
      missedSessions: missedCount,
      missedDates: [], // Would need to calculate actual missed dates
      trend: trend,
    );
  }

  Future<List<PRRecord>> _fetchRecentPRs(String clientId, DateTime sinceDate) async {
    // Fetch exercise history and detect PRs
    final historyData = await _supabase
        .from('exercise_history')
        .select('*')
        .eq('user_id', clientId)
        .gte('completed_at', sinceDate.toIso8601String())
        .order('completed_at', ascending: false);

    Map<String, PRRecord> latestPRs = {};

    for (final entry in historyData) {
      final exerciseName = entry['exercise_name'] as String;
      final weight = entry['weight'] as double;
      final reps = entry['reps'] as int;
      final completedAt = DateTime.parse(entry['completed_at']);

      // Check if it's a weight PR
      if (!latestPRs.containsKey(exerciseName) || weight > latestPRs[exerciseName]!.value) {
        latestPRs[exerciseName] = PRRecord(
          exerciseName: exerciseName,
          type: 'weight',
          value: weight,
          achievedDate: completedAt,
          description: 'New weight PR: ${weight.toStringAsFixed(1)}kg x $reps reps',
        );
      }
    }

    return latestPRs.values.toList()
      ..sort((a, b) => b.achievedDate.compareTo(a.achievedDate));
  }

  String _generateSummary({
    required String clientName,
    required String timeframe,
    required GainsReport gains,
    required ComplianceMetrics compliance,
    required PatternAnalysis patterns,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('$clientName has made excellent progress over the past $timeframe.');
    buffer.writeln();

    if (gains.totalPRs > 0) {
      buffer.writeln('They achieved ${gains.totalPRs} personal records with an overall strength gain of ${gains.overallGainPercentage.toStringAsFixed(1)}%.');
    }

    buffer.writeln('Training consistency was ${patterns.consistencyScore >= 80 ? "excellent" : patterns.consistencyScore >= 60 ? "good" : "needs improvement"} (${patterns.consistencyScore}/100).');

    if (compliance.completionRate >= 0.9) {
      buffer.writeln('Workout adherence was outstanding at ${compliance.completionRateDisplay}.');
    } else if (compliance.completionRate >= 0.7) {
      buffer.writeln('Workout adherence was solid at ${compliance.completionRateDisplay}.');
    } else {
      buffer.writeln('Workout adherence could be improved (${compliance.completionRateDisplay}).');
    }

    return buffer.toString();
  }
}