class CoachClientPeriod {
  final String id;
  final String coachId;
  final String clientId;
  final DateTime startDate;
  final int durationWeeks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CoachClientPeriod({
    required this.id,
    required this.coachId,
    required this.clientId,
    required this.startDate,
    required this.durationWeeks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CoachClientPeriod.fromMap(Map<String, dynamic> map) {
    return CoachClientPeriod(
      id: map['id']?.toString() ?? '',
      coachId: map['coach_id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      startDate: DateTime.tryParse(map['start_date']?.toString() ?? '') ?? DateTime.now(),
      durationWeeks: map['duration_weeks'] as int? ?? 12,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coach_id': coachId,
      'client_id': clientId,
      'start_date': startDate.toIso8601String().split('T')[0], // Date only
      'duration_weeks': durationWeeks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Calculate the end date of the period
  DateTime get endDate {
    return startDate.add(Duration(days: durationWeeks * 7));
  }

  /// Calculate weeks completed since start
  int get weeksCompleted {
    final now = DateTime.now();
    final difference = now.difference(startDate);
    final weeks = (difference.inDays / 7).floor();
    return weeks.clamp(0, durationWeeks);
  }

  /// Calculate weeks remaining
  int get weeksRemaining {
    return (durationWeeks - weeksCompleted).clamp(0, durationWeeks);
  }

  /// Calculate progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (durationWeeks == 0) return 0.0;
    return (weeksCompleted / durationWeeks).clamp(0.0, 1.0);
  }

  /// Check if the period is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Check if the period has ended
  bool get hasEnded {
    return DateTime.now().isAfter(endDate);
  }

  /// Get a human-readable status
  String get status {
    if (hasEnded) return 'Completed';
    if (isActive) return 'Active';
    return 'Upcoming';
  }

  /// Get formatted date range
  String get dateRange {
    final start = '${startDate.day}/${startDate.month}/${startDate.year}';
    final end = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$start - $end';
  }
}
