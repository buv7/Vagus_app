import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final _sb = Supabase.instance.client;

/// Represents a client in the coach's client management system
class CoachClient {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final DateTime? lastActive;
  final String status; // 'active', 'inactive', 'pending'
  final int totalSessions;
  final double avgRating;
  final DateTime? lastCheckin;
  final String? currentPlan;
  final Map<String, dynamic>? metrics;

  CoachClient({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.lastActive,
    required this.status,
    required this.totalSessions,
    required this.avgRating,
    this.lastCheckin,
    this.currentPlan,
    this.metrics,
  });

  factory CoachClient.fromMap(Map<String, dynamic> data) {
    return CoachClient(
      id: data['id'] as String,
      name: data['name'] as String? ?? 'Unknown Client',
      email: data['email'] as String?,
      avatarUrl: null, // avatar_url column doesn't exist yet
      lastActive: data['last_active'] != null 
          ? DateTime.tryParse(data['last_active'].toString()) 
          : null,
      status: data['status'] as String? ?? 'active',
      totalSessions: (data['total_sessions'] as num?)?.toInt() ?? 0,
      avgRating: (data['avg_rating'] as num?)?.toDouble() ?? 0.0,
      lastCheckin: data['last_checkin'] != null 
          ? DateTime.tryParse(data['last_checkin'].toString()) 
          : null,
      currentPlan: data['current_plan'] as String?,
      metrics: data['metrics'] as Map<String, dynamic>?,
    );
  }
}

/// Represents client metrics for analytics
class ClientMetrics {
  final int totalClients;
  final int activeClients;
  final int pendingClients;
  final double avgSessionRating;
  final int totalSessions;
  final double clientRetentionRate;

  ClientMetrics({
    required this.totalClients,
    required this.activeClients,
    required this.pendingClients,
    required this.avgSessionRating,
    required this.totalSessions,
    required this.clientRetentionRate,
  });

  factory ClientMetrics.empty() {
    return ClientMetrics(
      totalClients: 0,
      activeClients: 0,
      pendingClients: 0,
      avgSessionRating: 0.0,
      totalSessions: 0,
      clientRetentionRate: 0.0,
    );
  }
}

/// Service for managing coach's clients
class CoachClientManagementService {
  static final CoachClientManagementService _instance = CoachClientManagementService._internal();
  factory CoachClientManagementService() => _instance;
  CoachClientManagementService._internal();

  // Cache for client data
  final Map<String, List<CoachClient>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 10);

  /// Get all clients for a coach with optional filtering
  Future<List<CoachClient>> getClients({
    required String coachId,
    String? searchQuery,
    String? statusFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Check cache first
      final cacheKey = '${coachId}_${searchQuery ?? ''}_${statusFilter ?? ''}';
      if (_cache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
        final cached = _cache[cacheKey]!;
        return cached.skip(offset).take(limit).toList();
      }

      // Build query
      var query = _sb
          .from('coach_clients')
          .select('''
            client_id,
            profiles!coach_clients_client_id_fkey(
              id,
              name,
              email,
              name,
              last_active,
              created_at
            )
          ''')
          .eq('coach_id', coachId);

      // Apply filters
      if (statusFilter != null && statusFilter != 'all') {
        // Note: This would need a status field in coach_clients table
        // For now, we'll filter after fetching
      }

      final response = await query.limit(limit + offset);

      // Process response
      final clients = <CoachClient>[];
      for (final row in response as List<dynamic>) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        if (profile == null) continue;

        // Get additional client data
        final clientId = profile['id'] as String;
        final clientData = await _getClientDetails(clientId);
        
        final client = CoachClient.fromMap({
          ...profile,
          ...clientData,
        });

        // Apply search filter
        if (searchQuery != null && searchQuery.isNotEmpty) {
          if (!client.name.toLowerCase().contains(searchQuery.toLowerCase()) &&
              !(client.email?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)) {
            continue;
          }
        }

        // Apply status filter
        if (statusFilter != null && statusFilter != 'all') {
          if (client.status != statusFilter) continue;
        }

        clients.add(client);
      }

      // Cache results
      _cache[cacheKey] = clients;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return clients.skip(offset).take(limit).toList();
    } catch (e) {
      print('CoachClientManagementService: Error getting clients - $e');
      return [];
    }
  }

  /// Get client details including sessions, ratings, and metrics
  Future<Map<String, dynamic>> _getClientDetails(String clientId) async {
    try {
      // Get session count and average rating
      final sessionsResponse = await _sb
          .from('calendar_events')
          .select('id, status')
          .eq('client_id', clientId)
          .eq('status', 'completed');

      final totalSessions = (sessionsResponse as List<dynamic>).length;

      // Get last check-in
      final checkinResponse = await _sb
          .from('checkins')
          .select('created_at')
          .eq('client_id', clientId)
          .order('created_at', ascending: false)
          .limit(1);

      final lastCheckin = checkinResponse.isNotEmpty 
          ? DateTime.tryParse(checkinResponse.first['created_at']?.toString() ?? '')
          : null;

      // Determine status based on activity
      final status = _determineClientStatus(lastCheckin);

      return {
        'total_sessions': totalSessions,
        'avg_rating': 4.5, // TODO: Calculate from actual ratings
        'last_checkin': lastCheckin?.toIso8601String(),
        'status': status,
      };
    } catch (e) {
      print('CoachClientManagementService: Error getting client details for $clientId - $e');
      return {
        'total_sessions': 0,
        'avg_rating': 0.0,
        'status': 'inactive',
      };
    }
  }

  /// Determine client status based on last activity
  String _determineClientStatus(DateTime? lastCheckin) {
    if (lastCheckin == null) return 'inactive';
    
    final daysSinceCheckin = DateTime.now().difference(lastCheckin).inDays;
    if (daysSinceCheckin <= 3) return 'active';
    if (daysSinceCheckin <= 7) return 'pending';
    return 'inactive';
  }

  /// Get client metrics for the coach
  Future<ClientMetrics> getClientMetrics(String coachId) async {
    try {
      final clients = await getClients(coachId: coachId);
      
      final totalClients = clients.length;
      final activeClients = clients.where((c) => c.status == 'active').length;
      final pendingClients = clients.where((c) => c.status == 'pending').length;
      
      final totalSessions = clients.fold<int>(0, (sum, client) => sum + client.totalSessions);
      final avgRating = clients.isNotEmpty 
          ? clients.fold<double>(0, (sum, client) => sum + client.avgRating) / clients.length
          : 0.0;

      // Calculate retention rate (clients active in last 30 days / total clients)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final activeInLast30Days = clients.where((c) => 
          c.lastActive != null && c.lastActive!.isAfter(thirtyDaysAgo)).length;
      final retentionRate = totalClients > 0 ? activeInLast30Days / totalClients : 0.0;

      return ClientMetrics(
        totalClients: totalClients,
        activeClients: activeClients,
        pendingClients: pendingClients,
        avgSessionRating: avgRating,
        totalSessions: totalSessions,
        clientRetentionRate: retentionRate,
      );
    } catch (e) {
      print('CoachClientManagementService: Error getting client metrics - $e');
      return ClientMetrics.empty();
    }
  }

  /// Send a message to a client
  Future<bool> sendMessageToClient({
    required String coachId,
    required String clientId,
    required String message,
  }) async {
    try {
      // Create or get conversation
      final conversationId = await _getOrCreateConversation(coachId, clientId);
      
      // Send message
      await _sb.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': coachId,
        'content': message,
        'message_type': 'text',
      });

      return true;
    } catch (e) {
      print('CoachClientManagementService: Error sending message - $e');
      return false;
    }
  }

  /// Get or create a conversation between coach and client
  Future<String> _getOrCreateConversation(String coachId, String clientId) async {
    try {
      // Try to find existing conversation
      final existing = await _sb
          .from('conversations')
          .select('id')
          .eq('coach_id', coachId)
          .eq('client_id', clientId)
          .maybeSingle();

      if (existing != null) {
        return existing['id'] as String;
      }

      // Create new conversation
      final response = await _sb.from('conversations').insert({
        'coach_id': coachId,
        'client_id': clientId,
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      print('CoachClientManagementService: Error creating conversation - $e');
      rethrow;
    }
  }

  /// Assign a plan to a client
  Future<bool> assignPlanToClient({
    required String coachId,
    required String clientId,
    required String planId,
    required String planType, // 'workout' or 'nutrition'
  }) async {
    try {
      await _sb.from('plan_assignments').insert({
        'plan_id': planId,
        'plan_type': planType,
        'client_id': clientId,
        'assigned_by': coachId,
        'status': 'active',
      });

      return true;
    } catch (e) {
      print('CoachClientManagementService: Error assigning plan - $e');
      return false;
    }
  }

  /// Remove a client from coach's list
  Future<bool> removeClient({
    required String coachId,
    required String clientId,
  }) async {
    try {
      await _sb
          .from('coach_clients')
          .delete()
          .eq('coach_id', coachId)
          .eq('client_id', clientId);

      // Clear cache
      _clearCacheForCoach(coachId);

      return true;
    } catch (e) {
      print('CoachClientManagementService: Error removing client - $e');
      return false;
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
    _cache.removeWhere((key, value) => key.startsWith(coachId));
    _cacheTimestamps.removeWhere((key, value) => key.startsWith(coachId));
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
