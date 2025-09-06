import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coach/coach_profile.dart';

class CoachPortfolioService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get coach profile by coach ID
  Future<CoachProfile?> getCoachProfile(String coachId) async {
    try {
      final response = await _supabase
          .from('coach_profiles')
          .select()
          .eq('coach_id', coachId)
          .maybeSingle();

      if (response == null) return null;

      return CoachProfile.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch coach profile: $e');
    }
  }

  /// Create or update coach profile
  Future<void> createOrUpdateProfile(CoachProfile profile) async {
    try {
      final data = profile.toMap();
      data.remove('updated_at'); // Let the database handle this

      await _supabase
          .from('coach_profiles')
          .upsert(data);
    } catch (e) {
      throw Exception('Failed to save coach profile: $e');
    }
  }

  /// Get all media for a coach
  Future<List<CoachMedia>> getCoachMedia(String coachId) async {
    try {
      final response = await _supabase
          .from('coach_media')
          .select()
          .eq('coach_id', coachId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((media) => CoachMedia.fromMap(media as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch coach media: $e');
    }
  }

  /// Get approved public media for a coach
  Future<List<CoachMedia>> getPublicMedia(String coachId) async {
    try {
      final response = await _supabase
          .from('coach_media')
          .select()
          .eq('coach_id', coachId)
          .eq('is_approved', true)
          .eq('visibility', 'public')
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((media) => CoachMedia.fromMap(media as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch public media: $e');
    }
  }

  /// Get approved media for a coach (including clients_only for connected clients)
  Future<List<CoachMedia>> getApprovedMedia(String coachId, {String? clientId}) async {
    try {
      String query = '''
        coach_id.eq.$coachId,
        is_approved.eq.true,
        or(visibility.eq.public${clientId != null ? ',and(visibility.eq.clients_only,coach_id.in.(select coach_id from profiles where id.eq.$clientId))' : ''})
      ''';

      final response = await _supabase
          .from('coach_media')
          .select()
          .or(query)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((media) => CoachMedia.fromMap(media as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch approved media: $e');
    }
  }

  /// Add new media to coach portfolio
  Future<String> addMedia(CoachMedia media) async {
    try {
      final data = media.toMap();
      data.remove('id'); // Let the database generate this
      data.remove('created_at'); // Let the database handle this
      data.remove('updated_at'); // Let the database handle this

      final response = await _supabase
          .from('coach_media')
          .insert(data)
          .select()
          .single();

      return response['id']?.toString() ?? '';
    } catch (e) {
      throw Exception('Failed to add media: $e');
    }
  }

  /// Update existing media
  Future<void> updateMedia(CoachMedia media) async {
    try {
      final data = media.toMap();
      data.remove('created_at'); // Don't update created_at
      data.remove('updated_at'); // Let the database handle this

      await _supabase
          .from('coach_media')
          .update(data)
          .eq('id', media.id);
    } catch (e) {
      throw Exception('Failed to update media: $e');
    }
  }

  /// Delete media
  Future<void> deleteMedia(String mediaId) async {
    try {
      await _supabase
          .from('coach_media')
          .delete()
          .eq('id', mediaId);
    } catch (e) {
      throw Exception('Failed to delete media: $e');
    }
  }

  /// Admin: Get all pending media for approval
  Future<List<CoachMedia>> getPendingMedia() async {
    try {
      final response = await _supabase
          .from('coach_media')
          .select()
          .eq('is_approved', false)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((media) => CoachMedia.fromMap(media as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending media: $e');
    }
  }

  /// Admin: Approve media
  Future<void> approveMedia(String mediaId) async {
    try {
      await _supabase
          .from('coach_media')
          .update({'is_approved': true})
          .eq('id', mediaId);
    } catch (e) {
      throw Exception('Failed to approve media: $e');
    }
  }

  /// Admin: Reject media
  Future<void> rejectMedia(String mediaId) async {
    try {
      await _supabase
          .from('coach_media')
          .delete()
          .eq('id', mediaId);
    } catch (e) {
      throw Exception('Failed to reject media: $e');
    }
  }

  /// Check if coach needs to complete portfolio
  Future<bool> needsPortfolioCompletion(String coachId) async {
    try {
      final profile = await getCoachProfile(coachId);
      return profile == null || !profile.isComplete;
    } catch (e) {
      return true; // Assume needs completion if there's an error
    }
  }

  /// Get portfolio completion status
  Future<Map<String, bool>> getPortfolioStatus(String coachId) async {
    try {
      final profile = await getCoachProfile(coachId);
      
      return {
        'has_profile': profile != null,
        'has_display_name': profile?.displayName != null && profile!.displayName!.isNotEmpty,
        'has_headline': profile?.headline != null && profile!.headline!.isNotEmpty,
        'has_bio': profile?.bio != null && profile!.bio!.isNotEmpty,
        'has_intro_video': profile?.introVideoUrl != null && profile!.introVideoUrl!.isNotEmpty,
        'is_complete': profile?.isComplete ?? false,
      };
    } catch (e) {
      return {
        'has_profile': false,
        'has_display_name': false,
        'has_headline': false,
        'has_bio': false,
        'has_intro_video': false,
        'is_complete': false,
      };
    }
  }
}
