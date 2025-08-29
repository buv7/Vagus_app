import 'package:uuid/uuid.dart';

enum MusicKind { spotify, soundcloud }

class MusicLink {
  final String id;
  final String ownerId;
  final MusicKind kind;
  final String uri;
  final String title;
  final String? art;
  final List<String> tags;
  final DateTime createdAt;

  MusicLink({
    String? id,
    required this.ownerId,
    required this.kind,
    required this.uri,
    required this.title,
    this.art,
    List<String>? tags,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory MusicLink.fromJson(Map<String, dynamic> json) {
    return MusicLink(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      kind: MusicKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => MusicKind.spotify,
      ),
      uri: json['uri'] as String,
      title: json['title'] as String,
      art: json['art'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'kind': kind.name,
      'uri': uri,
      'title': title,
      'art': art,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MusicLink copyWith({
    String? id,
    String? ownerId,
    MusicKind? kind,
    String? uri,
    String? title,
    String? art,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return MusicLink(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      kind: kind ?? this.kind,
      uri: uri ?? this.uri,
      title: title ?? this.title,
      art: art ?? this.art,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicLink &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MusicLink(id: $id, title: $title, kind: $kind)';
  }
}

class WorkoutMusicRef {
  final String id;
  final String planId;
  final int? weekIdx;
  final int? dayIdx;
  final String musicLinkId;
  final DateTime createdAt;

  WorkoutMusicRef({
    String? id,
    required this.planId,
    this.weekIdx,
    this.dayIdx,
    required this.musicLinkId,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory WorkoutMusicRef.fromJson(Map<String, dynamic> json) {
    return WorkoutMusicRef(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      weekIdx: json['week_idx'] as int?,
      dayIdx: json['day_idx'] as int?,
      musicLinkId: json['music_link_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'week_idx': weekIdx,
      'day_idx': dayIdx,
      'music_link_id': musicLinkId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutMusicRef &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WorkoutMusicRef(id: $id, planId: $planId, weekIdx: $weekIdx, dayIdx: $dayIdx)';
  }
}

class EventMusicRef {
  final String id;
  final String eventId;
  final String musicLinkId;
  final DateTime createdAt;

  EventMusicRef({
    String? id,
    required this.eventId,
    required this.musicLinkId,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory EventMusicRef.fromJson(Map<String, dynamic> json) {
    return EventMusicRef(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      musicLinkId: json['music_link_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'music_link_id': musicLinkId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventMusicRef &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EventMusicRef(id: $id, eventId: $eventId)';
  }
}

class UserMusicPrefs {
  final String userId;
  final String? defaultProvider;
  final bool autoOpen;
  final List<String> genres;
  final int? bpmMin;
  final int? bpmMax;
  final DateTime updatedAt;

  UserMusicPrefs({
    required this.userId,
    this.defaultProvider,
    this.autoOpen = true,
    List<String>? genres,
    this.bpmMin,
    this.bpmMax,
    DateTime? updatedAt,
  })  : genres = genres ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  factory UserMusicPrefs.fromJson(Map<String, dynamic> json) {
    return UserMusicPrefs(
      userId: json['user_id'] as String,
      defaultProvider: json['default_provider'] as String?,
      autoOpen: json['auto_open'] as bool? ?? true,
      genres: List<String>.from(json['genres'] ?? []),
      bpmMin: json['bpm_min'] as int?,
      bpmMax: json['bpm_max'] as int?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'default_provider': defaultProvider,
      'auto_open': autoOpen,
      'genres': genres,
      'bpm_min': bpmMin,
      'bpm_max': bpmMax,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserMusicPrefs copyWith({
    String? userId,
    String? defaultProvider,
    bool? autoOpen,
    List<String>? genres,
    int? bpmMin,
    int? bpmMax,
    DateTime? updatedAt,
  }) {
    return UserMusicPrefs(
      userId: userId ?? this.userId,
      defaultProvider: defaultProvider ?? this.defaultProvider,
      autoOpen: autoOpen ?? this.autoOpen,
      genres: genres ?? this.genres,
      bpmMin: bpmMin ?? this.bpmMin,
      bpmMax: bpmMax ?? this.bpmMax,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserMusicPrefs &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'UserMusicPrefs(userId: $userId, defaultProvider: $defaultProvider, autoOpen: $autoOpen)';
  }
}
