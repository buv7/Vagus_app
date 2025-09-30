class CardioSession {
  final String? id;
  final String dayId;
  final int orderIndex;
  final CardioMachineType? machineType;

  // Machine-specific settings stored as map
  final Map<String, dynamic> settings;

  final String? instructions;
  final int? durationMinutes;

  final DateTime createdAt;
  final DateTime updatedAt;

  CardioSession({
    this.id,
    required this.dayId,
    required this.orderIndex,
    this.machineType,
    Map<String, dynamic>? settings,
    this.instructions,
    this.durationMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : settings = settings ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory CardioSession.fromMap(Map<String, dynamic> map) {
    return CardioSession(
      id: map['id']?.toString(),
      dayId: map['day_id']?.toString() ?? '',
      orderIndex: (map['order_index'] as num?)?.toInt() ?? 0,
      machineType: CardioMachineType.fromString(map['machine_type']?.toString()),
      settings: Map<String, dynamic>.from(map['settings'] as Map? ?? {}),
      instructions: map['instructions']?.toString(),
      durationMinutes: (map['duration_minutes'] as num?)?.toInt(),
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
      if (machineType != null) 'machine_type': machineType!.value,
      'settings': settings,
      if (instructions != null) 'instructions': instructions,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CardioSession copyWith({
    String? id,
    String? dayId,
    int? orderIndex,
    CardioMachineType? machineType,
    Map<String, dynamic>? settings,
    String? instructions,
    int? durationMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CardioSession(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      orderIndex: orderIndex ?? this.orderIndex,
      machineType: machineType ?? this.machineType,
      settings: settings ?? this.settings,
      instructions: instructions ?? this.instructions,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validation
  String? validate() {
    if (orderIndex < 0) {
      return 'Order index must be non-negative';
    }
    if (durationMinutes != null && durationMinutes! < 0) {
      return 'Duration must be non-negative';
    }
    return null;
  }

  // Helper methods for machine-specific settings

  /// Get treadmill-specific settings
  TreadmillSettings? getTreadmillSettings() {
    if (machineType != CardioMachineType.treadmill) return null;
    return TreadmillSettings.fromMap(settings);
  }

  /// Get bike-specific settings
  BikeSettings? getBikeSettings() {
    if (machineType != CardioMachineType.bike) return null;
    return BikeSettings.fromMap(settings);
  }

  /// Get rower-specific settings
  RowerSettings? getRowerSettings() {
    if (machineType != CardioMachineType.rower) return null;
    return RowerSettings.fromMap(settings);
  }

  /// Get elliptical-specific settings
  EllipticalSettings? getEllipticalSettings() {
    if (machineType != CardioMachineType.elliptical) return null;
    return EllipticalSettings.fromMap(settings);
  }

  /// Get stairmaster-specific settings
  StairmasterSettings? getStairmasterSettings() {
    if (machineType != CardioMachineType.stairmaster) return null;
    return StairmasterSettings.fromMap(settings);
  }

  /// Get display summary of cardio session
  String getDisplaySummary() {
    final parts = <String>[];

    if (machineType != null) {
      parts.add(machineType!.displayName);
    }

    if (durationMinutes != null) {
      parts.add('$durationMinutes min');
    }

    // Add machine-specific key parameters
    switch (machineType) {
      case CardioMachineType.treadmill:
        final treadmill = getTreadmillSettings();
        if (treadmill?.speed != null) {
          parts.add('${treadmill!.speed} km/h');
        }
        if (treadmill?.incline != null) {
          parts.add('${treadmill!.incline}% incline');
        }
        break;
      case CardioMachineType.bike:
        final bike = getBikeSettings();
        if (bike?.resistance != null) {
          parts.add('Resistance ${bike!.resistance}');
        }
        if (bike?.rpm != null) {
          parts.add('${bike!.rpm} RPM');
        }
        break;
      case CardioMachineType.rower:
        final rower = getRowerSettings();
        if (rower?.resistance != null) {
          parts.add('Resistance ${rower!.resistance}');
        }
        if (rower?.strokeRate != null) {
          parts.add('${rower!.strokeRate} SPM');
        }
        break;
      case CardioMachineType.elliptical:
        final elliptical = getEllipticalSettings();
        if (elliptical?.resistance != null) {
          parts.add('Resistance ${elliptical!.resistance}');
        }
        if (elliptical?.incline != null) {
          parts.add('${elliptical!.incline}% incline');
        }
        break;
      case CardioMachineType.stairmaster:
        final stairmaster = getStairmasterSettings();
        if (stairmaster?.level != null) {
          parts.add('Level ${stairmaster!.level}');
        }
        break;
      default:
        break;
    }

    return parts.join(' • ');
  }
}

enum CardioMachineType {
  treadmill('treadmill'),
  bike('bike'),
  rower('rower'),
  elliptical('elliptical'),
  stairmaster('stairmaster');

  final String value;
  const CardioMachineType(this.value);

  static CardioMachineType? fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'treadmill':
        return CardioMachineType.treadmill;
      case 'bike':
        return CardioMachineType.bike;
      case 'rower':
        return CardioMachineType.rower;
      case 'elliptical':
        return CardioMachineType.elliptical;
      case 'stairmaster':
        return CardioMachineType.stairmaster;
      default:
        return null;
    }
  }

  String get displayName {
    switch (this) {
      case CardioMachineType.treadmill:
        return 'Treadmill';
      case CardioMachineType.bike:
        return 'Bike';
      case CardioMachineType.rower:
        return 'Rower';
      case CardioMachineType.elliptical:
        return 'Elliptical';
      case CardioMachineType.stairmaster:
        return 'Stairmaster';
    }
  }
}

// Machine-specific settings classes

class TreadmillSettings {
  final double? speed; // km/h
  final double? incline; // percentage
  final int? durationMin;

  TreadmillSettings({
    this.speed,
    this.incline,
    this.durationMin,
  });

  factory TreadmillSettings.fromMap(Map<String, dynamic> map) {
    return TreadmillSettings(
      speed: (map['speed'] as num?)?.toDouble(),
      incline: (map['incline'] as num?)?.toDouble(),
      durationMin: (map['duration_min'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (speed != null) 'speed': speed,
      if (incline != null) 'incline': incline,
      if (durationMin != null) 'duration_min': durationMin,
    };
  }
}

class BikeSettings {
  final int? resistance; // 1-20 scale
  final int? rpm; // Revolutions per minute
  final int? durationMin;

  BikeSettings({
    this.resistance,
    this.rpm,
    this.durationMin,
  });

  factory BikeSettings.fromMap(Map<String, dynamic> map) {
    return BikeSettings(
      resistance: (map['resistance'] as num?)?.toInt(),
      rpm: (map['rpm'] as num?)?.toInt(),
      durationMin: (map['duration_min'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (resistance != null) 'resistance': resistance,
      if (rpm != null) 'rpm': rpm,
      if (durationMin != null) 'duration_min': durationMin,
    };
  }
}

class RowerSettings {
  final int? resistance; // 1-10 scale
  final int? strokeRate; // Strokes per minute
  final int? durationMin;
  final int? targetDistance; // meters

  RowerSettings({
    this.resistance,
    this.strokeRate,
    this.durationMin,
    this.targetDistance,
  });

  factory RowerSettings.fromMap(Map<String, dynamic> map) {
    return RowerSettings(
      resistance: (map['resistance'] as num?)?.toInt(),
      strokeRate: (map['stroke_rate'] as num?)?.toInt(),
      durationMin: (map['duration_min'] as num?)?.toInt(),
      targetDistance: (map['target_distance'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (resistance != null) 'resistance': resistance,
      if (strokeRate != null) 'stroke_rate': strokeRate,
      if (durationMin != null) 'duration_min': durationMin,
      if (targetDistance != null) 'target_distance': targetDistance,
    };
  }
}

class EllipticalSettings {
  final int? resistance; // 1-20 scale
  final double? incline; // percentage
  final int? durationMin;

  EllipticalSettings({
    this.resistance,
    this.incline,
    this.durationMin,
  });

  factory EllipticalSettings.fromMap(Map<String, dynamic> map) {
    return EllipticalSettings(
      resistance: (map['resistance'] as num?)?.toInt(),
      incline: (map['incline'] as num?)?.toDouble(),
      durationMin: (map['duration_min'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (resistance != null) 'resistance': resistance,
      if (incline != null) 'incline': incline,
      if (durationMin != null) 'duration_min': durationMin,
    };
  }
}

class StairmasterSettings {
  final int? level; // 1-20 scale
  final int? durationMin;

  StairmasterSettings({
    this.level,
    this.durationMin,
  });

  factory StairmasterSettings.fromMap(Map<String, dynamic> map) {
    return StairmasterSettings(
      level: (map['level'] as num?)?.toInt(),
      durationMin: (map['duration_min'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (level != null) 'level': level,
      if (durationMin != null) 'duration_min': durationMin,
    };
  }
}