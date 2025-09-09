class AdBanner {
  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final String audience;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    required this.audience,
    required this.startsAt,
    this.endsAt,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdBanner.fromJson(Map<String, dynamic> json) {
    return AdBanner(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String,
      linkUrl: json['link_url'] as String?,
      audience: json['audience'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at'] as String) : null,
      isActive: json['is_active'] as bool,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'audience': audience,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && 
           startsAt.isBefore(now) && 
           (endsAt == null || endsAt!.isAfter(now));
  }
}
