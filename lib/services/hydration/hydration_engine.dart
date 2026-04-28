import 'dart:math' as math;

/// Smart hydration target calculator and intra-day distribution engine.
///
/// Formula:
///   target_ml = bodyweight_kg × 35
///             + (workout_minutes / 60) × 500   [workout bonus]
///             + max(0, (avg_temp_c − 25) × 50) [climate bonus]
///
/// Safety rail: result is clamped to [1500, 5000] ml.
/// Values outside this range require explicit coach override.
class HydrationEngine {
  HydrationEngine._();
  static final HydrationEngine instance = HydrationEngine._();

  static const int _minTargetMl = 1500;
  static const int _maxTargetMl = 5000;

  /// Calculate the daily hydration target in millilitres.
  ///
  /// [bodyweightKg]   Body weight in kilograms.
  /// [workoutMinutes] Total workout duration for the day (0 if rest day).
  /// [avgTempC]       Ambient temperature in Celsius (use null for temperate).
  HydrationTarget calculateTarget({
    required double bodyweightKg,
    int workoutMinutes = 0,
    double? avgTempC,
  }) {
    assert(bodyweightKg > 0, 'bodyweightKg must be positive');

    final baselineMl = (bodyweightKg * 35).round();
    final workoutBonus = ((workoutMinutes / 60.0) * 500).round();
    final climateBonus = avgTempC != null
        ? math.max(0, ((avgTempC - 25.0) * 50).round())
        : 0;

    final rawTotal = baselineMl + workoutBonus + climateBonus;
    final clampedTotal = rawTotal.clamp(_minTargetMl, _maxTargetMl);
    final wasRailApplied = rawTotal != clampedTotal;

    return HydrationTarget(
      totalMl: clampedTotal,
      baselineMl: baselineMl,
      workoutBonusMl: workoutBonus,
      climateBonusMl: climateBonus,
      railApplied: wasRailApplied,
    );
  }

  /// Distribute [targetMl] evenly across the waking window, returning
  /// the scheduled notification times and per-nudge volume.
  ///
  /// Window: [wakeTime, bedtime − 2 h]
  /// Interval: every [intervalMinutes] minutes (default 90).
  ///
  /// Returns an empty list if the window is too short for even one interval.
  List<HydrationNudge> distributeNudges({
    required int targetMl,
    required DateTime wakeTime,
    required DateTime bedtime,
    int intervalMinutes = 90,
  }) {
    final cutoff = bedtime.subtract(const Duration(hours: 2));

    if (!cutoff.isAfter(wakeTime)) return [];

    final windowMinutes = cutoff.difference(wakeTime).inMinutes;
    final nudgeCount = (windowMinutes / intervalMinutes).floor();

    if (nudgeCount <= 0) return [];

    final mlPerNudge = (targetMl / nudgeCount).round();
    final nudges = <HydrationNudge>[];

    for (var i = 0; i < nudgeCount; i++) {
      final scheduledAt =
          wakeTime.add(Duration(minutes: i * intervalMinutes));
      nudges.add(HydrationNudge(
        index: i,
        scheduledAt: scheduledAt,
        targetMl: mlPerNudge,
      ));
    }

    return nudges;
  }

  /// Returns how much water remains to be consumed today given [loggedMl]
  /// against [targetMl]. Never negative.
  int remainingMl(int targetMl, int loggedMl) =>
      math.max(0, targetMl - loggedMl);

  /// Percentage of target achieved, 0.0–1.0.
  double progressFraction(int targetMl, int loggedMl) {
    if (targetMl <= 0) return 0.0;
    return (loggedMl / targetMl).clamp(0.0, 1.0);
  }
}

/// Calculated hydration target with breakdown.
class HydrationTarget {
  final int totalMl;
  final int baselineMl;
  final int workoutBonusMl;
  final int climateBonusMl;

  /// True when the raw value was clamped by the safety rail.
  /// A rail application requires coach confirmation before persisting.
  final bool railApplied;

  const HydrationTarget({
    required this.totalMl,
    required this.baselineMl,
    required this.workoutBonusMl,
    required this.climateBonusMl,
    required this.railApplied,
  });

  String get formattedLiters => '${(totalMl / 1000.0).toStringAsFixed(1)} L';

  @override
  String toString() =>
      'HydrationTarget($totalMl ml = $baselineMl base + $workoutBonusMl workout + $climateBonusMl climate${railApplied ? " [rail]" : ""})';
}

/// A single scheduled hydration nudge.
class HydrationNudge {
  final int index;
  final DateTime scheduledAt;
  final int targetMl;

  const HydrationNudge({
    required this.index,
    required this.scheduledAt,
    required this.targetMl,
  });

  @override
  String toString() =>
      'HydrationNudge(#$index @ $scheduledAt, ${targetMl}ml)';
}
