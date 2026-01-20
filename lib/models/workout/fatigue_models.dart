import 'package:flutter/foundation.dart';

enum TransformationMode {
  strength,
  hypertrophy,
  endurance,
  deload,
  power,
  defaultMode;

  static TransformationMode fromDb(String? v) {
    switch ((v ?? 'default').toLowerCase()) {
      case 'strength':
        return TransformationMode.strength;
      case 'hypertrophy':
        return TransformationMode.hypertrophy;
      case 'endurance':
        return TransformationMode.endurance;
      case 'deload':
        return TransformationMode.deload;
      case 'power':
        return TransformationMode.power;
      default:
        return TransformationMode.defaultMode;
    }
  }

  String toDb() {
    switch (this) {
      case TransformationMode.defaultMode:
        return 'default';
      default:
        return name;
    }
  }

  String label() {
    switch (this) {
      case TransformationMode.defaultMode:
        return 'Default';
      case TransformationMode.strength:
        return 'Strength';
      case TransformationMode.hypertrophy:
        return 'Hypertrophy';
      case TransformationMode.endurance:
        return 'Endurance';
      case TransformationMode.deload:
        return 'Deload';
      case TransformationMode.power:
        return 'Power';
    }
  }
}

@immutable
class FatigueLog {
  final String id;
  final String userId;
  final String? workoutSessionId;

  final int? fatigueScore;
  final int? recoveryScore;
  final int? readinessScore;
  final int? sleepQuality;
  final int? stressLevel;
  final int? energyLevel;

  final String? notes;
  final DateTime loggedAt;
  final DateTime createdAt;

  const FatigueLog({
    required this.id,
    required this.userId,
    this.workoutSessionId,
    this.fatigueScore,
    this.recoveryScore,
    this.readinessScore,
    this.sleepQuality,
    this.stressLevel,
    this.energyLevel,
    this.notes,
    required this.loggedAt,
    required this.createdAt,
  });

  factory FatigueLog.fromJson(Map<String, dynamic> json) {
    return FatigueLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workoutSessionId: json['workout_session_id'] as String?,
      fatigueScore: json['fatigue_score'] as int?,
      recoveryScore: json['recovery_score'] as int?,
      readinessScore: json['readiness_score'] as int?,
      sleepQuality: json['sleep_quality'] as int?,
      stressLevel: json['stress_level'] as int?,
      energyLevel: json['energy_level'] as int?,
      notes: json['notes'] as String?,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'workout_session_id': workoutSessionId,
      'fatigue_score': fatigueScore,
      'recovery_score': recoveryScore,
      'readiness_score': readinessScore,
      'sleep_quality': sleepQuality,
      'stress_level': stressLevel,
      'energy_level': energyLevel,
      'notes': notes,
      'logged_at': loggedAt.toUtc().toIso8601String(),
    };
  }
}

@immutable
class RecoveryScore {
  final String id;
  final String userId;
  final DateTime date; // midnight local
  final double? overallRecovery; // 0..10
  final bool calculatedFromFatigueLogs;
  final String? recommendation;
  final DateTime createdAt;

  const RecoveryScore({
    required this.id,
    required this.userId,
    required this.date,
    required this.overallRecovery,
    required this.calculatedFromFatigueLogs,
    required this.recommendation,
    required this.createdAt,
  });

  factory RecoveryScore.fromJson(Map<String, dynamic> json) {
    return RecoveryScore(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse((json['date'] as String)).toLocal(),
      overallRecovery: (json['overall_recovery'] as num?)?.toDouble(),
      calculatedFromFatigueLogs: (json['calculated_from_fatigue_logs'] as bool?) ?? false,
      recommendation: json['recommendation'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

@immutable
class ReadinessIndicator {
  final double score; // 0..10
  final String label;
  final String hint;

  const ReadinessIndicator({
    required this.score,
    required this.label,
    required this.hint,
  });

  static ReadinessIndicator fromScore(double v) {
    if (v >= 8.0) {
      return ReadinessIndicator(score: v, label: 'Green', hint: 'Push performance.');
    } else if (v >= 6.0) {
      return ReadinessIndicator(score: v, label: 'Yellow', hint: 'Train hard but manage volume.');
    } else if (v >= 4.0) {
      return ReadinessIndicator(score: v, label: 'Orange', hint: 'Reduce intensity or volume.');
    }
    return ReadinessIndicator(score: v, label: 'Red', hint: 'Deload / active recovery.');
  }
}
