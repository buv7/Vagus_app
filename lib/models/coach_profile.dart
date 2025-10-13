class CoachProfile {
  final String coachId;
  final String? displayName;
  final String? username;
  final String? headline;
  final String? bio;
  final List<String>? specialties;
  final List<String>? certifications;
  final String? avatarUrl;
  final String? introVideoUrl;
  final bool isApproved;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CoachProfile({
    required this.coachId,
    this.displayName,
    this.username,
    this.headline,
    this.bio,
    this.specialties,
    this.certifications,
    this.avatarUrl,
    this.introVideoUrl,
    this.isApproved = false,
    this.createdAt,
    this.updatedAt,
  });

  factory CoachProfile.fromJson(Map<String, dynamic> json) {
    return CoachProfile(
      coachId: json['coach_id']?.toString() ?? '',
      displayName: json['display_name']?.toString(),
      username: json['username']?.toString(),
      headline: json['headline']?.toString(),
      bio: json['bio']?.toString(),
      specialties: (json['specialties'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      certifications: (json['certifications'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      avatarUrl: json['avatar_url']?.toString(),
      introVideoUrl: json['intro_video_url']?.toString(),
      isApproved: json['is_approved'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coach_id': coachId,
      'display_name': displayName,
      'username': username,
      'headline': headline,
      'bio': bio,
      'specialties': specialties,
      'certifications': certifications,
      'avatar_url': avatarUrl,
      'intro_video_url': introVideoUrl,
      'is_approved': isApproved,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isComplete {
    return displayName != null &&
        displayName!.isNotEmpty &&
        headline != null &&
        headline!.isNotEmpty &&
        bio != null &&
        bio!.isNotEmpty;
  }

  CoachProfile copyWith({
    String? coachId,
    String? displayName,
    String? username,
    String? headline,
    String? bio,
    List<String>? specialties,
    List<String>? certifications,
    String? avatarUrl,
    String? introVideoUrl,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoachProfile(
      coachId: coachId ?? this.coachId,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      headline: headline ?? this.headline,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
      certifications: certifications ?? this.certifications,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      introVideoUrl: introVideoUrl ?? this.introVideoUrl,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CoachMedia {
  final String id;
  final String coachId;
  final String title;
  final String? description;
  final String mediaUrl;
  final String mediaType; // 'video', 'course', 'article'
  final String visibility; // 'public', 'clients_only'
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

  factory CoachMedia.fromJson(Map<String, dynamic> json) {
    return CoachMedia(
      id: json['id']?.toString() ?? '',
      coachId: json['coach_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      mediaUrl: json['media_url']?.toString() ?? '',
      mediaType: json['media_type']?.toString() ?? 'video',
      visibility: json['visibility']?.toString() ?? 'clients_only',
      isApproved: json['is_approved'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
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
