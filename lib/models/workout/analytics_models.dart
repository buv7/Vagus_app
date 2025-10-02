/// Analytics Data Models
///
/// Data models for workout analytics and reporting
library;

/// Volume metrics for a specific time period
class VolumeMetrics {
  final double totalVolume; // kg
  final double avgVolumePerSession;
  final int totalSets;
  final int totalReps;
  final Map<String, double> volumeByMuscleGroup;
  final Map<String, double> volumeByExercise;
  final DateTime startDate;
  final DateTime endDate;

  VolumeMetrics({
    required this.totalVolume,
    required this.avgVolumePerSession,
    required this.totalSets,
    required this.totalReps,
    required this.volumeByMuscleGroup,
    required this.volumeByExercise,
    required this.startDate,
    required this.endDate,
  });

  String get totalVolumeDisplay {
    if (totalVolume >= 1000) {
      return '${(totalVolume / 1000).toStringAsFixed(1)} tons';
    }
    return '${totalVolume.toStringAsFixed(0)} kg';
  }
}

/// Muscle group distribution analysis
class DistributionReport {
  final Map<String, double> percentageByMuscleGroup;
  final Map<String, int> exerciseCountByMuscleGroup;
  final List<String> overdevelopedGroups;
  final List<String> underdevelopedGroups;
  final double pushPullRatio;
  final double upperLowerRatio;
  final List<String> recommendations;

  DistributionReport({
    required this.percentageByMuscleGroup,
    required this.exerciseCountByMuscleGroup,
    required this.overdevelopedGroups,
    required this.underdevelopedGroups,
    required this.pushPullRatio,
    required this.upperLowerRatio,
    required this.recommendations,
  });

  bool get isBalanced {
    return overdevelopedGroups.isEmpty && underdevelopedGroups.isEmpty;
  }
}

/// Strength gains report
class GainsReport {
  final Map<String, ExerciseGains> gainsByExercise;
  final double overallGainPercentage;
  final String bestGainingExercise;
  final String slowestGainingExercise;
  final int totalPRs;
  final DateTime startDate;
  final DateTime endDate;

  GainsReport({
    required this.gainsByExercise,
    required this.overallGainPercentage,
    required this.bestGainingExercise,
    required this.slowestGainingExercise,
    required this.totalPRs,
    required this.startDate,
    required this.endDate,
  });
}

/// Exercise-specific gains
class ExerciseGains {
  final String exerciseName;
  final double startingWeight;
  final double currentWeight;
  final double gainKg;
  final double gainPercentage;
  final double starting1RM;
  final double current1RM;
  final String trend; // 'improving', 'stable', 'declining'

  ExerciseGains({
    required this.exerciseName,
    required this.startingWeight,
    required this.currentWeight,
    required this.gainKg,
    required this.gainPercentage,
    required this.starting1RM,
    required this.current1RM,
    required this.trend,
  });
}

/// Training pattern analysis
class PatternAnalysis {
  final double avgSessionsPerWeek;
  final int totalWeeks;
  final int consistencyScore; // 0-100
  final List<int> preferredTrainingDays; // 0=Mon, 6=Sun
  final double avgSessionDuration; // minutes
  final Map<String, int> exerciseFrequency;
  final List<String> patterns; // e.g., "Trains more on Mondays", "Prefers evening sessions"

  PatternAnalysis({
    required this.avgSessionsPerWeek,
    required this.totalWeeks,
    required this.consistencyScore,
    required this.preferredTrainingDays,
    required this.avgSessionDuration,
    required this.exerciseFrequency,
    required this.patterns,
  });
}

/// Comprehensive progress report
class ComprehensiveReport {
  final String clientId;
  final String clientName;
  final DateTime reportDate;
  final DateTime periodStart;
  final DateTime periodEnd;

  // Volume metrics
  final VolumeMetrics volumeMetrics;

  // Strength metrics
  final GainsReport gainsReport;

  // Distribution
  final DistributionReport distribution;

  // Patterns
  final PatternAnalysis patterns;

  // Compliance
  final ComplianceMetrics compliance;

  // PRs
  final List<PRRecord> personalRecords;

  // Summary
  final String summary;
  final List<String> achievements;
  final List<String> areasForImprovement;

  ComprehensiveReport({
    required this.clientId,
    required this.clientName,
    required this.reportDate,
    required this.periodStart,
    required this.periodEnd,
    required this.volumeMetrics,
    required this.gainsReport,
    required this.distribution,
    required this.patterns,
    required this.compliance,
    required this.personalRecords,
    required this.summary,
    required this.achievements,
    required this.areasForImprovement,
  });
}

/// Plan comparison report
class ComparisonReport {
  final String plan1Id;
  final String plan2Id;
  final String plan1Name;
  final String plan2Name;

  final double volumeDifference;
  final double intensityDifference;
  final int frequencyDifference;
  final Map<String, String> differences;
  final List<String> similarities;
  final String recommendation;

  ComparisonReport({
    required this.plan1Id,
    required this.plan2Id,
    required this.plan1Name,
    required this.plan2Name,
    required this.volumeDifference,
    required this.intensityDifference,
    required this.frequencyDifference,
    required this.differences,
    required this.similarities,
    required this.recommendation,
  });
}

/// Progress projection data
class ProjectionData {
  final Map<String, List<ProjectionPoint>> exerciseProjections;
  final double confidenceScore; // 0-1
  final String methodology; // 'linear', 'polynomial', 'exponential'
  final DateTime projectionDate;

  ProjectionData({
    required this.exerciseProjections,
    required this.confidenceScore,
    required this.methodology,
    required this.projectionDate,
  });
}

/// Single projection point
class ProjectionPoint {
  final DateTime date;
  final double projectedWeight;
  final double lowerBound;
  final double upperBound;

  ProjectionPoint({
    required this.date,
    required this.projectedWeight,
    required this.lowerBound,
    required this.upperBound,
  });
}

/// Compliance metrics
class ComplianceMetrics {
  final int plannedSessions;
  final int completedSessions;
  final double completionRate;
  final int missedSessions;
  final List<DateTime> missedDates;
  final String trend; // 'improving', 'stable', 'declining'

  ComplianceMetrics({
    required this.plannedSessions,
    required this.completedSessions,
    required this.completionRate,
    required this.missedSessions,
    required this.missedDates,
    required this.trend,
  });

  String get completionRateDisplay => '${(completionRate * 100).toStringAsFixed(1)}%';
}

/// PR (Personal Record) entry
class PRRecord {
  final String exerciseName;
  final String type; // 'weight', 'volume', 'reps', '1rm'
  final double value;
  final DateTime achievedDate;
  final String description;

  PRRecord({
    required this.exerciseName,
    required this.type,
    required this.value,
    required this.achievedDate,
    required this.description,
  });

  String get displayValue {
    switch (type) {
      case 'weight':
        return '${value.toStringAsFixed(1)} kg';
      case 'volume':
        return '${value.toStringAsFixed(0)} kg total';
      case 'reps':
        return '${value.toInt()} reps';
      case '1rm':
        return '${value.toStringAsFixed(1)} kg (est. 1RM)';
      default:
        return value.toStringAsFixed(1);
    }
  }
}

/// Training frequency data point
class FrequencyDataPoint {
  final DateTime date;
  final int sessionsCount;
  final double totalVolume;

  FrequencyDataPoint({
    required this.date,
    required this.sessionsCount,
    required this.totalVolume,
  });
}

/// Volume trend data for charting
class VolumeTrendData {
  final List<VolumeDataPoint> dataPoints;
  final String timeframe; // 'weekly', 'monthly'
  final double averageVolume;
  final double peakVolume;
  final double lowestVolume;
  final String trend; // 'increasing', 'stable', 'decreasing'

  VolumeTrendData({
    required this.dataPoints,
    required this.timeframe,
    required this.averageVolume,
    required this.peakVolume,
    required this.lowestVolume,
    required this.trend,
  });
}

/// Single volume data point
class VolumeDataPoint {
  final DateTime date;
  final double volume;
  final int sets;
  final String label;

  VolumeDataPoint({
    required this.date,
    required this.volume,
    required this.sets,
    required this.label,
  });
}

/// Injury risk indicators
class InjuryRiskIndicators {
  final double overallRiskScore; // 0-100
  final List<RiskFactor> riskFactors;
  final List<String> warnings;
  final List<String> recommendations;

  InjuryRiskIndicators({
    required this.overallRiskScore,
    required this.riskFactors,
    required this.warnings,
    required this.recommendations,
  });

  String get riskLevel {
    if (overallRiskScore < 30) return 'Low';
    if (overallRiskScore < 60) return 'Moderate';
    return 'High';
  }
}

/// Individual risk factor
class RiskFactor {
  final String name;
  final double score; // 0-100
  final String description;
  final String mitigation;

  RiskFactor({
    required this.name,
    required this.score,
    required this.description,
    required this.mitigation,
  });
}

/// Fatigue index
class FatigueIndex {
  final double currentIndex; // 0-100
  final String level; // 'low', 'moderate', 'high', 'severe'
  final List<FatigueIndicator> indicators;
  final bool needsDeload;
  final String recommendation;

  FatigueIndex({
    required this.currentIndex,
    required this.level,
    required this.indicators,
    required this.needsDeload,
    required this.recommendation,
  });
}

/// Fatigue indicator
class FatigueIndicator {
  final String name;
  final double value;
  final String unit;
  final bool isElevated;

  FatigueIndicator({
    required this.name,
    required this.value,
    required this.unit,
    required this.isElevated,
  });
}

/// Exercise strength progression data
class StrengthProgressionData {
  final String exerciseName;
  final List<StrengthDataPoint> dataPoints;
  final double totalGain;
  final double avgWeeklyGain;
  final String trend;

  StrengthProgressionData({
    required this.exerciseName,
    required this.dataPoints,
    required this.totalGain,
    required this.avgWeeklyGain,
    required this.trend,
  });
}

/// Single strength data point
class StrengthDataPoint {
  final DateTime date;
  final double weight;
  final double? estimated1RM;
  final int? reps;
  final int? sets;

  StrengthDataPoint({
    required this.date,
    required this.weight,
    this.estimated1RM,
    this.reps,
    this.sets,
  });
}