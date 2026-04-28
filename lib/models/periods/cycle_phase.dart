import 'package:flutter/material.dart';

enum CyclePhase {
  menstrual,
  follicular,
  ovulation,
  luteal;

  String get displayName {
    switch (this) {
      case CyclePhase.menstrual:  return 'Menstrual';
      case CyclePhase.follicular: return 'Follicular';
      case CyclePhase.ovulation:  return 'Ovulation';
      case CyclePhase.luteal:     return 'Luteal';
    }
  }

  String get description {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Menstruation. Energy may be lower; prioritise recovery.';
      case CyclePhase.follicular:
        return 'Estrogen rising. Good window for higher-intensity training.';
      case CyclePhase.ovulation:
        return 'Peak energy and strength. Ideal for personal records.';
      case CyclePhase.luteal:
        return 'Progesterone dominant. Moderate intensity; watch for fatigue.';
    }
  }

  Color get color {
    switch (this) {
      case CyclePhase.menstrual:  return const Color(0xFFE53935); // red
      case CyclePhase.follicular: return const Color(0xFF43A047); // green
      case CyclePhase.ovulation:  return const Color(0xFF1E88E5); // blue
      case CyclePhase.luteal:     return const Color(0xFFFB8C00); // amber
    }
  }

  /// Determine the phase from a cycle day number and the user's average cycle length.
  ///
  /// Medical convention: ovulation occurs approximately 14 days before the
  /// next expected period, i.e. on cycle day (avgCycleLength - 14).
  static CyclePhase forCycleDay(int cycleDay, int avgCycleLength) {
    final ovulationDay = (avgCycleLength - 14).clamp(8, avgCycleLength - 2);
    if (cycleDay <= 5) return CyclePhase.menstrual;
    if (cycleDay < ovulationDay) return CyclePhase.follicular;
    if (cycleDay <= ovulationDay + 1) return CyclePhase.ovulation;
    return CyclePhase.luteal;
  }
}
