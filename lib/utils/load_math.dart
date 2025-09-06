// lib/utils/load_math.dart
import 'dart:math';

enum LoadUnit { kg, lb }

class LoadMath {
  // Bar defaults
  static const defaultKgBar = 20.0;
  static const defaultLbBar = 45.0;

  // Plates per side, largest → smallest
  static const kgPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
  static const lbPlates = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5];

  // Round to typical gyms: 2.5 kg / 5 lb
  static double roundToGym(double x, LoadUnit u) {
    final step = (u == LoadUnit.kg) ? 2.5 : 5.0;
    return (x / step).round() * step;
  }

  // Convert units
  static double kg2lb(double kg) => kg * 2.2046226218;
  static double lb2kg(double lb) => lb / 2.2046226218;

  // Compute target load from 1RM% if provided; else fallback to given weight
  // If both present, prefer percent1RM when in [30..95].
  static double? targetFromPercent({
    required double? percent1RM,
    required double? training1RM, // if you don't have this, pass null
    required double? fallbackWeight,
  }) {
    if (percent1RM != null && training1RM != null && percent1RM >= 30 && percent1RM <= 95) {
      return training1RM * (percent1RM / 100.0);
    }
    return fallbackWeight;
  }

  // If no training1RM, you can estimate from a known recent set using Epley:
  // 1RM ≈ w * (1 + reps/30). Guard for reps 1..12
  static double? estimate1RMFromSet(double? weight, int? reps) {
    if (weight == null || reps == null || reps <= 0 || reps > 12) return null;
    return weight * (1.0 + reps / 30.0);
  }

  // Warm-up scheme from topSet (3–5 ramp sets)
  // Example percentages: 40%x5, 60%x3, 75%x2, 85%x1 (configurable by exercise type later)
  static List<WarmupSet> buildWarmup({
    required double topSet,
    required LoadUnit unit,
    double barWeight = defaultKgBar,
    List<_WU> scheme = const [
      _WU(0.40, 5),
      _WU(0.60, 3),
      _WU(0.75, 2),
      _WU(0.85, 1),
    ],
  }) {
    return scheme.map((s) {
      final raw = topSet * s.pct;
      final rounded = roundToGym(raw, unit);
      return WarmupSet(percent: (s.pct * 100).round(), reps: s.reps, weight: max(rounded, barWeight));
    }).toList();
  }

  // Plate breakdown per side for barbell lifts
  static List<double> platesPerSide({
    required double total,
    required LoadUnit unit,
    required double barWeight,
  }) {
    if (total <= barWeight) return const [];
    final eachSide = (total - barWeight) / 2.0;
    final plates = <double>[];
    var remain = eachSide;
    final pool = unit == LoadUnit.kg ? kgPlates : lbPlates;
    for (final p in pool) {
      while (remain + 1e-6 >= p) {
        plates.add(p);
        remain -= p;
      }
    }
    // ignore leftover ≤ smallest plate; rounding already handled
    return plates;
  }
}

class WarmupSet {
  final int percent; // e.g., 60
  final int reps;
  final double weight; // same unit as selected
  const WarmupSet({required this.percent, required this.reps, required this.weight});
  @override
  String toString() => '${percent}% × $reps @ ${weight.toStringAsFixed(0)}';
}

class _WU {
  final double pct;
  final int reps;
  const _WU(this.pct, this.reps);
}
