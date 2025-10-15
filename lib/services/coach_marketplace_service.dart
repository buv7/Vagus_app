import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coach_profile.dart';

class CoachMarketplaceService {
  final _supabase = Supabase.instance.client;

  /// Get all active coaches for marketplace
  Future<List<CoachProfile>> getActiveCoaches() async {
    try {
      final response = await _supabase
          .from('coach_profiles')
          .select('''
            *,
            profiles!inner(
              id,
              full_name,
              username,
              avatar_url
            )
          ''')
          .eq('is_active', true)
          .eq('marketplace_enabled', true)
          .order('rating', ascending: false);

      return (response as List)
          .map((json) => CoachProfile.fromJson({
                ...json,
                'avatar_url': json['profiles']?['avatar_url'],
                'username': json['profiles']?['username'],
                'display_name': json['display_name'] ?? json['profiles']?['full_name'],
              }))
          .toList();
    } catch (e) {
      // Fallback if columns don't exist yet
      final response = await _supabase
          .from('coach_profiles')
          .select()
          .order('updated_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => CoachProfile.fromJson(json))
          .toList();
    }
  }

  /// Search coaches by query
  Future<List<CoachProfile>> searchCoaches(String query) async {
    try {
      final response = await _supabase
          .from('coach_profiles')
          .select('''
            *,
            profiles!inner(
              id,
              full_name,
              username,
              avatar_url
            )
          ''')
          .eq('is_active', true)
          .eq('marketplace_enabled', true)
          .or('display_name.ilike.%$query%,bio.ilike.%$query%')
          .limit(50);

      return (response as List)
          .map((json) => CoachProfile.fromJson({
                ...json,
                'avatar_url': json['profiles']?['avatar_url'],
                'username': json['profiles']?['username'],
                'display_name': json['display_name'] ?? json['profiles']?['full_name'],
              }))
          .toList();
    } catch (e) {
      // Fallback if columns don't exist yet
      final response = await _supabase
          .from('coach_profiles')
          .select()
          .or('display_name.ilike.%$query%,bio.ilike.%$query%')
          .limit(50);

      return (response as List)
          .map((json) => CoachProfile.fromJson(json))
          .toList();
    }
  }

  /// Get coaches by specialty
  Future<List<CoachProfile>> getCoachesBySpecialty(String specialty) async {
    try {
      final response = await _supabase
          .from('coach_profiles')
          .select('''
            *,
            profiles!inner(
              id,
              full_name,
              username,
              avatar_url
            )
          ''')
          .eq('is_active', true)
          .eq('marketplace_enabled', true)
          .contains('specialties', [specialty])
          .order('rating', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => CoachProfile.fromJson({
                ...json,
                'avatar_url': json['profiles']?['avatar_url'],
                'username': json['profiles']?['username'],
                'display_name': json['display_name'] ?? json['profiles']?['full_name'],
              }))
          .toList();
    } catch (e) {
      // Fallback if columns don't exist yet
      final response = await _supabase
          .from('coach_profiles')
          .select()
          .contains('specialties', [specialty])
          .order('updated_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => CoachProfile.fromJson(json))
          .toList();
    }
  }

  /// Connect client with coach
  Future<void> connectWithCoach(String coachId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Check if request already exists
    final existingRequest = await _supabase
        .from('coach_requests')
        .select()
        .eq('coach_id', coachId)
        .eq('client_id', userId)
        .maybeSingle();

    if (existingRequest != null) {
      throw Exception('You already have a ${existingRequest['status']} request with this coach');
    }

    // Create request in coach_requests table (this is what coaches see)
    await _supabase.from('coach_requests').insert({
      'coach_id': coachId,
      'client_id': userId,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Check if entry exists in user_coach_links (base table)
    final existingConnection = await _supabase
        .from('user_coach_links')
        .select()
        .eq('coach_id', coachId)
        .eq('client_id', userId)
        .maybeSingle();

    if (existingConnection == null) {
      // Create new entry in user_coach_links for status tracking
      await _supabase.from('user_coach_links').insert({
        'coach_id': coachId,
        'client_id': userId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      // Update existing entry to pending
      await _supabase
          .from('user_coach_links')
          .update({'status': 'pending'})
          .eq('coach_id', coachId)
          .eq('client_id', userId);
    }
  }

  /// Check if already connected (only returns true for active connections)
  Future<bool> isConnected(String coachId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _supabase
        .from('coach_clients')
        .select()
        .eq('coach_id', coachId)
        .eq('client_id', userId)
        .eq('status', 'active')
        .maybeSingle();

    return response != null;
  }

  /// Check connection status (returns 'active', 'pending', 'rejected', or null)
  Future<String?> getConnectionStatus(String coachId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('coach_clients')
        .select('status')
        .eq('coach_id', coachId)
        .eq('client_id', userId)
        .maybeSingle();

    return response?['status'] as String?;
  }

  /// Cancel a pending connection request
  Future<void> cancelConnectionRequest(String coachId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Delete from coach_requests
    await _supabase
        .from('coach_requests')
        .delete()
        .eq('coach_id', coachId)
        .eq('client_id', userId)
        .eq('status', 'pending');

    // Delete from user_coach_links (the base table for coach_clients view)
    await _supabase
        .from('user_coach_links')
        .delete()
        .eq('coach_id', coachId)
        .eq('client_id', userId)
        .eq('status', 'pending');
  }
}
