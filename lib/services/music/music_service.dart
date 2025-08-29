import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/music/music_models.dart';

class MusicService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // CRUD Operations for Music Links
  Future<MusicLink> createLink({
    required String title,
    required MusicKind kind,
    required String uri,
    String? art,
    List<String>? tags,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final data = {
      'owner_id': user.id,
      'kind': kind.name,
      'uri': uri,
      'title': title,
      'art': art,
      'tags': tags ?? [],
    };

    final result = await _supabase
        .from('music_links')
        .insert(data)
        .select()
        .single();

    return MusicLink.fromJson(result);
  }

  Future<List<MusicLink>> listMyLinks() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final result = await _supabase
        .from('music_links')
        .select()
        .eq('owner_id', user.id)
        .order('created_at', ascending: false);

    return (result as List).map((json) => MusicLink.fromJson(json)).toList();
  }

  Future<void> deleteLink(String linkId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase
        .from('music_links')
        .delete()
        .eq('id', linkId)
        .eq('owner_id', user.id);
  }

  // Attach/Detach Operations
  Future<void> attachToPlanDay({
    required String planId,
    int? weekIdx,
    int? dayIdx,
    required String musicLinkId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if user is coach of this plan
    final plan = await _supabase
        .from('workout_plans')
        .select('coach_id')
        .eq('id', planId)
        .single();

    if (plan['coach_id'] != user.id) {
      throw Exception('Only the plan coach can attach music');
    }

    // Check Pro gating
    final canAttach = await canAttachMore(user.id, planId, weekIdx, dayIdx);
    if (!canAttach) {
      throw Exception('Free users can only attach 1 music link per plan/day. Upgrade to Pro for unlimited.');
    }

    final data = {
      'plan_id': planId,
      'week_idx': weekIdx,
      'day_idx': dayIdx,
      'music_link_id': musicLinkId,
    };

    await _supabase.from('workout_music_refs').insert(data);
  }

  Future<void> detachFromPlanDay({
    required String planId,
    int? weekIdx,
    int? dayIdx,
    required String musicLinkId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final query = _supabase
        .from('workout_music_refs')
        .delete()
        .eq('plan_id', planId)
        .eq('music_link_id', musicLinkId);
    
    if (weekIdx != null) {
      await query.eq('week_idx', weekIdx);
    }
    if (dayIdx != null) {
      await query.eq('day_idx', dayIdx);
    }
    
    await query;
  }

  Future<void> attachToEvent({
    required String eventId,
    required String musicLinkId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if user is coach of this event
    final event = await _supabase
        .from('events')
        .select('coach_id')
        .eq('id', eventId)
        .single();

    if (event['coach_id'] != user.id) {
      throw Exception('Only the event coach can attach music');
    }

    final data = {
      'event_id': eventId,
      'music_link_id': musicLinkId,
    };

    await _supabase.from('event_music_refs').insert(data);
  }

  Future<void> detachFromEvent({
    required String eventId,
    required String musicLinkId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase
        .from('event_music_refs')
        .delete()
        .eq('event_id', eventId)
        .eq('music_link_id', musicLinkId);
  }

  // Query Operations
  Future<List<MusicLink>> getForPlanDay({
    required String planId,
    int? weekIdx,
    int? dayIdx,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final query = _supabase
        .from('workout_music_refs')
        .select('music_link_id, music_links(*)')
        .eq('plan_id', planId);
    
    if (weekIdx != null) {
      await query.eq('week_idx', weekIdx);
    }
    if (dayIdx != null) {
      await query.eq('day_idx', dayIdx);
    }
    
    final result = await query;

    return (result as List)
        .map((row) => MusicLink.fromJson(row['music_links']))
        .toList();
  }

  Future<List<MusicLink>> getForEvent(String eventId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final result = await _supabase
        .from('event_music_refs')
        .select('music_link_id, music_links(*)')
        .eq('event_id', eventId);

    return (result as List)
        .map((row) => MusicLink.fromJson(row['music_links']))
        .toList();
  }

  // Preferences Operations
  Future<UserMusicPrefs?> getPrefs(String userId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (user.id != userId) {
      throw Exception('Can only access own preferences');
    }

    final result = await _supabase
        .from('user_music_prefs')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (result == null) return null;
    return UserMusicPrefs.fromJson(result);
  }

  Future<UserMusicPrefs> setPrefs(UserMusicPrefs prefs) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (user.id != prefs.userId) {
      throw Exception('Can only update own preferences');
    }

    final data = prefs.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();

    final result = await _supabase
        .from('user_music_prefs')
        .upsert(data)
        .select()
        .single();

    return UserMusicPrefs.fromJson(result);
  }

  // Deep Link Opening
  Future<bool> openDeepLink(MusicLink link) async {
    try {
      String url;
      
      switch (link.kind) {
        case MusicKind.spotify:
          // Try spotify: URI first, fallback to https
          if (link.uri.startsWith('spotify:')) {
            url = link.uri;
          } else if (link.uri.startsWith('https://open.spotify.com')) {
            url = link.uri;
          } else {
            // Convert to spotify: URI if possible
            url = _convertToSpotifyUri(link.uri);
          }
          break;
          
        case MusicKind.soundcloud:
          // SoundCloud only supports https URLs
          url = link.uri.startsWith('https://') ? link.uri : 'https://soundcloud.com';
          break;
      }

      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // Fallback to web URL for Spotify
        if (link.kind == MusicKind.spotify && url.startsWith('spotify:')) {
          final webUrl = _convertSpotifyToWeb(url);
          final webUri = Uri.parse(webUrl);
          final canLaunchWeb = await canLaunchUrl(webUri);
          if (canLaunchWeb) {
            await launchUrl(webUri, mode: LaunchMode.externalApplication);
            return true;
          }
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error opening music link: $e');
      return false;
    }
  }

  String _convertToSpotifyUri(String uri) {
    // Convert various Spotify URL formats to spotify: URI
    if (uri.contains('open.spotify.com/track/')) {
      final trackId = uri.split('/track/').last.split('?').first;
      return 'spotify:track:$trackId';
    } else if (uri.contains('open.spotify.com/playlist/')) {
      final playlistId = uri.split('/playlist/').last.split('?').first;
      return 'spotify:playlist:$playlistId';
    } else if (uri.contains('open.spotify.com/album/')) {
      final albumId = uri.split('/album/').last.split('?').first;
      return 'spotify:album:$albumId';
    }
    return uri;
  }

  String _convertSpotifyToWeb(String spotifyUri) {
    // Convert spotify: URI to web URL
    if (spotifyUri.startsWith('spotify:track:')) {
      final trackId = spotifyUri.split(':').last;
      return 'https://open.spotify.com/track/$trackId';
    } else if (spotifyUri.startsWith('spotify:playlist:')) {
      final playlistId = spotifyUri.split(':').last;
      return 'https://open.spotify.com/playlist/$playlistId';
    } else if (spotifyUri.startsWith('spotify:album:')) {
      final albumId = spotifyUri.split(':').last;
      return 'https://open.spotify.com/album/$albumId';
    }
    return 'https://open.spotify.com';
  }

  // Pro Gating Helper
  Future<bool> canAttachMore(String userId, String planId, int? weekIdx, int? dayIdx) async {
    // Get user tier (simplified - you may want to check actual subscription)
    final profile = await _supabase
        .from('profiles')
        .select('tier')
        .eq('id', userId)
        .single();
    
    final tier = profile['tier'] ?? 'free';
    
    if (tier == 'pro') return true; // Pro users can attach unlimited
    
    // Free users: max 1 per plan/day
    final query = _supabase
        .from('workout_music_refs')
        .select('id')
        .eq('plan_id', planId);
    
    if (weekIdx != null) {
      await query.eq('week_idx', weekIdx);
    }
    if (dayIdx != null) {
      await query.eq('day_idx', dayIdx);
    }
    
    final currentCount = await query;
    final count = currentCount.length;
    return count < 1;
  }

  // Analytics hooks
  void logMusicAttach(String context, String linkId) {
    debugPrint('music_attach: $context, link: $linkId');
  }

  void logMusicOpen(String linkId, String provider) {
    debugPrint('music_open: $linkId, provider: $provider');
  }

  void logMusicAutoOpen(String linkId) {
    debugPrint('music_auto_open: $linkId');
  }

  void logMusicPrefUpdate(String userId, String field) {
    debugPrint('music_pref_update: $userId, field: $field');
  }

  void logMusicLimitBlocked(String userId, String context) {
    debugPrint('music_limit_blocked: $userId, context: $context');
  }
}
