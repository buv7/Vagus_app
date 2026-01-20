import 'package:flutter/foundation.dart';

enum MissionType {
  workout,
  nutrition,
  checkin,
  message,
  custom;

  String get label {
    switch (this) {
      case MissionType.workout:
        return 'Workout';
      case MissionType.nutrition:
        return 'Nutrition';
      case MissionType.checkin:
        return 'Check-in';
      case MissionType.message:
        return 'Message';
      case MissionType.custom:
        return 'Custom';
    }
  }

  String toDb() => name;

  static MissionType fromDb(String value) {
    return MissionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MissionType.custom,
    );
  }
}

enum PreventionAction {
  reminder,
  encouragement,
  streakProtection,
  missionAdjustment;

  String get label {
    switch (this) {
      case PreventionAction.reminder:
        return 'Reminder';
      case PreventionAction.encouragement:
        return 'Encouragement';
      case PreventionAction.streakProtection:
        return 'Streak Protection';
      case PreventionAction.missionAdjustment:
        return 'Mission Adjustment';
    }
  }

  String toDb() => name;

  static PreventionAction fromDb(String value) {
    return PreventionAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PreventionAction.reminder,
    );
  }
}

@immutable
class DailyMission {
  final String id;
  final String userId;
  final DateTime date;
  final MissionType missionType;
  final String missionTitle;
  final String? missionDescription;
  final Map<String, dynamic>? missionData;
  final bool completed;
  final DateTime? completedAt;
  final int xpReward;
  final DateTime createdAt;

  const DailyMission({
    required this.id,
    required this.userId,
    required this.date,
    required this.missionType,
    required this.missionTitle,
    this.missionDescription,
    this.missionData,
    required this.completed,
    this.completedAt,
    required this.xpReward,
    required this.createdAt,
  });

  factory DailyMission.fromJson(Map<String, dynamic> json) {
    return DailyMission(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String).toLocal(),
      missionType: MissionType.fromDb(json['mission_type'] as String),
      missionTitle: json['mission_title'] as String,
      missionDescription: json['mission_description'] as String?,
      missionData: json['mission_data'] as Map<String, dynamic>?,
      completed: (json['completed'] as bool?) ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      xpReward: (json['xp_reward'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'date': date.toIso8601String().substring(0, 10),
      'mission_type': missionType.toDb(),
      'mission_title': missionTitle,
      'mission_description': missionDescription,
      'mission_data': missionData,
      'completed': completed,
      'completed_at': completedAt?.toUtc().toIso8601String(),
      'xp_reward': xpReward,
    };
  }
}

@immutable
class DeathSpiralPreventionLog {
  final String id;
  final String userId;
  final DateTime missedDate;
  final PreventionAction preventionAction;
  final Map<String, dynamic>? actionData;
  final DateTime actionTakenAt;
  final bool? success;
  final DateTime createdAt;

  const DeathSpiralPreventionLog({
    required this.id,
    required this.userId,
    required this.missedDate,
    required this.preventionAction,
    this.actionData,
    required this.actionTakenAt,
    this.success,
    required this.createdAt,
  });

  factory DeathSpiralPreventionLog.fromJson(Map<String, dynamic> json) {
    return DeathSpiralPreventionLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      missedDate: DateTime.parse(json['missed_date'] as String).toLocal(),
      preventionAction: PreventionAction.fromDb(json['prevention_action'] as String),
      actionData: json['action_data'] as Map<String, dynamic>?,
      actionTakenAt: DateTime.parse(json['action_taken_at'] as String),
      success: json['success'] as bool?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'missed_date': missedDate.toIso8601String().substring(0, 10),
      'prevention_action': preventionAction.toDb(),
      'action_data': actionData,
      'action_taken_at': actionTakenAt.toUtc().toIso8601String(),
      'success': success,
    };
  }
}

@immutable
class DopamineOpenEvent {
  final String id;
  final String userId;
  final DateTime openedAt;
  final String? dopamineTrigger;
  final Map<String, dynamic>? triggerData;
  final int? engagementDurationSeconds;

  const DopamineOpenEvent({
    required this.id,
    required this.userId,
    required this.openedAt,
    this.dopamineTrigger,
    this.triggerData,
    this.engagementDurationSeconds,
  });

  factory DopamineOpenEvent.fromJson(Map<String, dynamic> json) {
    return DopamineOpenEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      openedAt: DateTime.parse(json['opened_at'] as String),
      dopamineTrigger: json['dopamine_trigger'] as String?,
      triggerData: json['trigger_data'] as Map<String, dynamic>?,
      engagementDurationSeconds: json['engagement_duration_seconds'] as int?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'opened_at': openedAt.toUtc().toIso8601String(),
      'dopamine_trigger': dopamineTrigger,
      'trigger_data': triggerData,
      'engagement_duration_seconds': engagementDurationSeconds,
    };
  }
}
