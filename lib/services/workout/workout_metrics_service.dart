import 'dart:convert';

class WorkoutMetricsService {
  WorkoutMetricsService._();

  /// Computes a weekly muscle volume summary for the given plan.
  ///
  /// The returned map is keyed by muscle group name and contains:
  /// { 'sets': int, 'reps': int, 'volume': double }
  ///
  /// - plan: expects a structure like { 'weeks': [ { 'days': [ { 'exercises': [ { ... } ] } ] } ] }
  /// - weekIndex: zero-based index of the week to summarize
  static Map<String, dynamic> weekVolumeSummary(
    Map<String, dynamic> plan, {
    required int weekIndex,
  }) {
    final result = <String, Map<String, num>>{}; // muscle -> {sets, reps, volume}

    final weeksRaw = plan['weeks'];
    if (weeksRaw is! List) return {};
    if (weekIndex < 0 || weekIndex >= weeksRaw.length) return {};

    final week = weeksRaw[weekIndex];
    if (week is! Map) return {};

    final daysRaw = week['days'];
    if (daysRaw is! List) return {};

    for (final dayRaw in daysRaw) {
      if (dayRaw is! Map) continue;
      final exercisesRaw = dayRaw['exercises'];
      if (exercisesRaw is! List) continue;

      for (final exRaw in exercisesRaw) {
        if (exRaw is! Map) continue;
        final exercise = Map<String, dynamic>.from(exRaw);
        final String name = (exercise['name'] ?? '').toString();
        final int sets = _asInt(exercise['sets']);
        final int reps = _asInt(exercise['reps']);
        final double weight = _asDouble(exercise['weight']);
        final double volume = (weight > 0 && reps > 0) ? (weight * reps) : 0.0;

        final List<String> muscles = _pluckMuscles(exercise, name);
        if (muscles.isEmpty) {
          // Bucket unknowns into a generic group to avoid losing data
          _accumulate(result, 'Other', sets: sets, reps: reps, volume: volume);
        } else {
          for (final muscle in muscles) {
            _accumulate(result, muscle, sets: sets, reps: reps, volume: volume);
          }
        }
      }
    }

    // Convert to dynamic
    return result.map((k, v) => MapEntry(k, {
          'sets': (v['sets'] ?? 0).toInt(),
          'reps': (v['reps'] ?? 0).toInt(),
          'volume': (v['volume'] ?? 0).toDouble(),
        }));
  }

  static void _accumulate(
    Map<String, Map<String, num>> target,
    String muscle, {
    required int sets,
    required int reps,
    required double volume,
  }) {
    final bucket = target[muscle] ?? {'sets': 0, 'reps': 0, 'volume': 0.0};
    bucket['sets'] = (bucket['sets'] ?? 0) + sets;
    bucket['reps'] = (bucket['reps'] ?? 0) + reps;
    bucket['volume'] = (bucket['volume'] ?? 0.0) + volume;
    target[muscle] = bucket;
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  /// Prefer explicit exercise['muscles'] when present; else map by name keywords.
  static List<String> _pluckMuscles(Map<String, dynamic> exercise, String exerciseName) {
    final musclesRaw = exercise['muscles'];
    if (musclesRaw is List) {
      final names = musclesRaw
          .where((e) => e != null)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (names.isNotEmpty) return names;
    }

    final n = exerciseName.toLowerCase();
    final Set<String> inferred = {};

    // Common compound lifts
    if (n.contains('bench')) inferred.addAll(['Chest', 'Triceps', 'Shoulders']);
    if (n.contains('squat')) inferred.addAll(['Quads', 'Glutes', 'Hamstrings', 'Core']);
    if (n.contains('deadlift')) inferred.addAll(['Back', 'Glutes', 'Hamstrings']);
    if (n.contains('row')) inferred.addAll(['Back', 'Biceps']);
    if (n.contains('pull-up') || n.contains('pull up') || n.contains('chin')) {
      inferred.addAll(['Back', 'Biceps']);
    }
    if (n.contains('press')) inferred.addAll(['Shoulders', 'Chest', 'Triceps']);
    if (n.contains('overhead')) inferred.add('Shoulders');
    if (n.contains('ohp')) inferred.add('Shoulders');
    if (n.contains('lunge')) inferred.addAll(['Quads', 'Glutes']);
    if (n.contains('calf')) inferred.add('Calves');
    if (n.contains('curl')) inferred.add('Biceps');
    if (n.contains('extension') && n.contains('tricep')) inferred.add('Triceps');
    if (n.contains('dip')) inferred.add('Triceps');
    if (n.contains('crunch') || n.contains('plank') || n.contains('sit-up') || n.contains('sit up')) {
      inferred.add('Core');
    }
    if (n.contains('lat pulldown') || n.contains('pulldown')) inferred.addAll(['Back', 'Biceps']);

    return inferred.toList(growable: false);
  }

  /// A simple, stable hash for memoization keys when needed.
  static String stablePlanHash(Map<String, dynamic> plan) {
    try {
      return base64Url.encode(utf8.encode(json.encode(plan)));
    } catch (_) {
      // Fallback to toString if plan has non-encodable content
      return plan.toString();
    }
  }
}


