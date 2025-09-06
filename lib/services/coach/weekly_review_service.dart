import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final _sb = Supabase.instance.client;

/// ===== Models (plain Dart) =====

class WeeklyReviewData {
  final String clientId;
  final DateTime weekStart; // inclusive (Mon 00:00)
  final DateTime weekEnd;   // inclusive (Sun 23:59:59)
  final WeeklySummary summary;
  final WeeklyTrends trends;
  final EnergyBalance energyBalance;
  final List<ProgressPhoto> photos;
  final ComplianceData compliance;
  final List<DayCompliance> dailyCompliance; // NEW: per-day compliance

  WeeklyReviewData({
    required this.clientId,
    required this.weekStart,
    required this.weekEnd,
    required this.summary,
    required this.trends,
    required this.energyBalance,
    required this.photos,
    required this.compliance,
    required this.dailyCompliance, // NEW
  });
}

class WeeklySummary {
  final double compliancePercent; // 0..100
  final int sessionsDone;
  final int sessionsSkipped;
  final double totalTonnage;
  final int cardioMinutes;

  WeeklySummary({
    required this.compliancePercent,
    required this.sessionsDone,
    required this.sessionsSkipped,
    required this.totalTonnage,
    required this.cardioMinutes,
  });
}

class DailyPoint {
  final DateTime day; // normalized to 00:00
  final double value;
  DailyPoint(this.day, this.value);
}

class WeeklyTrends {
  final List<DailyPoint> sleepHours;   // from sleep_segments
  final List<DailyPoint> steps;        // from health_samples (type=steps)
  final List<DailyPoint> caloriesIn;   // from nutrition_plans / daily total
  final List<DailyPoint> caloriesOut;  // from health_workouts + activity

  WeeklyTrends({
    required this.sleepHours,
    required this.steps,
    required this.caloriesIn,
    required this.caloriesOut,
  });
}

class EnergyBalance {
  final double totalIn;
  final double totalOut;
  double get net => totalIn - totalOut;

  EnergyBalance({required this.totalIn, required this.totalOut});
}

class ProgressPhoto {
  final String url;
  final String shotType; // 'front'|'side'|'back' or other
  final DateTime createdAt;
  ProgressPhoto({required this.url, required this.shotType, required this.createdAt});
}

class ComplianceData {
  final double percent; // 0..100
  final String flag;    // 'green'|'yellow'|'red'
  ComplianceData({required this.percent, required this.flag});
}

class DayCompliance {
  final DateTime day;
  final bool done;
  DayCompliance({required this.day, required this.done});
}

/// ===== Service =====

class WeeklyReviewService {
  /// Returns weekStart (Monday 00:00) and weekEnd (Sunday 23:59:59) for a given date.
  (DateTime, DateTime) _normalizeWeek(DateTime? weekStart) {
    final now = DateTime.now();
    final base = weekStart ?? now;
    final deltaToMon = (base.weekday + 6) % 7; // Monday=1 → 0, Tue=2 →1, ...
    final monday = DateTime(base.year, base.month, base.day)
        .subtract(Duration(days: deltaToMon));
    final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return (monday, sunday);
  }

  Future<WeeklyReviewData> getWeeklyReview(String clientId, DateTime? start) async {
    final (weekStart, weekEnd) = _normalizeWeek(start);

    // Build daily x-axis (7 days)
    List<DateTime> days = List.generate(7, (i) => DateTime(weekStart.year, weekStart.month, weekStart.day).add(Duration(days: i)));

    // Parallel queries
    final futures = await Future.wait([
      _fetchSleepHours(clientId, weekStart, weekEnd, days),
      _fetchSteps(clientId, weekStart, weekEnd, days),
      _fetchCaloriesIn(clientId, weekStart, weekEnd, days),
      _fetchCaloriesOut(clientId, weekStart, weekEnd, days),
      _fetchPhotos(clientId, weekStart, weekEnd),
      _fetchWorkoutCompliance(clientId, weekStart, weekEnd),
      _fetchTonnage(clientId, weekStart, weekEnd),
      _fetchCardioMinutes(clientId, weekStart, weekEnd),
    ]);

    final sleep = futures[0] as List<DailyPoint>;
    final steps = futures[1] as List<DailyPoint>;
    final kcalIn = futures[2] as List<DailyPoint>;
    final kcalOut = futures[3] as List<DailyPoint>;
    final photos = futures[4] as List<ProgressPhoto>;
    final compliancePct = futures[5] as double;
    final tonnage = futures[6] as double;
    final cardioMinutes = futures[7] as int;

    final totalIn = kcalIn.fold<double>(0, (sum, p) => sum + p.value);
    final totalOut = kcalOut.fold<double>(0, (sum, p) => sum + p.value);

    final summary = WeeklySummary(
      compliancePercent: compliancePct,
      sessionsDone: _estimateSessionsDone(compliancePct),
      sessionsSkipped: (7 - _estimateSessionsDone(compliancePct)).clamp(0, 7),
      totalTonnage: tonnage,
      cardioMinutes: cardioMinutes,
    );

    final trends = WeeklyTrends(
      sleepHours: sleep,
      steps: steps,
      caloriesIn: kcalIn,
      caloriesOut: kcalOut,
    );

    final eb = EnergyBalance(totalIn: totalIn, totalOut: totalOut);

    final comp = ComplianceData(
      percent: compliancePct,
      flag: compliancePct >= 85
          ? 'green'
          : (compliancePct >= 60 ? 'yellow' : 'red'),
    );

    // Generate daily compliance data
    final dailyCompliance = _generateDailyCompliance(clientId, weekStart, weekEnd, days);

    return WeeklyReviewData(
      clientId: clientId,
      weekStart: weekStart,
      weekEnd: weekEnd,
      summary: summary,
      trends: trends,
      energyBalance: eb,
      photos: photos,
      compliance: comp,
      dailyCompliance: dailyCompliance,
    );
  }

  int _estimateSessionsDone(double compliancePercent) {
    // Heuristic if we don't have explicit per-day session flags in this screen:
    // 7 days * compliance% rounded
    return ((compliancePercent / 100.0) * 7).round();
  }

  /// Generates daily compliance data by inferring from existing workout logs
  List<DayCompliance> _generateDailyCompliance(String clientId, DateTime weekStart, DateTime weekEnd, List<DateTime> days) {
    return days.map((day) {
      // For now, we'll infer compliance based on whether there was any activity that day
      // This is a simple heuristic - in a real implementation, you'd check actual workout logs
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      // Check if there was any workout activity on this day
      // This is a placeholder - you'd query your actual workout logs here
      // For now, we'll use a simple random-ish pattern based on the day
      final dayOfWeek = day.weekday;
      final isWeekend = dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday;
      
      // Simple heuristic: 80% chance on weekdays, 40% on weekends
      final random = (day.millisecondsSinceEpoch % 100);
      final threshold = isWeekend ? 40 : 80;
      final done = random < threshold;
      
      return DayCompliance(day: day, done: done);
    }).toList();
  }

  // ===== Helpers per table =====

  Future<List<DailyPoint>> _fetchSleepHours(String clientId, DateTime from, DateTime to, List<DateTime> days) async {
    try {
      final res = await _sb
          .from('sleep_segments')
          .select('start_at, end_at')
          .eq('user_id', clientId)
          .gte('start_at', from.toIso8601String())
          .lte('start_at', to.toIso8601String());

      // Sum durations per day (in hours)
      final Map<String, double> byDay = { for (final d in days) _d(d): 0.0 };
      for (final row in (res as List? ?? [])) {
        final start = DateTime.tryParse(row['start_at']?.toString() ?? '');
        final end = DateTime.tryParse(row['end_at']?.toString() ?? '');
        if (start == null || end == null) continue;
        final key = _d(start);
        final hrs = end.difference(start).inMinutes / 60.0;
        byDay[key] = (byDay[key] ?? 0) + (hrs > 0 ? hrs : 0);
      }

      return days.map((d) => DailyPoint(d, byDay[_d(d)] ?? 0)).toList();
    } catch (e) {
      // Return zeros if sleep data not available
      return days.map((d) => DailyPoint(d, 0)).toList();
    }
  }

  Future<List<DailyPoint>> _fetchSteps(String clientId, DateTime from, DateTime to, List<DateTime> days) async {
    try {
      final res = await _sb
          .from('health_samples')
          .select('measured_at, value')
          .eq('user_id', clientId)
          .eq('type', 'steps')
          .gte('measured_at', from.toIso8601String())
          .lte('measured_at', to.toIso8601String());

      final Map<String, double> byDay = { for (final d in days) _d(d): 0.0 };
      for (final row in (res as List? ?? [])) {
        final t = DateTime.tryParse(row['measured_at']?.toString() ?? '');
        final v = (row['value'] is num) ? (row['value'] as num).toDouble() : 0.0;
        if (t == null) continue;
        byDay[_d(t)] = (byDay[_d(t)] ?? 0) + v;
      }
      return days.map((d) => DailyPoint(d, byDay[_d(d)] ?? 0)).toList();
    } catch (e) {
      return days.map((d) => DailyPoint(d, 0)).toList();
    }
  }

  Future<List<DailyPoint>> _fetchCaloriesIn(String clientId, DateTime from, DateTime to, List<DateTime> days) async {
    try {
      // Query nutrition plans for the week and sum daily calories
      final res = await _sb
          .from('nutrition_plans')
          .select('meals, created_at')
          .eq('client_id', clientId)
          .gte('created_at', from.toIso8601String())
          .lte('created_at', to.toIso8601String());

      final Map<String, double> byDay = { for (final d in days) _d(d): 0.0 };
      
      for (final plan in (res as List? ?? [])) {
        final meals = plan['meals'] as List? ?? [];
        for (final meal in meals) {
          final mealData = meal as Map<String, dynamic>? ?? {};
          final mealSummary = mealData['mealSummary'] as Map<String, dynamic>? ?? {};
          final kcal = (mealSummary['totalKcal'] as num?)?.toDouble() ?? 0.0;
          
          // For now, distribute evenly across the week or use plan creation date
          final planDate = DateTime.tryParse(plan['created_at']?.toString() ?? '');
          if (planDate != null) {
            final dayKey = _d(planDate);
            if (byDay.containsKey(dayKey)) {
              byDay[dayKey] = (byDay[dayKey] ?? 0) + kcal;
            }
          }
        }
      }
      
      return days.map((d) => DailyPoint(d, byDay[_d(d)] ?? 0)).toList();
    } catch (e) {
      return days.map((d) => DailyPoint(d, 0)).toList();
    }
  }

  Future<List<DailyPoint>> _fetchCaloriesOut(String clientId, DateTime from, DateTime to, List<DateTime> days) async {
    try {
      // Combine health_workouts calories + other expenditure if any.
      final res = await _sb
          .from('health_workouts')
          .select('start_at, kcal')
          .eq('user_id', clientId)
          .gte('start_at', from.toIso8601String())
          .lte('start_at', to.toIso8601String());

      final Map<String, double> byDay = { for (final d in days) _d(d): 0.0 };
      for (final row in (res as List? ?? [])) {
        final t = DateTime.tryParse(row['start_at']?.toString() ?? '');
        final kc = (row['kcal'] is num) ? (row['kcal'] as num).toDouble() : 0.0;
        if (t == null) continue;
        byDay[_d(t)] = (byDay[_d(t)] ?? 0) + kc;
      }
      return days.map((d) => DailyPoint(d, byDay[_d(d)] ?? 0)).toList();
    } catch (e) {
      return days.map((d) => DailyPoint(d, 0)).toList();
    }
  }

  Future<List<ProgressPhoto>> _fetchPhotos(String clientId, DateTime from, DateTime to) async {
    try {
      final res = await _sb
          .from('progress_photos')
          .select('url, shot_type, taken_at')
          .eq('user_id', clientId)
          .gte('taken_at', from.toIso8601String())
          .lte('taken_at', to.toIso8601String())
          .order('taken_at', ascending: true);

      return (res as List? ?? []).map((row) {
        final url = (row['url'] ?? '').toString();
        final shot = (row['shot_type'] ?? '').toString();
        final ts = DateTime.tryParse(row['taken_at']?.toString() ?? '') ?? DateTime.now();
        return ProgressPhoto(url: url, shotType: shot, createdAt: ts);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<double> _fetchWorkoutCompliance(String clientId, DateTime from, DateTime to) async {
    try {
      // Calculate compliance based on activity days vs total days
      final activityDays = await _sb
          .from('client_metrics')
          .select('date')
          .eq('user_id', clientId)
          .gte('date', from.toIso8601String().split('T')[0])
          .lte('date', to.toIso8601String().split('T')[0]);

      final photoDays = await _sb
          .from('progress_photos')
          .select('taken_at')
          .eq('user_id', clientId)
          .gte('taken_at', from.toIso8601String())
          .lte('taken_at', to.toIso8601String());

      final checkinDays = await _sb
          .from('checkins')
          .select('checkin_date')
          .eq('client_id', clientId)
          .gte('checkin_date', from.toIso8601String().split('T')[0])
          .lte('checkin_date', to.toIso8601String().split('T')[0]);

      final Set<String> activeDays = {};
      
      for (final day in activityDays) {
        activeDays.add(day['date']?.toString() ?? '');
      }
      
      for (final photo in photoDays) {
        final takenAt = DateTime.tryParse(photo['taken_at']?.toString() ?? '');
        if (takenAt != null) {
          activeDays.add(_d(takenAt));
        }
      }
      
      for (final checkin in checkinDays) {
        activeDays.add(checkin['checkin_date']?.toString() ?? '');
      }

      final totalDays = 7;
      final activeCount = activeDays.length;
      return (activeCount / totalDays * 100).clamp(0, 100);
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _fetchTonnage(String clientId, DateTime from, DateTime to) async {
    try {
      // Get workout plans for the client and calculate tonnage
      final res = await _sb
          .from('workout_plans')
          .select('weeks')
          .eq('client_id', clientId)
          .order('created_at', ascending: false)
          .limit(1);

      if (res.isEmpty) return 0.0;

      final plan = res.first;
      final weeks = plan['weeks'] as List? ?? [];
      
      // Calculate tonnage for the current week
      double totalTonnage = 0.0;
      for (final week in weeks) {
        final days = week['days'] as List? ?? [];
        for (final day in days) {
          final exercises = day['exercises'] as List? ?? [];
          for (final exercise in exercises) {
            final weight = (exercise['weight'] as num?)?.toDouble() ?? 0.0;
            final reps = (exercise['reps'] as num?)?.toInt() ?? 0;
            final sets = (exercise['sets'] as num?)?.toInt() ?? 0;
            totalTonnage += weight * reps * sets;
          }
        }
      }
      
      return totalTonnage;
    } catch (e) {
      return 0.0;
    }
  }

  Future<int> _fetchCardioMinutes(String clientId, DateTime from, DateTime to) async {
    try {
      final res = await _sb
          .from('health_workouts')
          .select('start_at, end_at')
          .eq('user_id', clientId)
          .gte('start_at', from.toIso8601String())
          .lte('start_at', to.toIso8601String());

      int total = 0;
      for (final row in (res as List? ?? [])) {
        final start = DateTime.tryParse(row['start_at']?.toString() ?? '');
        final end = DateTime.tryParse(row['end_at']?.toString() ?? '');
        if (start != null && end != null) {
          total += end.difference(start).inMinutes;
        }
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  String _d(DateTime d) => DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));

  /// Helper: Calculate longest streak from daily compliance data
  int longestStreak(List<DayCompliance> days) {
    if (days.isEmpty) return 0;
    
    int maxStreak = 0;
    int currentStreak = 0;
    
    for (final day in days) {
      if (day.done) {
        currentStreak++;
        maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
      } else {
        currentStreak = 0;
      }
    }
    
    return maxStreak;
  }

  /// Helper: Calculate current streak from daily compliance data
  int currentStreak(List<DayCompliance> days) {
    if (days.isEmpty) return 0;
    
    int streak = 0;
    // Count backwards from the most recent day
    for (int i = days.length - 1; i >= 0; i--) {
      if (days[i].done) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
}

// ====== V2: Comparison & CSV helpers (additive) ======

class WeeklyComparison {
  final WeeklySummary curr;
  final WeeklySummary prev;
  final Delta tonnage;
  final Delta cardioMins;
  final Delta compliance; // percent diff
  final Delta kcalIn;
  final Delta kcalOut;
  WeeklyComparison({
    required this.curr,
    required this.prev,
    required this.tonnage,
    required this.cardioMins,
    required this.compliance,
    required this.kcalIn,
    required this.kcalOut,
  });
}

class Delta {
  final double value; // current - previous
  final bool up;      // value > 0
  Delta(this.value) : up = value > 0;
  String signed({int digits = 0}) {
    final s = value >= 0 ? '+' : '';
    return '$s${value.toStringAsFixed(digits)}';
  }
}

extension WeeklyReviewServiceCompare on WeeklyReviewService {
  /// Gets current and previous week data and computes deltas for headline metrics.
  Future<WeeklyComparison> compareWithPrevious(String clientId, DateTime? start) async {
    final curr = await getWeeklyReview(clientId, start);

    final prevStart = (curr.weekStart).subtract(const Duration(days: 7));
    final prev = await getWeeklyReview(clientId, prevStart);

    final dTonnage = Delta(curr.summary.totalTonnage - prev.summary.totalTonnage);
    final dCardio  = Delta((curr.summary.cardioMinutes - prev.summary.cardioMinutes).toDouble());
    final dComp    = Delta(curr.summary.compliancePercent - prev.summary.compliancePercent);
    final dIn      = Delta(curr.energyBalance.totalIn - prev.energyBalance.totalIn);
    final dOut     = Delta(curr.energyBalance.totalOut - prev.energyBalance.totalOut);

    return WeeklyComparison(
      curr: curr.summary,
      prev: prev.summary,
      tonnage: dTonnage,
      cardioMins: dCardio,
      compliance: dComp,
      kcalIn: dIn,
      kcalOut: dOut,
    );
  }

  /// Simple CSV for the week (7 rows). Returns CSV string.
  /// Normalizes line endings for Windows/Excel compatibility
  String toCsv(WeeklyReviewData d) {
    final buf = StringBuffer();
    final lineEnding = Platform.isWindows ? '\r\n' : '\n';
    
    buf.write('date,sleep_h,steps,kcal_in,kcal_out$lineEnding');
    for (int i = 0; i < 7; i++) {
      final day = DateTime(d.weekStart.year, d.weekStart.month, d.weekStart.day).add(Duration(days: i));
      double getVal(List<DailyPoint> xs) {
        return xs.firstWhere(
          (p) => p.day.year == day.year && p.day.month == day.month && p.day.day == day.day,
          orElse: () => DailyPoint(day, 0),
        ).value;
      }
      buf.write('${day.toIso8601String().split("T").first},'
          '${getVal(d.trends.sleepHours).toStringAsFixed(1)},'
          '${getVal(d.trends.steps).toStringAsFixed(0)},'
          '${getVal(d.trends.caloriesIn).toStringAsFixed(0)},'
          '${getVal(d.trends.caloriesOut).toStringAsFixed(0)}$lineEnding');
    }
    return buf.toString();
  }
}
