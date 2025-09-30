import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoachCardVm {
  final String coachId;
  final String displayName;
  final String? username;
  final String? headline;
  final List<String> specialties;
  final String? avatarUrl;
  final double? ratingAvg;

  const CoachCardVm({
    required this.coachId,
    required this.displayName,
    this.username,
    this.headline,
    this.specialties = const [],
    this.avatarUrl,
    this.ratingAvg,
  });

  factory CoachCardVm.fromMap(Map<String, dynamic> map) {
    return CoachCardVm(
      coachId: map['coach_id']?.toString() ?? '',
      displayName: map['display_name']?.toString() ?? '',
      username: map['username']?.toString(),
      headline: map['headline']?.toString(),
      specialties: (map['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      avatarUrl: map['avatar_url']?.toString(),
      ratingAvg: map['rating_avg']?.toDouble(),
    );
  }
}

class CoachPublicVm {
  final String coachId;
  final String displayName;
  final String? username;
  final String? headline;
  final String? bio;
  final List<String> specialties;
  final String? avatarUrl;
  final String? introVideoUrl;
  final double? ratingAvg;

  const CoachPublicVm({
    required this.coachId,
    required this.displayName,
    this.username,
    this.headline,
    this.bio,
    this.specialties = const [],
    this.avatarUrl,
    this.introVideoUrl,
    this.ratingAvg,
  });

  factory CoachPublicVm.fromMap(Map<String, dynamic> map) {
    return CoachPublicVm(
      coachId: map['coach_id']?.toString() ?? '',
      displayName: map['display_name']?.toString() ?? '',
      username: map['username']?.toString(),
      headline: map['headline']?.toString(),
      bio: map['bio']?.toString(),
      specialties: (map['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      avatarUrl: map['avatar_url']?.toString(),
      introVideoUrl: map['intro_video_url']?.toString(),
      ratingAvg: map['rating_avg']?.toDouble(),
    );
  }
}

class CoachRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Search coaches in the marketplace
  Future<List<CoachCardVm>> search({
    String? q,
    String? username,
    int limit = 24,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('profiles')
          .select('''
            id,
            display_name,
            username,
            avatar_url,
            coach_profiles!inner(
              headline,
              specialties
            )
          ''')
          .not('coach_profiles.headline', 'is', null);

      // Apply search filters
      if (username != null && username.isNotEmpty) {
        // Remove @ prefix if present
        final cleanUsername = username.startsWith('@') ? username.substring(1) : username;
        query = query.ilike('username', '%$cleanUsername%');
      } else if (q != null && q.isNotEmpty) {
        // General search across display name and headline
        query = query.or('display_name.ilike.%$q%,coach_profiles.headline.ilike.%$q%');
      }

      final response = await query
          .order('display_name')
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>).map((item) {
        final coachProfile = item['coach_profiles'] as List<dynamic>;
        final profile = coachProfile.isNotEmpty ? coachProfile.first : {};

        return CoachCardVm.fromMap({
          'coach_id': item['id'],
          'display_name': item['display_name'],
          'username': item['username'],
          'avatar_url': item['avatar_url'],
          'headline': profile['headline'],
          'specialties': profile['specialties'] ?? [],
          'rating_avg': null, // TODO: Implement ratings when available
        });
      }).toList();
    } catch (e) {
      debugPrint('Error searching coaches: $e');
      return [];
    }
  }

  /// Get coach by username for profile view
  Future<CoachPublicVm?> byUsername(String username) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('''
            id,
            display_name,
            username,
            avatar_url,
            coach_profiles!inner(
              headline,
              bio,
              specialties,
              intro_video_url
            )
          ''')
          .eq('username', username.toLowerCase())
          .maybeSingle();

      if (response == null) return null;

      final coachProfile = response['coach_profiles'] as List<dynamic>;
      final profile = coachProfile.isNotEmpty ? coachProfile.first : {};

      return CoachPublicVm.fromMap({
        'coach_id': response['id'],
        'display_name': response['display_name'],
        'username': response['username'],
        'avatar_url': response['avatar_url'],
        'headline': profile['headline'],
        'bio': profile['bio'],
        'specialties': profile['specialties'] ?? [],
        'intro_video_url': profile['intro_video_url'],
        'rating_avg': null, // TODO: Implement ratings when available
      });
    } catch (e) {
      debugPrint('Error getting coach by username: $e');
      return null;
    }
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', username.toLowerCase())
          .maybeSingle();

      return response == null;
    } catch (e) {
      debugPrint('Error checking username availability: $e');
      return false;
    }
  }

  /// Update username for current user
  Future<bool> updateUsername(String username) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('profiles')
          .update({'username': username.toLowerCase()})
          .eq('id', user.id);

      return true;
    } catch (e) {
      debugPrint('Error updating username: $e');
      return false;
    }
  }
}