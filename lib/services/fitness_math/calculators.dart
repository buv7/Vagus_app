// Fitness math: 1RM, strength coefficients, RP volume landmarks, BMR/TDEE.
//
// All formulas are open math from public sources. Each is unit-tested in
// test/services/fitness_math/calculators_test.dart with the citation in the
// test name so the source is traceable.

import 'dart:math' as math;

enum Sex { male, female }

enum Lift { squat, bench, deadlift, total }

enum Experience { beginner, intermediate, advanced }

enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  quads,
  hamstrings,
  glutes,
  calves,
  forearms,
  abs,
}

/// One-rep max estimators. All accept (weight lifted, reps performed) and
/// return the implied 1RM in the same unit as `weight`.
class OneRepMax {
  OneRepMax._();

  static void _checkInputs(double weight, int reps) {
    if (weight <= 0) {
      throw ArgumentError.value(weight, 'weight', 'must be > 0');
    }
    if (reps < 1) {
      throw ArgumentError.value(reps, 'reps', 'must be >= 1');
    }
  }

  /// Epley (1985). Standard for moderate reps.
  static double epley(double weight, int reps) {
    _checkInputs(weight, reps);
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  /// Brzycki (1993). Undefined at reps >= 37 (denominator collapses).
  static double brzycki(double weight, int reps) {
    _checkInputs(weight, reps);
    if (reps == 1) return weight;
    if (reps >= 37) {
      throw ArgumentError.value(reps, 'reps', 'Brzycki undefined at reps >= 37');
    }
    return weight * 36.0 / (37 - reps);
  }

  /// Lombardi (1989). Power curve; less accurate for very high reps.
  static double lombardi(double weight, int reps) {
    _checkInputs(weight, reps);
    return weight * math.pow(reps, 0.10).toDouble();
  }

  /// Lander (1985).
  static double lander(double weight, int reps) {
    _checkInputs(weight, reps);
    if (reps == 1) return weight;
    return (100 * weight) / (101.3 - 2.67123 * reps);
  }

  /// Mayhew et al. (1992).
  static double mayhew(double weight, int reps) {
    _checkInputs(weight, reps);
    if (reps == 1) return weight;
    return (100 * weight) / (52.2 + 41.9 * math.exp(-0.055 * reps));
  }

  /// O'Conner et al. (1989).
  static double oconner(double weight, int reps) {
    _checkInputs(weight, reps);
    if (reps == 1) return weight;
    return weight * (1 + 0.025 * reps);
  }

  /// Wathan (1994).
  static double wathan(double weight, int reps) {
    _checkInputs(weight, reps);
    if (reps == 1) return weight;
    return (100 * weight) / (48.8 + 53.8 * math.exp(-0.075 * reps));
  }

  /// Arithmetic mean of all seven estimators.
  static double average(double weight, int reps) {
    final values = <double>[
      epley(weight, reps),
      // Brzycki undefined for very high reps; fall back to Epley equivalence.
      reps < 37 ? brzycki(weight, reps) : epley(weight, reps),
      lombardi(weight, reps),
      lander(weight, reps),
      mayhew(weight, reps),
      oconner(weight, reps),
      wathan(weight, reps),
    ];
    return values.reduce((a, b) => a + b) / values.length;
  }
}

/// Strength score normalisation: compares lifters across body weights.
class Strength {
  Strength._();

  /// DOTS (replaced Wilks in OpenPowerlifting 2020). Returns score points.
  /// Coefficients from OpenPowerlifting / Tim Konertz.
  static double dots(double lift, double bodyweight, Sex sex) {
    _checkBw(bodyweight);
    final c = sex == Sex.male
        ? const [
            -307.75076,
            24.0900756,
            -0.1918759221,
            0.0007391293,
            -0.000001093,
          ]
        : const [
            -57.96288,
            13.6175032,
            -0.1126655495,
            0.0005158568,
            -0.0000010706,
          ];
    final bw = bodyweight;
    final bw2 = bw * bw;
    final bw3 = bw2 * bw;
    final bw4 = bw3 * bw;
    final poly = c[0] + c[1] * bw + c[2] * bw2 + c[3] * bw3 + c[4] * bw4;
    return lift * 500.0 / poly;
  }

  /// Wilks (1996 original). Kept for legacy comparison; prefer DOTS.
  static double wilks(double lift, double bodyweight, Sex sex) {
    _checkBw(bodyweight);
    final c = sex == Sex.male
        ? const [
            -216.0475144,
            16.2606339,
            -0.002388645,
            -0.00113732,
            7.01863e-6,
            -1.291e-8,
          ]
        : const [
            594.31747775582,
            -27.23842536447,
            0.82112226871,
            -0.00930733913,
            4.731582e-5,
            -9.054e-8,
          ];
    final bw = bodyweight;
    final bw2 = bw * bw;
    final bw3 = bw2 * bw;
    final bw4 = bw3 * bw;
    final bw5 = bw4 * bw;
    final poly = c[0] +
        c[1] * bw +
        c[2] * bw2 +
        c[3] * bw3 +
        c[4] * bw4 +
        c[5] * bw5;
    return lift * 500.0 / poly;
  }

  /// IPF GL Points ("Goodlift", 2020 IPF official). Per-lift, per-sex.
  /// Form: lift * 100 / (A - B * exp(-C * bodyweight)).
  static double ipfgl(double lift, double bodyweight, Sex sex, Lift event) {
    _checkBw(bodyweight);
    final coefs = _ipfglCoefs(sex, event);
    return lift *
        100.0 /
        (coefs[0] - coefs[1] * math.exp(-coefs[2] * bodyweight));
  }

  static List<double> _ipfglCoefs(Sex sex, Lift event) {
    if (sex == Sex.male) {
      switch (event) {
        case Lift.squat:
          return const [1199.72839, 1025.18162, 0.00921];
        case Lift.bench:
          return const [320.98041, 281.40258, 0.01008];
        case Lift.deadlift:
          return const [1236.25115, 1449.21864, 0.01644];
        case Lift.total:
          return const [1199.72839, 1025.18162, 0.00921];
      }
    }
    switch (event) {
      case Lift.squat:
        return const [610.32796, 1045.59282, 0.03048];
      case Lift.bench:
        return const [142.40398, 442.52671, 0.04724];
      case Lift.deadlift:
        return const [472.85878, 879.16327, 0.04701];
      case Lift.total:
        return const [610.32796, 1045.59282, 0.03048];
    }
  }

  static void _checkBw(double bodyweight) {
    if (bodyweight <= 0) {
      throw ArgumentError.value(bodyweight, 'bodyweight', 'must be > 0');
    }
  }
}

/// Renaissance Periodization weekly volume landmarks (sets per muscle / week).
/// MEV — minimum effective volume (smallest dose that grows muscle).
/// MAV — maximum adaptive volume (the productive sweet spot).
/// MRV — maximum recoverable volume (above this, regression).
///
/// Base values are intermediate; beginners trend lower (~70%), advanced higher
/// (~115%). Sources: Israetel et al., Renaissance Periodization training guides.
class Volume {
  Volume._();

  static int mev(Experience exp, MuscleGroup mg) =>
      _adjust(_base(mg).mev, exp);

  static int mav(Experience exp, MuscleGroup mg) =>
      _adjust(_base(mg).mav, exp);

  static int mrv(Experience exp, MuscleGroup mg) =>
      _adjust(_base(mg).mrv, exp);

  static int _adjust(int base, Experience exp) {
    switch (exp) {
      case Experience.beginner:
        return (base * 0.70).round();
      case Experience.intermediate:
        return base;
      case Experience.advanced:
        return (base * 1.15).round();
    }
  }

  static _Landmark _base(MuscleGroup mg) {
    switch (mg) {
      case MuscleGroup.chest:
        return const _Landmark(8, 16, 22);
      case MuscleGroup.back:
        return const _Landmark(10, 18, 25);
      case MuscleGroup.shoulders:
        return const _Landmark(8, 19, 26);
      case MuscleGroup.biceps:
        return const _Landmark(8, 17, 26);
      case MuscleGroup.triceps:
        return const _Landmark(6, 12, 18);
      case MuscleGroup.quads:
        return const _Landmark(8, 15, 20);
      case MuscleGroup.hamstrings:
        return const _Landmark(6, 13, 20);
      case MuscleGroup.glutes:
        return const _Landmark(0, 8, 16);
      case MuscleGroup.calves:
        return const _Landmark(8, 14, 20);
      case MuscleGroup.forearms:
        return const _Landmark(2, 9, 25);
      case MuscleGroup.abs:
        return const _Landmark(0, 18, 25);
    }
  }
}

class _Landmark {
  final int mev;
  final int mav;
  final int mrv;
  const _Landmark(this.mev, this.mav, this.mrv);
}

/// Energy expenditure: BMR + TDEE.
class Energy {
  Energy._();

  /// Mifflin-St Jeor (1990). Best general-purpose BMR when body fat % unknown.
  /// Returns kcal/day.
  static double mifflinStJeor({
    required double weightKg,
    required double heightCm,
    required int age,
    required Sex sex,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age < 0) {
      throw ArgumentError('weightKg, heightCm must be > 0; age must be >= 0');
    }
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return base + (sex == Sex.male ? 5.0 : -161.0);
  }

  /// Katch-McArdle (1996). More accurate when body fat % is measured.
  /// `bodyFatPct` is a fraction in [0.0, 1.0). Returns kcal/day.
  static double katchMcArdle({
    required double weightKg,
    required double bodyFatPct,
  }) {
    if (weightKg <= 0) {
      throw ArgumentError.value(weightKg, 'weightKg', 'must be > 0');
    }
    if (bodyFatPct < 0 || bodyFatPct >= 1) {
      throw ArgumentError.value(
        bodyFatPct,
        'bodyFatPct',
        'must be in [0.0, 1.0)',
      );
    }
    final lbm = weightKg * (1 - bodyFatPct);
    return 370 + 21.6 * lbm;
  }

  /// Total daily energy expenditure = BMR * activity factor.
  /// Conventional factors: 1.2 sedentary, 1.375 light, 1.55 moderate,
  /// 1.725 active, 1.9 very active.
  static double tdee(double bmr, double activityFactor) {
    if (bmr <= 0) {
      throw ArgumentError.value(bmr, 'bmr', 'must be > 0');
    }
    if (activityFactor < 1.0 || activityFactor > 2.5) {
      throw ArgumentError.value(
        activityFactor,
        'activityFactor',
        'must be in [1.0, 2.5]',
      );
    }
    return bmr * activityFactor;
  }
}
