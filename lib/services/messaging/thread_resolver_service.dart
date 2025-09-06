// lib/services/messaging/thread_resolver_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ThreadResolverService {
  static final ThreadResolverService instance = ThreadResolverService._();
  ThreadResolverService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Try to resolve a 1:1 thread between these two users.
  /// Returns threadId or null if not found.
  Future<String?> resolveOneToOne({
    required String coachId,
    required String clientId,
  }) async {
    try {
      // Query message_threads table for existing 1:1 thread
      final response = await _supabase
          .from('message_threads')
          .select('id, last_message_at')
          .eq('coach_id', coachId)
          .eq('client_id', clientId)
          .order('last_message_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first['id'] as String?;
      }

      return null;
    } catch (e) {
      // Log error but don't throw - graceful fallback
      print('ThreadResolverService: Failed to resolve thread: $e');
      return null;
    }
  }

  /// Get coach ID for a given client ID from coach_clients table
  Future<String?> getCoachForClient(String clientId) async {
    try {
      final response = await _supabase
          .from('coach_clients')
          .select('coach_id')
          .eq('client_id', clientId)
          .maybeSingle();

      return response?['coach_id'] as String?;
    } catch (e) {
      print('ThreadResolverService: Failed to get coach for client: $e');
      return null;
    }
  }
}
