import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service for managing workout knowledge base (exercises and intensifiers)
class WorkoutKnowledgeService {
  WorkoutKnowledgeService._();
  static final WorkoutKnowledgeService instance = WorkoutKnowledgeService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // EXERCISE KNOWLEDGE CRUD
  // =====================================================

  /// Search exercises with optional filters
  /// Now includes alias/synonym search for better results
  Future<List<Map<String, dynamic>>> searchExercises({
    String? query,
    String? status,
    String? language,
    List<String>? muscles,
    List<String>? equipment,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Use RPC function for alias-aware search when query is provided
      // This ensures we search both exercise names and aliases
      if (query != null && query.isNotEmpty) {
        try {
          final response = await _supabase.rpc(
            'search_exercises_with_aliases',
            params: {
              'p_query': query,
              'p_status': status ?? 'approved',
              'p_language': language,
              'p_muscles': muscles,
              'p_equipment': equipment,
              'p_limit': limit,
              'p_offset': offset,
            },
          );
          
          if (response != null) {
            final results = List<Map<String, dynamic>>.from(response);
            // Hydrate Arabic descriptions if language='ar' is requested
            if (language == 'ar') {
              return _hydrateArabicDescriptions(results);
            }
            return results;
          }
        } catch (rpcError) {
          // If RPC fails, fall back to regular search
          debugPrint('⚠️ RPC search failed, falling back to regular search: $rpcError');
        }
      }
      
      // Fallback: Regular search (for non-query searches or if RPC fails)
      var request = _supabase
          .from('exercise_knowledge')
          .select();

      // Filter by status (default: approved for non-admins)
      // Always filter by status - default to 'approved' if not specified
      // Note: RLS also enforces approved-only access, but filtering here improves clarity and performance
      final statusFilter = status ?? 'approved';
      request = request.eq('status', statusFilter);

      // Filter by language
      if (language != null) {
        request = request.eq('language', language);
      }

      // Filter by primary muscles (array contains)
      if (muscles != null && muscles.isNotEmpty) {
        request = request.overlaps('primary_muscles', muscles);
      }

      // Filter by equipment (array contains)
      if (equipment != null && equipment.isNotEmpty) {
        request = request.overlaps('equipment', equipment);
      }

      // Text search (simple ILIKE search on name and short_desc)
      if (query != null && query.isNotEmpty) {
        request = request.or(
          'name.ilike.%$query%,short_desc.ilike.%$query%',
        );
      }

      // Apply ordering and pagination after filters
      final response = await request
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      final results = List<Map<String, dynamic>>.from(response);
      
      // If language='ar' is requested, fetch and hydrate Arabic translations
      if (language == 'ar') {
        return await _hydrateArabicDescriptionsFromTranslations(results);
      }
      
      return results;
    } catch (e) {
      debugPrint('❌ Error searching exercises: $e');
      return [];
    }
  }

  /// Get exercise by ID
  Future<Map<String, dynamic>?> getExercise(String id) async {
    try {
      final response = await _supabase
          .from('exercise_knowledge')
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      debugPrint('❌ Error getting exercise: $e');
      return null;
    }
  }

  /// Get exercise knowledge by ID (alias for getExercise, with specific fields)
  /// If language='ar', returns Arabic descriptions from exercise_translations
  Future<Map<String, dynamic>?> getExerciseKnowledgeById(
    String id, {
    String language = 'en',
  }) async {
    try {
      // Get English exercise first
      final response = await _supabase
          .from('exercise_knowledge')
          .select('id, name, short_desc, how_to, cues, common_mistakes, primary_muscles, secondary_muscles, equipment, movement_pattern, difficulty')
          .eq('id', id)
          .eq('language', 'en') // Always get English as base
          .maybeSingle();

      if (response == null) return null;

      final exercise = Map<String, dynamic>.from(response);

      // If Arabic is requested, fetch and hydrate Arabic translations
      if (language == 'ar') {
        final arabicTranslation = await _supabase
            .from('exercise_translations')
            .select('name, short_desc, how_to, cues, common_mistakes')
            .eq('exercise_id', id)
            .eq('language', 'ar')
            .maybeSingle();

        if (arabicTranslation != null) {
          // Replace English fields with Arabic if available
          exercise['name'] = arabicTranslation['name'] ?? exercise['name'];
          exercise['short_desc'] = arabicTranslation['short_desc'] ?? exercise['short_desc'];
          exercise['how_to'] = arabicTranslation['how_to'] ?? exercise['how_to'];
          exercise['cues'] = arabicTranslation['cues'] ?? exercise['cues'];
          exercise['common_mistakes'] = arabicTranslation['common_mistakes'] ?? exercise['common_mistakes'];
        }
      }

      return exercise;
    } catch (e) {
      debugPrint('❌ Error getting exercise knowledge by ID: $e');
      return null;
    }
  }

  /// Get linked intensifiers for an exercise (from exercise_intensifier_links)
  Future<List<Map<String, dynamic>>> getLinkedIntensifiersForExercise(
    String exerciseId, {
    String language = 'en',
  }) async {
    try {
      final response = await _supabase
          .from('exercise_intensifier_links')
          .select('''
            intensifier_id,
            intensifier_knowledge!inner(
              id,
              name,
              short_desc,
              fatigue_cost,
              intensity_rules,
              status,
              language
            )
          ''')
          .eq('exercise_id', exerciseId)
          .eq('intensifier_knowledge.status', 'approved')
          .eq('intensifier_knowledge.language', language);

      // Flatten the nested structure
      return (response as List).map((item) {
        final link = item as Map<String, dynamic>;
        final intensifier = link['intensifier_knowledge'] as Map<String, dynamic>?;
        if (intensifier == null) return null;
        
        return {
          'id': intensifier['id'],
          'name': intensifier['name'],
          'short_desc': intensifier['short_desc'],
          'fatigue_cost': intensifier['fatigue_cost'],
          'intensity_rules': intensifier['intensity_rules'],
        };
      }).where((item) => item != null).cast<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('❌ Error getting linked intensifiers: $e');
      return [];
    }
  }

  /// Create exercise (coaches/admins can create pending/draft)
  Future<Map<String, dynamic>> createExercise(Map<String, dynamic> data) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Ensure created_by is set
      data['created_by'] = user.id;

      // Default status to pending if not set
      if (!data.containsKey('status') || data['status'] == null) {
        data['status'] = 'pending';
      }

      final response = await _supabase
          .from('exercise_knowledge')
          .insert(data)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('❌ Error creating exercise: $e');
      throw Exception('Failed to create exercise: $e');
    }
  }

  /// Update exercise (admins can update all, coaches can update own pending/draft)
  Future<Map<String, dynamic>> updateExercise(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('exercise_knowledge')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('❌ Error updating exercise: $e');
      throw Exception('Failed to update exercise: $e');
    }
  }

  /// Delete exercise (admin only)
  Future<void> deleteExercise(String id) async {
    try {
      await _supabase.from('exercise_knowledge').delete().eq('id', id);
    } catch (e) {
      debugPrint('❌ Error deleting exercise: $e');
      throw Exception('Failed to delete exercise: $e');
    }
  }

  /// Update exercise status (approve/reject - admin only)
  Future<void> updateExerciseStatus(String id, String status) async {
    try {
      await _supabase
          .from('exercise_knowledge')
          .update({'status': status})
          .eq('id', id);
    } catch (e) {
      debugPrint('❌ Error updating exercise status: $e');
      throw Exception('Failed to update exercise status: $e');
    }
  }

  /// Batch upsert exercise knowledge items (idempotent)
  /// Only fills missing fields, preserves existing content
  Future<int> upsertExerciseKnowledgeBatch(
    List<Map<String, dynamic>> items,
  ) async {
    try {
      if (items.isEmpty) return 0;

      int imported = 0;
      const batchSize = 200; // Process in batches to avoid timeouts (200 per batch for performance)

      for (int i = 0; i < items.length; i += batchSize) {
        final batch = items.skip(i).take(batchSize).toList();

        // Use individual upserts with conflict handling
        // Supabase Flutter SDK doesn't support onConflict directly, so we handle it manually
        for (final item in batch) {
          try {
            final data = Map<String, dynamic>.from(item);
            data['language'] = data['language'] ?? 'en';
            data['status'] = data['status'] ?? 'approved';
            data.remove('id');

            // Try to find existing by name (case-insensitive) and language
            final existing = await _supabase
                .from('exercise_knowledge')
                .select('id, name, language, short_desc, primary_muscles, equipment, how_to, secondary_muscles')
                .eq('language', data['language'] as String)
                .ilike('name', data['name'] as String)
                .maybeSingle();

            if (existing != null) {
              // Update only empty/null fields
              final updateData = <String, dynamic>{};
              
              final existingShortDesc = existing['short_desc'] as String?;
              final newShortDesc = data['short_desc'] as String?;
              if ((existingShortDesc == null || existingShortDesc.isEmpty) && 
                  (newShortDesc != null && newShortDesc.isNotEmpty)) {
                updateData['short_desc'] = newShortDesc;
              }
              
              final existingHowTo = existing['how_to'] as String?;
              final newHowTo = data['how_to'] as String?;
              if ((existingHowTo == null || existingHowTo.isEmpty) && 
                  (newHowTo != null && newHowTo.isNotEmpty)) {
                updateData['how_to'] = newHowTo;
              }
              
              final existingMuscles = existing['primary_muscles'] as List?;
              final newMuscles = data['primary_muscles'] as List?;
              if ((existingMuscles == null || existingMuscles.isEmpty) &&
                  (newMuscles != null && newMuscles.isNotEmpty)) {
                updateData['primary_muscles'] = newMuscles;
              }
              
              final existingSecMuscles = existing['secondary_muscles'] as List?;
              final newSecMuscles = data['secondary_muscles'] as List?;
              if ((existingSecMuscles == null || existingSecMuscles.isEmpty) &&
                  (newSecMuscles != null && newSecMuscles.isNotEmpty)) {
                updateData['secondary_muscles'] = newSecMuscles;
              }
              
              final existingEquipment = existing['equipment'] as List?;
              final newEquipment = data['equipment'] as List?;
              if ((existingEquipment == null || existingEquipment.isEmpty) &&
                  (newEquipment != null && newEquipment.isNotEmpty)) {
                updateData['equipment'] = newEquipment;
              }
              
              if (updateData.isNotEmpty) {
                await _supabase
                    .from('exercise_knowledge')
                    .update(updateData)
                    .eq('id', existing['id']);
              }
              imported++;
            } else {
              // Insert new - use insert with ignoreDuplicates or handle conflict
              try {
                await _supabase
                    .from('exercise_knowledge')
                    .insert(data);
                imported++;
              } catch (insertError) {
                // If duplicate key error, it's already there, skip
                if (insertError.toString().contains('duplicate') || 
                    insertError.toString().contains('unique')) {
                  debugPrint('⚠️ Duplicate exercise skipped: ${data['name']}');
                } else {
                  rethrow;
                }
              }
            }
          } catch (itemError) {
            debugPrint('❌ Error upserting item ${item['name']}: $itemError');
          }
        }
      }

      return imported;
    } catch (e) {
      debugPrint('❌ Error in batch upsert: $e');
      throw Exception('Failed to batch upsert exercises: $e');
    }
  }

  // =====================================================
  // INTENSIFIER KNOWLEDGE CRUD
  // =====================================================

  /// Search intensifiers with optional filters
  /// Now includes Arabic translation search via RPC function
  Future<List<Map<String, dynamic>>> searchIntensifiers({
    String? query,
    String? status,
    String? language,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Use RPC function for alias-aware search when query is provided
      // This includes Arabic translations
      if (query != null && query.isNotEmpty) {
        try {
          final response = await _supabase.rpc(
            'search_intensifiers_with_aliases',
            params: {
              'p_query': query,
              'p_status': status ?? 'approved',
              'p_language': language,
              'p_limit': limit,
              'p_offset': offset,
            },
          );
          
          return List<Map<String, dynamic>>.from(response ?? []);
        } catch (rpcError) {
          // Fallback to direct query if RPC function doesn't exist yet
          debugPrint('⚠️ RPC function not available, using direct query: $rpcError');
        }
      }
      
      // Fallback: Direct query (for backward compatibility or when no query)
      var request = _supabase
          .from('intensifier_knowledge')
          .select();

      // Filter by status (default: approved for non-admins)
      if (status != null) {
        request = request.eq('status', status);
      }

      // Filter by language
      if (language != null) {
        request = request.eq('language', language);
      }

      // Text search
      if (query != null && query.isNotEmpty) {
        request = request.or(
          'name.ilike.%$query%,short_desc.ilike.%$query%',
        );
      }

      // Apply ordering and pagination after filters
      final response = await request
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error searching intensifiers: $e');
      return [];
    }
  }

  /// Get intensifier by ID
  Future<Map<String, dynamic>?> getIntensifier(String id) async {
    try {
      final response = await _supabase
          .from('intensifier_knowledge')
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      debugPrint('❌ Error getting intensifier: $e');
      return null;
    }
  }

  /// Create intensifier (coaches/admins can create pending/draft)
  Future<Map<String, dynamic>> createIntensifier(
    Map<String, dynamic> data,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Ensure created_by is set
      data['created_by'] = user.id;

      // Default status to pending if not set
      if (!data.containsKey('status') || data['status'] == null) {
        data['status'] = 'pending';
      }

      final response = await _supabase
          .from('intensifier_knowledge')
          .insert(data)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('❌ Error creating intensifier: $e');
      throw Exception('Failed to create intensifier: $e');
    }
  }

  /// Update intensifier (admins can update all, coaches can update own pending/draft)
  Future<Map<String, dynamic>> updateIntensifier(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('intensifier_knowledge')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('❌ Error updating intensifier: $e');
      throw Exception('Failed to update intensifier: $e');
    }
  }

  /// Delete intensifier (admin only)
  Future<void> deleteIntensifier(String id) async {
    try {
      await _supabase.from('intensifier_knowledge').delete().eq('id', id);
    } catch (e) {
      debugPrint('❌ Error deleting intensifier: $e');
      throw Exception('Failed to delete intensifier: $e');
    }
  }

  /// Update intensifier status (approve/reject - admin only)
  Future<void> updateIntensifierStatus(String id, String status) async {
    try {
      await _supabase
          .from('intensifier_knowledge')
          .update({'status': status})
          .eq('id', id);
    } catch (e) {
      debugPrint('❌ Error updating intensifier status: $e');
      throw Exception('Failed to update intensifier status: $e');
    }
  }

  // =====================================================
  // HELPER: Check if user is admin
  // =====================================================

  Future<bool> isAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      return response != null && response['role'] == 'admin';
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');
      return false;
    }
  }

  // =====================================================
  // HELPER: Hydrate Arabic descriptions
  // =====================================================

  /// Hydrate Arabic descriptions from RPC response
  /// RPC already returns arabic_* fields, so we merge them into main fields
  List<Map<String, dynamic>> _hydrateArabicDescriptions(
    List<Map<String, dynamic>> results,
  ) {
    return results.map((exercise) {
      final arabicName = exercise['arabic_name'] as String?;
      final arabicShortDesc = exercise['arabic_short_desc'] as String?;
      final arabicHowTo = exercise['arabic_how_to'] as String?;
      final arabicCues = exercise['arabic_cues'] as List<dynamic>?;
      final arabicMistakes = exercise['arabic_common_mistakes'] as List<dynamic>?;

      // Replace English fields with Arabic if available (fallback to English)
      if (arabicName != null && arabicName.isNotEmpty) {
        exercise['name'] = arabicName;
      }
      if (arabicShortDesc != null && arabicShortDesc.isNotEmpty) {
        exercise['short_desc'] = arabicShortDesc;
      }
      if (arabicHowTo != null && arabicHowTo.isNotEmpty) {
        exercise['how_to'] = arabicHowTo;
      }
      if (arabicCues != null && arabicCues.isNotEmpty) {
        exercise['cues'] = arabicCues;
      }
      if (arabicMistakes != null && arabicMistakes.isNotEmpty) {
        exercise['common_mistakes'] = arabicMistakes;
      }

      // Remove arabic_* fields from response (cleanup)
      exercise.remove('arabic_name');
      exercise.remove('arabic_aliases');
      exercise.remove('arabic_short_desc');
      exercise.remove('arabic_how_to');
      exercise.remove('arabic_cues');
      exercise.remove('arabic_common_mistakes');

      return exercise;
    }).toList();
  }

  /// Hydrate Arabic descriptions by fetching from exercise_translations
  /// Used when RPC is not available or for fallback search
  Future<List<Map<String, dynamic>>> _hydrateArabicDescriptionsFromTranslations(
    List<Map<String, dynamic>> exercises,
  ) async {
    if (exercises.isEmpty) return exercises;

    try {
      final exerciseIds = exercises.map((e) => e['id'] as String).toList();

      // Fetch all Arabic translations in one query
      final translationsResponse = await _supabase
          .from('exercise_translations')
          .select('exercise_id, name, short_desc, how_to, cues, common_mistakes')
          .inFilter('exercise_id', exerciseIds)
          .eq('language', 'ar');

      if (translationsResponse.isEmpty) return exercises;

      // Create a map for quick lookup
      final translationsMap = <String, Map<String, dynamic>>{};
      for (final trans in translationsResponse) {
        translationsMap[trans['exercise_id'] as String] = trans;
      }

      // Merge Arabic translations into exercises
      return exercises.map((exercise) {
        final exerciseId = exercise['id'] as String;
        final translation = translationsMap[exerciseId];

        if (translation != null) {
          // Replace English fields with Arabic if available
          final arabicName = translation['name'] as String?;
          final arabicShortDesc = translation['short_desc'] as String?;
          final arabicHowTo = translation['how_to'] as String?;
          final arabicCues = translation['cues'] as List<dynamic>?;
          final arabicMistakes = translation['common_mistakes'] as List<dynamic>?;

          if (arabicName != null && arabicName.isNotEmpty) {
            exercise['name'] = arabicName;
          }
          if (arabicShortDesc != null && arabicShortDesc.isNotEmpty) {
            exercise['short_desc'] = arabicShortDesc;
          }
          if (arabicHowTo != null && arabicHowTo.isNotEmpty) {
            exercise['how_to'] = arabicHowTo;
          }
          if (arabicCues != null && arabicCues.isNotEmpty) {
            exercise['cues'] = arabicCues;
          }
          if (arabicMistakes != null && arabicMistakes.isNotEmpty) {
            exercise['common_mistakes'] = arabicMistakes;
          }
        }

        return exercise;
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error hydrating Arabic descriptions: $e');
      return exercises; // Return original if hydration fails
    }
  }

  /// Regenerate exercise-intensifier links (admin only)
  /// Calls RPC function to regenerate links for top exercises
  Future<Map<String, dynamic>> regenerateExerciseIntensifierLinks({
    int limit = 500,
  }) async {
    try {
      final response = await _supabase.rpc(
        'regenerate_exercise_intensifier_links',
        params: {'p_limit': limit},
      );

      if (response == null) {
        throw Exception('No response from server');
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('❌ Error regenerating exercise-intensifier links: $e');
      
      // Provide readable error messages
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('not authorized') || errorString.contains('admin')) {
        throw Exception('Admin access required to regenerate links');
      } else if (errorString.contains('invalid limit')) {
        throw Exception('Invalid limit: must be between 1 and 1000');
      } else {
        throw Exception('Failed to regenerate links: $e');
      }
    }
  }
}
