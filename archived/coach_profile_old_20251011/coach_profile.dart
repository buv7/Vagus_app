class CoachProfile {
  final String coachId;
  final String? displayName;
  final String? username;
  final String? headline;
  final String? bio;
  final List<String> specialties;
  final String? introVideoUrl;
  final DateTime updatedAt;

  const CoachProfile({
    required this.coachId,
    this.displayName,
    this.username,
    this.headline,
    this.bio,
    this.specialties = const [],
    this.introVideoUrl,
    required this.updatedAt,
  });

  factory CoachProfile.fromMap(Map<String, dynamic> map) {
    return CoachProfile(
      coachId: map['coach_id']?.toString() ?? '',
      displayName: map['display_name']?.toString(),
      username: map['username']?.toString(),
      headline: map['headline']?.toString(),
      bio: map['bio']?.toString(),
      specialties: (map['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      introVideoUrl: map['intro_video_url']?.toString(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coach_id': coachId,
      'display_name': displayName,
      'username': username,
      'headline': headline,
      'bio': bio,
      'specialties': specialties,
      'intro_video_url': introVideoUrl,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isComplete {
    return displayName != null &&
        displayName!.isNotEmpty &&
        headline != null &&
        headline!.isNotEmpty &&
        bio != null &&
        bio!.isNotEmpty &&
        introVideoUrl != null &&
        introVideoUrl!.isNotEmpty;
  }
}

class CoachMedia {
  final String id;
  final String coachId;
  final String title;
  final String? description;
  final String mediaUrl;
  final String mediaType; // 'video' or 'course'
  final String visibility; // 'public' or 'clients_only'
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CoachMedia({
    required this.id,
    required this.coachId,
    required this.title,
    this.description,
    required this.mediaUrl,
    required this.mediaType,
    required this.visibility,
    required this.isApproved,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CoachMedia.fromMap(Map<String, dynamic> map) {
    return CoachMedia(
      id: map['id']?.toString() ?? '',
      coachId: map['coach_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString(),
      mediaUrl: map['media_url']?.toString() ?? '',
      mediaType: map['media_type']?.toString() ?? 'video',
      visibility: map['visibility']?.toString() ?? 'clients_only',
      isApproved: map['is_approved'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coach_id': coachId,
      'title': title,
      'description': description,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'visibility': visibility,
      'is_approved': isApproved,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
