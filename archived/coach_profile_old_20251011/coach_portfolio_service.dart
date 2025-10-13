import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coach/coach_profile.dart';
import '../models/coach/coach_profile_stats.dart';

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
      final String query = '''
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

  /// Get comprehensive coach profile stats
  Future<CoachProfileStats> getCoachStats(String coachId) async {
    try {
      final response = await _supabase.rpc('get_coach_stats', params: {
        'p_coach_id': coachId,
      });

      if (response == null) {
        return CoachProfileStats(
          coachId: coachId,
          lastUpdated: DateTime.now(),
        );
      }

      return CoachProfileStats.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      // Return default stats if query fails
      return CoachProfileStats(
        coachId: coachId,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Get detailed profile completeness information
  Future<CoachProfileCompleteness> getProfileCompleteness(String coachId) async {
    try {
      final profile = await getCoachProfile(coachId);
      final media = await getCoachMedia(coachId);

      // Check for avatar from user profile
      final avatarResponse = await _supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', coachId)
          .maybeSingle();

      final hasAvatar = avatarResponse?['avatar_url'] != null &&
                       avatarResponse!['avatar_url'].toString().isNotEmpty;

      // Check for certifications (assuming a certifications table exists)
      int certificationCount = 0;
      try {
        final certResponse = await _supabase
            .from('coach_certifications')
            .select('id')
            .eq('coach_id', coachId);
        certificationCount = (certResponse as List).length;
      } catch (e) {
        // Certifications table might not exist yet
        certificationCount = 0;
      }

      return CoachProfileCompleteness(
        coachId: coachId,
        hasProfile: profile != null,
        hasDisplayName: profile?.displayName != null && profile!.displayName!.isNotEmpty,
        hasUsername: profile?.username != null && profile!.username!.isNotEmpty,
        hasHeadline: profile?.headline != null && profile!.headline!.isNotEmpty,
        hasBio: profile?.bio != null && profile!.bio!.isNotEmpty,
        hasSpecialties: profile?.specialties.isNotEmpty ?? false,
        hasIntroVideo: profile?.introVideoUrl != null && profile!.introVideoUrl!.isNotEmpty,
        hasPortfolioMedia: media.isNotEmpty,
        hasCertifications: certificationCount > 0,
        hasAvatar: hasAvatar,
        mediaCount: media.length,
        certificationCount: certificationCount,
      );
    } catch (e) {
      return CoachProfileCompleteness(coachId: coachId);
    }
  }

  /// Get full coach profile data including stats and completeness
  Future<Map<String, dynamic>> getFullCoachProfile(String coachId, {String? viewerId}) async {
    try {
      // Run all queries concurrently for better performance
      final futures = await Future.wait([
        getCoachProfile(coachId),
        getCoachStats(coachId),
        getProfileCompleteness(coachId),
        viewerId != null ? getApprovedMedia(coachId, clientId: viewerId) : getPublicMedia(coachId),
      ]);

      final profile = futures[0] as CoachProfile?;
      final stats = futures[1] as CoachProfileStats;
      final completeness = futures[2] as CoachProfileCompleteness;
      final media = futures[3] as List<CoachMedia>;

      return {
        'profile': profile,
        'stats': stats,
        'completeness': completeness,
        'media': media,
        'is_owner': viewerId == coachId,
        'can_edit': viewerId == coachId,
      };
    } catch (e) {
      throw Exception('Failed to fetch full coach profile: $e');
    }
  }

  /// Check username availability
  Future<bool> isUsernameAvailable(String username, {String? excludeCoachId}) async {
    try {
      var query = _supabase
          .from('coach_profiles')
          .select('coach_id')
          .eq('username', username.toLowerCase());

      if (excludeCoachId != null) {
        query = query.neq('coach_id', excludeCoachId);
      }

      final response = await query.maybeSingle();
      return response == null;
    } catch (e) {
      return false; // Assume not available if check fails
    }
  }

  /// Update profile view count
  Future<void> incrementProfileView(String coachId, {String? viewerId}) async {
    try {
      // Don't count self-views
      if (viewerId == coachId) return;

      await _supabase.rpc('increment_profile_view', params: {
        'p_coach_id': coachId,
        'p_viewer_id': viewerId,
      });
    } catch (e) {
      // Silently fail for analytics - don't interrupt user experience
    }
  }
}
