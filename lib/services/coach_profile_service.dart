// Create new simplified coach profile service at lib/services/coach_profile_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coach_profile.dart';

class CoachProfileService {
  final _supabase = Supabase.instance.client;

  // Get complete profile with all related data
  Future<Map<String, dynamic>> getFullProfile(String coachId) async {
    final response = await _supabase.rpc(
      'get_coach_profile_complete',
      params: {'p_coach_id': coachId},
    );

    return {
      'profile': CoachProfile.fromJson(response['profile']),
      'media': response['media'] ?? [],
      'stats': response['stats'] ?? {},
      'completeness': response['completeness'] ?? {},
    };
  }

  // Update profile
  Future<void> updateProfile(String coachId, Map<String, dynamic> updates) async {
    await _supabase
        .from('coach_profiles')
        .upsert({
          'coach_id': coachId,
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  // Media management
  Future<List<Map<String, dynamic>>> getCoachMedia(String coachId) async {
    final response = await _supabase
        .from('coach_media')
        .select()
        .eq('coach_id', coachId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addMedia(Map<String, dynamic> media) async {
    await _supabase.from('coach_media').insert(media);
  }

  Future<void> deleteMedia(String mediaId) async {
    await _supabase
        .from('coach_media')
        .delete()
        .eq('id', mediaId);
  }

  // Check username availability
  Future<bool> isUsernameAvailable(String username, {String? excludeCoachId}) async {
    var query = _supabase
        .from('coach_profiles')
        .select('coach_id')
        .eq('username', username);

    if (excludeCoachId != null) {
      query = query.neq('coach_id', excludeCoachId);
    }

    final response = await query;
    return response.isEmpty;
  }

  // Get marketplace requirements status
  Future<Map<String, bool>> getMarketplaceStatus(String coachId) async {
    final profile = await getFullProfile(coachId);

    return {
      'has_profile': profile['completeness']['hasDisplayName'] ?? false,
      'has_intro_video': profile['completeness']['hasIntroVideo'] ?? false,
      'has_media': (profile['media'] as List).length >= 3,
      'has_pricing': await _checkPricing(coachId),
      'has_business': await _checkBusiness(coachId),
      'is_approved': profile['profile']?.isApproved ?? false,
    };
  }

  Future<bool> _checkPricing(String coachId) async {
    final response = await _supabase
        .from('coach_pricing')
        .select('id')
        .eq('coach_id', coachId)
        .limit(1);
    return response.isNotEmpty;
  }

  Future<bool> _checkBusiness(String coachId) async {
    final response = await _supabase
        .from('business_profiles')
        .select('id')
        .eq('user_id', coachId)
        .limit(1);
    return response.isNotEmpty;
  }
}
