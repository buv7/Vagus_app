library;

enum VideoSource { own, youtube, instagram, tiktok, other }

VideoSource videoSourceFromString(String s) {
  switch (s) {
    case 'youtube':
      return VideoSource.youtube;
    case 'instagram':
      return VideoSource.instagram;
    case 'tiktok':
      return VideoSource.tiktok;
    case 'other':
      return VideoSource.other;
    default:
      return VideoSource.own;
  }
}

String videoSourceToString(VideoSource s) {
  switch (s) {
    case VideoSource.youtube:
      return 'youtube';
    case VideoSource.instagram:
      return 'instagram';
    case VideoSource.tiktok:
      return 'tiktok';
    case VideoSource.other:
      return 'other';
    case VideoSource.own:
      return 'own';
  }
}

class ExerciseVideo {
  final String? id;
  final String exerciseId;
  final String videoUrl;
  final VideoSource source;
  final String uploaderUserId;
  final int? durationSeconds;
  final String? thumbnailUrl;
  final String language;
  final bool isDefault;
  final String? clientId;
  final String? title;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExerciseVideo({
    this.id,
    required this.exerciseId,
    required this.videoUrl,
    this.source = VideoSource.own,
    required this.uploaderUserId,
    this.durationSeconds,
    this.thumbnailUrl,
    this.language = 'en',
    this.isDefault = false,
    this.clientId,
    this.title,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ExerciseVideo.fromMap(Map<String, dynamic> m) {
    return ExerciseVideo(
      id: m['id'] as String?,
      exerciseId: m['exercise_id'] as String,
      videoUrl: m['video_url'] as String,
      source: videoSourceFromString(m['source'] as String? ?? 'own'),
      uploaderUserId: m['uploader_user_id'] as String,
      durationSeconds: m['duration_seconds'] as int?,
      thumbnailUrl: m['thumbnail_url'] as String?,
      language: m['language'] as String? ?? 'en',
      isDefault: m['is_default'] as bool? ?? false,
      clientId: m['client_id'] as String?,
      title: m['title'] as String?,
      description: m['description'] as String?,
      isActive: m['is_active'] as bool? ?? true,
      createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : null,
      updatedAt: m['updated_at'] != null ? DateTime.parse(m['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'exercise_id': exerciseId,
      'video_url': videoUrl,
      'source': videoSourceToString(source),
      'uploader_user_id': uploaderUserId,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      'language': language,
      'is_default': isDefault,
      if (clientId != null) 'client_id': clientId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      'is_active': isActive,
    };
  }

  ExerciseVideo copyWith({
    String? id,
    String? exerciseId,
    String? videoUrl,
    VideoSource? source,
    String? uploaderUserId,
    int? durationSeconds,
    String? thumbnailUrl,
    String? language,
    bool? isDefault,
    String? clientId,
    String? title,
    String? description,
    bool? isActive,
  }) {
    return ExerciseVideo(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      videoUrl: videoUrl ?? this.videoUrl,
      source: source ?? this.source,
      uploaderUserId: uploaderUserId ?? this.uploaderUserId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      language: language ?? this.language,
      isDefault: isDefault ?? this.isDefault,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class ExerciseImageOverride {
  final String? id;
  final String exerciseId;
  final String coachId;
  final String? clientId;
  final String imageUrl;
  final DateTime? createdAt;

  const ExerciseImageOverride({
    this.id,
    required this.exerciseId,
    required this.coachId,
    this.clientId,
    required this.imageUrl,
    this.createdAt,
  });

  factory ExerciseImageOverride.fromMap(Map<String, dynamic> m) {
    return ExerciseImageOverride(
      id: m['id'] as String?,
      exerciseId: m['exercise_id'] as String,
      coachId: m['coach_id'] as String,
      clientId: m['client_id'] as String?,
      imageUrl: m['image_url'] as String,
      createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'exercise_id': exerciseId,
      'coach_id': coachId,
      if (clientId != null) 'client_id': clientId,
      'image_url': imageUrl,
    };
  }
}
