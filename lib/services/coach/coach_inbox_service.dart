import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'weekly_review_service.dart';
import '../progress/progress_service.dart';

final _sb = Supabase.instance.client;

/// Represents a client flag with issues that need coach attention
class ClientFlag {
  final String clientId;
  final String clientName;
  final List<String> issues;
  final DateTime lastUpdate;
  final String? avatarUrl;

  ClientFlag({
    required this.clientId,
    required this.clientName,
    required this.issues,
    required this.lastUpdate,
    this.avatarUrl,
  });
}

/// Service for managing coach inbox with auto-flagged clients
class CoachInboxService {
  static final CoachInboxService _instance = CoachInboxService._internal();
  factory CoachInboxService() => _instance;
  CoachInboxService._internal();

  // Session cache
  final Map<String, List<ClientFlag>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 15);

  /// Gets all flags for a coach's clients
  Future<List<ClientFlag>> getFlagsForCoach(String coachId) async {
    // Check cache first
    if (_cache.containsKey(coachId) && _isCacheValid(coachId)) {
      return _cache[coachId]!;
    }

    try {
      // Get coach's clients
      final clients = await _getCoachClients(coachId);
      if (clients.isEmpty) {
        _cache[coachId] = [];
        _cacheTimestamps[coachId] = DateTime.now();
        return [];
      }

      // Get flags for all clients in parallel
      final clientIds = clients.map((c) => c['id'] as String).toList();
      final flags = <ClientFlag>[];

      for (final client in clients) {
        final clientId = client['id'] as String;
        final clientName = client['name'] as String? ?? 'Unknown Client';

        final issues = await _checkClientIssues(clientId);
        if (issues.isNotEmpty) {
          flags.add(ClientFlag(
            clientId: clientId,
            clientName: clientName,
            issues: issues,
            lastUpdate: DateTime.now(),
          ));
        }
      }

      // Sort by number of issues (most critical first)
      flags.sort((a, b) => b.issues.length.compareTo(a.issues.length));

      // Cache results
      _cache[coachId] = flags;
      _cacheTimestamps[coachId] = DateTime.now();

      return flags;
    } catch (e) {
      print('CoachInboxService: Error getting flags for coach $coachId - $e');
      return [];
    }
  }

  /// Gets coach's clients from the database
  Future<List<Map<String, dynamic>>> _getCoachClients(String coachId) async {
    try {
      final links = await _sb
          .from('coach_clients')
          .select('client_id')
          .eq('coach_id', coachId);

      if (links.isEmpty) return [];

      final clientIds = links.map((row) => row['client_id'] as String).toList();
      
      final clients = await _sb
          .from('profiles')
          .select('id, name')
          .inFilter('id', clientIds);

      return List<Map<String, dynamic>>.from(clients);
    } catch (e) {
      print('CoachInboxService: Error getting coach clients - $e');
      return [];
    }
  }

  /// Checks for issues with a specific client
  Future<List<String>> _checkClientIssues(String clientId) async {
    final issues = <String>[];
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    try {
      // Check sleep issues (average <6h over past 3 days)
      final sleepIssue = await _checkLowSleep(clientId, threeDaysAgo);
      if (sleepIssue) issues.add('Low sleep');

      // Check steps issues (average <5k over past 3 days)
      final stepsIssue = await _checkLowSteps(clientId, threeDaysAgo);
      if (stepsIssue) issues.add('Low steps');

      // Check skipped sessions (any missed workouts in last 3 days)
      final skippedIssue = await _checkSkippedSessions(clientId, threeDaysAgo);
      if (skippedIssue) issues.add('Skipped sessions');

      // Check high negative net kcal (<-1000 kcal average past 3 days)
      final kcalIssue = await _checkHighNegativeKcal(clientId, threeDaysAgo);
      if (kcalIssue) issues.add('High negative kcal');

      // Check overdue check-ins (>7 days)
      final checkinIssue = await _checkOverdueCheckin(clientId, sevenDaysAgo);
      if (checkinIssue) issues.add('Check-in overdue');

    } catch (e) {
      print('CoachInboxService: Error checking client issues for $clientId - $e');
    }

    return issues;
  }

  /// Checks if client has low sleep average over past 3 days
  Future<bool> _checkLowSleep(String clientId, DateTime threeDaysAgo) async {
    try {
      final response = await _sb
          .from('sleep_segments')
          .select('start_time, end_time')
          .gte('start_time', threeDaysAgo.toIso8601String())
          .order('start_time', ascending: false);

      if (response.isEmpty) return false;

      // Calculate daily sleep totals
      final dailySleep = <String, double>{};
      for (final row in response as List<dynamic>) {
        final start = DateTime.tryParse(row['start_time']?.toString() ?? '');
        final end = DateTime.tryParse(row['end_time']?.toString() ?? '');
        if (start == null || end == null) continue;

        final day = DateFormat('yyyy-MM-dd').format(start);
        final hours = end.difference(start).inMinutes / 60.0;
        dailySleep[day] = (dailySleep[day] ?? 0) + hours;
      }

      if (dailySleep.isEmpty) return false;

      // Calculate average
      final totalHours = dailySleep.values.fold<double>(0, (sum, hours) => sum + hours);
      final avgHours = totalHours / dailySleep.length;

      return avgHours < 6.0;
    } catch (e) {
      print('CoachInboxService: Error checking sleep for $clientId - $e');
      return false;
    }
  }

  /// Checks if client has low steps average over past 3 days
  Future<bool> _checkLowSteps(String clientId, DateTime threeDaysAgo) async {
    try {
      final response = await _sb
          .from('health_samples')
          .select('sample_time, value')
          .eq('type', 'steps')
          .gte('sample_time', threeDaysAgo.toIso8601String())
          .order('sample_time', ascending: false);

      if (response.isEmpty) return false;

      // Calculate daily step totals
      final dailySteps = <String, double>{};
      for (final row in response as List<dynamic>) {
        final time = DateTime.tryParse(row['sample_time']?.toString() ?? '');
        final value = (row['value'] is num) ? (row['value'] as num).toDouble() : 0.0;
        if (time == null) continue;

        final day = DateFormat('yyyy-MM-dd').format(time);
        dailySteps[day] = (dailySteps[day] ?? 0) + value;
      }

      if (dailySteps.isEmpty) return false;

      // Calculate average
      final totalSteps = dailySteps.values.fold<double>(0, (sum, steps) => sum + steps);
      final avgSteps = totalSteps / dailySteps.length;

      return avgSteps < 5000;
    } catch (e) {
      print('CoachInboxService: Error checking steps for $clientId - $e');
      return false;
    }
  }

  /// Checks if client has skipped sessions in last 3 days
  Future<bool> _checkSkippedSessions(String clientId, DateTime threeDaysAgo) async {
    try {
      // Check for any missed workout sessions
      final response = await _sb
          .from('workout_sessions')
          .select('status, scheduled_date')
          .eq('client_id', clientId)
          .eq('status', 'missed')
          .gte('scheduled_date', threeDaysAgo.toIso8601String());

      return (response as List<dynamic>).isNotEmpty;
    } catch (e) {
      print('CoachInboxService: Error checking skipped sessions for $clientId - $e');
      return false;
    }
  }

  /// Checks if client has high negative net kcal over past 3 days
  Future<bool> _checkHighNegativeKcal(String clientId, DateTime threeDaysAgo) async {
    try {
      // Get calories in and out for past 3 days
      final kcalInResponse = await _sb
          .rpc('get_daily_calories_in', params: {
            'p_client_id': clientId,
            'p_start': threeDaysAgo.toIso8601String(),
            'p_end': DateTime.now().toIso8601String(),
          })
          .select();

      final kcalOutResponse = await _sb
          .from('health_workouts')
          .select('start_time, calories')
          .gte('start_time', threeDaysAgo.toIso8601String());

      // Calculate daily net calories
      final dailyNet = <String, double>{};
      
      // Process calories in
      for (final row in kcalInResponse as List<dynamic>) {
        final day = DateTime.tryParse(row['day']?.toString() ?? '');
        final kcal = (row['kcal'] is num) ? (row['kcal'] as num).toDouble() : 0.0;
        if (day == null) continue;
        
        final dayKey = DateFormat('yyyy-MM-dd').format(day);
        dailyNet[dayKey] = (dailyNet[dayKey] ?? 0) + kcal;
      }

      // Process calories out (subtract)
      for (final row in kcalOutResponse as List<dynamic>) {
        final time = DateTime.tryParse(row['start_time']?.toString() ?? '');
        final kcal = (row['calories'] is num) ? (row['calories'] as num).toDouble() : 0.0;
        if (time == null) continue;
        
        final dayKey = DateFormat('yyyy-MM-dd').format(time);
        dailyNet[dayKey] = (dailyNet[dayKey] ?? 0) - kcal;
      }

      if (dailyNet.isEmpty) return false;

      // Calculate average net
      final totalNet = dailyNet.values.fold<double>(0, (sum, net) => sum + net);
      final avgNet = totalNet / dailyNet.length;

      return avgNet < -1000;
    } catch (e) {
      print('CoachInboxService: Error checking kcal for $clientId - $e');
      return false;
    }
  }

  /// Checks if client has overdue check-ins (>7 days)
  Future<bool> _checkOverdueCheckin(String clientId, DateTime sevenDaysAgo) async {
    try {
      final response = await _sb
          .from('checkins')
          .select('created_at')
          .eq('client_id', clientId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return true; // No check-ins at all

      final lastCheckin = DateTime.tryParse(response.first['created_at']?.toString() ?? '');
      if (lastCheckin == null) return true;

      return lastCheckin.isBefore(sevenDaysAgo);
    } catch (e) {
      print('CoachInboxService: Error checking check-ins for $clientId - $e');
      return false;
    }
  }

  /// Checks if cache is still valid
  bool _isCacheValid(String coachId) {
    final timestamp = _cacheTimestamps[coachId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Clears cache for a specific coach
  void clearCache(String coachId) {
    _cache.remove(coachId);
    _cacheTimestamps.remove(coachId);
  }

  /// Clears all cache
  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
