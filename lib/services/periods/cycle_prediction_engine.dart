import 'dart:math';

import '../../models/periods/cycle_phase.dart';
import '../../models/periods/cycle_prediction.dart';
import '../../models/periods/menstrual_cycle.dart';

/// Pure prediction engine — no I/O, no Supabase dependency.
///
/// Algorithm: rolling average of the last 6 completed cycle lengths.
/// Confidence: ±1 population stddev, clamped to [1, 14] days.
/// Irregular: stddev > 7 days.
/// Ovulation: ~14 days before predicted next period start.
///
/// IMPORTANT: predictions are derived from plaintext cycle dates on the
/// client. Do NOT forward the output to any third-party LLM or API.
class CyclePredictionEngine {
  const CyclePredictionEngine();

  /// Returns a prediction or null when there are no completed cycles.
  CyclePrediction? predict(List<MenstrualCycle> cycles) {
    if (cycles.isEmpty) return null;

    final completed = cycles
        .where((c) => c.cycleEnd != null && c.cycleLength != null)
        .take(6)
        .toList();

    if (completed.isEmpty) return null;

    final lengths = completed.map((c) => c.cycleLength!.toDouble()).toList();
    final avg = lengths.reduce((a, b) => a + b) / lengths.length;

    double stddev = 0.0;
    if (lengths.length >= 2) {
      final variance =
          lengths.map((l) => pow(l - avg, 2)).reduce((a, b) => a + b) /
              lengths.length;
      stddev = sqrt(variance);
    }

    final confidence = stddev.ceil().clamp(1, 14);
    final isIrregular = stddev > 7.0;

    final lastStart = cycles.first.cycleStart;
    final nextStart = lastStart.add(Duration(days: avg.round()));
    final ovulation = nextStart.subtract(const Duration(days: 14));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cycleStartDay =
        DateTime(lastStart.year, lastStart.month, lastStart.day);
    final cycleDay = today.difference(cycleStartDay).inDays + 1;

    final phase = CyclePhase.forCycleDay(cycleDay.clamp(1, 60), avg.round());

    return CyclePrediction(
      nextPeriodStart: nextStart,
      confidenceIntervalDays: confidence,
      ovulationEstimate: ovulation,
      currentPhase: phase,
      cycleDay: cycleDay.clamp(1, 60),
      avgCycleLengthDays: avg,
      isIrregular: isIrregular,
    );
  }
}
