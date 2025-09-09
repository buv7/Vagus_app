import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/ads/ad_banner.dart';

class AdBannerService {
  static final AdBannerService _instance = AdBannerService._internal();
  factory AdBannerService() => _instance;
  AdBannerService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Cache for active ads per audience (5-minute cache)
  final Map<String, List<AdBanner>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Fetch active ads for a specific audience
  /// Includes ads with audience 'both' as well as the specific audience
  Future<List<AdBanner>> fetchActive({required String audience}) async {
    final cacheKey = audience;
    final now = DateTime.now();
    
    // Check cache first
    if (_cache.containsKey(cacheKey) && 
        _cacheTimestamps.containsKey(cacheKey) &&
        now.difference(_cacheTimestamps[cacheKey]!) < _cacheExpiry) {
      return _cache[cacheKey]!;
    }

    try {
      // Fetch ads that are active and match the audience
      final response = await _supabase
          .from('v_current_ads')
          .select('*')
          .inFilter('audience', [audience, 'both'])
          .order('created_at', ascending: false);

      final ads = (response as List)
          .map((json) => AdBanner.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update cache
      _cache[cacheKey] = ads;
      _cacheTimestamps[cacheKey] = now;

      return ads;
    } catch (e) {
      print('Error fetching active ads: $e');
      return [];
    }
  }

  /// Track an impression for an ad
  Future<void> trackImpression(String adId) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('ad_impressions').insert({
        'ad_id': adId,
        'user_id': user?.id,
        'seen_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error tracking impression: $e');
      // Don't throw - tracking failures shouldn't break the UI
    }
  }

  /// Track a click for an ad
  Future<void> trackClick(String adId) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('ad_clicks').insert({
        'ad_id': adId,
        'user_id': user?.id,
        'clicked_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error tracking click: $e');
      // Don't throw - tracking failures shouldn't break the UI
    }
  }

  /// Check if current user is an admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('admin_users')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Create a new ad banner (admin only)
  Future<String> createAdBanner({
    required String title,
    required String imageUrl,
    String? linkUrl,
    required String audience,
    DateTime? startsAt,
    DateTime? endsAt,
    bool isActive = true,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase.from('ad_banners').insert({
        'title': title,
        'image_url': imageUrl,
        'link_url': linkUrl,
        'audience': audience,
        'starts_at': (startsAt ?? DateTime.now()).toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
        'is_active': isActive,
        'created_by': user.id,
      }).select('id').single();

      // Clear cache to force refresh
      _cache.clear();
      _cacheTimestamps.clear();

      return response['id'] as String;
    } catch (e) {
      print('Error creating ad banner: $e');
      rethrow;
    }
  }

  /// Update an ad banner (admin only)
  Future<void> updateAdBanner({
    required String id,
    String? title,
    String? imageUrl,
    String? linkUrl,
    String? audience,
    DateTime? startsAt,
    DateTime? endsAt,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (linkUrl != null) updates['link_url'] = linkUrl;
      if (audience != null) updates['audience'] = audience;
      if (startsAt != null) updates['starts_at'] = startsAt.toIso8601String();
      if (endsAt != null) updates['ends_at'] = endsAt.toIso8601String();
      if (isActive != null) updates['is_active'] = isActive;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('ad_banners').update(updates).eq('id', id);

      // Clear cache to force refresh
      _cache.clear();
      _cacheTimestamps.clear();
    } catch (e) {
      print('Error updating ad banner: $e');
      rethrow;
    }
  }

  /// Delete an ad banner (admin only)
  Future<void> deleteAdBanner(String id) async {
    try {
      await _supabase.from('ad_banners').delete().eq('id', id);

      // Clear cache to force refresh
      _cache.clear();
      _cacheTimestamps.clear();
    } catch (e) {
      print('Error deleting ad banner: $e');
      rethrow;
    }
  }

  /// Get all ad banners for admin management
  Future<List<AdBanner>> getAllAdBanners() async {
    try {
      final response = await _supabase
          .from('ad_banners')
          .select('*')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AdBanner.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching all ad banners: $e');
      return [];
    }
  }
}
