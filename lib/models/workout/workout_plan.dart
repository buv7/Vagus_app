import 'exercise.dart';
import 'cardio_session.dart';
import 'workout_summary.dart';

class WorkoutPlan {
  final String? id;
  final String coachId;
  final String clientId;
  final String name;
  final String? description;
  final int durationWeeks;
  final DateTime? startDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final bool isTemplate;
  final String? templateCategory;
  final bool aiGenerated;
  final bool unseenUpdate;
  final bool isArchived;
  final Map<String, dynamic> metadata;
  final int versionNumber;

  // Nested structure
  final List<WorkoutWeek> weeks;

  WorkoutPlan({
    this.id,
    required this.coachId,
    required this.clientId,
    required this.name,
    this.description,
    required this.durationWeeks,
    this.startDate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.isTemplate = false,
    this.templateCategory,
    this.aiGenerated = false,
    this.unseenUpdate = false,
    this.isArchived = false,
    Map<String, dynamic>? metadata,
    this.versionNumber = 1,
    required this.weeks,
  }) : metadata = metadata ?? {};

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    return WorkoutPlan(
      id: map['id']?.toString(),
      coachId: map['coach_id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      durationWeeks: (map['duration_weeks'] as num?)?.toInt() ?? 1,
      startDate: map['start_date'] != null
          ? DateTime.tryParse(map['start_date'].toString())
          : null,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      createdBy: map['created_by']?.toString() ?? '',
      isTemplate: map['is_template'] as bool? ?? false,
      templateCategory: map['template_category']?.toString(),
      aiGenerated: map['ai_generated'] as bool? ?? false,
      unseenUpdate: map['unseen_update'] as bool? ?? false,
      isArchived: map['is_archived'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
      versionNumber: (map['version_number'] as num?)?.toInt() ?? 1,
      weeks: (map['weeks'] as List<dynamic>?)
              ?.map((week) => WorkoutWeek.fromMap(week as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'coach_id': coachId,
      'client_id': clientId,
      'name': name,
      if (description != null) 'description': description,
      'duration_weeks': durationWeeks,
      if (startDate != null) 'start_date': startDate!.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'is_template': isTemplate,
      if (templateCategory != null) 'template_category': templateCategory,
      'ai_generated': aiGenerated,
      'unseen_update': unseenUpdate,
      'is_archived': isArchived,
      'metadata': metadata,
      'version_number': versionNumber,
      'weeks': weeks.map((week) => week.toMap()).toList(),
    };
  }

  WorkoutPlan copyWith({
    String? id,
    String? coachId,
    String? clientId,
    String? name,
    String? description,
    int? durationWeeks,
    DateTime? startDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isTemplate,
    String? templateCategory,
    bool? aiGenerated,
    bool? unseenUpdate,
    bool? isArchived,
    Map<String, dynamic>? metadata,
    int? versionNumber,
    List<WorkoutWeek>? weeks,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      description: description ?? this.description,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isTemplate: isTemplate ?? this.isTemplate,
      templateCategory: templateCategory ?? this.templateCategory,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      unseenUpdate: unseenUpdate ?? this.unseenUpdate,
      isArchived: isArchived ?? this.isArchived,
      metadata: metadata ?? this.metadata,
      versionNumber: versionNumber ?? this.versionNumber,
      weeks: weeks ?? this.weeks,
    );
  }

  // Validation
  String? validate() {
    if (name.trim().isEmpty) {
      return 'Plan name is required';
    }
    if (durationWeeks < 1) {
      return 'Duration must be at least 1 week';
    }
    if (weeks.length != durationWeeks) {
      return 'Number of weeks must match duration';
    }

    // Validate each week
    for (int i = 0; i < weeks.length; i++) {
      final weekError = weeks[i].validate();
      if (weekError != null) {
        return 'Week ${i + 1}: $weekError';
      }
    }

    return null;
  }

  // Helper methods

  /// Get summary for the entire plan
  WorkoutPlanSummary getPlanSummary() {
    final weeklySummaries = weeks.map((week) => week.getWeeklySummary()).toList();
    return WorkoutPlanSummary(
      planName: name,
      totalWeeks: durationWeeks,
      weeklySummaries: weeklySummaries,
    );
  }

  /// Get a specific week by number (1-indexed)
  WorkoutWeek? getWeek(int weekNumber) {
    if (weekNumber < 1 || weekNumber > weeks.length) return null;
    return weeks[weekNumber - 1];
  }

  /// Get all exercises across all weeks
  List<Exercise> getAllExercises() {
    final allExercises = <Exercise>[];
    for (final week in weeks) {
      for (final day in week.days) {
        allExercises.addAll(day.exercises);
      }
    }
    return allExercises;
  }

  /// Get unique exercise names across the plan
  Set<String> getUniqueExerciseNames() {
    return getAllExercises().map((e) => e.name).toSet();
  }

  /// Calculate total training days in the plan
  int getTotalTrainingDays() {
    int count = 0;
    for (final week in weeks) {
      for (final day in week.days) {
        if (day.exercises.isNotEmpty || day.cardioSessions.isNotEmpty) {
          count++;
        }
      }
    }
    return count;
  }

  /// Get the current week number based on start date
  int? getCurrentWeekNumber() {
    if (startDate == null) return null;

    final now = DateTime.now();
    final daysSinceStart = now.difference(startDate!).inDays;

    if (daysSinceStart < 0) return null; // Plan hasn't started yet

    final weekNumber = (daysSinceStart / 7).floor() + 1;
    return weekNumber <= durationWeeks ? weekNumber : durationWeeks;
  }

  /// Check if the plan is currently active
  bool get isActive {
    if (startDate == null || isArchived) return false;

    final now = DateTime.now();
    final endDate = startDate!.add(Duration(days: durationWeeks * 7));

    return now.isAfter(startDate!) && now.isBefore(endDate);
  }

  /// Get progress percentage (0-100)
  double? getProgressPercentage() {
    if (startDate == null) return null;

    final now = DateTime.now();
    final totalDays = durationWeeks * 7;
    final daysPassed = now.difference(startDate!).inDays;

    if (daysPassed < 0) return 0.0;
    if (daysPassed >= totalDays) return 100.0;

    return (daysPassed / totalDays * 100);
  }
}

class WorkoutWeek {
  final String? id;
  final String planId;
  final int weekNumber;
  final String? notes;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested days
  final List<WorkoutDay> days;

  WorkoutWeek({
    this.id,
    required this.planId,
    required this.weekNumber,
    this.notes,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.days,
  })  : attachments = attachments ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory WorkoutWeek.fromMap(Map<String, dynamic> map) {
    return WorkoutWeek(
      id: map['id']?.toString(),
      planId: map['plan_id']?.toString() ?? '',
      weekNumber: (map['week_number'] as num?)?.toInt() ?? 1,
      notes: map['notes']?.toString(),
      attachments: (map['attachments'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
          [],
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      days: (map['days'] as List<dynamic>?)
              ?.map((day) => WorkoutDay.fromMap(day as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plan_id': planId,
      'week_number': weekNumber,
      if (notes != null) 'notes': notes,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'days': days.map((day) => day.toMap()).toList(),
    };
  }

  WorkoutWeek copyWith({
    String? id,
    String? planId,
    int? weekNumber,
    String? notes,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<WorkoutDay>? days,
  }) {
    return WorkoutWeek(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      weekNumber: weekNumber ?? this.weekNumber,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      days: days ?? this.days,
    );
  }

  String? validate() {
    if (weekNumber < 1) {
      return 'Week number must be positive';
    }

    for (int i = 0; i < days.length; i++) {
      final dayError = days[i].validate();
      if (dayError != null) {
        return 'Day ${i + 1}: $dayError';
      }
    }

    return null;
  }

  /// Get summary for this week
  WeeklySummary getWeeklySummary() {
    final dailySummaries = days.map((day) => day.getDaySummary()).toList();
    return WeeklySummary(
      dailySummaries: dailySummaries,
      weekNumber: weekNumber,
    );
  }
}

class WorkoutDay {
  final String? id;
  final String weekId;
  final int dayNumber;
  final String label;
  final String? clientComment;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested exercises and cardio
  final List<Exercise> exercises;
  final List<CardioSession> cardioSessions;

  WorkoutDay({
    this.id,
    required this.weekId,
    required this.dayNumber,
    required this.label,
    this.clientComment,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Exercise>? exercises,
    List<CardioSession>? cardioSessions,
  })  : attachments = attachments ?? [],
        exercises = exercises ?? [],
        cardioSessions = cardioSessions ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory WorkoutDay.fromMap(Map<String, dynamic> map) {
    return WorkoutDay(
      id: map['id']?.toString(),
      weekId: map['week_id']?.toString() ?? '',
      dayNumber: (map['day_number'] as num?)?.toInt() ?? 1,
      label: map['label']?.toString() ?? '',
      clientComment: map['client_comment']?.toString(),
      attachments: (map['attachments'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
          [],
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((ex) => Exercise.fromMap(ex as Map<String, dynamic>))
              .toList() ??
          [],
      cardioSessions: (map['cardio'] as List<dynamic>?)
              ?.map((cardio) => CardioSession.fromMap(cardio as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'week_id': weekId,
      'day_number': dayNumber,
      'label': label,
      if (clientComment != null) 'client_comment': clientComment,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'exercises': exercises.map((ex) => ex.toMap()).toList(),
      'cardio': cardioSessions.map((cardio) => cardio.toMap()).toList(),
    };
  }

  WorkoutDay copyWith({
    String? id,
    String? weekId,
    int? dayNumber,
    String? label,
    String? clientComment,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Exercise>? exercises,
    List<CardioSession>? cardioSessions,
  }) {
    return WorkoutDay(
      id: id ?? this.id,
      weekId: weekId ?? this.weekId,
      dayNumber: dayNumber ?? this.dayNumber,
      label: label ?? this.label,
      clientComment: clientComment ?? this.clientComment,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      exercises: exercises ?? this.exercises,
      cardioSessions: cardioSessions ?? this.cardioSessions,
    );
  }

  String? validate() {
    if (dayNumber < 1) {
      return 'Day number must be positive';
    }
    if (label.trim().isEmpty) {
      return 'Day label is required';
    }

    for (int i = 0; i < exercises.length; i++) {
      final exerciseError = exercises[i].validate();
      if (exerciseError != null) {
        return 'Exercise ${i + 1}: $exerciseError';
      }
    }

    for (int i = 0; i < cardioSessions.length; i++) {
      final cardioError = cardioSessions[i].validate();
      if (cardioError != null) {
        return 'Cardio ${i + 1}: $cardioError';
      }
    }

    return null;
  }

  /// Get summary for this day
  WorkoutSummary getDaySummary() {
    return WorkoutSummary.calculate(
      exercises: exercises,
      cardioSessions: cardioSessions,
    );
  }

  /// Check if this is a rest day
  bool get isRestDay => exercises.isEmpty && cardioSessions.isEmpty;
}

class WorkoutPlanSummary {
  final String planName;
  final int totalWeeks;
  final List<WeeklySummary> weeklySummaries;

  WorkoutPlanSummary({
    required this.planName,
    required this.totalWeeks,
    required this.weeklySummaries,
  });

  /// Get total volume across all weeks
  double get totalVolume {
    return weeklySummaries.fold(
      0.0,
      (sum, week) => sum + week.totalWeeklyVolume,
    );
  }

  /// Get average weekly volume
  double get averageWeeklyVolume {
    if (weeklySummaries.isEmpty) return 0.0;
    return totalVolume / weeklySummaries.length;
  }

  /// Get total training days across all weeks
  int get totalTrainingDays {
    return weeklySummaries.fold(
      0,
      (sum, week) => sum + week.trainingDays,
    );
  }

  /// Get average training days per week
  double get averageTrainingDaysPerWeek {
    if (weeklySummaries.isEmpty) return 0.0;
    return totalTrainingDays / weeklySummaries.length;
  }

  /// Get brief plan summary
  String getBriefSummary({String unit = 'kg'}) {
    return '$totalWeeks weeks • $totalTrainingDays training days • ${(totalVolume / 1000).toStringAsFixed(1)}k $unit total';
  }

  /// Get detailed plan summary
  String getDetailedSummary({String unit = 'kg'}) {
    final lines = <String>[];

    lines.add('$planName - Summary:');
    lines.add('Duration: $totalWeeks weeks');
    lines.add('Total Training Days: $totalTrainingDays (${averageTrainingDaysPerWeek.toStringAsFixed(1)}/week avg)');
    lines.add('Total Volume: ${(totalVolume / 1000).toStringAsFixed(1)}k $unit');
    lines.add('Average Weekly Volume: ${(averageWeeklyVolume / 1000).toStringAsFixed(1)}k $unit');

    return lines.join('\n');
  }
}