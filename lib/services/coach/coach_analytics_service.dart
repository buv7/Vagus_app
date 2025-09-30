// lib/services/coach/coach_analytics_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _sb = Supabase.instance.client;

/// Analytics summary data for coach dashboard
class CoachAnalyticsSummary {
  final int totalClients;
  final int activeClients;
  final int totalSessions;
  final double avgSessionRating;
  final int totalMessages;
  final int unreadMessages;
  final double clientRetentionRate;
  final double avgResponseTime;
  final double avgCompliance;
  final List<double> sparkCompliance;
  final double avgSteps;
  final List<double> sparkSteps;
  final double netEnergyBalance;
  final List<double> sparkEnergy;
  final int checkinsThisWeek;

  const CoachAnalyticsSummary({
    required this.totalClients,
    required this.activeClients,
    required this.totalSessions,
    required this.avgSessionRating,
    required this.totalMessages,
    required this.unreadMessages,
    required this.clientRetentionRate,
    required this.avgResponseTime,
    required this.avgCompliance,
    required this.sparkCompliance,
    required this.avgSteps,
    required this.sparkSteps,
    required this.netEnergyBalance,
    required this.sparkEnergy,
    required this.checkinsThisWeek,
  });

  factory CoachAnalyticsSummary.empty() {
    return const CoachAnalyticsSummary(
      totalClients: 0,
      activeClients: 0,
      totalSessions: 0,
      avgSessionRating: 0.0,
      totalMessages: 0,
      unreadMessages: 0,
      clientRetentionRate: 0.0,
      avgResponseTime: 0.0,
      avgCompliance: 0.0,
      sparkCompliance: [],
      avgSteps: 0.0,
      sparkSteps: [],
      netEnergyBalance: 0.0,
      sparkEnergy: [],
      checkinsThisWeek: 0,
    );
  }
}

/// Service for coach analytics data
class CoachAnalyticsService {
  static final CoachAnalyticsService _instance = CoachAnalyticsService._internal();
  factory CoachAnalyticsService() => _instance;
  CoachAnalyticsService._internal();

  // Cache for analytics data
  final Map<String, CoachAnalyticsSummary> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// Get analytics summary for a date range
  Future<CoachAnalyticsSummary> getSummary({
    required String coachId,
    required int days,
  }) async {
    try {
      // Check cache first
      final cacheKey = '${coachId}_$days';
      if (_cache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
        return _cache[cacheKey]!;
      }

      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      // Get all analytics data in parallel
      final results = await Future.wait([
        _getClientMetrics(coachId, startDate, endDate),
        _getSessionMetrics(coachId, startDate, endDate),
        _getMessageMetrics(coachId, startDate, endDate),
        _getComplianceMetrics(coachId, startDate, endDate),
        _getHealthMetrics(coachId, startDate, endDate),
        _getCheckinMetrics(coachId, startDate, endDate),
      ]);

      final clientMetrics = results[0];
      final sessionMetrics = results[1];
      final messageMetrics = results[2];
      final complianceMetrics = results[3];
      final healthMetrics = results[4];
      final checkinMetrics = results[5];

      final summary = CoachAnalyticsSummary(
        totalClients: clientMetrics['total'] as int,
        activeClients: clientMetrics['active'] as int,
        totalSessions: sessionMetrics['total'] as int,
        avgSessionRating: sessionMetrics['avg_rating'] as double,
        totalMessages: messageMetrics['total'] as int,
        unreadMessages: messageMetrics['unread'] as int,
        clientRetentionRate: clientMetrics['retention_rate'] as double,
        avgResponseTime: messageMetrics['avg_response_time'] as double,
        avgCompliance: complianceMetrics['avg_compliance'] as double,
        sparkCompliance: complianceMetrics['spark_data'] as List<double>,
        avgSteps: healthMetrics['avg_steps'] as double,
        sparkSteps: healthMetrics['spark_steps'] as List<double>,
        netEnergyBalance: healthMetrics['net_energy'] as double,
        sparkEnergy: healthMetrics['spark_energy'] as List<double>,
        checkinsThisWeek: checkinMetrics['this_week'] as int,
      );

      // Cache results
      _cache[cacheKey] = summary;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return summary;
    } catch (e) {
      debugPrint('CoachAnalyticsService: Error getting analytics summary - $e');
      return CoachAnalyticsSummary.empty();
    }
  }

  /// Get client metrics
  Future<Map<String, dynamic>> _getClientMetrics(String coachId, DateTime startDate, DateTime endDate) async {
    try {
      // Get total clients
      final totalResponse = await _sb
          .from('coach_clients')
          .select('client_id')
          .eq('coach_id', coachId);

      final totalClients = (totalResponse as List<dynamic>).length;

      // Get active clients (clients with activity in the date range)
      final activeResponse = await _sb
          .from('coach_clients')
          .select('client_id')
          .eq('coach_id', coachId);

      final clientIds = activeResponse.map((row) => row['client_id'] as String).toList();
      
      int activeClients = 0;
      if (clientIds.isNotEmpty) {
        final activityResponse = await _sb
            .from('checkins')
            .select('client_id')
            .inFilter('client_id', clientIds)
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String());

        activeClients = (activityResponse as List<dynamic>).length;
      }

      // Calculate retention rate
      final retentionRate = totalClients > 0 ? activeClients / totalClients : 0.0;

      return {
        'total': totalClients,
        'active': activeClients,
        'retention_rate': retentionRate,
      };
    } catch (e) {
      debugPrint('CoachAnalyticsService: Error getting client metrics - $e');
      return {'total': 0, 'active': 0, 'retention_rate': 0.0};
    }
  }

  /// Get session metrics
  Future<Map<String, dynamic>> _getSessionMetrics(String coachId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _sb
          .from('calendar_events')
          .select('id, status')
          .eq('coach_id', coachId)
          .eq('status', 'completed')
          .gte('start_at', startDate.toIso8601String())
          .lte('start_at', endDate.toIso8601String());

      final totalSessions = (response as List<dynamic>).length;
      // TODO: Get actual session ratings
      final avgRating = 4.5;

      return {
        'total': totalSessions,
        'avg_rating': avgRating,
      };
    } catch (e) {
      debugPrint('CoachAnalyticsService: Error getting session metrics - $e');
      return {'total': 0, 'avg_rating': 0.0};
    }
  }

  /// Get message metrics
  Future<Map<String, dynamic>> _getMessageMetrics(String coachId, DateTime startDate, DateTime endDate) async {
    try {
      // Get total messages
      final totalResponse = await _sb
          .from('messages')
          .select('id')
          .eq('sender_id', coachId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final totalMessages = (totalResponse as List<dynamic>).length;

      // Get unread messages (messages sent to coach)
      final conversationsResponse = await _sb
          .from('conversations')
          .select('id')
          .eq('coach_id', coachId);

      final conversationIds = conversationsResponse.map((row) => row['id'] as String).toList();
      
      int unreadMessages = 0;
      if (conversationIds.isNotEmpty) {
        final unreadResponse = await _sb
            .from('messages')
            .select('id')
            .inFilter('conversation_id', conversationIds)
            .eq('is_read', false)
            .neq('sender_id', coachId);

        unreadMessages = (unreadResponse as List<dynamic>).length;
      }

      // TODO: Calculate average response time
      final avgResponseTime = 2.5; // hours

      return {
        'total': totalMessages,
        'unread': unreadMessages,
        'avg_response_time': avgResponseTime,
      };
    } catch (e) {
      debugPrint('CoachAnalyticsService: Error getting message metrics - $e');
      return {'total': 0, 'unread': 0, 'avg_response_time': 0.0};
    }
  }

  /// Get compliance metrics
  Future<Map<String, dynamic>> _getComplianceMetrics(String coachId, DateTime startDate, DateTime endDate) async {
    try {
      // Get coach's clients
      final clientsResponse = await _sb
          .from('coach_clients')
          .select('client_id')
          .eq('coach_id', coachId);

      final clientIds = clientsResponse.map((row) => row['client_id'] as String).toList();
      
      if (clientIds.isEmpty) {
        return {
          'avg_compliance': 0.0,
          'spark_data': <double>[],
        };
      }

      // Calculate compliance based on check-ins and completed sessions
      final checkinsResponse = await _sb
          .from('checkins')
          .select('client_id, created_at')
          .inFilter('client_id', clientIds)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final sessionsResponse = await _sb
          .from('calendar_events')
          .select('client_id, start_at')
          .inFilter('client_id', clientIds)
          .eq('status', 'completed')
          .gte('start_at', startDate.toIso8601String())
          .lte('start_at', endDate.toIso8601String());

      // Calculate daily compliance
      final dailyCompliance = <double>[];
      final days = endDate.difference(startDate).inDays;
      
      for (int i = 0; i < days; i++) {
        final day = startDate.add(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final dayCheckins = (checkinsResponse as List<dynamic>).where((c) {
          final createdAt = DateTime.tryParse(c['created_at']?.toString() ?? '');
          return createdAt != null && createdAt.isAfter(dayStart) && createdAt.isBefore(dayEnd);
        }).length;

        final daySessions = (sessionsResponse as List<dynamic>).where((s) {
          final startAt = DateTime.tryParse(s['start_at']?.toString() ?? '');
          return startAt != null && startAt.isAfter(dayStart) && startAt.isBefore(dayEnd);
        }).length;

        final expectedActivity = clientIds.length * 0.5; // Expected 50% daily activity
        final actualActivity = dayCheckins + daySessions;
        final compliance = expectedActivity > 0 ? (actualActivity / expectedActivity).clamp(0.0, 1.0) : 0.0;
        
        dailyCompliance.add(compliance);
      }

      final avgCompliance = dailyCompliance.isNotEmpty 
          ? dailyCompliance.fold(0.0, (sum, compliance) => sum + compliance) / dailyCompliance.length
          : 0.0;

      return {
        'avg_compliance': avgCompliance,
        'spark_data': dailyCompliance,
      };
    } catch (e) {
      debugPrint('CoachAnalyticsService: Error getting compliance metrics - $e');
      return {
        'avg_compliance': 0.0,
        'spark_data': <double>[],
      };
    }
  }

  /// Get health metrics
  Future<Map<String, dynamic>> _getHealthMetrics(String coachId, DateTime startDate, DateTime endDate) async {
    try {
      // Get coach's clients
      final clientsResponse = await _sb
          .from('coach_clients')
          .select('client_id')
          .eq('coach_id', coachId);

      final clientIds = clientsResponse.map((row) => row['client_id'] as String).toList();
      
      if (clientIds.isEmpty) {
        return {
          'avg_steps': 0.0,
          'spark_steps': <double>[],
          'net_energy': 0.0,
          'spark_energy': <double>[],
        };
      }

      // Get steps data
      final stepsResponse = await _sb
          .from('health_samples')
          .select('sample_time, value')
          .eq('type', 'steps')
          .inFilter('user_id', clientIds)
          .gte('sample_time', startDate.toIso8601String())
          .lte('sample_time', endDate.toIso8601String());

      // Calculate daily steps
      final dailySteps = <double>[];
      final days = endDate.difference(startDate).inDays;
      
      for (int i = 0; i < days; i++) {
        final day = startDate.add(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final daySteps = (stepsResponse as List<dynamic>).where((s) {
          final sampleTime = DateTime.tryParse(s['sample_time']?.toString() ?? '');
          return sampleTime != null && sampleTime.isAfter(dayStart) && sampleTime.isBefore(dayEnd);
        }).fold<double>(0.0, (sum, s) => sum + ((s['value'] as num?)?.toDouble() ?? 0.0));

        dailySteps.add(daySteps);
      }

      final avgSteps = dailySteps.isNotEmpty 
          ? dailySteps.fold(0.0, (sum, steps) => sum + steps) / dailySteps.length
          : 0.0;

      // TODO: Calculate net energy balance
      final netEnergy = 0.0;
      final sparkEnergy = <double>[];

      return {
        'avg_steps': avgSteps,
        'spark_steps': dailySteps,
        'net_energy': netEnergy,
        'spark_energy': sparkEnergy,
      };
    } catch (e) {
      debugPrint('CoachAnalyticsService: Error getting health metrics - $e');
      return {
        'avg_steps': 0.0,
        'spark_steps': <double>[],
        'net_energy': 0.0,
        'spark_energy': <double>[],
      };
    }
  }

  /// Get check-in metrics
  Future<Map<String, dynamic>> _getCheckinMetrics(String coachId, DateTime startDate, DateTime endDate) async {
    try {
      // Get coach's clients
      final clientsResponse = await _sb
          .from('coach_clients')
          .select('client_id')
          .eq('coach_id', coachId);

      final clientIds = clientsResponse.map((row) => row['client_id'] as String).toList();
      
      if (clientIds.isEmpty) {
        return {'this_week': 0};
      }

      // Get check-ins this week
      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final checkinsResponse = await _sb
          .from('checkins')
          .select('id')
          .inFilter('client_id', clientIds)
          .gte('created_at', weekStart.toIso8601String())
          .lte('created_at', weekEnd.toIso8601String());

      final checkinsThisWeek = (checkinsResponse as List<dynamic>).length;

      return {
        'this_week': checkinsThisWeek,
      };
    } catch (e) {
      debugPrint('CoachAnalyticsService: Error getting check-in metrics - $e');
      return {'this_week': 0};
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Clear cache for a specific coach
  void clearCache(String coachId) {
    _cache.removeWhere((key, value) => key.startsWith(coachId));
    _cacheTimestamps.removeWhere((key, value) => key.startsWith(coachId));
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
