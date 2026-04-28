import 'cycle_phase.dart';

class CyclePrediction {
  final DateTime nextPeriodStart;

  /// ± days around nextPeriodStart (1 standard deviation, clamped 1–14).
  final int confidenceIntervalDays;

  /// Estimated ovulation date (~14 days before next period).
  final DateTime ovulationEstimate;

  final CyclePhase currentPhase;

  /// Day within the current cycle (1-indexed).
  final int cycleDay;

  final double avgCycleLengthDays;
  final bool isIrregular;

  const CyclePrediction({
    required this.nextPeriodStart,
    required this.confidenceIntervalDays,
    required this.ovulationEstimate,
    required this.currentPhase,
    required this.cycleDay,
    required this.avgCycleLengthDays,
    required this.isIrregular,
  });

  DateTime get nextPeriodEarliest =>
      nextPeriodStart.subtract(Duration(days: confidenceIntervalDays));

  DateTime get nextPeriodLatest =>
      nextPeriodStart.add(Duration(days: confidenceIntervalDays));

  int get daysUntilNextPeriod {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
        nextPeriodStart.year, nextPeriodStart.month, nextPeriodStart.day);
    return start.difference(today).inDays;
  }

  int get daysUntilOvulation {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final ovDay = DateTime(
        ovulationEstimate.year, ovulationEstimate.month, ovulationEstimate.day);
    return ovDay.difference(today).inDays;
  }
}
