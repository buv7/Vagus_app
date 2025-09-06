import 'package:equatable/equatable.dart';

/// Model for tracking supplements in nutrition plans
class Supplement extends Equatable {
  final String? id;
  final String planId;
  final int dayIndex;
  final String name;
  final String? dosage;
  final String? timing;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Supplement({
    this.id,
    required this.planId,
    required this.dayIndex,
    required this.name,
    this.dosage,
    this.timing,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from database map
  factory Supplement.fromMap(Map<String, dynamic> map) {
    return Supplement(
      id: map['id']?.toString(),
      planId: map['plan_id']?.toString() ?? '',
      dayIndex: map['day_index'] as int? ?? 0,
      name: map['name']?.toString() ?? '',
      dosage: map['dosage']?.toString(),
      timing: map['timing']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plan_id': planId,
      'day_index': dayIndex,
      'name': name,
      if (dosage != null) 'dosage': dosage,
      if (timing != null) 'timing': timing,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with new values
  Supplement copyWith({
    String? id,
    String? planId,
    int? dayIndex,
    String? name,
    String? dosage,
    String? timing,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplement(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      dayIndex: dayIndex ?? this.dayIndex,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      timing: timing ?? this.timing,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name with timing
  String get displayName {
    if (timing != null && timing!.isNotEmpty) {
      return '$name • $timing';
    }
    return name;
  }

  /// Get short display name (just name)
  String get shortName => name;

  /// Get timing display name
  String get timingDisplayName {
    switch (timing?.toLowerCase()) {
      case 'morning':
        return 'Morning';
      case 'preworkout':
        return 'Pre-workout';
      case 'postworkout':
        return 'Post-workout';
      case 'bedtime':
        return 'Bedtime';
      case 'with_meal':
        return 'With meal';
      case 'other':
        return 'Other';
      default:
        return timing ?? 'Not specified';
    }
  }

  /// Get timing emoji
  String get timingEmoji {
    switch (timing?.toLowerCase()) {
      case 'morning':
        return '🌅';
      case 'preworkout':
        return '💪';
      case 'postworkout':
        return '🏃';
      case 'bedtime':
        return '🌙';
      case 'with_meal':
        return '🍽️';
      case 'other':
        return '💊';
      default:
        return '💊';
    }
  }

  /// Check if supplement has timing
  bool get hasTiming => timing != null && timing!.isNotEmpty;

  /// Check if supplement has dosage
  bool get hasDosage => dosage != null && dosage!.isNotEmpty;

  /// Check if supplement has notes
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  /// Get formatted dosage
  String get formattedDosage => dosage ?? 'No dosage specified';

  /// Get formatted notes
  String get formattedNotes => notes ?? 'No notes';

  @override
  List<Object?> get props => [
        id,
        planId,
        dayIndex,
        name,
        dosage,
        timing,
        notes,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'Supplement(id: $id, name: $name, timing: $timing, dayIndex: $dayIndex)';
}

/// Supplement timing enum
enum SupplementTiming {
  morning,
  preworkout,
  postworkout,
  bedtime,
  withMeal,
  other;

  /// Get display name
  String get displayName {
    switch (this) {
      case SupplementTiming.morning:
        return 'Morning';
      case SupplementTiming.preworkout:
        return 'Pre-workout';
      case SupplementTiming.postworkout:
        return 'Post-workout';
      case SupplementTiming.bedtime:
        return 'Bedtime';
      case SupplementTiming.withMeal:
        return 'With meal';
      case SupplementTiming.other:
        return 'Other';
    }
  }

  /// Get emoji
  String get emoji {
    switch (this) {
      case SupplementTiming.morning:
        return '🌅';
      case SupplementTiming.preworkout:
        return '💪';
      case SupplementTiming.postworkout:
        return '🏃';
      case SupplementTiming.bedtime:
        return '🌙';
      case SupplementTiming.withMeal:
        return '🍽️';
      case SupplementTiming.other:
        return '💊';
    }
  }

  /// Get database value
  String get dbValue {
    switch (this) {
      case SupplementTiming.morning:
        return 'morning';
      case SupplementTiming.preworkout:
        return 'preworkout';
      case SupplementTiming.postworkout:
        return 'postworkout';
      case SupplementTiming.bedtime:
        return 'bedtime';
      case SupplementTiming.withMeal:
        return 'with_meal';
      case SupplementTiming.other:
        return 'other';
    }
  }

  /// Create from database value
  static SupplementTiming? fromDbValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'morning':
        return SupplementTiming.morning;
      case 'preworkout':
        return SupplementTiming.preworkout;
      case 'postworkout':
        return SupplementTiming.postworkout;
      case 'bedtime':
        return SupplementTiming.bedtime;
      case 'with_meal':
        return SupplementTiming.withMeal;
      case 'other':
        return SupplementTiming.other;
      default:
        return null;
    }
  }
}
