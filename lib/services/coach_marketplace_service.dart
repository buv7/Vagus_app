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

    await _supabase.from('coach_clients').insert({
      'coach_id': coachId,
      'client_id': userId,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Check if already connected
  Future<bool> isConnected(String coachId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _supabase
        .from('coach_clients')
        .select()
        .eq('coach_id', coachId)
        .eq('client_id', userId)
        .maybeSingle();

    return response != null;
  }
}
