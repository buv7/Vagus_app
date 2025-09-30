import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/workout/exercise_library_models.dart';

/// Exercise Library Service for managing exercise database
///
/// Handles:
/// - Exercise search with advanced filters
/// - Custom exercise creation and management
/// - Exercise favorites
/// - Exercise alternatives
/// - Media upload and management
/// - Popular exercise recommendations
class ExerciseLibraryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // SEARCH AND RETRIEVAL
  // =====================================================

  /// Search exercises with advanced filters
  Future<List<ExerciseLibraryItem>> searchExercises({
    String? query,
    List<String>? muscleGroups,
    List<String>? equipment,
    String? difficulty,
    String? category,
    bool includeCustom = true,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      final response = await _supabase.rpc(
        'search_exercises',
        params: {
          'search_query': query,
          'muscle_groups_filter': muscleGroups,
          'equipment_filter': equipment,
          'difficulty_filter': difficulty,
          'category_filter': category,
          'include_custom': includeCustom,
          'user_id': userId,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => ExerciseLibraryItem.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to search exercises: $e');
    }
  }

  /// Get exercise details by ID
  Future<ExerciseLibraryItem> getExerciseDetails(String exerciseId) async {
    try {
      final response = await _supabase
          .from('exercise_library')
          .select('''
            *,
            exercise_media(*),
            exercise_tags(tag),
            exercise_favorites!inner(user_id)
          ''')
          .eq('id', exerciseId)
          .maybeSingle();

      if (response == null) {
        throw Exception('Exercise not found');
      }

      return ExerciseLibraryItem.fromMap(response);
    } catch (e) {
      throw Exception('Failed to get exercise details: $e');
    }
  }

  /// Get popular exercises by muscle group
  Future<List<ExerciseLibraryItem>> fetchPopularExercises({
    String? muscleGroup,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('exercise_library')
          .select('*')
          .eq('is_public', true)
          .order('usage_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => ExerciseLibraryItem.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch popular exercises: $e');
    }
  }

  /// Get exercise alternatives
  Future<List<ExerciseAlternative>> suggestAlternatives(
    String exerciseId, {
    String? reason,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_exercise_alternatives',
        params: {
          'p_exercise_id': exerciseId,
          'p_reason': reason,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => ExerciseAlternative.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to suggest alternatives: $e');
    }
  }

  // =====================================================
  // CRUD OPERATIONS
  // =====================================================

  /// Create custom exercise
  Future<String> createCustomExercise(ExerciseLibraryItem exercise) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('exercise_library')
          .insert({
            'name': exercise.name,
            'name_ar': exercise.nameAr,
            'name_ku': exercise.nameKu,
            'category': exercise.category,
            'primary_muscle_groups': exercise.primaryMuscleGroups,
            'secondary_muscle_groups': exercise.secondaryMuscleGroups,
            'equipment_needed': exercise.equipmentNeeded,
            'difficulty_level': exercise.difficultyLevel,
            'instructions': exercise.instructions,
            'instructions_ar': exercise.instructionsAr,
            'instructions_ku': exercise.instructionsKu,
            'video_url': exercise.videoUrl,
            'thumbnail_url': exercise.thumbnailUrl,
            'created_by': userId,
            'is_public': false,
          })
          .select('id')
          .single();

      final exerciseId = response['id'] as String;

      // Add tags if provided
      if (exercise.tags != null && exercise.tags!.isNotEmpty) {
        await _addTags(exerciseId, exercise.tags!);
      }

      return exerciseId;
    } catch (e) {
      throw Exception('Failed to create custom exercise: $e');
    }
  }

  /// Update exercise
  Future<void> updateExercise(ExerciseLibraryItem exercise) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('exercise_library')
          .update({
            'name': exercise.name,
            'name_ar': exercise.nameAr,
            'name_ku': exercise.nameKu,
            'category': exercise.category,
            'primary_muscle_groups': exercise.primaryMuscleGroups,
            'secondary_muscle_groups': exercise.secondaryMuscleGroups,
            'equipment_needed': exercise.equipmentNeeded,
            'difficulty_level': exercise.difficultyLevel,
            'instructions': exercise.instructions,
            'instructions_ar': exercise.instructionsAr,
            'instructions_ku': exercise.instructionsKu,
            'video_url': exercise.videoUrl,
            'thumbnail_url': exercise.thumbnailUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', exercise.id!)
          .eq('created_by', userId);

      // Update tags
      if (exercise.tags != null) {
        // Delete existing tags
        await _supabase
            .from('exercise_tags')
            .delete()
            .eq('exercise_id', exercise.id!);

        // Add new tags
        if (exercise.tags!.isNotEmpty) {
          await _addTags(exercise.id!, exercise.tags!);
        }
      }
    } catch (e) {
      throw Exception('Failed to update exercise: $e');
    }
  }

  /// Delete exercise
  Future<void> deleteExercise(String exerciseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('exercise_library')
          .delete()
          .eq('id', exerciseId)
          .eq('created_by', userId);
    } catch (e) {
      throw Exception('Failed to delete exercise: $e');
    }
  }

  // =====================================================
  // MEDIA MANAGEMENT
  // =====================================================

  /// Upload exercise video
  Future<String> uploadExerciseVideo(
    String exerciseId,
    String filePath,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'exercise_videos/$userId/${exerciseId}_$timestamp.mp4';

      // Upload to storage
      await _supabase.storage.from('workout-media').upload(
            fileName,
            File(filePath),
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final videoUrl = _supabase.storage
          .from('workout-media')
          .getPublicUrl(fileName);

      // Update exercise record
      await _supabase
          .from('exercise_library')
          .update({'video_url': videoUrl})
          .eq('id', exerciseId)
          .eq('created_by', userId);

      // Add to exercise_media table
      await _supabase.from('exercise_media').insert({
        'exercise_id': exerciseId,
        'media_type': 'video',
        'url': videoUrl,
        'angle': 'front',
      });

      return videoUrl;
    } catch (e) {
      throw Exception('Failed to upload exercise video: $e');
    }
  }

  /// Upload exercise thumbnail
  Future<String> uploadExerciseThumbnail(
    String exerciseId,
    String filePath,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'exercise_thumbnails/$userId/${exerciseId}_$timestamp.jpg';

      // Upload to storage
      await _supabase.storage.from('workout-media').upload(
            fileName,
            File(filePath),
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final thumbnailUrl = _supabase.storage
          .from('workout-media')
          .getPublicUrl(fileName);

      // Update exercise record
      await _supabase
          .from('exercise_library')
          .update({'thumbnail_url': thumbnailUrl})
          .eq('id', exerciseId)
          .eq('created_by', userId);

      return thumbnailUrl;
    } catch (e) {
      throw Exception('Failed to upload exercise thumbnail: $e');
    }
  }

  /// Add media to exercise (multiple angles)
  Future<void> addExerciseMedia({
    required String exerciseId,
    required String mediaType,
    required String url,
    String? angle,
    String? description,
  }) async {
    try {
      // Get next order index
      final countResponse = await _supabase
          .from('exercise_media')
          .select('order_index')
          .eq('exercise_id', exerciseId)
          .order('order_index', ascending: false)
          .limit(1)
          .maybeSingle();

      final nextIndex = countResponse != null
          ? (countResponse['order_index'] as int) + 1
          : 0;

      await _supabase.from('exercise_media').insert({
        'exercise_id': exerciseId,
        'media_type': mediaType,
        'url': url,
        'angle': angle,
        'description': description,
        'order_index': nextIndex,
      });
    } catch (e) {
      throw Exception('Failed to add exercise media: $e');
    }
  }

  /// Get exercise media
  Future<List<ExerciseMedia>> getExerciseMedia(String exerciseId) async {
    try {
      final response = await _supabase
          .from('exercise_media')
          .select('*')
          .eq('exercise_id', exerciseId)
          .order('order_index');

      return (response as List)
          .map((item) => ExerciseMedia.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to get exercise media: $e');
    }
  }

  // =====================================================
  // FAVORITES
  // =====================================================

  /// Toggle favorite
  Future<void> toggleFavorite(String exerciseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if already favorited
      final existing = await _supabase
          .from('exercise_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('exercise_id', exerciseId)
          .maybeSingle();

      if (existing != null) {
        // Remove favorite
        await _supabase
            .from('exercise_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('exercise_id', exerciseId);
      } else {
        // Add favorite
        await _supabase.from('exercise_favorites').insert({
          'user_id': userId,
          'exercise_id': exerciseId,
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  /// Get user favorites
  Future<List<ExerciseLibraryItem>> getFavorites() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('exercise_favorites')
          .select('''
            exercise_id,
            exercise_library(*)
          ''')
          .eq('user_id', userId);

      return (response as List)
          .map((item) => ExerciseLibraryItem.fromMap(item['exercise_library']))
          .toList();
    } catch (e) {
      throw Exception('Failed to get favorites: $e');
    }
  }

  /// Check if exercise is favorited
  Future<bool> isFavorite(String exerciseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('exercise_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('exercise_id', exerciseId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // =====================================================
  // ALTERNATIVES MANAGEMENT
  // =====================================================

  /// Add exercise alternative
  Future<void> addAlternative({
    required String exerciseId,
    required String alternativeId,
    String? reason,
    double similarityScore = 0.80,
  }) async {
    try {
      await _supabase.from('exercise_alternatives').insert({
        'exercise_id': exerciseId,
        'alternative_id': alternativeId,
        'reason': reason,
        'similarity_score': similarityScore,
      });
    } catch (e) {
      throw Exception('Failed to add alternative: $e');
    }
  }

  /// Remove exercise alternative
  Future<void> removeAlternative({
    required String exerciseId,
    required String alternativeId,
  }) async {
    try {
      await _supabase
          .from('exercise_alternatives')
          .delete()
          .eq('exercise_id', exerciseId)
          .eq('alternative_id', alternativeId);
    } catch (e) {
      throw Exception('Failed to remove alternative: $e');
    }
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  /// Add tags to exercise
  Future<void> _addTags(String exerciseId, List<String> tags) async {
    final tagInserts = tags.map((tag) => {
          'exercise_id': exerciseId,
          'tag': tag.toLowerCase().trim(),
        }).toList();

    await _supabase.from('exercise_tags').insert(tagInserts);
  }

  /// Get available muscle groups
  List<String> getAvailableMuscleGroups() {
    return [
      'chest',
      'back',
      'shoulders',
      'biceps',
      'triceps',
      'forearms',
      'quads',
      'hamstrings',
      'glutes',
      'calves',
      'core',
      'abs',
    ];
  }

  /// Get available equipment
  List<String> getAvailableEquipment() {
    return [
      'barbell',
      'dumbbell',
      'kettlebell',
      'cable',
      'machine',
      'bodyweight',
      'resistance_band',
      'medicine_ball',
      'smith_machine',
      'bench',
      'rack',
      'pull_up_bar',
      'rings',
      'trx',
    ];
  }

  /// Get available categories
  List<String> getAvailableCategories() {
    return [
      'compound',
      'isolation',
      'cardio',
      'stretching',
      'plyometric',
      'olympic',
    ];
  }

  /// Get available difficulty levels
  List<String> getAvailableDifficultyLevels() {
    return [
      'beginner',
      'intermediate',
      'advanced',
      'expert',
    ];
  }
}