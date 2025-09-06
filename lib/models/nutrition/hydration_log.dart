import 'package:equatable/equatable.dart';

/// Model for tracking daily hydration intake
class HydrationLog extends Equatable {
  final String userId;
  final DateTime date;
  final int ml;
  final DateTime updatedAt;

  const HydrationLog({
    required this.userId,
    required this.date,
    required this.ml,
    required this.updatedAt,
  });

  /// Create from database map
  factory HydrationLog.fromMap(Map<String, dynamic> map) {
    return HydrationLog(
      userId: map['user_id']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      ml: map['ml'] as int? ?? 0,
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'ml': ml,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with new values
  HydrationLog copyWith({
    String? userId,
    DateTime? date,
    int? ml,
    DateTime? updatedAt,
  }) {
    return HydrationLog(
      userId: userId ?? this.userId,
      date: date ?? this.date,
      ml: ml ?? this.ml,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get hydration status based on ml intake
  HydrationStatus get status {
    if (ml >= 3000) return HydrationStatus.excellent;
    if (ml >= 2000) return HydrationStatus.good;
    if (ml >= 1000) return HydrationStatus.fair;
    return HydrationStatus.low;
  }

  /// Get progress percentage (0.0 to 1.0) based on target
  double getProgressPercentage(int targetMl) {
    if (targetMl <= 0) return 0.0;
    return (ml / targetMl).clamp(0.0, 1.0);
  }

  /// Get remaining ml to reach target
  int getRemainingMl(int targetMl) {
    return (targetMl - ml).clamp(0, targetMl);
  }

  /// Check if target is reached
  bool hasReachedTarget(int targetMl) {
    return ml >= targetMl;
  }

  /// Get formatted ml string
  String get formattedMl => '${ml}ml';

  /// Get formatted liters string
  String get formattedLiters {
    final liters = ml / 1000.0;
    return '${liters.toStringAsFixed(1)}L';
  }

  @override
  List<Object?> get props => [userId, date, ml, updatedAt];

  @override
  String toString() => 'HydrationLog(userId: $userId, date: $date, ml: ${ml}ml)';
}

/// Hydration status enum
enum HydrationStatus {
  low,
  fair,
  good,
  excellent;

  /// Get display name for status
  String get displayName {
    switch (this) {
      case HydrationStatus.low:
        return 'Low';
      case HydrationStatus.fair:
        return 'Fair';
      case HydrationStatus.good:
        return 'Good';
      case HydrationStatus.excellent:
        return 'Excellent';
    }
  }

  /// Get color for status (for UI)
  String get colorName {
    switch (this) {
      case HydrationStatus.low:
        return 'red';
      case HydrationStatus.fair:
        return 'orange';
      case HydrationStatus.good:
        return 'blue';
      case HydrationStatus.excellent:
        return 'green';
    }
  }

  /// Get emoji for status
  String get emoji {
    switch (this) {
      case HydrationStatus.low:
        return '💧';
      case HydrationStatus.fair:
        return '💧💧';
      case HydrationStatus.good:
        return '💧💧💧';
      case HydrationStatus.excellent:
        return '💧💧💧💧';
    }
  }
}
