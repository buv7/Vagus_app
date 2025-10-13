import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/program_ingest/program_ingest_job.dart';

class ProgramApplyService {
  static final ProgramApplyService _instance = ProgramApplyService._internal();
  factory ProgramApplyService() => _instance;
  ProgramApplyService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Apply parsed program data to a client
  Future<Map<String, int>> apply(ProgramIngestResult result, String clientId) async {
    final counts = <String, int>{
      'notes': 0,
      'supplements': 0,
      'nutrition_plans': 0,
      'workout_plans': 0,
    };

    try {
      // Start a transaction-like operation by batching operations
      final operations = <Future<void>>[];

      // 1. Apply notes
      if (result.notes != null && result.notes!.isNotEmpty) {
        operations.add(_applyNotes(result.notes!, clientId).then((count) {
          counts['notes'] = count;
        }));
      }

      // 2. Apply supplements
      if (result.supplements.isNotEmpty) {
        operations.add(_applySupplements(result.supplements, clientId).then((count) {
          counts['supplements'] = count;
        }));
      }

      // 3. Apply nutrition plan
      if (result.nutritionPlan != null) {
        operations.add(_applyNutritionPlan(result.nutritionPlan!, clientId).then((count) {
          counts['nutrition_plans'] = count;
        }));
      }

      // 4. Apply workout plan
      if (result.workoutPlan != null) {
        operations.add(_applyWorkoutPlan(result.workoutPlan!, clientId).then((count) {
          counts['workout_plans'] = count;
        }));
      }

      // Wait for all operations to complete
      await Future.wait(operations);

      return counts;
    } catch (e) {
      debugPrint('Error applying program: $e');
      rethrow;
    }
  }

  /// Apply notes to client
  Future<int> _applyNotes(String notes, String clientId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('client_notes').insert({
        'client_id': clientId,
        'coach_id': user.id,
        'title': 'Program Notes',
        'content': notes,
      });

      return 1;
    } catch (e) {
      debugPrint('Error applying notes: $e');
      return 0;
    }
  }

  /// Apply supplements to client
  Future<int> _applySupplements(List<Map<String, dynamic>> supplements, String clientId) async {
    try {
      if (supplements.isEmpty) return 0;

      final supplementData = supplements.map((supp) => {
        'client_id': clientId,
        'name': supp['name'] ?? 'Unknown Supplement',
        'dosage': supp['dosage'],
        'timing': supp['timing'],
        'notes': supp['notes'],
      }).toList();

      await _supabase.from('supplements').insert(supplementData);
      return supplements.length;
    } catch (e) {
      debugPrint('Error applying supplements: $e');
      return 0;
    }
  }

  /// Apply nutrition plan to client
  Future<int> _applyNutritionPlan(Map<String, dynamic> nutritionPlan, String clientId) async {
    try {
      // Check if nutrition_plans table exists and has the right structure
      // For now, we'll store it as a JSON in a simple table
      // This can be enhanced later to create proper nutrition plan records
      
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Try to insert into nutrition_plans table if it exists
      try {
        await _supabase.from('nutrition_plans').insert({
          'client_id': clientId,
          'coach_id': user.id,
          'name': 'Imported Nutrition Plan',
          'plan_data': nutritionPlan,
          'is_active': true,
        });
        return 1;
      } catch (e) {
        // If nutrition_plans table doesn't exist or has different structure,
        // store as a note instead
        debugPrint('Nutrition plans table not available, storing as note: $e');
        await _supabase.from('client_notes').insert({
          'client_id': clientId,
          'coach_id': user.id,
          'title': 'Nutrition Plan',
          'content': 'Nutrition Plan Data:\n${nutritionPlan.toString()}',
        });
        return 1;
      }
    } catch (e) {
      debugPrint('Error applying nutrition plan: $e');
      return 0;
    }
  }

  /// Apply workout plan to client
  Future<int> _applyWorkoutPlan(Map<String, dynamic> workoutPlan, String clientId) async {
    try {
      // Check if workout_plans table exists and has the right structure
      // For now, we'll store it as a JSON in a simple table
      // This can be enhanced later to create proper workout plan records
      
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Try to insert into workout_plans table if it exists
      try {
        final result = await _supabase.rpc('create_workout_plan', params: {
          'plan_name': 'Imported Workout Plan',
          'plan_description': 'Workout plan imported from program',
          'plan_created_by': user.id,
          'plan_client_id': clientId,
          'plan_coach_id': user.id,
          'plan_duration_weeks': 4,
          'plan_is_template': false,
          'plan_status': 'active',
          'plan_metadata': {'imported_plan_data': workoutPlan},
        });
        
        if (result['success'] == true) {
          return 1;
        } else {
          throw Exception('Failed to create workout plan: ${result['error']}');
        }
      } catch (e) {
        // If workout_plans table doesn't exist or has different structure,
        // store as a note instead
        debugPrint('Workout plans table not available, storing as note: $e');
        await _supabase.from('client_notes').insert({
          'client_id': clientId,
          'coach_id': user.id,
          'title': 'Workout Plan',
          'content': 'Workout Plan Data:\n${workoutPlan.toString()}',
        });
        return 1;
      }
    } catch (e) {
      debugPrint('Error applying workout plan: $e');
      return 0;
    }
  }

  /// Get applied notes for a client
  Future<List<Map<String, dynamic>>> getClientNotes(String clientId) async {
    try {
      final response = await _supabase
          .from('client_notes')
          .select('*')
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching client notes: $e');
      return [];
    }
  }

  /// Get applied supplements for a client
  Future<List<Map<String, dynamic>>> getClientSupplements(String clientId) async {
    try {
      final response = await _supabase
          .from('supplements')
          .select('*')
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching client supplements: $e');
      return [];
    }
  }
}
