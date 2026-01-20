import 'package:uuid/uuid.dart';

/// Supplement model representing a supplement definition
class Supplement {
  final String id;
  final String name;
  final String dosage;
  final String? instructions;
  final String category;
  final String color;
  final String icon;
  final bool isActive;
  final String createdBy;
  final String? clientId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Supplement({
    required this.id,
    required this.name,
    required this.dosage,
    this.instructions,
    this.category = 'general',
    this.color = '#6C83F7',
    this.icon = 'medication',
    this.isActive = true,
    required this.createdBy,
    this.clientId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new supplement with generated ID and timestamps
  factory Supplement.create({
    required String name,
    required String dosage,
    String? instructions,
    String category = 'general',
    String color = '#6C83F7',
    String icon = 'medication',
    required String createdBy,
    String? clientId,
  }) {
    final now = DateTime.now();
    return Supplement(
      id: const Uuid().v4(),
      name: name,
      dosage: dosage,
      instructions: instructions,
      category: category,
      color: color,
      icon: icon,
      createdBy: createdBy,
      clientId: clientId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create supplement from database map
  factory Supplement.fromMap(Map<String, dynamic> map) {
    // Handle both owner_id (new schema) and created_by (old schema)
    final createdByValue = map['owner_id'] as String? ?? map['created_by'] as String;
    return Supplement(
      id: map['id'] as String,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      instructions: map['instructions'] as String?,
      category: map['category'] as String? ?? 'general',
      color: map['color'] as String? ?? '#6C83F7',
      icon: map['icon'] as String? ?? 'medication',
      isActive: map['is_active'] as bool? ?? true,
      createdBy: createdByValue,
      clientId: map['client_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'instructions': instructions,
      'category': category,
      'color': color,
      'icon': icon,
      'is_active': isActive,
      'owner_id': createdBy, // Map created_by to owner_id for RLS compatibility
      'created_by': createdBy, // Keep for backward compatibility if column exists
      'client_id': clientId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Supplement copyWith({
    String? id,
    String? name,
    String? dosage,
    String? instructions,
    String? category,
    String? color,
    String? icon,
    bool? isActive,
    String? createdBy,
    String? clientId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplement(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      category: category ?? this.category,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      clientId: clientId ?? this.clientId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name for category
  String get categoryDisplayName {
    switch (category) {
      case 'vitamin':
        return 'Vitamin';
      case 'mineral':
        return 'Mineral';
      case 'protein':
        return 'Protein';
      case 'pre_workout':
        return 'Pre-Workout';
      case 'post_workout':
        return 'Post-Workout';
      case 'omega':
        return 'Omega';
      case 'probiotic':
        return 'Probiotic';
      case 'herbal':
        return 'Herbal';
      case 'general':
      default:
        return 'General';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Supplement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Supplement(id: $id, name: $name, dosage: $dosage, category: $category)';
  }
}

/// Supplement schedule model representing when supplements should be taken
class SupplementSchedule {
  final String id;
  final String supplementId;
  final String scheduleType;
  final String frequency;
  final int timesPerDay;
  final List<DateTime>? specificTimes;
  final int? intervalHours;
  final List<int>? daysOfWeek;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupplementSchedule({
    required this.id,
    required this.supplementId,
    required this.scheduleType,
    required this.frequency,
    required this.timesPerDay,
    this.specificTimes,
    this.intervalHours,
    this.daysOfWeek,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new schedule with generated ID and timestamps
  factory SupplementSchedule.create({
    required String supplementId,
    required String scheduleType,
    required String frequency,
    required int timesPerDay,
    List<DateTime>? specificTimes,
    int? intervalHours,
    List<int>? daysOfWeek,
    DateTime? startDate,
    DateTime? endDate,
    required String createdBy,
  }) {
    final now = DateTime.now();
    return SupplementSchedule(
      id: const Uuid().v4(),
      supplementId: supplementId,
      scheduleType: scheduleType,
      frequency: frequency,
      timesPerDay: timesPerDay,
      specificTimes: specificTimes,
      intervalHours: intervalHours,
      daysOfWeek: daysOfWeek,
      startDate: startDate ?? now,
      endDate: endDate,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create schedule from database map
  factory SupplementSchedule.fromMap(Map<String, dynamic> map) {
    // Parse specific times from TIME[] array
    List<DateTime>? specificTimes;
    if (map['specific_times'] != null) {
      final timeList = map['specific_times'] as List;
      specificTimes = timeList.map((time) {
        if (time is String) {
          // Parse time string like "08:00:00"
          final parts = time.split(':');
          if (parts.length >= 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            return DateTime(2024, 1, 1, hour, minute); // Use arbitrary date for time only
          }
        }
        return DateTime.now(); // Fallback
      }).toList();
    }

    // Parse days of week from INTEGER[] array
    List<int>? daysOfWeek;
    if (map['days_of_week'] != null) {
      final daysList = map['days_of_week'] as List;
      daysOfWeek = daysList.map((day) => day as int).toList();
    }

    // Handle both owner_id (new schema) and created_by (old schema)
    final createdByValue = map['owner_id'] as String? ?? map['created_by'] as String;
    return SupplementSchedule(
      id: map['id'] as String,
      supplementId: map['supplement_id'] as String,
      scheduleType: map['schedule_type'] as String,
      frequency: map['frequency'] as String,
      timesPerDay: map['times_per_day'] as int,
      specificTimes: specificTimes,
      intervalHours: map['interval_hours'] as int?,
      daysOfWeek: daysOfWeek,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null 
          ? DateTime.parse(map['end_date'] as String)
          : null,
      isActive: map['is_active'] as bool? ?? true,
      createdBy: createdByValue,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    // Convert DateTime times to TIME strings
    List<String>? specificTimeStrings;
    if (specificTimes != null) {
      specificTimeStrings = specificTimes!.map((time) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
      }).toList();
    }

    return {
      'id': id,
      'supplement_id': supplementId,
      'schedule_type': scheduleType,
      'frequency': frequency,
      'times_per_day': timesPerDay,
      'specific_times': specificTimeStrings,
      'interval_hours': intervalHours,
      'days_of_week': daysOfWeek,
      'start_date': startDate.toIso8601String().split('T')[0], // Date only
      'end_date': endDate?.toIso8601String().split('T')[0],
      'is_active': isActive,
      'owner_id': createdBy, // Map created_by to owner_id for RLS compatibility
      'created_by': createdBy, // Keep for backward compatibility if column exists
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  SupplementSchedule copyWith({
    String? id,
    String? supplementId,
    String? scheduleType,
    String? frequency,
    int? timesPerDay,
    List<DateTime>? specificTimes,
    int? intervalHours,
    List<int>? daysOfWeek,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplementSchedule(
      id: id ?? this.id,
      supplementId: supplementId ?? this.supplementId,
      scheduleType: scheduleType ?? this.scheduleType,
      frequency: frequency ?? this.frequency,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      specificTimes: specificTimes ?? this.specificTimes,
      intervalHours: intervalHours ?? this.intervalHours,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name for schedule type
  String get scheduleTypeDisplayName {
    switch (scheduleType) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'custom':
        return 'Custom';
      default:
        return scheduleType;
    }
  }

  /// Check if schedule is active for a given date
  bool isActiveForDate(DateTime date) {
    if (!isActive) return false;
    if (date.isBefore(startDate)) return false;
    if (endDate != null && date.isAfter(endDate!)) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplementSchedule &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SupplementSchedule(id: $id, supplementId: $supplementId, frequency: $frequency)';
  }
}

/// Supplement log model representing actual supplement intake records
class SupplementLog {
  final String id;
  final String supplementId;
  final String? scheduleId;
  final String userId;
  final DateTime takenAt;
  final String status;
  final String? notes;
  final DateTime createdAt;

  const SupplementLog({
    required this.id,
    required this.supplementId,
    this.scheduleId,
    required this.userId,
    required this.takenAt,
    this.status = 'taken',
    this.notes,
    required this.createdAt,
  });

  /// Create a new log with generated ID and timestamps
  factory SupplementLog.create({
    required String supplementId,
    String? scheduleId,
    required String userId,
    DateTime? takenAt,
    String status = 'taken',
    String? notes,
  }) {
    final now = DateTime.now();
    return SupplementLog(
      id: const Uuid().v4(),
      supplementId: supplementId,
      scheduleId: scheduleId,
      userId: userId,
      takenAt: takenAt ?? now,
      status: status,
      notes: notes,
      createdAt: now,
    );
  }

  /// Create log from database map
  factory SupplementLog.fromMap(Map<String, dynamic> map) {
    return SupplementLog(
      id: map['id'] as String,
      supplementId: map['supplement_id'] as String,
      scheduleId: map['schedule_id'] as String?,
      userId: map['user_id'] as String,
      takenAt: DateTime.parse(map['taken_at'] as String),
      status: map['status'] as String? ?? 'taken',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplement_id': supplementId,
      'schedule_id': scheduleId,
      'user_id': userId,
      'taken_at': takenAt.toIso8601String(),
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  SupplementLog copyWith({
    String? id,
    String? supplementId,
    String? scheduleId,
    String? userId,
    DateTime? takenAt,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return SupplementLog(
      id: id ?? this.id,
      supplementId: supplementId ?? this.supplementId,
      scheduleId: scheduleId ?? this.scheduleId,
      userId: userId ?? this.userId,
      takenAt: takenAt ?? this.takenAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get display name for status
  String get statusDisplayName {
    switch (status) {
      case 'taken':
        return 'Taken';
      case 'skipped':
        return 'Skipped';
      case 'snoozed':
        return 'Snoozed';
      default:
        return status;
    }
  }

  /// Check if log is for today
  bool get isToday {
    final now = DateTime.now();
    return takenAt.year == now.year &&
           takenAt.month == now.month &&
           takenAt.day == now.day;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplementLog &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SupplementLog(id: $id, supplementId: $supplementId, status: $status, takenAt: $takenAt)';
  }
}

/// Combined model for supplements due today (from database function)
class SupplementDueToday {
  final String supplementId;
  final String supplementName;
  final String dosage;
  final String? instructions;
  final String category;
  final String color;
  final String icon;
  final String? scheduleId;
  final int timesPerDay;
  final List<DateTime>? specificTimes;
  final DateTime? nextDue;
  final DateTime? lastTaken;
  final int takenCount;

  const SupplementDueToday({
    required this.supplementId,
    required this.supplementName,
    required this.dosage,
    this.instructions,
    required this.category,
    required this.color,
    required this.icon,
    this.scheduleId,
    required this.timesPerDay,
    this.specificTimes,
    this.nextDue,
    this.lastTaken,
    required this.takenCount,
  });

  /// Create from database function result
  factory SupplementDueToday.fromMap(Map<String, dynamic> map) {
    // Parse specific times from TIME[] array
    List<DateTime>? specificTimes;
    if (map['specific_times'] != null) {
      final timeList = map['specific_times'] as List;
      specificTimes = timeList.map((time) {
        if (time is String) {
          final parts = time.split(':');
          if (parts.length >= 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            return DateTime(2024, 1, 1, hour, minute);
          }
        }
        return DateTime.now();
      }).toList();
    }

    return SupplementDueToday(
      supplementId: map['supplement_id'] as String,
      supplementName: map['supplement_name'] as String,
      dosage: map['dosage'] as String,
      instructions: map['instructions'] as String?,
      category: map['category'] as String,
      color: map['color'] as String,
      icon: map['icon'] as String,
      scheduleId: map['schedule_id'] as String?,
      timesPerDay: map['times_per_day'] as int,
      specificTimes: specificTimes,
      nextDue: map['next_due'] != null 
          ? DateTime.parse(map['next_due'] as String)
          : null,
      lastTaken: map['last_taken'] != null 
          ? DateTime.parse(map['last_taken'] as String)
          : null,
      takenCount: map['taken_count'] as int,
    );
  }

  /// Check if supplement is overdue
  bool get isOverdue {
    if (nextDue == null) return false;
    return DateTime.now().isAfter(nextDue!);
  }

  /// Check if supplement is due soon (within 1 hour)
  bool get isDueSoon {
    if (nextDue == null) return false;
    final now = DateTime.now();
    final oneHourFromNow = now.add(const Duration(hours: 1));
    return nextDue!.isBefore(oneHourFromNow) && nextDue!.isAfter(now);
  }

  /// Get progress percentage for today
  double get progressPercentage {
    if (timesPerDay <= 0) return 0.0;
    return (takenCount / timesPerDay).clamp(0.0, 1.0);
  }

  /// Check if supplement is completed for today
  bool get isCompletedToday {
    return takenCount >= timesPerDay;
  }
}
