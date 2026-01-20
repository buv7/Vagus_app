import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/exercise_library_data.dart';
import '../../models/workout/exercise_library_models.dart';

/// Service for fetching distinct metadata values from workout/exercise tables
/// 
/// Provides cached access to:
/// - Difficulty levels
/// - Group types
/// - Workout goals
/// - Equipment types
/// - Primary muscle groups
/// 
/// All methods include fallback to local seed data if DB query fails
class WorkoutMetadataService {
  static final WorkoutMetadataService _instance = WorkoutMetadataService._internal();
  factory WorkoutMetadataService() => _instance;
  WorkoutMetadataService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache with TTL (30 minutes for metadata, 10 minutes for exercise library)
  static const Duration _cacheTTL = Duration(minutes: 30);
  static const Duration _exerciseLibraryCacheTTL = Duration(minutes: 10);
  
  final Map<String, List<String>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Exercise library cache (by query key)
  final Map<String, List<ExerciseLibraryItem>> _exerciseLibraryCache = {};
  final Map<String, DateTime> _exerciseLibraryCacheTimestamps = {};
  
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    final age = DateTime.now().difference(_cacheTimestamps[key]!);
    return age < _cacheTTL;
  }
  
  void _setCache(String key, List<String> data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }
  
  List<String>? _getCache(String key) {
    if (_isCacheValid(key)) {
      return _cache[key];
    }
    return null;
  }

  /// Get distinct difficulty levels from exercises_library
  /// Falls back to seed data if DB query fails
  Future<List<String>> getDistinctLibraryDifficulties() async {
    const cacheKey = 'library_difficulties';
    
    // Check cache
    final cached = _getCache(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _supabase
          .from('exercises_library')
          .select('difficulty')
          .not('difficulty', 'is', null)
          .order('difficulty');

      final difficulties = (response as List<dynamic>)
          .map((row) => row['difficulty'] as String)
          .toSet() // Remove duplicates
          .toList()
        ..sort(); // Sort alphabetically

      // Cache result
      _setCache(cacheKey, difficulties);
      
      return difficulties.isNotEmpty 
          ? difficulties 
          : _getDefaultDifficulties(); // Fallback if empty
    } catch (e) {
      // Fallback to defaults on error
      return _getDefaultDifficulties();
    }
  }

  /// Get distinct group types from exercise_groups table
  /// Falls back to known enum values if DB query fails
  Future<List<String>> getDistinctGroupTypes() async {
    const cacheKey = 'group_types';
    
    // Check cache
    final cached = _getCache(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _supabase
          .from('exercise_groups')
          .select('type')
          .order('type');

      final types = (response as List<dynamic>)
          .map((row) => row['type'] as String)
          .toSet() // Remove duplicates
          .toList()
        ..sort(); // Sort alphabetically

      // Cache result
      _setCache(cacheKey, types);
      
      return types.isNotEmpty 
          ? types 
          : _getDefaultGroupTypes(); // Fallback if empty
    } catch (e) {
      // Fallback to defaults on error
      return _getDefaultGroupTypes();
    }
  }

  /// Get distinct workout goals from workout_plans table
  /// Falls back to known values if DB query fails
  Future<List<String>> getDistinctWorkoutGoals() async {
    const cacheKey = 'workout_goals';
    
    // Check cache
    final cached = _getCache(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _supabase
          .from('workout_plans')
          .select('goal')
          .not('goal', 'is', null)
          .order('goal');

      final goals = (response as List<dynamic>)
          .map((row) => row['goal'] as String)
          .toSet() // Remove duplicates
          .toList()
        ..sort(); // Sort alphabetically

      // Cache result
      _setCache(cacheKey, goals);
      
      return goals.isNotEmpty 
          ? goals 
          : _getDefaultWorkoutGoals(); // Fallback if empty
    } catch (e) {
      // Fallback to defaults on error
      return _getDefaultWorkoutGoals();
    }
  }

  /// Get distinct equipment types from exercises_library (equipment_needed array)
  /// Falls back to seed data if DB query fails
  Future<List<String>> getDistinctEquipment() async {
    const cacheKey = 'equipment';
    
    // Check cache
    final cached = _getCache(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      // Query all exercises and flatten equipment_needed arrays
      final response = await _supabase
          .from('exercises_library')
          .select('equipment_needed')
          .not('equipment_needed', 'is', null);

      final equipmentSet = <String>{};
      for (final row in response as List<dynamic>) {
        final equipmentList = row['equipment_needed'] as List<dynamic>?;
        if (equipmentList != null) {
          equipmentSet.addAll(
            equipmentList.map((e) => e.toString()),
          );
        }
      }

      final equipment = equipmentSet.toList()..sort();

      // Cache result
      _setCache(cacheKey, equipment);
      
      return equipment.isNotEmpty 
          ? equipment 
          : _getDefaultEquipment(); // Fallback if empty
    } catch (e) {
      // Fallback to defaults on error
      return _getDefaultEquipment();
    }
  }

  /// Get exercise library items from exercises_library table
  /// Falls back to seed data if DB query fails or returns empty
  /// [DEPRECATED] Use getExerciseLibraryPaginated for pagination support
  Future<List<ExerciseLibraryItem>> getExerciseLibrary({
    String? search,
    List<String>? muscles,
    List<String>? equipment,
    int limit = 200,
  }) async {
    // Create cache key from query parameters
    final cacheKey = 'library_${search ?? ''}_${muscles?.join(',') ?? ''}_${equipment?.join(',') ?? ''}_$limit';
    
    // Check cache
    if (_exerciseLibraryCache.containsKey(cacheKey) && 
        _exerciseLibraryCacheTimestamps.containsKey(cacheKey)) {
      final age = DateTime.now().difference(_exerciseLibraryCacheTimestamps[cacheKey]!);
      if (age < _exerciseLibraryCacheTTL) {
        return _exerciseLibraryCache[cacheKey]!;
      }
    }

    try {
      var query = _supabase
          .from('exercises_library')
          .select();

      // Apply search filter (name ilike)
      if (search != null && search.isNotEmpty) {
        query = query.ilike('name', '%$search%');
      }

      // Apply muscle group filter (muscle_group is TEXT, not array in DB)
      if (muscles != null && muscles.isNotEmpty) {
        query = query.inFilter('muscle_group', muscles);
      }

      // Apply equipment filter (equipment_needed is TEXT[] array)
      if (equipment != null && equipment.isNotEmpty) {
        // Use array overlap operator: && (overlap)
        // This requires a raw SQL filter or using .contains() for each equipment
        // For simplicity, filter in memory after fetch (PostgreSQL array overlap is complex via client)
        // We'll filter after fetching for now
      }

      final response = await query.order('name').limit(limit);

      List<ExerciseLibraryItem> items = (response as List<dynamic>)
          .map((row) {
            // Convert DB row to map format expected by ExerciseLibraryItem.fromMap
            // DB has: muscle_group (TEXT), difficulty (TEXT), equipment_needed (TEXT[])
            // Model expects: primary_muscle_groups (array), category, difficulty_level
            final muscleGroup = row['muscle_group'] as String? ?? '';
            final primaryMuscleGroups = muscleGroup.isNotEmpty ? [muscleGroup] : [];
            
            // Create map with proper field mappings
            final mappedRow = <String, dynamic>{
              'id': row['id'],
              'name': row['name'],
              'name_ar': row['name_ar'],
              'name_ku': row['name_ku'],
              'category': muscleGroup.isNotEmpty ? muscleGroup : 'unknown', // Use muscle_group as category
              'primary_muscle_groups': primaryMuscleGroups,
              'secondary_muscle_groups': row['secondary_muscles'] ?? [],
              'equipment_needed': row['equipment_needed'] ?? [],
              'difficulty_level': row['difficulty'], // Map difficulty -> difficulty_level
              'instructions': row['description'], // Map description -> instructions
              'instructions_ar': null,
              'instructions_ku': null,
              'video_url': row['video_url'],
              'thumbnail_url': row['thumbnail_url'] ?? row['image_url'],
              'created_by': row['created_by'],
              'is_public': true, // Default to public
              'usage_count': 0, // Default to 0
              'created_at': row['created_at']?.toString(),
              'updated_at': row['updated_at']?.toString(),
              'tags': row['tags'],
            };
            
            return ExerciseLibraryItem.fromMap(mappedRow);
          })
          .toList();

      // Filter by equipment if needed (in memory, as array overlap is complex)
      if (equipment != null && equipment.isNotEmpty) {
        items = items.where((item) {
          // Check if any of the requested equipment is in the item's equipment_needed array
          return item.equipmentNeeded.any((eq) => equipment.contains(eq));
        }).toList();
      }

      // Cache result
      _exerciseLibraryCache[cacheKey] = items;
      _exerciseLibraryCacheTimestamps[cacheKey] = DateTime.now();

      // Fallback to seed data if empty
      if (items.isEmpty) {
        return _getFallbackExerciseLibrary();
      }

      return items;
    } catch (e) {
      // Fallback to seed data on error
      return _getFallbackExerciseLibrary();
    }
  }

  /// Get exercise library items with pagination support
  /// Returns a list of exercises for the specified page
  /// Does NOT cache paginated results to avoid stale data
  /// 
  /// Tries `exercises_library` first, falls back to `exercise_knowledge` if table doesn't exist
  Future<List<ExerciseLibraryItem>> getExerciseLibraryPaginated({
    String? search,
    List<String>? muscles,
    List<String>? equipment,
    int page = 0,
    int pageSize = 50,
  }) async {
    // Try exercises_library first
    try {
      return await _getExerciseLibraryPaginatedFromTable(
        'exercises_library',
        search: search,
        muscles: muscles,
        equipment: equipment,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      // If exercises_library doesn't exist, try exercise_knowledge as fallback
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('does not exist') || 
          errorStr.contains('relation') && errorStr.contains('not found')) {
        try {
          return await _getExerciseLibraryPaginatedFromTable(
            'exercise_knowledge',
            search: search,
            muscles: muscles,
            equipment: equipment,
            page: page,
            pageSize: pageSize,
          );
        } catch (e2) {
          // Re-throw original error with helpful message
          throw Exception(
            'Exercise library table not found. Please run migration to create exercises_library table. '
            'Original error: $e'
          );
        }
      }
      // Re-throw other errors
      rethrow;
    }
  }

  /// Internal method to fetch exercises from a specific table
  Future<List<ExerciseLibraryItem>> _getExerciseLibraryPaginatedFromTable(
    String tableName, {
    String? search,
    List<String>? muscles,
    List<String>? equipment,
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      var query = _supabase
          .from(tableName)
          .select();

      // Apply search filter (name ilike) - ONLY if search is not null and not empty
      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('name', '%${search.trim()}%');
      }

      // Apply muscle group filter
      // exercises_library uses: muscle_group (TEXT)
      // exercise_knowledge uses: primary_muscles (TEXT[])
      if (muscles != null && muscles.isNotEmpty) {
        if (tableName == 'exercise_knowledge') {
          // For exercise_knowledge, use array overlap on primary_muscles
          query = query.overlaps('primary_muscles', muscles);
        } else {
          // For exercises_library, use inFilter on muscle_group (TEXT)
          query = query.inFilter('muscle_group', muscles);
        }
      }

      // Apply equipment filter at database level using array overlap (&& operator)
      // This uses the GIN index for efficient filtering on large datasets
      // ONLY if equipment is not null and not empty
      if (equipment != null && equipment.isNotEmpty) {
        if (tableName == 'exercise_knowledge') {
          // exercise_knowledge uses 'equipment' (TEXT[])
          query = query.overlaps('equipment', equipment);
        } else {
          // exercises_library uses 'equipment_needed' (TEXT[])
          query = query.overlaps('equipment_needed', equipment);
        }
      }

      // Calculate offset for pagination
      final offset = page * pageSize;

      // Apply pagination
      final response = await query
          .order('name')
          .range(offset, offset + pageSize - 1);

      List<ExerciseLibraryItem> items = (response as List<dynamic>)
          .map((row) {
            // Convert DB row to map format expected by ExerciseLibraryItem.fromMap
            // Handle both exercises_library and exercise_knowledge schemas
            if (tableName == 'exercise_knowledge') {
              // exercise_knowledge schema
              final primaryMuscles = (row['primary_muscles'] as List<dynamic>?) ?? [];
              final primaryMuscleGroups = primaryMuscles.map((e) => e.toString()).toList();
              final category = primaryMuscleGroups.isNotEmpty 
                  ? primaryMuscleGroups.first 
                  : 'unknown';
              
              // Extract media from JSONB
              final media = row['media'] as Map<String, dynamic>? ?? {};
              
              final mappedRow = <String, dynamic>{
                'id': row['id'],
                'name': row['name'],
                'name_ar': null,
                'name_ku': null,
                'category': category,
                'primary_muscle_groups': primaryMuscleGroups,
                'secondary_muscle_groups': (row['secondary_muscles'] as List<dynamic>?) 
                    ?.map((e) => e.toString()).toList() ?? [],
                'equipment_needed': (row['equipment'] as List<dynamic>?) 
                    ?.map((e) => e.toString()).toList() ?? [],
                'difficulty_level': row['difficulty'],
                'instructions': row['how_to'] ?? row['short_desc'],
                'instructions_ar': null,
                'instructions_ku': null,
                'video_url': media['video_url'],
                'thumbnail_url': media['image_url'] ?? media['thumbnail_url'],
                'created_by': row['created_by'],
                'is_public': true,
                'usage_count': 0,
                'created_at': row['created_at']?.toString(),
                'updated_at': row['updated_at']?.toString(),
                'tags': [],
              };
              
              return ExerciseLibraryItem.fromMap(mappedRow);
            } else {
              // exercises_library schema
              final muscleGroup = row['muscle_group'] as String? ?? '';
              final primaryMuscleGroups = muscleGroup.isNotEmpty ? [muscleGroup] : [];
              
              final mappedRow = <String, dynamic>{
                'id': row['id'],
                'name': row['name'],
                'name_ar': row['name_ar'],
                'name_ku': row['name_ku'],
                'category': muscleGroup.isNotEmpty ? muscleGroup : 'unknown',
                'primary_muscle_groups': primaryMuscleGroups,
                'secondary_muscle_groups': row['secondary_muscles'] ?? [],
                'equipment_needed': row['equipment_needed'] ?? [],
                'difficulty_level': row['difficulty'],
                'instructions': row['description'],
                'instructions_ar': null,
                'instructions_ku': null,
                'video_url': row['video_url'],
                'thumbnail_url': row['thumbnail_url'] ?? row['image_url'],
                'created_by': row['created_by'],
                'is_public': true,
                'usage_count': 0,
                'created_at': row['created_at']?.toString(),
                'updated_at': row['updated_at']?.toString(),
                'tags': row['tags'],
              };
              
              return ExerciseLibraryItem.fromMap(mappedRow);
            }
          })
          .toList();

      return items;
    } catch (e) {
      // Re-throw error so caller can handle it properly
      rethrow;
    }
  }

  /// Get total count of exercises matching filters (for pagination)
  /// Returns null to indicate count is unknown - UI should show loaded count instead
  /// This method exists for API compatibility but doesn't fetch actual count
  /// due to Supabase client limitations with count queries
  Future<int?> getExerciseLibraryCount({
    String? search,
    List<String>? muscles,
    List<String>? equipment,
  }) async {
    // Supabase Flutter client doesn't easily expose count from query responses
    // For performance, we skip count fetching - UI will show loaded count instead
    return null;
  }

  /// Get distinct primary muscle groups from exercises_library
  /// Falls back to seed data if DB query fails
  Future<List<String>> getDistinctPrimaryMuscles() async {
    const cacheKey = 'primary_muscles';
    
    // Check cache
    final cached = _getCache(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _supabase
          .from('exercises_library')
          .select('muscle_group')
          .order('muscle_group');

      final muscles = (response as List<dynamic>)
          .map((row) => row['muscle_group'] as String)
          .toSet() // Remove duplicates
          .toList()
        ..sort(); // Sort alphabetically

      // Cache result
      _setCache(cacheKey, muscles);
      
      return muscles.isNotEmpty 
          ? muscles 
          : _getDefaultMuscleGroups(); // Fallback if empty
    } catch (e) {
      // Fallback to defaults on error
      return _getDefaultMuscleGroups();
    }
  }

  /// Clear all cached data (useful for testing or manual refresh)
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _exerciseLibraryCache.clear();
    _exerciseLibraryCacheTimestamps.clear();
  }

  /// Clear specific cache entry
  void clearCacheEntry(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }
  
  /// Clear exercise library cache
  void clearExerciseLibraryCache() {
    _exerciseLibraryCache.clear();
    _exerciseLibraryCacheTimestamps.clear();
  }

  // =====================================================
  // FALLBACK DEFAULTS (from seed data)
  // =====================================================

  List<String> _getDefaultDifficulties() {
    return ['beginner', 'intermediate', 'advanced'];
  }

  List<String> _getDefaultGroupTypes() {
    // Known enum values from ExerciseGroupType (excluding 'none' and 'unknown')
    return ['circuit', 'drop_set', 'giant_set', 'rest_pause', 'superset'];
  }

  List<String> _getDefaultWorkoutGoals() {
    // Known values from database CHECK constraint (before removal)
    return [
      'endurance',
      'general_fitness',
      'hypertrophy',
      'powerlifting',
      'strength',
      'weight_loss',
    ];
  }

  List<String> _getDefaultEquipment() {
    // From ExerciseLibraryData.equipmentTypes (excluding 'All')
    final seedEquipment = ExerciseLibraryData.equipmentTypes;
    return seedEquipment.where((e) => e != 'All').toList();
  }

  List<String> _getDefaultMuscleGroups() {
    // From ExerciseLibraryData.muscleGroups
    return ExerciseLibraryData.muscleGroups;
  }

  /// Convert seed ExerciseTemplate data to ExerciseLibraryItem for fallback
  List<ExerciseLibraryItem> _getFallbackExerciseLibrary() {
    final templates = ExerciseLibraryData.getAllExercises();
    return templates.map((template) {
      return ExerciseLibraryItem(
        id: null,
        name: template.name,
        category: template.muscleGroup.toLowerCase(), // Use muscle group as category
        primaryMuscleGroups: [template.muscleGroup],
        equipmentNeeded: [template.equipment],
        difficultyLevel: template.difficulty.toLowerCase(),
        isPublic: true,
        usageCount: 0,
      );
    }).toList();
  }
}
