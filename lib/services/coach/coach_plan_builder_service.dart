import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _sb = Supabase.instance.client;

/// Represents a workout plan
class WorkoutPlan {
  final String id;
  final String coachId;
  final String title;
  final String? description;
  final String difficulty;
  final int durationWeeks;
  final bool isTemplate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalExercises;
  final double avgRating;
  final int usageCount;

  WorkoutPlan({
    required this.id,
    required this.coachId,
    required this.title,
    this.description,
    required this.difficulty,
    required this.durationWeeks,
    required this.isTemplate,
    required this.createdAt,
    required this.updatedAt,
    required this.totalExercises,
    required this.avgRating,
    required this.usageCount,
  });

  factory WorkoutPlan.fromMap(Map<String, dynamic> data) {
    return WorkoutPlan(
      id: data['id'] as String,
      coachId: data['coach_id'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      difficulty: data['difficulty'] as String? ?? 'Beginner',
      durationWeeks: (data['duration_weeks'] as num?)?.toInt() ?? 8,
      isTemplate: (data['is_template'] as bool?) ?? false,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
      totalExercises: (data['total_exercises'] as num?)?.toInt() ?? 0,
      avgRating: (data['avg_rating'] as num?)?.toDouble() ?? 0.0,
      usageCount: (data['usage_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Represents a nutrition plan
class NutritionPlan {
  final String id;
  final String coachId;
  final String title;
  final String? description;
  final String difficulty;
  final int durationWeeks;
  final bool isTemplate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalMeals;
  final double avgRating;
  final int usageCount;

  NutritionPlan({
    required this.id,
    required this.coachId,
    required this.title,
    this.description,
    required this.difficulty,
    required this.durationWeeks,
    required this.isTemplate,
    required this.createdAt,
    required this.updatedAt,
    required this.totalMeals,
    required this.avgRating,
    required this.usageCount,
  });

  factory NutritionPlan.fromMap(Map<String, dynamic> data) {
    return NutritionPlan(
      id: data['id'] as String,
      coachId: data['coach_id'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      difficulty: data['difficulty'] as String? ?? 'Beginner',
      durationWeeks: (data['duration_weeks'] as num?)?.toInt() ?? 8,
      isTemplate: (data['is_template'] as bool?) ?? false,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
      totalMeals: (data['total_meals'] as num?)?.toInt() ?? 0,
      avgRating: (data['avg_rating'] as num?)?.toDouble() ?? 0.0,
      usageCount: (data['usage_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Represents plan metrics for analytics
class PlanMetrics {
  final int totalWorkoutPlans;
  final int totalNutritionPlans;
  final int totalTemplates;
  final double avgPlanRating;
  final int totalAssignments;
  final int activeAssignments;

  PlanMetrics({
    required this.totalWorkoutPlans,
    required this.totalNutritionPlans,
    required this.totalTemplates,
    required this.avgPlanRating,
    required this.totalAssignments,
    required this.activeAssignments,
  });

  factory PlanMetrics.empty() {
    return PlanMetrics(
      totalWorkoutPlans: 0,
      totalNutritionPlans: 0,
      totalTemplates: 0,
      avgPlanRating: 0.0,
      totalAssignments: 0,
      activeAssignments: 0,
    );
  }
}

/// Service for managing coach's workout and nutrition plans
class CoachPlanBuilderService {
  static final CoachPlanBuilderService _instance = CoachPlanBuilderService._internal();
  factory CoachPlanBuilderService() => _instance;
  CoachPlanBuilderService._internal();

  // Cache for plans
  final Map<String, List<WorkoutPlan>> _workoutPlansCache = {};
  final Map<String, List<NutritionPlan>> _nutritionPlansCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 15);

  /// Get workout plans for a coach
  Future<List<WorkoutPlan>> getWorkoutPlans({
    required String coachId,
    String? searchQuery,
    String? difficultyFilter,
    bool? templateFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Check cache first
      final cacheKey = 'workout_${coachId}_${searchQuery ?? ''}_${difficultyFilter ?? ''}_${templateFilter ?? ''}';
      if (_workoutPlansCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
        final cached = _workoutPlansCache[cacheKey]!;
        return cached.skip(offset).take(limit).toList();
      }

      // Build query
      var query = _sb
          .from('workout_plans')
          .select('*')
          .eq('coach_id', coachId);

      // Apply filters
      if (difficultyFilter != null && difficultyFilter != 'all') {
        query = query.eq('difficulty', difficultyFilter);
      }

      if (templateFilter != null) {
        query = query.eq('is_template', templateFilter);
      }

      final response = await query
          .order('updated_at', ascending: false)
          .limit(limit + offset);

      // Process response
      final plans = <WorkoutPlan>[];
      for (final row in response as List<dynamic>) {
        // Get additional plan data
        final planData = await _getWorkoutPlanDetails(row['id'] as String);
        
        final plan = WorkoutPlan.fromMap({
          ...row,
          ...planData,
        });

        // Apply search filter
        if (searchQuery != null && searchQuery.isNotEmpty) {
          if (!plan.title.toLowerCase().contains(searchQuery.toLowerCase()) &&
              !(plan.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)) {
            continue;
          }
        }

        plans.add(plan);
      }

      // Cache results
      _workoutPlansCache[cacheKey] = plans;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return plans.skip(offset).take(limit).toList();
    } catch (e) {
      debugPrint('CoachPlanBuilderService: Error getting workout plans - $e');
      return [];
    }
  }

  /// Get nutrition plans for a coach
  Future<List<NutritionPlan>> getNutritionPlans({
    required String coachId,
    String? searchQuery,
    String? difficultyFilter,
    bool? templateFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Check cache first
      final cacheKey = 'nutrition_${coachId}_${searchQuery ?? ''}_${difficultyFilter ?? ''}_${templateFilter ?? ''}';
      if (_nutritionPlansCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
        final cached = _nutritionPlansCache[cacheKey]!;
        return cached.skip(offset).take(limit).toList();
      }

      // Build query
      var query = _sb
          .from('nutrition_plans')
          .select('*')
          .eq('coach_id', coachId);

      // Apply filters
      if (difficultyFilter != null && difficultyFilter != 'all') {
        query = query.eq('difficulty', difficultyFilter);
      }

      if (templateFilter != null) {
        query = query.eq('is_template', templateFilter);
      }

      final response = await query
          .order('updated_at', ascending: false)
          .limit(limit + offset);

      // Process response
      final plans = <NutritionPlan>[];
      for (final row in response as List<dynamic>) {
        // Get additional plan data
        final planData = await _getNutritionPlanDetails(row['id'] as String);
        
        final plan = NutritionPlan.fromMap({
          ...row,
          ...planData,
        });

        // Apply search filter
        if (searchQuery != null && searchQuery.isNotEmpty) {
          if (!plan.title.toLowerCase().contains(searchQuery.toLowerCase()) &&
              !(plan.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)) {
            continue;
          }
        }

        plans.add(plan);
      }

      // Cache results
      _nutritionPlansCache[cacheKey] = plans;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return plans.skip(offset).take(limit).toList();
    } catch (e) {
      debugPrint('CoachPlanBuilderService: Error getting nutrition plans - $e');
      return [];
    }
  }

  /// Get workout plan details including exercises and ratings
  Future<Map<String, dynamic>> _getWorkoutPlanDetails(String planId) async {
    try {
      // Get exercise count
      final exercisesResponse = await _sb
          .from('workout_plan_exercises')
          .select('id')
          .eq('plan_id', planId);

      final totalExercises = (exercisesResponse as List<dynamic>).length;

      // Get average rating
      final ratingsResponse = await _sb
          .from('plan_ratings')
          .select('rating')
          .eq('plan_id', planId)
          .eq('plan_type', 'workout');

      double avgRating = 0.0;
      if (ratingsResponse.isNotEmpty) {
        final ratings = ratingsResponse.map((r) => (r['rating'] as num).toDouble()).toList();
        avgRating = ratings.fold(0.0, (sum, rating) => sum + rating) / ratings.length;
      }

      // Get usage count
      final usageResponse = await _sb
          .from('plan_assignments')
          .select('id')
          .eq('plan_id', planId)
          .eq('plan_type', 'workout');

      final usageCount = (usageResponse as List<dynamic>).length;

      return {
        'total_exercises': totalExercises,
        'avg_rating': avgRating,
        'usage_count': usageCount,
      };
    } catch (e) {
      debugPrint('CoachPlanBuilderService: Error getting workout plan details - $e');
      return {
        'total_exercises': 0,
        'avg_rating': 0.0,
        'usage_count': 0,
      };
    }
  }

  /// Get nutrition plan details including meals and ratings
  Future<Map<String, dynamic>> _getNutritionPlanDetails(String planId) async {
    try {
      // Get meal count
      final mealsResponse = await _sb
          .from('nutrition_meals')
          .select('id')
          .eq('plan_id', planId);

      final totalMeals = (mealsResponse as List<dynamic>).length;

      // Get average rating
      final ratingsResponse = await _sb
          .from('plan_ratings')
          .select('rating')
          .eq('plan_id', planId)
          .eq('plan_type', 'nutrition');

      double avgRating = 0.0;
      if (ratingsResponse.isNotEmpty) {
        final ratings = ratingsResponse.map((r) => (r['rating'] as num).toDouble()).toList();
        avgRating = ratings.fold(0.0, (sum, rating) => sum + rating) / ratings.length;
      }

      // Get usage count
      final usageResponse = await _sb
          .from('plan_assignments')
          .select('id')
          .eq('plan_id', planId)
          .eq('plan_type', 'nutrition');

      final usageCount = (usageResponse as List<dynamic>).length;

      return {
        'total_meals': totalMeals,
        'avg_rating': avgRating,
        'usage_count': usageCount,
      };
    } catch (e) {
      debugPrint('CoachPlanBuilderService: Error getting nutrition plan details - $e');
      return {
        'total_meals': 0,
        'avg_rating': 0.0,
        'usage_count': 0,
      };
    }
  }

  /// Create a new workout plan
  Future<String?> createWorkoutPlan({
    required String coachId,
    required String title,
    String? description,
    String difficulty = 'Beginner',
    int durationWeeks = 8,
    bool isTemplate = false,
  }) async {
    try {
      final response = await _sb.from('workout_plans').insert({
        'coach_id': coachId,
        'title': title,
        'description': description,
        'difficulty': difficulty,
        'duration_weeks': durationWeeks,
        'is_template': isTemplate,
      }).select('id').single();

      // Clear cache
      _clearCacheForCoach(coachId);

      return response['id'] as String;
    } catch (e) {
      debugPrint('CoachPlanBuilderService: Error creating workout plan - $e');
      return null;
    }
  }

  /// Create a new nutrition plan
  Future<String?> createNutritionPlan({
    required String coachId,
    required String title,
    String? description,
    String difficulty = 'Beginner',
    int durationWeeks = 8,
    bool isTemplate = false,
  }) async {
    try {
      final response = await _sb.from('nutrition_plans').insert({
        'coach_id': coachId,
        'title': title,
        'description': description,
        'difficulty': difficulty,
        'duration_weeks': durationWeeks,
        'is_template': isTemplate,
      }).select('id').single();

      // Clear cache
      _clearCacheForCoach(coachId);

      return response['id'] as String;
    } catch (e) {
      debugPrint('CoachPlanBuilderService: Error creating nutrition plan - $e');
      return null;
    }
  }

  /// Update a workout plan
  Future<bool> updateWorkoutPlan({
    required String planId,
    required String coachId,
    String? title,
    String? description,
    String? difficulty,
    int? durationWeeks,
    bool? isTemplate,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (difficulty != null) updateData['difficulty'] = difficulty;
      if (durationWeeks != null) updateData['duration_weeks'] = durationWeeks;
      if (isTemplate != null) updateData['is_template'] = isTemplate;

      await _sb
          .from('workout_plans')
          .update(updateData)
          .eq('id', planId)
          .eq('coach_id', coachId);

      // Clear cache
      _clearCacheForCoach(coachId);

      return true;
    } catch (e) {
      debugPrint('CoachPlanBuilderService: Error updating workout plan - $e');
      return false;
    }
  }

  /// Update a nutrition plan
  Future<bool> updateNutritionPlan({
    required String planId,
    required String coachId,
    String? title,
    String? description,
    String? difficulty,
    int? durationWeeks,
    bool? isTemplate,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (difficulty != null) updateData['difficulty'] = difficulty;
      if (durationWeeks != null) updateData['duration_weeks'] = durationWeeks;
      if (isTemplate != null) updateData['is_template'] = isTemplate;

      await _sb
          .from('nutrition_plans')
          .update(updateData)
          .eq('id', planId)
          .eq('coach_id', coachId);

      // Clear cache
      _clearCacheForCoach(coachId);

      return true;
    } catch (e) {
      debugPrint('CoachPlanBuilderService: Error updating nutrition plan - $e');
      return false;
    }
  }

  /// Delete a workout plan
  Future<bool> deleteWorkoutPlan({
    required String planId,
    required String coachId,
  }) async {
    try {
      await _sb
          .from('workout_plans')
          .delete()
          .eq('id', planId)
          .eq('coach_id', coachId);

      // Clear cache
      _clearCacheForCoach(coachId);

      return true;
    } catch (e) {
      debugPrint('CoachPlanBuilderService: Error deleting workout plan - $e');
      return false;
    }
  }

  /// Delete a nutrition plan
  Future<bool> deleteNutritionPlan({
    required String planId,
    required String coachId,
  }) async {
    try {
      await _sb
          .from('nutrition_plans')
          .delete()
          .eq('id', planId)
          .eq('coach_id', coachId);

      // Clear cache
      _clearCacheForCoach(coachId);

      return true;
    } catch (e) {
      debugPrint('CoachPlanBuilderService: Error deleting nutrition plan - $e');
      return false;
    }
  }

  /// Get plan metrics for a coach
  Future<PlanMetrics> getPlanMetrics(String coachId) async {
    try {
      // Get workout plans count
      final workoutPlansResponse = await _sb
          .from('workout_plans')
          .select('id')
          .eq('coach_id', coachId);

      final totalWorkoutPlans = (workoutPlansResponse as List<dynamic>).length;

      // Get nutrition plans count
      final nutritionPlansResponse = await _sb
          .from('nutrition_plans')
          .select('id')
          .eq('coach_id', coachId);

      final totalNutritionPlans = (nutritionPlansResponse as List<dynamic>).length;

      // Get templates count
      final templatesResponse = await _sb
          .from('workout_plans')
          .select('id')
          .eq('coach_id', coachId)
          .eq('is_template', true);

      final nutritionTemplatesResponse = await _sb
          .from('nutrition_plans')
          .select('id')
          .eq('coach_id', coachId)
          .eq('is_template', true);

      final totalTemplates = (templatesResponse as List<dynamic>).length + 
                           (nutritionTemplatesResponse as List<dynamic>).length;

      // Get assignments count
      final assignmentsResponse = await _sb
          .from('plan_assignments')
          .select('id, status')
          .eq('assigned_by', coachId);

      final totalAssignments = (assignmentsResponse as List<dynamic>).length;
      final activeAssignments = assignmentsResponse
          .where((a) => a['status'] == 'active')
          .length;

      // Calculate average rating
      final ratingsResponse = await _sb
          .from('plan_ratings')
          .select('rating')
          .inFilter('plan_id', [
            ...workoutPlansResponse.map((p) => p['id']),
            ...nutritionPlansResponse.map((p) => p['id']),
          ]);

      double avgPlanRating = 0.0;
      if (ratingsResponse.isNotEmpty) {
        final ratings = ratingsResponse.map((r) => (r['rating'] as num).toDouble()).toList();
        avgPlanRating = ratings.fold(0.0, (sum, rating) => sum + rating) / ratings.length;
      }

      return PlanMetrics(
        totalWorkoutPlans: totalWorkoutPlans,
        totalNutritionPlans: totalNutritionPlans,
        totalTemplates: totalTemplates,
        avgPlanRating: avgPlanRating,
        totalAssignments: totalAssignments,
        activeAssignments: activeAssignments,
      );
    } catch (e) {
      debugPrint('CoachPlanBuilderService: Error getting plan metrics - $e');
      return PlanMetrics.empty();
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Clear cache for a specific coach
  void _clearCacheForCoach(String coachId) {
    _workoutPlansCache.removeWhere((key, value) => key.contains(coachId));
    _nutritionPlansCache.removeWhere((key, value) => key.contains(coachId));
    _cacheTimestamps.removeWhere((key, value) => key.contains(coachId));
  }

  /// Clear all cache
  void clearAllCache() {
    _workoutPlansCache.clear();
    _nutritionPlansCache.clear();
    _cacheTimestamps.clear();
  }
}
