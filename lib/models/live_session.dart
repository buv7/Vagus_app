import 'package:supabase_flutter/supabase_flutter.dart';

enum SessionType {
  audioCall,
  videoCall,
  groupCall,
  coachingSession;

  String get value {
    switch (this) {
      case SessionType.audioCall:
        return 'audio_call';
      case SessionType.videoCall:
        return 'video_call';
      case SessionType.groupCall:
        return 'group_call';
      case SessionType.coachingSession:
        return 'coaching_session';
    }
  }

  static SessionType fromString(String value) {
    switch (value) {
      case 'audio_call':
        return SessionType.audioCall;
      case 'video_call':
        return SessionType.videoCall;
      case 'group_call':
        return SessionType.groupCall;
      case 'coaching_session':
        return SessionType.coachingSession;
      default:
        return SessionType.videoCall;
    }
  }
}

enum SessionStatus {
  scheduled,
  active,
  ended,
  cancelled,
  missed;

  String get value {
    switch (this) {
      case SessionStatus.scheduled:
        return 'scheduled';
      case SessionStatus.active:
        return 'active';
      case SessionStatus.ended:
        return 'ended';
      case SessionStatus.cancelled:
        return 'cancelled';
      case SessionStatus.missed:
        return 'missed';
    }
  }

  static SessionStatus fromString(String value) {
    switch (value) {
      case 'scheduled':
        return SessionStatus.scheduled;
      case 'active':
        return SessionStatus.active;
      case 'ended':
        return SessionStatus.ended;
      case 'cancelled':
        return SessionStatus.cancelled;
      case 'missed':
        return SessionStatus.missed;
      default:
        return SessionStatus.scheduled;
    }
  }
}

class LiveSession {
  final String id;
  final SessionType sessionType;
  final String? title;
  final String? description;
  final String? coachId;
  final String? clientId;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final SessionStatus status;
  final int maxParticipants;
  final bool isRecordingEnabled;
  final String? recordingUrl;
  final String? sessionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  LiveSession({
    required this.id,
    required this.sessionType,
    this.title,
    this.description,
    this.coachId,
    this.clientId,
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
    this.durationMinutes = 0,
    this.status = SessionStatus.scheduled,
    this.maxParticipants = 2,
    this.isRecordingEnabled = false,
    this.recordingUrl,
    this.sessionNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: json['id'] as String,
      sessionType: SessionType.fromString(json['session_type'] as String),
      title: json['title'] as String?,
      description: json['description'] as String?,
      coachId: json['coach_id'] as String?,
      clientId: json['client_id'] as String?,
      scheduledAt: json['scheduled_at'] != null 
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null 
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      status: SessionStatus.fromString(json['status'] as String),
      maxParticipants: json['max_participants'] as int? ?? 2,
      isRecordingEnabled: json['is_recording_enabled'] as bool? ?? false,
      recordingUrl: json['recording_url'] as String?,
      sessionNotes: json['session_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_type': sessionType.value,
      'title': title,
      'description': description,
      'coach_id': coachId,
      'client_id': clientId,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'status': status.value,
      'max_participants': maxParticipants,
      'is_recording_enabled': isRecordingEnabled,
      'recording_url': recordingUrl,
      'session_notes': sessionNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LiveSession copyWith({
    String? id,
    SessionType? sessionType,
    String? title,
    String? description,
    String? coachId,
    String? clientId,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMinutes,
    SessionStatus? status,
    int? maxParticipants,
    bool? isRecordingEnabled,
    String? recordingUrl,
    String? sessionNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LiveSession(
      id: id ?? this.id,
      sessionType: sessionType ?? this.sessionType,
      title: title ?? this.title,
      description: description ?? this.description,
      coachId: coachId ?? this.coachId,
      clientId: clientId ?? this.clientId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      isRecordingEnabled: isRecordingEnabled ?? this.isRecordingEnabled,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      sessionNotes: sessionNotes ?? this.sessionNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == SessionStatus.active;
  bool get isScheduled => status == SessionStatus.scheduled;
  bool get isEnded => status == SessionStatus.ended;
  bool get isCancelled => status == SessionStatus.cancelled;
  bool get isMissed => status == SessionStatus.missed;

  bool get isVideoCall => sessionType == SessionType.videoCall || sessionType == SessionType.groupCall;
  bool get isAudioCall => sessionType == SessionType.audioCall;
  bool get isGroupCall => sessionType == SessionType.groupCall;
  bool get isCoachingSession => sessionType == SessionType.coachingSession;

  Duration? get duration {
    if (startedAt == null) return null;
    final endTime = endedAt ?? DateTime.now();
    return endTime.difference(startedAt!);
  }

  String get durationFormatted {
    final dur = duration;
    if (dur == null) return '0:00';
    
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    final seconds = dur.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  String toString() {
    return 'LiveSession(id: $id, type: ${sessionType.value}, status: ${status.value}, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
