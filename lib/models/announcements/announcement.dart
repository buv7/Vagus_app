class Announcement {
  final String id;
  final String title;
  final String? body;
  final String? imageUrl;
  final String ctaType; // 'none', 'url', 'coach'
  final String? ctaValue; // URL or coach_id depending on cta_type
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    this.body,
    this.imageUrl,
    this.ctaType = 'none',
    this.ctaValue,
    this.startAt,
    this.endAt,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString(),
      imageUrl: map['image_url']?.toString(),
      ctaType: map['cta_type']?.toString() ?? 'none',
      ctaValue: map['cta_value']?.toString(),
      startAt: map['start_at'] != null ? DateTime.tryParse(map['start_at'].toString()) : null,
      endAt: map['end_at'] != null ? DateTime.tryParse(map['end_at'].toString()) : null,
      isActive: map['is_active'] as bool? ?? true,
      createdBy: map['created_by']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'cta_type': ctaType,
      'cta_value': ctaValue,
      'start_at': startAt?.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    if (!isActive) return false;
    if (startAt != null && now.isBefore(startAt!)) return false;
    if (endAt != null && now.isAfter(endAt!)) return false;
    return true;
  }

  bool get hasCta => ctaType != 'none' && ctaValue != null;
}

class AnnouncementAnalytics {
  final String announcementId;
  final int impressions;
  final int uniqueUsers;
  final int clicks;
  final double ctr; // click-through rate
  final Map<String, int> roleBreakdown;

  const AnnouncementAnalytics({
    required this.announcementId,
    required this.impressions,
    required this.uniqueUsers,
    required this.clicks,
    required this.ctr,
    required this.roleBreakdown,
  });

  factory AnnouncementAnalytics.fromMap(Map<String, dynamic> map) {
    return AnnouncementAnalytics(
      announcementId: map['announcement_id']?.toString() ?? '',
      impressions: map['impressions'] as int? ?? 0,
      uniqueUsers: map['unique_users'] as int? ?? 0,
      clicks: map['clicks'] as int? ?? 0,
      ctr: (map['ctr'] as num?)?.toDouble() ?? 0.0,
      roleBreakdown: Map<String, int>.from(map['role_breakdown'] as Map? ?? {}),
    );
  }
}
