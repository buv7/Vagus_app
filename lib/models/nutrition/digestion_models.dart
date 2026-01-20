import 'package:flutter/foundation.dart';
import 'dart:convert';

enum BloatFactor {
  dairy,
  gluten,
  highFiber,
  processedFoods,
  alcohol,
  largeMeals,
  fastEating,
  stress,
  other;

  String get label {
    switch (this) {
      case BloatFactor.dairy:
        return 'Dairy';
      case BloatFactor.gluten:
        return 'Gluten';
      case BloatFactor.highFiber:
        return 'High Fiber';
      case BloatFactor.processedFoods:
        return 'Processed Foods';
      case BloatFactor.alcohol:
        return 'Alcohol';
      case BloatFactor.largeMeals:
        return 'Large Meals';
      case BloatFactor.fastEating:
        return 'Fast Eating';
      case BloatFactor.stress:
        return 'Stress';
      case BloatFactor.other:
        return 'Other';
    }
  }

  static BloatFactor? fromString(String value) {
    try {
      return BloatFactor.values.firstWhere(
        (e) => e.name == value || e.label.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

enum ChaosMode {
  travel,
  chaos,
  restDay,
  normal;

  String get label {
    switch (this) {
      case ChaosMode.travel:
        return 'Travel';
      case ChaosMode.chaos:
        return 'Chaos';
      case ChaosMode.restDay:
        return 'Rest Day';
      case ChaosMode.normal:
        return 'Normal';
    }
  }

  String toDb() => name;

  static ChaosMode fromDb(String value) {
    return ChaosMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChaosMode.normal,
    );
  }
}

@immutable
class DigestionLog {
  final String id;
  final String userId;
  final DateTime date;
  final int? digestionQuality; // 1-5
  final int? bloatLevel; // 0-10
  final List<BloatFactor> bloatingFactors;
  final int? complianceScore; // 0-100
  final String? notes;
  final DateTime createdAt;

  const DigestionLog({
    required this.id,
    required this.userId,
    required this.date,
    this.digestionQuality,
    this.bloatLevel,
    this.bloatingFactors = const [],
    this.complianceScore,
    this.notes,
    required this.createdAt,
  });

  factory DigestionLog.fromJson(Map<String, dynamic> json) {
    return DigestionLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String).toLocal(),
      digestionQuality: json['digestion_quality'] as int?,
      bloatLevel: json['bloat_level'] as int?,
      bloatingFactors: (json['bloating_factors'] as List<dynamic>?)
              ?.map((e) => BloatFactor.fromString(e as String))
              .whereType<BloatFactor>()
              .toList() ??
          [],
      complianceScore: json['compliance_score'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'date': date.toIso8601String().substring(0, 10),
      'digestion_quality': digestionQuality,
      'bloat_level': bloatLevel,
      'bloating_factors': bloatingFactors.map((e) => e.name).toList(),
      'compliance_score': complianceScore,
      'notes': notes,
    };
  }
}

@immutable
class TravelModeEntry {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final ChaosMode mode;
  final String? location;
  final String? nutritionPlanId;
  final Map<String, dynamic>? adaptedMacros;
  final String? notes;
  final DateTime createdAt;

  const TravelModeEntry({
    required this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
    required this.mode,
    this.location,
    this.nutritionPlanId,
    this.adaptedMacros,
    this.notes,
    required this.createdAt,
  });

  factory TravelModeEntry.fromJson(Map<String, dynamic> json) {
    return TravelModeEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String).toLocal(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String).toLocal()
          : null,
      mode: ChaosMode.fromDb(json['mode'] as String),
      location: json['location'] as String?,
      nutritionPlanId: json['nutrition_plan_id'] as String?,
      adaptedMacros: json['adapted_macros'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate?.toIso8601String().substring(0, 10),
      'mode': mode.toDb(),
      'location': location,
      'nutrition_plan_id': nutritionPlanId,
      'adapted_macros': adaptedMacros != null ? jsonEncode(adaptedMacros) : null,
      'notes': notes,
    };
  }

  bool get isActive {
    final now = DateTime.now();
    if (endDate != null && now.isAfter(endDate!)) return false;
    return now.isAfter(startDate) || now.isAtSameMomentAs(startDate);
  }
}

@immutable
class ChaosControlSettings {
  final String id;
  final String userId;
  final bool autoAdaptOnChaos;
  final bool chaosDetectionEnabled;
  final bool travelModeAutoEnable;
  final DateTime createdAt;

  const ChaosControlSettings({
    required this.id,
    required this.userId,
    required this.autoAdaptOnChaos,
    required this.chaosDetectionEnabled,
    required this.travelModeAutoEnable,
    required this.createdAt,
  });

  factory ChaosControlSettings.fromJson(Map<String, dynamic> json) {
    return ChaosControlSettings(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      autoAdaptOnChaos: (json['auto_adapt_on_chaos'] as bool?) ?? true,
      chaosDetectionEnabled: (json['chaos_detection_enabled'] as bool?) ?? true,
      travelModeAutoEnable: (json['travel_mode_auto_enable'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'auto_adapt_on_chaos': autoAdaptOnChaos,
      'chaos_detection_enabled': chaosDetectionEnabled,
      'travel_mode_auto_enable': travelModeAutoEnable,
    };
  }
}
