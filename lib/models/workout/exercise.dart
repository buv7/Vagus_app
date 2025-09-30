class Exercise {
  final String? id;
  final String dayId;
  final int orderIndex;
  final String name;

  // Volume parameters
  final int? sets;
  final String? reps; // Can be "8-12", "AMRAP", "8", etc.
  final int? rest; // Rest in seconds

  // Intensity parameters
  final double? weight; // Weight in kg/lbs
  final int? percent1RM; // Percentage of 1RM (0-100)
  final int? rir; // Reps in reserve (0-5)
  final String? tempo; // e.g., "3-1-1-0"

  // Calculated/tracked metrics
  final double? tonnage; // Total volume (sets × reps × weight)

  // Exercise details
  final String? notes;
  final List<String>? mediaUrls; // Video demonstrations, images

  // Grouping (supersets, circuits, etc.)
  final String? groupId; // Identifier for grouping exercises
  final ExerciseGroupType groupType;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  Exercise({
    this.id,
    required this.dayId,
    required this.orderIndex,
    required this.name,
    this.sets,
    this.reps,
    this.rest,
    this.weight,
    this.percent1RM,
    this.rir,
    this.tempo,
    this.tonnage,
    this.notes,
    this.mediaUrls,
    this.groupId,
    this.groupType = ExerciseGroupType.none,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id']?.toString(),
      dayId: map['day_id']?.toString() ?? '',
      orderIndex: (map['order_index'] as num?)?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      sets: (map['sets'] as num?)?.toInt(),
      reps: map['reps']?.toString(),
      rest: (map['rest'] as num?)?.toInt(),
      weight: (map['weight'] as num?)?.toDouble(),
      percent1RM: (map['percent_1rm'] as num?)?.toInt(),
      rir: (map['rir'] as num?)?.toInt(),
      tempo: map['tempo']?.toString(),
      tonnage: (map['tonnage'] as num?)?.toDouble(),
      notes: map['notes']?.toString(),
      mediaUrls: (map['media_urls'] as List<dynamic>?)
          ?.map((url) => url.toString())
          .toList(),
      groupId: map['group_id']?.toString(),
      groupType: ExerciseGroupType.fromString(map['group_type']?.toString()),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'day_id': dayId,
      'order_index': orderIndex,
      'name': name,
      if (sets != null) 'sets': sets,
      if (reps != null) 'reps': reps,
      if (rest != null) 'rest': rest,
      if (weight != null) 'weight': weight,
      if (percent1RM != null) 'percent_1rm': percent1RM,
      if (rir != null) 'rir': rir,
      if (tempo != null) 'tempo': tempo,
      if (tonnage != null) 'tonnage': tonnage,
      if (notes != null) 'notes': notes,
      if (mediaUrls != null) 'media_urls': mediaUrls,
      if (groupId != null) 'group_id': groupId,
      'group_type': groupType.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Exercise copyWith({
    String? id,
    String? dayId,
    int? orderIndex,
    String? name,
    int? sets,
    String? reps,
    int? rest,
    double? weight,
    int? percent1RM,
    int? rir,
    String? tempo,
    double? tonnage,
    String? notes,
    List<String>? mediaUrls,
    String? groupId,
    ExerciseGroupType? groupType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      orderIndex: orderIndex ?? this.orderIndex,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      rest: rest ?? this.rest,
      weight: weight ?? this.weight,
      percent1RM: percent1RM ?? this.percent1RM,
      rir: rir ?? this.rir,
      tempo: tempo ?? this.tempo,
      tonnage: tonnage ?? this.tonnage,
      notes: notes ?? this.notes,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      groupId: groupId ?? this.groupId,
      groupType: groupType ?? this.groupType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validation
  String? validate() {
    if (name.trim().isEmpty) {
      return 'Exercise name is required';
    }
    if (orderIndex < 0) {
      return 'Order index must be non-negative';
    }
    if (sets != null && sets! < 0) {
      return 'Sets must be non-negative';
    }
    if (rest != null && rest! < 0) {
      return 'Rest must be non-negative';
    }
    if (weight != null && weight! < 0) {
      return 'Weight must be non-negative';
    }
    if (percent1RM != null && (percent1RM! < 0 || percent1RM! > 100)) {
      return 'Percent 1RM must be between 0 and 100';
    }
    if (rir != null && (rir! < 0 || rir! > 5)) {
      return 'RIR must be between 0 and 5';
    }
    return null;
  }

  // Helper methods

  /// Calculate estimated 1RM using Epley formula
  /// Returns null if weight or reps are not available
  double? calculateEstimated1RM() {
    if (weight == null || reps == null) return null;

    // Extract numeric reps value (handle "8-12" format)
    final repsMatch = RegExp(r'^\d+').firstMatch(reps!);
    if (repsMatch == null) return null;

    final repsNumeric = int.tryParse(repsMatch.group(0)!);
    if (repsNumeric == null || repsNumeric < 1 || repsNumeric > 15) {
      return null;
    }

    if (repsNumeric == 1) {
      return weight;
    }

    // Epley formula: 1RM = weight × (1 + reps / 30)
    return weight! * (1 + repsNumeric / 30.0);
  }

  /// Calculate total volume for this exercise
  /// Returns null if required data is not available
  double? calculateVolume() {
    if (sets == null || weight == null || reps == null) return null;

    // Extract numeric reps value
    final repsMatch = RegExp(r'^\d+').firstMatch(reps!);
    if (repsMatch == null) return null;

    final repsNumeric = int.tryParse(repsMatch.group(0)!);
    if (repsNumeric == null) return null;

    return sets! * repsNumeric * weight!;
  }

  /// Get working weight from percent1RM if available
  /// Requires a known 1RM value
  double? getWorkingWeight(double? oneRepMax) {
    if (percent1RM == null || oneRepMax == null) return null;
    return oneRepMax * (percent1RM! / 100.0);
  }

  /// Parse reps string into numeric value (takes first number)
  int? getRepsNumeric() {
    if (reps == null) return null;
    final match = RegExp(r'^\d+').firstMatch(reps!);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }

  /// Check if this exercise is part of a group (superset, circuit, etc.)
  bool get isGrouped => groupType != ExerciseGroupType.none && groupId != null;

  /// Get display text for intensity
  String getIntensityDisplay() {
    final parts = <String>[];

    if (percent1RM != null) {
      parts.add('${percent1RM}% 1RM');
    }
    if (rir != null) {
      parts.add('RIR $rir');
    }
    if (tempo != null) {
      parts.add('Tempo: $tempo');
    }

    return parts.isEmpty ? '' : parts.join(' • ');
  }

  /// Get display text for volume
  String getVolumeDisplay() {
    if (sets == null || reps == null) return '';

    final parts = ['$sets × $reps'];

    if (weight != null) {
      parts.add('@ ${weight}kg');
    }

    return parts.join(' ');
  }
}

enum ExerciseGroupType {
  none('none'),
  superset('superset'),
  circuit('circuit'),
  giantSet('giant_set'),
  dropSet('drop_set'),
  restPause('rest_pause');

  final String value;
  const ExerciseGroupType(this.value);

  static ExerciseGroupType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'superset':
        return ExerciseGroupType.superset;
      case 'circuit':
        return ExerciseGroupType.circuit;
      case 'giant_set':
        return ExerciseGroupType.giantSet;
      case 'drop_set':
        return ExerciseGroupType.dropSet;
      case 'rest_pause':
        return ExerciseGroupType.restPause;
      default:
        return ExerciseGroupType.none;
    }
  }

  String get displayName {
    switch (this) {
      case ExerciseGroupType.none:
        return 'Standard';
      case ExerciseGroupType.superset:
        return 'Superset';
      case ExerciseGroupType.circuit:
        return 'Circuit';
      case ExerciseGroupType.giantSet:
        return 'Giant Set';
      case ExerciseGroupType.dropSet:
        return 'Drop Set';
      case ExerciseGroupType.restPause:
        return 'Rest-Pause';
    }
  }
}