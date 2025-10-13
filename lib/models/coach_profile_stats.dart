class CoachProfileStats {
  final String coachId;
  final double rating;
  final int reviewCount;
  final int clientCount;
  final int yearsExperience;
  final double successRate;
  final int profileViews;
  final int mediaViews;
  final int connectionsThisMonth;
  final DateTime lastUpdated;

  const CoachProfileStats({
    required this.coachId,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.clientCount = 0,
    this.yearsExperience = 0,
    this.successRate = 0.0,
    this.profileViews = 0,
    this.mediaViews = 0,
    this.connectionsThisMonth = 0,
    required this.lastUpdated,
  });

  factory CoachProfileStats.fromMap(Map<String, dynamic> map) {
    return CoachProfileStats(
      coachId: map['coach_id']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      clientCount: (map['client_count'] as num?)?.toInt() ?? 0,
      yearsExperience: (map['years_experience'] as num?)?.toInt() ?? 0,
      successRate: (map['success_rate'] as num?)?.toDouble() ?? 0.0,
      profileViews: (map['profile_views'] as num?)?.toInt() ?? 0,
      mediaViews: (map['media_views'] as num?)?.toInt() ?? 0,
      connectionsThisMonth: (map['connections_this_month'] as num?)?.toInt() ?? 0,
      lastUpdated: DateTime.tryParse(map['last_updated']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coach_id': coachId,
      'rating': rating,
      'review_count': reviewCount,
      'client_count': clientCount,
      'years_experience': yearsExperience,
      'success_rate': successRate,
      'profile_views': profileViews,
      'media_views': mediaViews,
      'connections_this_month': connectionsThisMonth,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  String get ratingText => rating > 0 ? rating.toStringAsFixed(1) : 'New';

  String get clientCountText {
    if (clientCount == 0) return 'No clients yet';
    if (clientCount == 1) return '1 client';
    return '$clientCount clients';
  }

  String get experienceText {
    if (yearsExperience == 0) return 'New coach';
    if (yearsExperience == 1) return '1 year experience';
    return '$yearsExperience years experience';
  }

  String get successRateText {
    if (successRate == 0) return 'N/A';
    return '${successRate.toStringAsFixed(0)}% success rate';
  }
}

class CoachProfileCompleteness {
  final String coachId;
  final bool hasProfile;
  final bool hasDisplayName;
  final bool hasUsername;
  final bool hasHeadline;
  final bool hasBio;
  final bool hasSpecialties;
  final bool hasIntroVideo;
  final bool hasPortfolioMedia;
  final bool hasCertifications;
  final bool hasAvatar;
  final int mediaCount;
  final int certificationCount;

  const CoachProfileCompleteness({
    required this.coachId,
    this.hasProfile = false,
    this.hasDisplayName = false,
    this.hasUsername = false,
    this.hasHeadline = false,
    this.hasBio = false,
    this.hasSpecialties = false,
    this.hasIntroVideo = false,
    this.hasPortfolioMedia = false,
    this.hasCertifications = false,
    this.hasAvatar = false,
    this.mediaCount = 0,
    this.certificationCount = 0,
  });

  factory CoachProfileCompleteness.fromMap(Map<String, dynamic> map) {
    return CoachProfileCompleteness(
      coachId: map['coach_id']?.toString() ?? '',
      hasProfile: map['has_profile'] as bool? ?? false,
      hasDisplayName: map['has_display_name'] as bool? ?? false,
      hasUsername: map['has_username'] as bool? ?? false,
      hasHeadline: map['has_headline'] as bool? ?? false,
      hasBio: map['has_bio'] as bool? ?? false,
      hasSpecialties: map['has_specialties'] as bool? ?? false,
      hasIntroVideo: map['has_intro_video'] as bool? ?? false,
      hasPortfolioMedia: map['has_portfolio_media'] as bool? ?? false,
      hasCertifications: map['has_certifications'] as bool? ?? false,
      hasAvatar: map['has_avatar'] as bool? ?? false,
      mediaCount: (map['media_count'] as num?)?.toInt() ?? 0,
      certificationCount: (map['certification_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coach_id': coachId,
      'has_profile': hasProfile,
      'has_display_name': hasDisplayName,
      'has_username': hasUsername,
      'has_headline': hasHeadline,
      'has_bio': hasBio,
      'has_specialties': hasSpecialties,
      'has_intro_video': hasIntroVideo,
      'has_portfolio_media': hasPortfolioMedia,
      'has_certifications': hasCertifications,
      'has_avatar': hasAvatar,
      'media_count': mediaCount,
      'certification_count': certificationCount,
    };
  }

  int get completedSteps {
    int count = 0;
    if (hasProfile) count++;
    if (hasDisplayName) count++;
    if (hasUsername) count++;
    if (hasHeadline) count++;
    if (hasBio) count++;
    if (hasSpecialties) count++;
    if (hasIntroVideo) count++;
    if (hasPortfolioMedia) count++;
    if (hasCertifications) count++;
    if (hasAvatar) count++;
    return count;
  }

  int get totalSteps => 10;

  double get completionPercentage => (completedSteps / totalSteps) * 100;

  bool get isComplete => completedSteps == totalSteps;

  List<ProfileCompletionItem> get missingItems {
    final List<ProfileCompletionItem> missing = [];

    if (!hasDisplayName) {
      missing.add(const ProfileCompletionItem(
        title: 'Add Display Name',
        description: 'Set your professional name',
        priority: ProfileCompletionPriority.high,
      ));
    }

    if (!hasUsername) {
      missing.add(const ProfileCompletionItem(
        title: 'Choose Username',
        description: 'Create a unique @username',
        priority: ProfileCompletionPriority.high,
      ));
    }

    if (!hasHeadline) {
      missing.add(const ProfileCompletionItem(
        title: 'Write Headline',
        description: 'Create a compelling tagline',
        priority: ProfileCompletionPriority.high,
      ));
    }

    if (!hasBio) {
      missing.add(const ProfileCompletionItem(
        title: 'Add Biography',
        description: 'Tell your professional story',
        priority: ProfileCompletionPriority.medium,
      ));
    }

    if (!hasSpecialties) {
      missing.add(const ProfileCompletionItem(
        title: 'Select Specialties',
        description: 'Choose your areas of expertise',
        priority: ProfileCompletionPriority.medium,
      ));
    }

    if (!hasIntroVideo) {
      missing.add(const ProfileCompletionItem(
        title: 'Upload Intro Video',
        description: 'Introduce yourself to potential clients',
        priority: ProfileCompletionPriority.medium,
      ));
    }

    if (!hasPortfolioMedia) {
      missing.add(const ProfileCompletionItem(
        title: 'Add Portfolio Media',
        description: 'Showcase your expertise with videos/courses',
        priority: ProfileCompletionPriority.low,
      ));
    }

    if (!hasCertifications) {
      missing.add(const ProfileCompletionItem(
        title: 'Upload Certifications',
        description: 'Add your professional credentials',
        priority: ProfileCompletionPriority.low,
      ));
    }

    if (!hasAvatar) {
      missing.add(const ProfileCompletionItem(
        title: 'Upload Profile Photo',
        description: 'Add a professional headshot',
        priority: ProfileCompletionPriority.high,
      ));
    }

    return missing;
  }

  String get nextStepTitle {
    final highPriority = missingItems.where((item) =>
        item.priority == ProfileCompletionPriority.high).toList();
    if (highPriority.isNotEmpty) {
      return highPriority.first.title;
    }

    final mediumPriority = missingItems.where((item) =>
        item.priority == ProfileCompletionPriority.medium).toList();
    if (mediumPriority.isNotEmpty) {
      return mediumPriority.first.title;
    }

    return missingItems.isNotEmpty ? missingItems.first.title : '';
  }
}

class ProfileCompletionItem {
  final String title;
  final String description;
  final ProfileCompletionPriority priority;

  const ProfileCompletionItem({
    required this.title,
    required this.description,
    required this.priority,
  });
}

enum ProfileCompletionPriority {
  high,
  medium,
  low,
}
