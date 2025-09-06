import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/periods/coach_client_period.dart';

class PeriodsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get the active period for a coach-client pair
  Future<CoachClientPeriod?> getActivePeriod(String coachId, String clientId) async {
    try {
      final response = await _supabase
          .from('coach_client_periods')
          .select()
          .eq('coach_id', coachId)
          .eq('client_id', clientId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return CoachClientPeriod.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch active period: $e');
    }
  }

  /// Get all periods for a coach-client pair
  Future<List<CoachClientPeriod>> getPeriods(String coachId, String clientId) async {
    try {
      final response = await _supabase
          .from('coach_client_periods')
          .select()
          .eq('coach_id', coachId)
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((period) => CoachClientPeriod.fromMap(period as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch periods: $e');
    }
  }

  /// Create a new period for a coach-client pair
  Future<String> createPeriod({
    required String coachId,
    required String clientId,
    required DateTime startDate,
    required int durationWeeks,
  }) async {
    try {
      final data = {
        'coach_id': coachId,
        'client_id': clientId,
        'start_date': startDate.toIso8601String().split('T')[0], // Date only
        'duration_weeks': durationWeeks,
      };

      final response = await _supabase
          .from('coach_client_periods')
          .insert(data)
          .select()
          .single();

      return response['id']?.toString() ?? '';
    } catch (e) {
      throw Exception('Failed to create period: $e');
    }
  }

  /// Update an existing period
  Future<void> updatePeriod(CoachClientPeriod period) async {
    try {
      final data = period.toMap();
      data.remove('id'); // Don't update the ID
      data.remove('created_at'); // Don't update created_at

      await _supabase
          .from('coach_client_periods')
          .update(data)
          .eq('id', period.id);
    } catch (e) {
      throw Exception('Failed to update period: $e');
    }
  }

  /// Delete a period
  Future<void> deletePeriod(String periodId) async {
    try {
      await _supabase
          .from('coach_client_periods')
          .delete()
          .eq('id', periodId);
    } catch (e) {
      throw Exception('Failed to delete period: $e');
    }
  }

  /// Get all periods for a coach (across all clients)
  Future<List<CoachClientPeriod>> getPeriodsForCoach(String coachId) async {
    try {
      final response = await _supabase
          .from('coach_client_periods')
          .select()
          .eq('coach_id', coachId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((period) => CoachClientPeriod.fromMap(period as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch coach periods: $e');
    }
  }

  /// Get all periods for a client (across all coaches)
  Future<List<CoachClientPeriod>> getPeriodsForClient(String clientId) async {
    try {
      final response = await _supabase
          .from('coach_client_periods')
          .select()
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((period) => CoachClientPeriod.fromMap(period as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch client periods: $e');
    }
  }

  /// Get period statistics for a coach
  Future<Map<String, dynamic>> getCoachPeriodStats(String coachId) async {
    try {
      final periods = await getPeriodsForCoach(coachId);
      
      final activePeriods = periods.where((p) => p.isActive).length;
      final completedPeriods = periods.where((p) => p.hasEnded).length;
      final totalClients = periods.map((p) => p.clientId).toSet().length;
      
      return {
        'total_periods': periods.length,
        'active_periods': activePeriods,
        'completed_periods': completedPeriods,
        'total_clients': totalClients,
      };
    } catch (e) {
      throw Exception('Failed to fetch coach period stats: $e');
    }
  }
}
