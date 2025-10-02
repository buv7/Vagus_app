/// Workout notification types and models
///
/// Defines notification types, payloads, and preferences
/// for workout-related push notifications
library;

/// Workout notification types
enum WorkoutNotificationType {
  planAssigned('plan_assigned'),
  workoutReminder('workout_reminder'),
  restDayReminder('rest_day_reminder'),
  deloadWeekAlert('deload_week_alert'),
  prCelebration('pr_celebration'),
  coachFeedback('coach_feedback'),
  missedWorkout('missed_workout'),
  weeklySummary('weekly_summary'),
  workoutStarted('workout_started'),
  workoutCompleted('workout_completed'),
  progressMilestone('progress_milestone');

  final String value;
  const WorkoutNotificationType(this.value);

  static WorkoutNotificationType fromString(String value) {
    return WorkoutNotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => WorkoutNotificationType.workoutReminder,
    );
  }
}

/// Base notification payload
class WorkoutNotificationPayload {
  final WorkoutNotificationType type;
  final String userId;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  WorkoutNotificationPayload({
    required this.type,
    required this.userId,
    required this.data,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type.value,
        'user_id': userId,
        'created_at': createdAt.toIso8601String(),
        'data': data,
      };

  factory WorkoutNotificationPayload.fromJson(Map<String, dynamic> json) {
    return WorkoutNotificationPayload(
      type: WorkoutNotificationType.fromString(json['type']),
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      data: json['data'] ?? {},
    );
  }
}

/// Plan assigned notification
class PlanAssignedNotification {
  final String planId;
  final String planName;
  final String coachId;
  final String coachName;
  final int totalWeeks;
  final DateTime startDate;

  PlanAssignedNotification({
    required this.planId,
    required this.planName,
    required this.coachId,
    required this.coachName,
    required this.totalWeeks,
    required this.startDate,
  });

  Map<String, dynamic> toJson() => {
        'plan_id': planId,
        'plan_name': planName,
        'coach_id': coachId,
        'coach_name': coachName,
        'total_weeks': totalWeeks,
        'start_date': startDate.toIso8601String(),
      };

  factory PlanAssignedNotification.fromJson(Map<String, dynamic> json) {
    return PlanAssignedNotification(
      planId: json['plan_id'],
      planName: json['plan_name'],
      coachId: json['coach_id'],
      coachName: json['coach_name'],
      totalWeeks: json['total_weeks'],
      startDate: DateTime.parse(json['start_date']),
    );
  }

  String get title => 'New Workout Plan Assigned';
  String get body => '$coachName assigned you "$planName" ($totalWeeks weeks)';
}

/// Workout reminder notification
class WorkoutReminderNotification {
  final String dayId;
  final String dayLabel;
  final DateTime scheduledTime;
  final int exerciseCount;
  final int estimatedDuration;
  final List<String> muscleGroups;

  WorkoutReminderNotification({
    required this.dayId,
    required this.dayLabel,
    required this.scheduledTime,
    required this.exerciseCount,
    required this.estimatedDuration,
    required this.muscleGroups,
  });

  Map<String, dynamic> toJson() => {
        'day_id': dayId,
        'day_label': dayLabel,
        'scheduled_time': scheduledTime.toIso8601String(),
        'exercise_count': exerciseCount,
        'estimated_duration': estimatedDuration,
        'muscle_groups': muscleGroups,
      };

  factory WorkoutReminderNotification.fromJson(Map<String, dynamic> json) {
    return WorkoutReminderNotification(
      dayId: json['day_id'],
      dayLabel: json['day_label'],
      scheduledTime: DateTime.parse(json['scheduled_time']),
      exerciseCount: json['exercise_count'],
      estimatedDuration: json['estimated_duration'],
      muscleGroups: List<String>.from(json['muscle_groups'] ?? []),
    );
  }

  String get title => 'Time for $dayLabel';
  String get body =>
      '$exerciseCount exercises • ${muscleGroups.join(', ')} • ~$estimatedDuration min';
}

/// Rest day notification
class RestDayNotification {
  final DateTime date;
  final String motivationalMessage;
  final bool isActiveRecovery;
  final List<String>? recoveryActivities;

  RestDayNotification({
    required this.date,
    required this.motivationalMessage,
    this.isActiveRecovery = false,
    this.recoveryActivities,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'motivational_message': motivationalMessage,
        'is_active_recovery': isActiveRecovery,
        'recovery_activities': recoveryActivities,
      };

  factory RestDayNotification.fromJson(Map<String, dynamic> json) {
    return RestDayNotification(
      date: DateTime.parse(json['date']),
      motivationalMessage: json['motivational_message'],
      isActiveRecovery: json['is_active_recovery'] ?? false,
      recoveryActivities: json['recovery_activities'] != null
          ? List<String>.from(json['recovery_activities'])
          : null,
    );
  }

  String get title => 'Rest Day 💤';
  String get body => motivationalMessage;
}

/// Deload week alert
class DeloadWeekNotification {
  final int weekNumber;
  final String reason;
  final double intensityReduction;
  final List<String> recommendations;

  DeloadWeekNotification({
    required this.weekNumber,
    required this.reason,
    required this.intensityReduction,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
        'week_number': weekNumber,
        'reason': reason,
        'intensity_reduction': intensityReduction,
        'recommendations': recommendations,
      };

  factory DeloadWeekNotification.fromJson(Map<String, dynamic> json) {
    return DeloadWeekNotification(
      weekNumber: json['week_number'],
      reason: json['reason'],
      intensityReduction: json['intensity_reduction'],
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  String get title => 'Deload Week Ahead';
  String get body =>
      'Week $weekNumber is a recovery week (${(intensityReduction * 100).toInt()}% reduced intensity)';
}

/// PR celebration notification
class PRCelebrationNotification {
  final String exerciseName;
  final String prType; // 'weight', 'volume', 'reps', '1rm'
  final double previousValue;
  final double newValue;
  final double improvement;
  final DateTime achievedDate;

  PRCelebrationNotification({
    required this.exerciseName,
    required this.prType,
    required this.previousValue,
    required this.newValue,
    required this.improvement,
    required this.achievedDate,
  });

  Map<String, dynamic> toJson() => {
        'exercise_name': exerciseName,
        'pr_type': prType,
        'previous_value': previousValue,
        'new_value': newValue,
        'improvement': improvement,
        'achieved_date': achievedDate.toIso8601String(),
      };

  factory PRCelebrationNotification.fromJson(Map<String, dynamic> json) {
    return PRCelebrationNotification(
      exerciseName: json['exercise_name'],
      prType: json['pr_type'],
      previousValue: json['previous_value'],
      newValue: json['new_value'],
      improvement: json['improvement'],
      achievedDate: DateTime.parse(json['achieved_date']),
    );
  }

  String get title => '🎉 New Personal Record!';
  String get body {
    switch (prType) {
      case 'weight':
        return '$exerciseName: ${newValue.toStringAsFixed(1)}kg (+${improvement.toStringAsFixed(1)}%)';
      case 'volume':
        return '$exerciseName: ${newValue.toStringAsFixed(0)}kg total volume';
      case 'reps':
        return '$exerciseName: ${newValue.toInt()} reps';
      case '1rm':
        return '$exerciseName: ${newValue.toStringAsFixed(1)}kg (est. 1RM)';
      default:
        return '$exerciseName: New PR!';
    }
  }
}

/// Coach feedback notification
class CoachFeedbackNotification {
  final String coachId;
  final String coachName;
  final String exerciseId;
  final String exerciseName;
  final String comment;
  final String? videoUrl;
  final DateTime commentedAt;

  CoachFeedbackNotification({
    required this.coachId,
    required this.coachName,
    required this.exerciseId,
    required this.exerciseName,
    required this.comment,
    this.videoUrl,
    required this.commentedAt,
  });

  Map<String, dynamic> toJson() => {
        'coach_id': coachId,
        'coach_name': coachName,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'comment': comment,
        'video_url': videoUrl,
        'commented_at': commentedAt.toIso8601String(),
      };

  factory CoachFeedbackNotification.fromJson(Map<String, dynamic> json) {
    return CoachFeedbackNotification(
      coachId: json['coach_id'],
      coachName: json['coach_name'],
      exerciseId: json['exercise_id'],
      exerciseName: json['exercise_name'],
      comment: json['comment'],
      videoUrl: json['video_url'],
      commentedAt: DateTime.parse(json['commented_at']),
    );
  }

  String get title => '$coachName commented on $exerciseName';
  String get body => comment.length > 100 ? '${comment.substring(0, 97)}...' : comment;
}

/// Missed workout notification
class MissedWorkoutNotification {
  final String dayId;
  final String dayLabel;
  final DateTime missedDate;
  final int consecutiveMissed;
  final String motivationalMessage;

  MissedWorkoutNotification({
    required this.dayId,
    required this.dayLabel,
    required this.missedDate,
    required this.consecutiveMissed,
    required this.motivationalMessage,
  });

  Map<String, dynamic> toJson() => {
        'day_id': dayId,
        'day_label': dayLabel,
        'missed_date': missedDate.toIso8601String(),
        'consecutive_missed': consecutiveMissed,
        'motivational_message': motivationalMessage,
      };

  factory MissedWorkoutNotification.fromJson(Map<String, dynamic> json) {
    return MissedWorkoutNotification(
      dayId: json['day_id'],
      dayLabel: json['day_label'],
      missedDate: DateTime.parse(json['missed_date']),
      consecutiveMissed: json['consecutive_missed'],
      motivationalMessage: json['motivational_message'],
    );
  }

  String get title => 'Missed Workout: $dayLabel';
  String get body => motivationalMessage;
}

/// Weekly summary notification
class WeeklySummaryNotification {
  final int weekNumber;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int completedSessions;
  final int totalSessions;
  final double totalVolume;
  final int newPRs;
  final double consistencyScore;
  final String summaryText;

  WeeklySummaryNotification({
    required this.weekNumber,
    required this.weekStart,
    required this.weekEnd,
    required this.completedSessions,
    required this.totalSessions,
    required this.totalVolume,
    required this.newPRs,
    required this.consistencyScore,
    required this.summaryText,
  });

  Map<String, dynamic> toJson() => {
        'week_number': weekNumber,
        'week_start': weekStart.toIso8601String(),
        'week_end': weekEnd.toIso8601String(),
        'completed_sessions': completedSessions,
        'total_sessions': totalSessions,
        'total_volume': totalVolume,
        'new_prs': newPRs,
        'consistency_score': consistencyScore,
        'summary_text': summaryText,
      };

  factory WeeklySummaryNotification.fromJson(Map<String, dynamic> json) {
    return WeeklySummaryNotification(
      weekNumber: json['week_number'],
      weekStart: DateTime.parse(json['week_start']),
      weekEnd: DateTime.parse(json['week_end']),
      completedSessions: json['completed_sessions'],
      totalSessions: json['total_sessions'],
      totalVolume: json['total_volume'],
      newPRs: json['new_prs'],
      consistencyScore: json['consistency_score'],
      summaryText: json['summary_text'],
    );
  }

  String get title => 'Week $weekNumber Summary';
  String get body =>
      '$completedSessions/$totalSessions workouts • ${(totalVolume / 1000).toStringAsFixed(1)}k kg • $newPRs PRs';
}

/// Notification preferences
class WorkoutNotificationPreferences {
  final bool workoutRemindersEnabled;
  final String? workoutReminderTime; // e.g., "08:00"
  final int reminderMinutesBefore; // e.g., 30 for 30 min before
  final bool restDayRemindersEnabled;
  final bool prCelebrationEnabled;
  final bool coachFeedbackEnabled;
  final bool missedWorkoutEnabled;
  final bool weeklySummaryEnabled;
  final String? weeklySummaryDay; // e.g., "Sunday"
  final String? weeklySummaryTime; // e.g., "18:00"
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String timezone; // e.g., "America/New_York"

  WorkoutNotificationPreferences({
    this.workoutRemindersEnabled = true,
    this.workoutReminderTime,
    this.reminderMinutesBefore = 30,
    this.restDayRemindersEnabled = true,
    this.prCelebrationEnabled = true,
    this.coachFeedbackEnabled = true,
    this.missedWorkoutEnabled = true,
    this.weeklySummaryEnabled = true,
    this.weeklySummaryDay = 'Sunday',
    this.weeklySummaryTime = '18:00',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.timezone = 'UTC',
  });

  Map<String, dynamic> toJson() => {
        'workout_reminders_enabled': workoutRemindersEnabled,
        'workout_reminder_time': workoutReminderTime,
        'reminder_minutes_before': reminderMinutesBefore,
        'rest_day_reminders_enabled': restDayRemindersEnabled,
        'pr_celebration_enabled': prCelebrationEnabled,
        'coach_feedback_enabled': coachFeedbackEnabled,
        'missed_workout_enabled': missedWorkoutEnabled,
        'weekly_summary_enabled': weeklySummaryEnabled,
        'weekly_summary_day': weeklySummaryDay,
        'weekly_summary_time': weeklySummaryTime,
        'sound_enabled': soundEnabled,
        'vibration_enabled': vibrationEnabled,
        'timezone': timezone,
      };

  factory WorkoutNotificationPreferences.fromJson(Map<String, dynamic> json) {
    return WorkoutNotificationPreferences(
      workoutRemindersEnabled: json['workout_reminders_enabled'] ?? true,
      workoutReminderTime: json['workout_reminder_time'],
      reminderMinutesBefore: json['reminder_minutes_before'] ?? 30,
      restDayRemindersEnabled: json['rest_day_reminders_enabled'] ?? true,
      prCelebrationEnabled: json['pr_celebration_enabled'] ?? true,
      coachFeedbackEnabled: json['coach_feedback_enabled'] ?? true,
      missedWorkoutEnabled: json['missed_workout_enabled'] ?? true,
      weeklySummaryEnabled: json['weekly_summary_enabled'] ?? true,
      weeklySummaryDay: json['weekly_summary_day'] ?? 'Sunday',
      weeklySummaryTime: json['weekly_summary_time'] ?? '18:00',
      soundEnabled: json['sound_enabled'] ?? true,
      vibrationEnabled: json['vibration_enabled'] ?? true,
      timezone: json['timezone'] ?? 'UTC',
    );
  }

  WorkoutNotificationPreferences copyWith({
    bool? workoutRemindersEnabled,
    String? workoutReminderTime,
    int? reminderMinutesBefore,
    bool? restDayRemindersEnabled,
    bool? prCelebrationEnabled,
    bool? coachFeedbackEnabled,
    bool? missedWorkoutEnabled,
    bool? weeklySummaryEnabled,
    String? weeklySummaryDay,
    String? weeklySummaryTime,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? timezone,
  }) {
    return WorkoutNotificationPreferences(
      workoutRemindersEnabled: workoutRemindersEnabled ?? this.workoutRemindersEnabled,
      workoutReminderTime: workoutReminderTime ?? this.workoutReminderTime,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      restDayRemindersEnabled: restDayRemindersEnabled ?? this.restDayRemindersEnabled,
      prCelebrationEnabled: prCelebrationEnabled ?? this.prCelebrationEnabled,
      coachFeedbackEnabled: coachFeedbackEnabled ?? this.coachFeedbackEnabled,
      missedWorkoutEnabled: missedWorkoutEnabled ?? this.missedWorkoutEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      weeklySummaryDay: weeklySummaryDay ?? this.weeklySummaryDay,
      weeklySummaryTime: weeklySummaryTime ?? this.weeklySummaryTime,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      timezone: timezone ?? this.timezone,
    );
  }
}
