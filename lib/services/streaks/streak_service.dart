import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enum for streak sources
enum StreakSource {
  workout,
  nutrition,
  checkin,
  photo,
  calendar,
  supplement,
  health,
}

/// Service for managing user streaks and compliance tracking
class StreakService {
  StreakService._();
  static final StreakService instance = StreakService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Mark a day as compliant for a user
  Future<void> markCompliant({
    required DateTime localDay,
    required StreakSource source,
    String? userId,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;
      if (user == null) return;

      // Convert to local date (strip time)
      final date = DateTime(localDay.year, localDay.month, localDay.day);
      
      await _supabase.rpc('mark_day_compliant', params: {
        'p_user_id': user,
        'p_date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
        'p_source': source.name,
      });

      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Day marked compliant - User: $user, Date: $date, Source: ${source.name}');
    } catch (e) {
      debugPrint('Failed to mark day compliant: $e');
      rethrow;
    }
  }

  /// Recompute streak for today if needed (idempotent)
  Future<void> recomputeForTodayIfNeeded({String? userId}) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;
      if (user == null) return;

      // Check if today has already been computed
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      final isCompliant = await _supabase.rpc('is_day_compliant', params: {
        'p_user_id': user,
        'p_date': todayDate.toIso8601String().split('T')[0],
      });

      if (isCompliant == true) {
        // Already computed for today, no need to recompute
        return;
      }

      // Recompute streak
      await _supabase.rpc('recompute_streak', params: {
        'p_user_id': user,
      });

      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Streak recomputed - User: $user, Date: $todayDate');
    } catch (e) {
      debugPrint('Failed to recompute streak: $e');
      rethrow;
    }
  }

  /// Get current streak information for a user
  Future<Map<String, dynamic>> getStreakInfo({String? userId}) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;
      if (user == null) return {'current_count': 0, 'longest_count': 0, 'shield_active': false};

      final response = await _supabase.rpc('get_streak_info', params: {
        'p_user_id': user,
      });

      if (response is List && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }

      return {'current_count': 0, 'longest_count': 0, 'shield_active': false};
    } catch (e) {
      debugPrint('Failed to get streak info: $e');
      return {'current_count': 0, 'longest_count': 0, 'shield_active': false};
    }
  }

  /// Check if a specific day is compliant
  Future<bool> isDayCompliant({
    required DateTime date,
    String? userId,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;
      if (user == null) return false;

      final dateStr = DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .split('T')[0];

      final response = await _supabase.rpc('is_day_compliant', params: {
        'p_user_id': user,
        'p_date': dateStr,
      });

      return response == true;
    } catch (e) {
      debugPrint('Failed to check day compliance: $e');
      return false;
    }
  }

  /// Start an appeal for a lost streak
  Future<String?> startAppeal({
    required DateTime lostOn,
    required String reason,
    List<String> evidencePaths = const [],
    String? userId,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;
      if (user == null) return null;

      final response = await _supabase
          .from('streak_appeals')
          .insert({
            'user_id': user,
            'lost_on': DateTime(lostOn.year, lostOn.month, lostOn.day)
                .toIso8601String()
                .split('T')[0],
            'reason': reason,
            'evidence_paths': evidencePaths,
          })
          .select()
          .single();

      final appealId = response['id'] as String?;
      
      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Streak appeal started - User: $user, Lost On: $lostOn, Appeal ID: $appealId');

      return appealId;
    } catch (e) {
      debugPrint('Failed to start appeal: $e');
      return null;
    }
  }

  /// Get appeals for a user
  Future<List<Map<String, dynamic>>> getAppeals({String? userId}) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;
      if (user == null) return [];

      final response = await _supabase
          .from('streak_appeals')
          .select()
          .eq('user_id', user)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((appeal) => appeal as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Failed to get appeals: $e');
      return [];
    }
  }

  /// Get streak days for a date range
  Future<List<Map<String, dynamic>>> getStreakDays({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;
      if (user == null) return [];

      final response = await _supabase
          .from('streak_days')
          .select()
          .eq('user_id', user)
          .gte('date', DateTime(startDate.year, startDate.month, startDate.day)
              .toIso8601String()
              .split('T')[0])
          .lte('date', DateTime(endDate.year, endDate.month, endDate.day)
              .toIso8601String()
              .split('T')[0])
          .order('date', ascending: true);

      return (response as List<dynamic>)
          .map((day) => day as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Failed to get streak days: $e');
      return [];
    }
  }

  // ===== ADMIN METHODS (stubbed for future implementation) =====

  /// Approve an appeal (admin only)
  Future<bool> approveAppeal({
    required String appealId,
    String? adminUserId,
  }) async {
    try {
      final admin = adminUserId ?? _supabase.auth.currentUser?.id;
      if (admin == null) return false;

      await _supabase
          .from('streak_appeals')
          .update({
            'status': 'approved',
            'resolved_by': admin,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appealId);

      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Appeal approved - Appeal ID: $appealId, Admin: $admin');

      return true;
    } catch (e) {
      debugPrint('Failed to approve appeal: $e');
      return false;
    }
  }

  /// Reject an appeal (admin only)
  Future<bool> rejectAppeal({
    required String appealId,
    String? adminUserId,
  }) async {
    try {
      final admin = adminUserId ?? _supabase.auth.currentUser?.id;
      if (admin == null) return false;

      await _supabase
          .from('streak_appeals')
          .update({
            'status': 'rejected',
            'resolved_by': admin,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appealId);

      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Appeal rejected - Appeal ID: $appealId, Admin: $admin');

      return true;
    } catch (e) {
      debugPrint('Failed to reject appeal: $e');
      return false;
    }
  }
}
