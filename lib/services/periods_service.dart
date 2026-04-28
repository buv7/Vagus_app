import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/periods/coach_client_period.dart';
import '../models/periods/cycle_phase.dart';
import '../models/periods/cycle_prediction.dart';
import '../models/periods/flow_level.dart';
import '../models/periods/menstrual_cycle.dart';
import '../models/periods/period_log.dart';
import '../models/periods/period_symptom.dart';
import 'periods/cycle_prediction_engine.dart';

class PeriodsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const _engine = CyclePredictionEngine();

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

  // =========================================================================
  // MENSTRUAL HEALTH — consent
  // =========================================================================

  /// Returns true if the current user has opted in to period tracking.
  Future<bool> hasPeriodTrackingConsent() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final row = await _supabase
          .from('period_tracking_consent')
          .select('opted_in')
          .eq('user_id', user.id)
          .maybeSingle();

      return row?['opted_in'] as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to check period tracking consent: $e');
    }
  }

  /// Returns true if the user has also consented to sharing data with their coach.
  Future<bool> hasCoachShareConsent() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final row = await _supabase
          .from('period_tracking_consent')
          .select('opted_in, coach_share')
          .eq('user_id', user.id)
          .maybeSingle();

      if (row == null) return false;
      return (row['opted_in'] as bool? ?? false) &&
          (row['coach_share'] as bool? ?? false);
    } catch (e) {
      throw Exception('Failed to check coach share consent: $e');
    }
  }

  /// Opts the current user in to period tracking.
  /// [coachShare] defaults to false — must be explicitly set to true.
  Future<void> grantPeriodTrackingConsent({bool coachShare = false}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase.from('period_tracking_consent').upsert(
        {
          'user_id': user.id,
          'opted_in': true,
          'opted_in_at': now,
          'opted_out_at': null,
          'coach_share': coachShare,
          'coach_share_updated_at': coachShare ? now : null,
          'updated_at': now,
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      throw Exception('Failed to grant period tracking consent: $e');
    }
  }

  /// Updates just the coach_share flag without touching opted_in.
  Future<void> setCoachShareConsent(bool coachShare) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase.from('period_tracking_consent').upsert(
        {
          'user_id': user.id,
          'coach_share': coachShare,
          'coach_share_updated_at': now,
          'updated_at': now,
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      throw Exception('Failed to update coach share consent: $e');
    }
  }

  /// Opts the current user out of period tracking entirely.
  /// Existing data is retained (GDPR erasure is handled separately).
  Future<void> revokePeriodTrackingConsent() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase.from('period_tracking_consent').upsert(
        {
          'user_id': user.id,
          'opted_in': false,
          'opted_out_at': now,
          'coach_share': false,
          'updated_at': now,
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      throw Exception('Failed to revoke period tracking consent: $e');
    }
  }

  // =========================================================================
  // MENSTRUAL HEALTH — daily logging
  // =========================================================================

  /// Upserts a period log entry for [date].
  ///
  /// Encryption happens server-side via periods_upsert_log RPC; plaintext is
  /// transmitted only over the TLS-encrypted Supabase connection and is never
  /// stored in plaintext. Returns the row id.
  Future<String> logPeriodDay({
    required DateTime date,
    FlowLevel? flow,
    List<PeriodSymptom>? symptoms,
    String? notes,
  }) async {
    try {
      final dateStr = _dateOnly(date);
      final symptomsJson = symptoms != null && symptoms.isNotEmpty
          ? jsonEncode(symptoms.map((s) => s.name).toList())
          : null;

      final result = await _supabase.rpc('periods_upsert_log', params: {
        'p_log_date': dateStr,
        if (flow != null) 'p_flow': flow.name,
        if (symptomsJson != null) 'p_symptoms': symptomsJson,
        if (notes != null) 'p_notes': notes,
      });

      return result?.toString() ?? '';
    } catch (e) {
      throw Exception('Failed to log period day: $e');
    }
  }

  /// Fetches and decrypts period logs for [startDate]–[endDate].
  ///
  /// One audit row is emitted for the entire batch via the
  /// periods_get_logs_decrypted RPC. Audit on every render, not every row.
  Future<List<PeriodLog>> getPeriodLogs({
    required DateTime startDate,
    required DateTime endDate,
    String justification = 'self_view',
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final rows = await _supabase.rpc('periods_get_logs_decrypted', params: {
        'p_start_date': _dateOnly(startDate),
        'p_end_date': _dateOnly(endDate),
        'p_justification': justification,
      }) as List<dynamic>;

      return rows
          .map((r) => PeriodLog.fromDecryptedMap(
                r as Map<String, dynamic>,
                user.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch period logs: $e');
    }
  }

  // =========================================================================
  // MENSTRUAL HEALTH — cycle management
  // =========================================================================

  /// Starts a new cycle on [startDate].
  ///
  /// Automatically closes any currently open cycle and snapshots the rolling
  /// avg_length_days + irregular_flag. Returns the new cycle id.
  Future<String> startNewCycle(DateTime startDate) async {
    try {
      final result = await _supabase.rpc('periods_start_cycle', params: {
        'p_cycle_start': _dateOnly(startDate),
      });
      return result?.toString() ?? '';
    } catch (e) {
      throw Exception('Failed to start new cycle: $e');
    }
  }

  /// Returns cycles for the current user, newest first.
  Future<List<MenstrualCycle>> getCycles({int limit = 6}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final rows = await _supabase
          .from('cycles')
          .select()
          .eq('user_id', user.id)
          .order('cycle_start', ascending: false)
          .limit(limit);

      return (rows as List<dynamic>)
          .map((r) => MenstrualCycle.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch cycles: $e');
    }
  }

  /// Returns the currently open cycle (cycle_end is null), or null if none.
  Future<MenstrualCycle?> getActiveCycle() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final row = await _supabase
          .from('cycles')
          .select()
          .eq('user_id', user.id)
          .filter('cycle_end', 'is', null)
          .order('cycle_start', ascending: false)
          .limit(1)
          .maybeSingle();

      return row != null ? MenstrualCycle.fromMap(row) : null;
    } catch (e) {
      throw Exception('Failed to fetch active cycle: $e');
    }
  }

  // =========================================================================
  // MENSTRUAL HEALTH — prediction
  // =========================================================================

  /// Computes next-cycle prediction from the user's cycle history using a
  /// rolling average of the last 6 completed cycles.
  ///
  /// Returns null when fewer than 1 completed cycle is available.
  ///
  /// IMPORTANT: this prediction runs entirely client-side on decrypted cycle
  /// dates. Do NOT forward the result to any third-party LLM endpoint.
  Future<CyclePrediction?> computePrediction() async {
    try {
      final cycles = await getCycles(limit: 8);
      return _buildPrediction(cycles);
    } catch (e) {
      throw Exception('Failed to compute cycle prediction: $e');
    }
  }

  /// Returns the current cycle phase, or null if no cycle data exists.
  Future<CyclePhase?> currentPhase() async {
    try {
      final cycles = await getCycles(limit: 7);
      final prediction = _buildPrediction(cycles);
      return prediction?.currentPhase;
    } catch (e) {
      throw Exception('Failed to determine current phase: $e');
    }
  }

  // =========================================================================
  // Private helpers
  // =========================================================================

  CyclePrediction? _buildPrediction(List<MenstrualCycle> cycles) =>
      _engine.predict(cycles);

  String _dateOnly(DateTime dt) => dt.toIso8601String().split('T')[0];
}
