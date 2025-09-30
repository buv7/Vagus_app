
enum ConnectionQuality {
  excellent,
  good,
  fair,
  poor;

  String get value {
    switch (this) {
      case ConnectionQuality.excellent:
        return 'excellent';
      case ConnectionQuality.good:
        return 'good';
      case ConnectionQuality.fair:
        return 'fair';
      case ConnectionQuality.poor:
        return 'poor';
    }
  }

  static ConnectionQuality fromString(String value) {
    switch (value) {
      case 'excellent':
        return ConnectionQuality.excellent;
      case 'good':
        return ConnectionQuality.good;
      case 'fair':
        return ConnectionQuality.fair;
      case 'poor':
        return ConnectionQuality.poor;
      default:
        return ConnectionQuality.good;
    }
  }
}

enum DeviceType {
  mobile,
  desktop,
  tablet;

  String get value {
    switch (this) {
      case DeviceType.mobile:
        return 'mobile';
      case DeviceType.desktop:
        return 'desktop';
      case DeviceType.tablet:
        return 'tablet';
    }
  }

  static DeviceType fromString(String value) {
    switch (value) {
      case 'mobile':
        return DeviceType.mobile;
      case 'desktop':
        return DeviceType.desktop;
      case 'tablet':
        return DeviceType.tablet;
      default:
        return DeviceType.mobile;
    }
  }
}

class CallParticipant {
  final String id;
  final String sessionId;
  final String userId;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final int durationSeconds;
  final bool isMuted;
  final bool isVideoEnabled;
  final bool isScreenSharing;
  final ConnectionQuality connectionQuality;
  final DeviceType? deviceType;
  final String? userAgent;
  final String? ipAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields for UI
  final String? userName;
  final String? userAvatar;
  final bool isCurrentUser;

  CallParticipant({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.joinedAt,
    this.leftAt,
    this.durationSeconds = 0,
    this.isMuted = false,
    this.isVideoEnabled = true,
    this.isScreenSharing = false,
    this.connectionQuality = ConnectionQuality.good,
    this.deviceType,
    this.userAgent,
    this.ipAddress,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatar,
    this.isCurrentUser = false,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      leftAt: json['left_at'] != null 
          ? DateTime.parse(json['left_at'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      isMuted: json['is_muted'] as bool? ?? false,
      isVideoEnabled: json['is_video_enabled'] as bool? ?? true,
      isScreenSharing: json['is_screen_sharing'] as bool? ?? false,
      connectionQuality: ConnectionQuality.fromString(json['connection_quality'] as String? ?? 'good'),
      deviceType: json['device_type'] != null 
          ? DeviceType.fromString(json['device_type'] as String)
          : null,
      userAgent: json['user_agent'] as String?,
      ipAddress: json['ip_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: json['user_name'] as String?,
      userAvatar: json['user_avatar'] as String?,
      isCurrentUser: json['is_current_user'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'is_muted': isMuted,
      'is_video_enabled': isVideoEnabled,
      'is_screen_sharing': isScreenSharing,
      'connection_quality': connectionQuality.value,
      'device_type': deviceType?.value,
      'user_agent': userAgent,
      'ip_address': ipAddress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CallParticipant copyWith({
    String? id,
    String? sessionId,
    String? userId,
    DateTime? joinedAt,
    DateTime? leftAt,
    int? durationSeconds,
    bool? isMuted,
    bool? isVideoEnabled,
    bool? isScreenSharing,
    ConnectionQuality? connectionQuality,
    DeviceType? deviceType,
    String? userAgent,
    String? ipAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userAvatar,
    bool? isCurrentUser,
  }) {
    return CallParticipant(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isMuted: isMuted ?? this.isMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      deviceType: deviceType ?? this.deviceType,
      userAgent: userAgent ?? this.userAgent,
      ipAddress: ipAddress ?? this.ipAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  bool get isActive => leftAt == null;
  bool get hasLeft => leftAt != null;

  Duration get duration {
    final endTime = leftAt ?? DateTime.now();
    return endTime.difference(joinedAt);
  }

  String get durationFormatted {
    final dur = duration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    final seconds = dur.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String get displayName => userName ?? 'User $userId';
  String get initials {
    final name = displayName;
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'U';
  }

  @override
  String toString() {
    return 'CallParticipant(id: $id, userId: $userId, isActive: $isActive, isMuted: $isMuted, isVideoEnabled: $isVideoEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CallParticipant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
