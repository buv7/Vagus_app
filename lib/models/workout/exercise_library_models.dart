/// Exercise Library Models
///
/// Data models for exercise library system
library;

/// Exercise library item
class ExerciseLibraryItem {
  final String? id;
  final String name;
  final String? nameAr;
  final String? nameKu;
  final String category;
  final List<String> primaryMuscleGroups;
  final List<String> secondaryMuscleGroups;
  final List<String> equipmentNeeded;
  final String? difficultyLevel;
  final String? instructions;
  final String? instructionsAr;
  final String? instructionsKu;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? createdBy;
  final bool isPublic;
  final int usageCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? tags;
  final bool? isFavorite;

  ExerciseLibraryItem({
    this.id,
    required this.name,
    this.nameAr,
    this.nameKu,
    required this.category,
    this.primaryMuscleGroups = const [],
    this.secondaryMuscleGroups = const [],
    this.equipmentNeeded = const [],
    this.difficultyLevel,
    this.instructions,
    this.instructionsAr,
    this.instructionsKu,
    this.videoUrl,
    this.thumbnailUrl,
    this.createdBy,
    this.isPublic = false,
    this.usageCount = 0,
    this.createdAt,
    this.updatedAt,
    this.tags,
    this.isFavorite,
  });

  factory ExerciseLibraryItem.fromMap(Map<String, dynamic> map) {
    return ExerciseLibraryItem(
      id: map['id'] as String?,
      name: map['name'] as String,
      nameAr: map['name_ar'] as String?,
      nameKu: map['name_ku'] as String?,
      category: map['category'] as String,
      primaryMuscleGroups: map['primary_muscle_groups'] != null
          ? List<String>.from(map['primary_muscle_groups'])
          : [],
      secondaryMuscleGroups: map['secondary_muscle_groups'] != null
          ? List<String>.from(map['secondary_muscle_groups'])
          : [],
      equipmentNeeded: map['equipment_needed'] != null
          ? List<String>.from(map['equipment_needed'])
          : [],
      difficultyLevel: map['difficulty_level'] as String?,
      instructions: map['instructions'] as String?,
      instructionsAr: map['instructions_ar'] as String?,
      instructionsKu: map['instructions_ku'] as String?,
      videoUrl: map['video_url'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      createdBy: map['created_by'] as String?,
      isPublic: map['is_public'] as bool? ?? false,
      usageCount: map['usage_count'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      tags: map['tags'] != null
          ? (map['tags'] as List).map((t) => t['tag'] as String).toList()
          : null,
      isFavorite: map['is_favorite'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'name_ku': nameKu,
      'category': category,
      'primary_muscle_groups': primaryMuscleGroups,
      'secondary_muscle_groups': secondaryMuscleGroups,
      'equipment_needed': equipmentNeeded,
      'difficulty_level': difficultyLevel,
      'instructions': instructions,
      'instructions_ar': instructionsAr,
      'instructions_ku': instructionsKu,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'created_by': createdBy,
      'is_public': isPublic,
      'usage_count': usageCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ExerciseLibraryItem copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? nameKu,
    String? category,
    List<String>? primaryMuscleGroups,
    List<String>? secondaryMuscleGroups,
    List<String>? equipmentNeeded,
    String? difficultyLevel,
    String? instructions,
    String? instructionsAr,
    String? instructionsKu,
    String? videoUrl,
    String? thumbnailUrl,
    String? createdBy,
    bool? isPublic,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return ExerciseLibraryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      nameKu: nameKu ?? this.nameKu,
      category: category ?? this.category,
      primaryMuscleGroups: primaryMuscleGroups ?? this.primaryMuscleGroups,
      secondaryMuscleGroups: secondaryMuscleGroups ?? this.secondaryMuscleGroups,
      equipmentNeeded: equipmentNeeded ?? this.equipmentNeeded,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      instructions: instructions ?? this.instructions,
      instructionsAr: instructionsAr ?? this.instructionsAr,
      instructionsKu: instructionsKu ?? this.instructionsKu,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdBy: createdBy ?? this.createdBy,
      isPublic: isPublic ?? this.isPublic,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  String? validate() {
    if (name.trim().isEmpty) {
      return 'Exercise name is required';
    }
    if (category.trim().isEmpty) {
      return 'Category is required';
    }
    if (primaryMuscleGroups.isEmpty) {
      return 'At least one muscle group is required';
    }
    return null;
  }
}

/// Exercise media item
class ExerciseMedia {
  final String? id;
  final String exerciseId;
  final String mediaType;
  final String url;
  final String? angle;
  final String? description;
  final int orderIndex;
  final DateTime? createdAt;

  ExerciseMedia({
    this.id,
    required this.exerciseId,
    required this.mediaType,
    required this.url,
    this.angle,
    this.description,
    this.orderIndex = 0,
    this.createdAt,
  });

  factory ExerciseMedia.fromMap(Map<String, dynamic> map) {
    return ExerciseMedia(
      id: map['id'] as String?,
      exerciseId: map['exercise_id'] as String,
      mediaType: map['media_type'] as String,
      url: map['url'] as String,
      angle: map['angle'] as String?,
      description: map['description'] as String?,
      orderIndex: map['order_index'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'media_type': mediaType,
      'url': url,
      'angle': angle,
      'description': description,
      'order_index': orderIndex,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

/// Exercise alternative
class ExerciseAlternative {
  final String id;
  final String name;
  final String category;
  final List<String> primaryMuscleGroups;
  final List<String> equipmentNeeded;
  final String? difficultyLevel;
  final String? videoUrl;
  final String? thumbnailUrl;
  final double similarityScore;
  final String? reason;

  ExerciseAlternative({
    required this.id,
    required this.name,
    required this.category,
    this.primaryMuscleGroups = const [],
    this.equipmentNeeded = const [],
    this.difficultyLevel,
    this.videoUrl,
    this.thumbnailUrl,
    required this.similarityScore,
    this.reason,
  });

  factory ExerciseAlternative.fromMap(Map<String, dynamic> map) {
    return ExerciseAlternative(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      primaryMuscleGroups: map['primary_muscle_groups'] != null
          ? List<String>.from(map['primary_muscle_groups'])
          : [],
      equipmentNeeded: map['equipment_needed'] != null
          ? List<String>.from(map['equipment_needed'])
          : [],
      difficultyLevel: map['difficulty_level'] as String?,
      videoUrl: map['video_url'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      similarityScore: (map['similarity_score'] as num).toDouble(),
      reason: map['reason'] as String?,
    );
  }
}