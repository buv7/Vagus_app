// =====================================================
// MACRO CYCLING & PERIODIZATION SERVICE
// =====================================================
// Revolutionary service for advanced macro manipulation and diet periodization.
//
// FEATURES:
// - Weekly macro variance templates
// - Carb cycling (high/medium/low days)
// - Multi-week diet phases (cutting/maintenance/bulking)
// - Performance nutrition timing
// - Refeed and diet break scheduling
// - Metabolic adaptation tracking
// - Cycle progress visualization
// =====================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =====================================================
// ENUMS
// =====================================================

enum DietPhase {
  cutting,      // Caloric deficit
  maintenance,  // Caloric balance
  bulking,      // Caloric surplus
  minicut,      // Short 2-4 week cut
  refeed,       // Strategic overfeed
}

enum CarbCycleDay {
  high,    // Training day / High carb
  medium,  // Moderate training / Medium carb
  low,     // Rest day / Low carb
  refeed,  // Strategic high carb day
}

enum TrainingIntensity {
  rest,
  low,
  moderate,
  high,
  peak,
}

// =====================================================
// MODELS
// =====================================================

/// Macro cycling template
class MacroCycleTemplate {
  final String id;
  final String name;
  final String description;
  final CycleType cycleType;
  final Map<String, DayMacroTarget> dayTargets; // 'monday' -> targets
  final int weekDuration; // Number of weeks
  final bool isPublic;

  MacroCycleTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.cycleType,
    required this.dayTargets,
    this.weekDuration = 1,
    this.isPublic = false,
  });

  factory MacroCycleTemplate.fromJson(Map<String, dynamic> json) {
    final dayTargetsMap = <String, DayMacroTarget>{};
    if (json['day_targets'] != null) {
      (json['day_targets'] as Map<String, dynamic>).forEach((key, value) {
        dayTargetsMap[key] = DayMacroTarget.fromJson(value as Map<String, dynamic>);
      });
    }

    return MacroCycleTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      cycleType: CycleType.values.firstWhere(
        (e) => e.name == json['cycle_type'],
        orElse: () => CycleType.custom,
      ),
      dayTargets: dayTargetsMap,
      weekDuration: json['week_duration'] as int? ?? 1,
      isPublic: json['is_public'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final dayTargetsJson = <String, dynamic>{};
    dayTargets.forEach((key, value) {
      dayTargetsJson[key] = value.toJson();
    });

    return {
      'id': id,
      'name': name,
      'description': description,
      'cycle_type': cycleType.name,
      'day_targets': dayTargetsJson,
      'week_duration': weekDuration,
      'is_public': isPublic,
    };
  }
}

enum CycleType {
  carbCycling,      // Carb cycling based on training
  calorieWave,      // Calorie wave (zig-zag)
  refeedProtocol,   // Periodic refeeds
  phasedDiet,       // Multi-phase diet
  custom,           // Custom template
}

/// Daily macro targets within a cycle
class DayMacroTarget {
  final CarbCycleDay cycleDay;
  final double calorieTarget;
  final double proteinTarget;
  final double carbTarget;
  final double fatTarget;
  final TrainingIntensity? expectedIntensity;
  final String? notes;

  DayMacroTarget({
    required this.cycleDay,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbTarget,
    required this.fatTarget,
    this.expectedIntensity,
    this.notes,
  });

  factory DayMacroTarget.fromJson(Map<String, dynamic> json) {
    return DayMacroTarget(
      cycleDay: CarbCycleDay.values.firstWhere(
        (e) => e.name == json['cycle_day'],
        orElse: () => CarbCycleDay.medium,
      ),
      calorieTarget: (json['calorie_target'] as num).toDouble(),
      proteinTarget: (json['protein_target'] as num).toDouble(),
      carbTarget: (json['carb_target'] as num).toDouble(),
      fatTarget: (json['fat_target'] as num).toDouble(),
      expectedIntensity: json['expected_intensity'] != null
          ? TrainingIntensity.values.firstWhere(
              (e) => e.name == json['expected_intensity'],
              orElse: () => TrainingIntensity.moderate,
            )
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cycle_day': cycleDay.name,
      'calorie_target': calorieTarget,
      'protein_target': proteinTarget,
      'carb_target': carbTarget,
      'fat_target': fatTarget,
      'expected_intensity': expectedIntensity?.name,
      'notes': notes,
    };
  }
}

/// Active macro cycle for a user
class ActiveMacroCycle {
  final String id;
  final String userId;
  final String templateId;
  final String templateName;
  final DateTime startDate;
  final DateTime? endDate;
  final int currentWeek;
  final bool isActive;
  final Map<String, DayMacroTarget> dayTargets;

  ActiveMacroCycle({
    required this.id,
    required this.userId,
    required this.templateId,
    required this.templateName,
    required this.startDate,
    this.endDate,
    this.currentWeek = 1,
    this.isActive = true,
    required this.dayTargets,
  });

  factory ActiveMacroCycle.fromJson(Map<String, dynamic> json) {
    final dayTargetsMap = <String, DayMacroTarget>{};
    if (json['day_targets'] != null) {
      (json['day_targets'] as Map<String, dynamic>).forEach((key, value) {
        dayTargetsMap[key] = DayMacroTarget.fromJson(value as Map<String, dynamic>);
      });
    }

    return ActiveMacroCycle(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      templateId: json['template_id'] as String,
      templateName: json['template_name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      currentWeek: json['current_week'] as int? ?? 1,
      isActive: json['is_active'] as bool? ?? true,
      dayTargets: dayTargetsMap,
    );
  }

  Map<String, dynamic> toJson() {
    final dayTargetsJson = <String, dynamic>{};
    dayTargets.forEach((key, value) {
      dayTargetsJson[key] = value.toJson();
    });

    return {
      'id': id,
      'user_id': userId,
      'template_id': templateId,
      'template_name': templateName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'current_week': currentWeek,
      'is_active': isActive,
      'day_targets': dayTargetsJson,
    };
  }

  /// Get target for specific date
  DayMacroTarget? getTargetForDate(DateTime date) {
    final weekday = _getWeekdayKey(date);
    return dayTargets[weekday];
  }

  String _getWeekdayKey(DateTime date) {
    const weekdays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return weekdays[date.weekday - 1];
  }
}

/// Diet phase with progression
class DietPhaseProgram {
  final String id;
  final String userId;
  final String name;
  final List<PhaseBlock> phases;
  final DateTime startDate;
  final DateTime? endDate;
  final int currentPhaseIndex;
  final bool isActive;

  DietPhaseProgram({
    required this.id,
    required this.userId,
    required this.name,
    required this.phases,
    required this.startDate,
    this.endDate,
    this.currentPhaseIndex = 0,
    this.isActive = true,
  });

  factory DietPhaseProgram.fromJson(Map<String, dynamic> json) {
    return DietPhaseProgram(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      phases: (json['phases'] as List)
          .map((p) => PhaseBlock.fromJson(p as Map<String, dynamic>))
          .toList(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      currentPhaseIndex: json['current_phase_index'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phases': phases.map((p) => p.toJson()).toList(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'current_phase_index': currentPhaseIndex,
      'is_active': isActive,
    };
  }

  PhaseBlock? get currentPhase {
    if (currentPhaseIndex >= 0 && currentPhaseIndex < phases.length) {
      return phases[currentPhaseIndex];
    }
    return null;
  }
}

/// Individual phase block
class PhaseBlock {
  final DietPhase phase;
  final int durationWeeks;
  final double dailyCalories;
  final double proteinGrams;
  final double carbGrams;
  final double fatGrams;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;

  PhaseBlock({
    required this.phase,
    required this.durationWeeks,
    required this.dailyCalories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    this.description,
    this.startDate,
    this.endDate,
  });

  factory PhaseBlock.fromJson(Map<String, dynamic> json) {
    return PhaseBlock(
      phase: DietPhase.values.firstWhere(
        (e) => e.name == json['phase'],
        orElse: () => DietPhase.maintenance,
      ),
      durationWeeks: json['duration_weeks'] as int,
      dailyCalories: (json['daily_calories'] as num).toDouble(),
      proteinGrams: (json['protein_grams'] as num).toDouble(),
      carbGrams: (json['carb_grams'] as num).toDouble(),
      fatGrams: (json['fat_grams'] as num).toDouble(),
      description: json['description'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phase': phase.name,
      'duration_weeks': durationWeeks,
      'daily_calories': dailyCalories,
      'protein_grams': proteinGrams,
      'carb_grams': carbGrams,
      'fat_grams': fatGrams,
      'description': description,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }
}

/// Refeed/diet break schedule
class RefeedSchedule {
  final String id;
  final String userId;
  final RefeedType type;
  final int frequencyDays; // Every X days
  final double calorieMultiplier; // 1.2 = 120% of maintenance
  final int durationHours;
  final DateTime? nextScheduledDate;
  final bool isActive;

  RefeedSchedule({
    required this.id,
    required this.userId,
    required this.type,
    required this.frequencyDays,
    this.calorieMultiplier = 1.2,
    this.durationHours = 24,
    this.nextScheduledDate,
    this.isActive = true,
  });

  factory RefeedSchedule.fromJson(Map<String, dynamic> json) {
    return RefeedSchedule(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: RefeedType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RefeedType.singleDay,
      ),
      frequencyDays: json['frequency_days'] as int,
      calorieMultiplier: json['calorie_multiplier'] != null
          ? (json['calorie_multiplier'] as num).toDouble()
          : 1.2,
      durationHours: json['duration_hours'] as int? ?? 24,
      nextScheduledDate: json['next_scheduled_date'] != null
          ? DateTime.parse(json['next_scheduled_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'frequency_days': frequencyDays,
      'calorie_multiplier': calorieMultiplier,
      'duration_hours': durationHours,
      'next_scheduled_date': nextScheduledDate?.toIso8601String(),
      'is_active': isActive,
    };
  }
}

enum RefeedType {
  singleDay,   // 1 day refeed
  weekend,     // 2 day refeed
  dietBreak,   // 7-14 day break at maintenance
}

// =====================================================
// SERVICE
// =====================================================

class MacroCyclingService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // PREDEFINED TEMPLATES
  // =====================================================

  /// Get popular carb cycling templates
  static List<MacroCycleTemplate> get popularTemplates => [
        // Classic 5-2 Carb Cycle
        MacroCycleTemplate(
          id: 'classic_5_2',
          name: 'Classic 5-2 Carb Cycle',
          description: '5 low-carb days, 2 high-carb days (weekend)',
          cycleType: CycleType.carbCycling,
          dayTargets: {
            'monday': DayMacroTarget(
              cycleDay: CarbCycleDay.low,
              calorieTarget: 1800,
              proteinTarget: 180,
              carbTarget: 100,
              fatTarget: 70,
            ),
            'tuesday': DayMacroTarget(
              cycleDay: CarbCycleDay.low,
              calorieTarget: 1800,
              proteinTarget: 180,
              carbTarget: 100,
              fatTarget: 70,
            ),
            'wednesday': DayMacroTarget(
              cycleDay: CarbCycleDay.low,
              calorieTarget: 1800,
              proteinTarget: 180,
              carbTarget: 100,
              fatTarget: 70,
            ),
            'thursday': DayMacroTarget(
              cycleDay: CarbCycleDay.low,
              calorieTarget: 1800,
              proteinTarget: 180,
              carbTarget: 100,
              fatTarget: 70,
            ),
            'friday': DayMacroTarget(
              cycleDay: CarbCycleDay.low,
              calorieTarget: 1800,
              proteinTarget: 180,
              carbTarget: 100,
              fatTarget: 70,
            ),
            'saturday': DayMacroTarget(
              cycleDay: CarbCycleDay.high,
              calorieTarget: 2400,
              proteinTarget: 180,
              carbTarget: 300,
              fatTarget: 50,
            ),
            'sunday': DayMacroTarget(
              cycleDay: CarbCycleDay.high,
              calorieTarget: 2400,
              proteinTarget: 180,
              carbTarget: 300,
              fatTarget: 50,
            ),
          },
          weekDuration: 1,
          isPublic: true,
        ),

        // Training-Based Cycle
        MacroCycleTemplate(
          id: 'training_based',
          name: 'Training-Based Cycle',
          description: 'High carbs on training days, low on rest days',
          cycleType: CycleType.carbCycling,
          dayTargets: {
            'monday': DayMacroTarget(
              cycleDay: CarbCycleDay.high,
              calorieTarget: 2200,
              proteinTarget: 180,
              carbTarget: 250,
              fatTarget: 55,
              expectedIntensity: TrainingIntensity.high,
            ),
            'tuesday': DayMacroTarget(
              cycleDay: CarbCycleDay.medium,
              calorieTarget: 2000,
              proteinTarget: 180,
              carbTarget: 175,
              fatTarget: 65,
              expectedIntensity: TrainingIntensity.moderate,
            ),
            'wednesday': DayMacroTarget(
              cycleDay: CarbCycleDay.high,
              calorieTarget: 2200,
              proteinTarget: 180,
              carbTarget: 250,
              fatTarget: 55,
              expectedIntensity: TrainingIntensity.high,
            ),
            'thursday': DayMacroTarget(
              cycleDay: CarbCycleDay.low,
              calorieTarget: 1800,
              proteinTarget: 180,
              carbTarget: 100,
              fatTarget: 70,
              expectedIntensity: TrainingIntensity.rest,
            ),
            'friday': DayMacroTarget(
              cycleDay: CarbCycleDay.high,
              calorieTarget: 2200,
              proteinTarget: 180,
              carbTarget: 250,
              fatTarget: 55,
              expectedIntensity: TrainingIntensity.high,
            ),
            'saturday': DayMacroTarget(
              cycleDay: CarbCycleDay.medium,
              calorieTarget: 2000,
              proteinTarget: 180,
              carbTarget: 175,
              fatTarget: 65,
              expectedIntensity: TrainingIntensity.moderate,
            ),
            'sunday': DayMacroTarget(
              cycleDay: CarbCycleDay.low,
              calorieTarget: 1800,
              proteinTarget: 180,
              carbTarget: 100,
              fatTarget: 70,
              expectedIntensity: TrainingIntensity.rest,
            ),
          },
          weekDuration: 1,
          isPublic: true,
        ),

        // Zig-Zag Calorie Wave
        MacroCycleTemplate(
          id: 'zigzag_wave',
          name: 'Zig-Zag Calorie Wave',
          description: 'Alternating high/low calories to boost metabolism',
          cycleType: CycleType.calorieWave,
          dayTargets: {
            'monday': DayMacroTarget(
              cycleDay: CarbCycleDay.medium,
              calorieTarget: 2000,
              proteinTarget: 180,
              carbTarget: 200,
              fatTarget: 60,
            ),
            'tuesday': DayMacroTarget(
              cycleDay: CarbCycleDay.low,
              calorieTarget: 1600,
              proteinTarget: 180,
              carbTarget: 120,
              fatTarget: 55,
            ),
            'wednesday': DayMacroTarget(
              cycleDay: CarbCycleDay.high,
              calorieTarget: 2400,
              proteinTarget: 180,
              carbTarget: 280,
              fatTarget: 65,
            ),
            'thursday': DayMacroTarget(
              cycleDay: CarbCycleDay.low,
              calorieTarget: 1600,
              proteinTarget: 180,
              carbTarget: 120,
              fatTarget: 55,
            ),
            'friday': DayMacroTarget(
              cycleDay: CarbCycleDay.medium,
              calorieTarget: 2000,
              proteinTarget: 180,
              carbTarget: 200,
              fatTarget: 60,
            ),
            'saturday': DayMacroTarget(
              cycleDay: CarbCycleDay.high,
              calorieTarget: 2400,
              proteinTarget: 180,
              carbTarget: 280,
              fatTarget: 65,
            ),
            'sunday': DayMacroTarget(
              cycleDay: CarbCycleDay.low,
              calorieTarget: 1600,
              proteinTarget: 180,
              carbTarget: 120,
              fatTarget: 55,
            ),
          },
          weekDuration: 1,
          isPublic: true,
        ),
      ];

  // =====================================================
  // CYCLE MANAGEMENT
  // =====================================================

  /// Start a macro cycle
  Future<ActiveMacroCycle?> startMacroCycle({
    required String userId,
    required String templateId,
    required String templateName,
    required Map<String, DayMacroTarget> dayTargets,
    DateTime? startDate,
    int? durationWeeks,
  }) async {
    try {
      final start = startDate ?? DateTime.now();
      final end = durationWeeks != null
          ? start.add(Duration(days: durationWeeks * 7))
          : null;

      final dayTargetsJson = <String, dynamic>{};
      dayTargets.forEach((key, value) {
        dayTargetsJson[key] = value.toJson();
      });

      final cycleData = {
        'user_id': userId,
        'template_id': templateId,
        'template_name': templateName,
        'start_date': start.toIso8601String(),
        'end_date': end?.toIso8601String(),
        'current_week': 1,
        'is_active': true,
        'day_targets': dayTargetsJson,
      };

      final response = await _supabase
          .from('active_macro_cycles')
          .insert(cycleData)
          .select()
          .single();

      notifyListeners();
      return ActiveMacroCycle.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error starting macro cycle: $e');
      return null;
    }
  }

  /// Get active cycle for user
  Future<ActiveMacroCycle?> getActiveCycle(String userId) async {
    try {
      final response = await _supabase
          .from('active_macro_cycles')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      return ActiveMacroCycle.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching active cycle: $e');
      return null;
    }
  }

  /// Get macro target for specific date
  Future<DayMacroTarget?> getTargetForDate(String userId, DateTime date) async {
    final cycle = await getActiveCycle(userId);
    if (cycle == null) return null;

    return cycle.getTargetForDate(date);
  }

  // =====================================================
  // DIET PHASES
  // =====================================================

  /// Create phased diet program
  Future<DietPhaseProgram?> createPhaseProgram({
    required String userId,
    required String name,
    required List<PhaseBlock> phases,
    DateTime? startDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now();

      final programData = {
        'user_id': userId,
        'name': name,
        'phases': phases.map((p) => p.toJson()).toList(),
        'start_date': start.toIso8601String(),
        'current_phase_index': 0,
        'is_active': true,
      };

      final response = await _supabase
          .from('diet_phase_programs')
          .insert(programData)
          .select()
          .single();

      notifyListeners();
      return DietPhaseProgram.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error creating phase program: $e');
      return null;
    }
  }

  /// Get active phase program
  Future<DietPhaseProgram?> getActivePhaseProgram(String userId) async {
    try {
      final response = await _supabase
          .from('diet_phase_programs')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      return DietPhaseProgram.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching phase program: $e');
      return null;
    }
  }

  /// Advance to next phase
  Future<bool> advanceToNextPhase(String programId, int currentIndex) async {
    try {
      await _supabase
          .from('diet_phase_programs')
          .update({'current_phase_index': currentIndex + 1})
          .eq('id', programId);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error advancing phase: $e');
      return false;
    }
  }

  // =====================================================
  // REFEED SCHEDULING
  // =====================================================

  /// Setup refeed schedule
  Future<RefeedSchedule?> setupRefeedSchedule({
    required String userId,
    required RefeedType type,
    required int frequencyDays,
    double calorieMultiplier = 1.2,
    int durationHours = 24,
  }) async {
    try {
      final nextDate = DateTime.now().add(Duration(days: frequencyDays));

      final scheduleData = {
        'user_id': userId,
        'type': type.name,
        'frequency_days': frequencyDays,
        'calorie_multiplier': calorieMultiplier,
        'duration_hours': durationHours,
        'next_scheduled_date': nextDate.toIso8601String(),
        'is_active': true,
      };

      final response = await _supabase
          .from('refeed_schedules')
          .insert(scheduleData)
          .select()
          .single();

      notifyListeners();
      return RefeedSchedule.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error setting up refeed: $e');
      return null;
    }
  }

  /// Get active refeed schedule
  Future<RefeedSchedule?> getActiveRefeedSchedule(String userId) async {
    try {
      final response = await _supabase
          .from('refeed_schedules')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      return RefeedSchedule.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching refeed schedule: $e');
      return null;
    }
  }

  /// Check if today is a refeed day
  Future<bool> isRefeedDay(String userId) async {
    final schedule = await getActiveRefeedSchedule(userId);
    if (schedule == null || schedule.nextScheduledDate == null) return false;

    final today = DateTime.now();
    final scheduledDate = schedule.nextScheduledDate!;

    return today.year == scheduledDate.year &&
        today.month == scheduledDate.month &&
        today.day == scheduledDate.day;
  }

  // =====================================================
  // UTILITY
  // =====================================================

  /// Calculate weekly average macros from cycle
  Map<String, double> calculateWeeklyAverages(ActiveMacroCycle cycle) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    cycle.dayTargets.values.forEach((target) {
      totalCalories += target.calorieTarget;
      totalProtein += target.proteinTarget;
      totalCarbs += target.carbTarget;
      totalFat += target.fatTarget;
    });

    final days = cycle.dayTargets.length;

    return {
      'calories': totalCalories / days,
      'protein': totalProtein / days,
      'carbs': totalCarbs / days,
      'fat': totalFat / days,
    };
  }
}