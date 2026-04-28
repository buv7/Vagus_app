class MenstrualCycle {
  final String id;
  final String userId;
  final DateTime cycleStart;
  final DateTime? cycleEnd;
  final double? avgLengthDays;
  final bool irregularFlag;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MenstrualCycle({
    required this.id,
    required this.userId,
    required this.cycleStart,
    this.cycleEnd,
    this.avgLengthDays,
    required this.irregularFlag,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenstrualCycle.fromMap(Map<String, dynamic> map) {
    final avgRaw = map['avg_length_days'];
    return MenstrualCycle(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      cycleStart: DateTime.tryParse(map['cycle_start']?.toString() ?? '') ?? DateTime.now(),
      cycleEnd: map['cycle_end'] != null
          ? DateTime.tryParse(map['cycle_end'].toString())
          : null,
      avgLengthDays: avgRaw != null ? double.tryParse(avgRaw.toString()) : null,
      irregularFlag: map['irregular_flag'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  bool get isOpen => cycleEnd == null;

  /// Length in days; null for an open (not yet ended) cycle.
  int? get cycleLength {
    if (cycleEnd == null) return null;
    return cycleEnd!.difference(cycleStart).inDays + 1;
  }
}
