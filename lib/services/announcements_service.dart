import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcements/announcement.dart';

class AnnouncementsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all active announcements for the current user
  Future<List<Announcement>> fetchActive() async {
    try {
      final response = await _supabase
          .from('announcements')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((announcement) => Announcement.fromMap(announcement as Map<String, dynamic>))
          .where((announcement) => announcement.isCurrentlyActive)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active announcements: $e');
    }
  }

  /// Record an impression for an announcement
  Future<void> recordImpression(String announcementId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Check if impression already exists for this user and announcement
      final existingImpression = await _supabase
          .from('announcement_impressions')
          .select()
          .eq('announcement_id', announcementId)
          .eq('user_id', user.id)
          .maybeSingle();

      // Only record if no existing impression
      if (existingImpression == null) {
        await _supabase.from('announcement_impressions').insert({
          'announcement_id': announcementId,
          'user_id': user.id,
        });
      }
    } catch (e) {
      // Don't throw - impressions are not critical
      debugPrint('Failed to record impression: $e');
    }
  }

  /// Record a click for an announcement
  Future<void> recordClick(String announcementId, {String? target}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('announcement_clicks').insert({
        'announcement_id': announcementId,
        'user_id': user.id,
        'target': target,
      });
    } catch (e) {
      // Don't throw - clicks are not critical
      debugPrint('Failed to record click: $e');
    }
  }

  /// Admin: Create or update an announcement
  Future<String> createOrUpdateAnnouncement(Announcement announcement) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final data = announcement.toMap();
      data.remove('id'); // Remove id for insert
      data['created_by'] = user.id;

      final response = await _supabase
          .from('announcements')
          .insert(data)
          .select()
          .single();

      return response['id']?.toString() ?? '';
    } catch (e) {
      throw Exception('Failed to create announcement: $e');
    }
  }

  /// Admin: Update an existing announcement
  Future<void> updateAnnouncement(Announcement announcement) async {
    try {
      final data = announcement.toMap();
      data.remove('created_by'); // Don't update created_by
      data.remove('created_at'); // Don't update created_at

      await _supabase
          .from('announcements')
          .update(data)
          .eq('id', announcement.id);
    } catch (e) {
      throw Exception('Failed to update announcement: $e');
    }
  }

  /// Admin: Delete an announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _supabase
          .from('announcements')
          .delete()
          .eq('id', announcementId);
    } catch (e) {
      throw Exception('Failed to delete announcement: $e');
    }
  }

  /// Admin: Fetch analytics for an announcement
  Future<AnnouncementAnalytics> fetchAnalytics(String announcementId) async {
    try {
      // Get impressions count
      final impressionsResponse = await _supabase
          .from('announcement_impressions')
          .select('user_id')
          .eq('announcement_id', announcementId);

      final impressions = (impressionsResponse as List<dynamic>).length;
      final uniqueUsers = (impressionsResponse as List<dynamic>)
          .map((imp) => imp['user_id'])
          .toSet()
          .length;

      // Get clicks count
      final clicksResponse = await _supabase
          .from('announcement_clicks')
          .select()
          .eq('announcement_id', announcementId);

      final clicks = (clicksResponse as List<dynamic>).length;

      // Calculate CTR
      final ctr = impressions > 0 ? (clicks / impressions) * 100 : 0.0;

      // Get role breakdown (simplified - would need more complex query for full breakdown)
      final roleBreakdown = <String, int>{
        'total': uniqueUsers,
      };

      return AnnouncementAnalytics(
        announcementId: announcementId,
        impressions: impressions,
        uniqueUsers: uniqueUsers,
        clicks: clicks,
        ctr: ctr,
        roleBreakdown: roleBreakdown,
      );
    } catch (e) {
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  /// Admin: Fetch all announcements for management
  Future<List<Announcement>> fetchAllForAdmin() async {
    try {
      final response = await _supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((announcement) => Announcement.fromMap(announcement as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch announcements: $e');
    }
  }
}
