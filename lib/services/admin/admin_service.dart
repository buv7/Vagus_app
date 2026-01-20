import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/feature_flags.dart';
import 'safety_layer_service.dart';

/// Admin service for managing users, coach approvals, and global settings
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  final supabase = Supabase.instance.client;

  // ===== USER MANAGEMENT =====

  /// List users with pagination and filtering
  Future<List<Map<String, dynamic>>> listUsers({
    String? query,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final request = supabase
          .from('profiles')
          .select('id, email, name, role, created_at, is_disabled, is_enabled')
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      if (query != null && query.isNotEmpty) {
        // Note: Search functionality would need to be implemented differently
        // For now, we'll return all users and filter client-side
      }

      final response = await request;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error listing users: $e');
      return [];
    }
  }

  /// Update user role and log audit
  Future<bool> updateUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return false;

      // ✅ VAGUS ADD: safety-layer-check START
      final isSafetyEnabled = await FeatureFlags.instance.isEnabled(FeatureFlags.adminSafetyLayer);
      if (isSafetyEnabled) {
        final safetyCheck = await SafetyLayerService.I.checkSafetyRule(
          action: 'update_user_role',
          payload: {
            'user_id': userId,
            'new_role': role,
          },
        );

        if (safetyCheck['allowed'] != true) {
          final reason = safetyCheck['reason'] as String? ?? 'Blocked by safety layer';
          debugPrint('❌ Safety layer blocked role update: $reason');
          throw Exception(reason);
        }

        if (safetyCheck['requireApproval'] as bool) {
          final reason = safetyCheck['reason'] as String? ?? 'Requires approval';
          debugPrint('⚠️ Role update requires approval: $reason');
          throw Exception(reason);
        }
      }
      // ✅ VAGUS ADD: safety-layer-check END

      // Get current role for audit
      final currentUserData = await supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      
      final oldRole = currentUserData['role'];

      // Update role
      await supabase
          .from('profiles')
          .update({'role': role})
          .eq('id', userId);

      // Log audit
      await logAdminAction(
        'role_change',
        target: userId,
        meta: {
          'old_role': oldRole,
          'new_role': role,
        },
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error updating user role: $e');
      return false;
    }
  }

  /// Toggle user enabled/disabled status
  Future<bool> toggleUserEnabled({
    required String userId,
    required bool enabled,
  }) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return false;

      // ✅ VAGUS ADD: safety-layer-check START
      final isSafetyEnabled = await FeatureFlags.instance.isEnabled(FeatureFlags.adminSafetyLayer);
      if (isSafetyEnabled && !enabled) {
        // Only check safety layer when DISABLING (destructive action)
        final safetyCheck = await SafetyLayerService.I.checkSafetyRule(
          action: 'disable_user',
          payload: {
            'user_id': userId,
            'enabled': enabled,
          },
        );

        if (safetyCheck['allowed'] != true) {
          final reason = safetyCheck['reason'] as String? ?? 'Blocked by safety layer';
          debugPrint('❌ Safety layer blocked user disable: $reason');
          throw Exception(reason);
        }

        if (safetyCheck['requireApproval'] as bool) {
          final reason = safetyCheck['reason'] as String? ?? 'Requires approval';
          debugPrint('⚠️ User disable requires approval: $reason');
          throw Exception(reason);
        }
      }
      // ✅ VAGUS ADD: safety-layer-check END

      // Check which column exists
      final userData = await supabase
          .from('profiles')
          .select('is_disabled, is_enabled')
          .eq('id', userId)
          .single();

      final Map<String, dynamic> updateData = {};
      String action = '';

      if (userData.containsKey('is_disabled')) {
        updateData['is_disabled'] = !enabled;
        action = enabled ? 'user_enabled' : 'user_disabled';
      } else if (userData.containsKey('is_enabled')) {
        updateData['is_enabled'] = enabled;
        action = enabled ? 'user_enabled' : 'user_disabled';
      } else {
        // Neither column exists
        return false;
      }

      // Update user
      await supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId);

      // Log audit
      await logAdminAction(
        action,
        target: userId,
        meta: {'enabled': enabled},
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error toggling user enabled: $e');
      return false;
    }
  }

  /// Get AI usage summary for a user
  Future<Map<String, dynamic>?> getAiUsageSummary(String userId) async {
    try {
      final response = await supabase.rpc('get_ai_usage_summary', params: {
        'uid': userId,
      });
      return response;
    } catch (e) {
      debugPrint('❌ Error getting AI usage summary: $e');
      return null;
    }
  }

  /// Reset user AI usage (no-op if not supported)
  Future<bool> resetUserAiUsage(String userId) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return false;

      // ✅ VAGUS ADD: safety-layer-check START
      final isSafetyEnabled = await FeatureFlags.instance.isEnabled(FeatureFlags.adminSafetyLayer);
      if (isSafetyEnabled) {
        final safetyCheck = await SafetyLayerService.I.checkSafetyRule(
          action: 'reset_user_ai_usage',
          payload: {
            'user_id': userId,
          },
        );

        if (safetyCheck['allowed'] != true) {
          final reason = safetyCheck['reason'] as String? ?? 'Blocked by safety layer';
          debugPrint('❌ Safety layer blocked AI usage reset: $reason');
          throw Exception(reason);
        }

        if (safetyCheck['requireApproval'] as bool) {
          final reason = safetyCheck['reason'] as String? ?? 'Requires approval';
          debugPrint('⚠️ AI usage reset requires approval: $reason');
          throw Exception(reason);
        }
      }
      // ✅ VAGUS ADD: safety-layer-check END

      // Check if reset function exists
      await supabase.rpc('reset_user_ai_usage', params: {
        'uid': userId,
      });
      
      // Log audit
      await logAdminAction(
        'ai_usage_reset',
        target: userId,
      );

      return true;
    } catch (e) {
      debugPrint('❌ AI usage reset not supported or failed: $e');
      return false;
    }
  }

  // ===== COACH REQUESTS =====

  /// List coach requests with optional status filter
  Future<List<Map<String, dynamic>>> listCoachRequests({
    String? status = 'pending',
  }) async {
    try {
      // Build the query step by step to avoid type issues
      var query = supabase
          .from('coach_applications')
          .select('''
            *,
            user:profiles!coach_applications_user_id_fkey(id, email, name),
            reviewer:profiles!coach_applications_reviewed_by_fkey(id, email, name)
          ''');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .not('user', 'is', null)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error listing coach requests: $e');
      return [];
    }
  }

  /// Approve coach application
  Future<bool> approveCoach(String requestId) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return false;

      // Get application details
      final application = await supabase
          .from('coach_applications')
          .select('user_id')
          .eq('id', requestId)
          .single();

      // ✅ VAGUS ADD: safety-layer-check START
      final isSafetyEnabled = await FeatureFlags.instance.isEnabled(FeatureFlags.adminSafetyLayer);
      if (isSafetyEnabled) {
        final safetyCheck = await SafetyLayerService.I.checkSafetyRule(
          action: 'approve_coach',
          payload: {
            'user_id': application['user_id'],
            'new_role': 'coach',
          },
        );

        if (safetyCheck['allowed'] != true) {
          final reason = safetyCheck['reason'] as String? ?? 'Blocked by safety layer';
          debugPrint('❌ Safety layer blocked coach approval: $reason');
          throw Exception(reason);
        }

        if (safetyCheck['requireApproval'] as bool) {
          final reason = safetyCheck['reason'] as String? ?? 'Requires approval';
          debugPrint('⚠️ Coach approval requires approval: $reason');
          throw Exception(reason);
        }
      }
      // ✅ VAGUS ADD: safety-layer-check END

      // Update application status
      await supabase
          .from('coach_applications')
          .update({
            'status': 'approved',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': currentUser.id,
          })
          .eq('id', requestId);

      // Update user role to coach
      await supabase
          .from('profiles')
          .update({'role': 'coach'})
          .eq('id', application['user_id']);

      // Log audit
      await logAdminAction(
        'coach_approved',
        target: application['user_id'],
        meta: {'request_id': requestId},
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error approving coach: $e');
      return false;
    }
  }

  /// Decline coach application
  Future<bool> declineCoach(String requestId, {String? reason}) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return false;

      // Get application details
      final application = await supabase
          .from('coach_applications')
          .select('user_id')
          .eq('id', requestId)
          .single();

      // Update application status
      await supabase
          .from('coach_applications')
          .update({
            'status': 'rejected',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': currentUser.id,
            'rejection_reason': reason ?? 'Application declined',
          })
          .eq('id', requestId);

      // Log audit
      await logAdminAction(
        'coach_declined',
        target: application['user_id'],
        meta: {
          'request_id': requestId,
          'reason': reason,
        },
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error declining coach: $e');
      return false;
    }
  }

  // ===== ADMIN SETTINGS =====

  /// Get admin setting by key
  Future<Map<String, dynamic>?> getAdminSetting(String key) async {
    try {
      final response = await supabase
          .from('admin_settings')
          .select('value, updated_at, updated_by')
          .eq('key', key)
          .single();
      
      return response;
    } catch (e) {
      debugPrint('❌ Error getting admin setting: $e');
      return null;
    }
  }

  /// Upsert admin setting
  Future<bool> upsertAdminSetting(String key, Map<String, dynamic> value) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return false;

      await supabase
          .from('admin_settings')
          .upsert({
            'key': key,
            'value': value,
            'updated_at': DateTime.now().toIso8601String(),
            'updated_by': currentUser.id,
          });

      // Log audit
      await logAdminAction(
        'setting_updated',
        target: key,
        meta: {'value': value},
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error upserting admin setting: $e');
      return false;
    }
  }

  // ===== AUDIT LOGGING =====

  /// Log admin action
  Future<bool> logAdminAction(
    String action, {
    String? target,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return false;

      await supabase
          .from('admin_audit_log')
          .insert({
            'actor_id': currentUser.id,
            'action': action,
            'target': target,
            'meta': meta ?? {},
          });

      return true;
    } catch (e) {
      debugPrint('❌ Error logging admin action: $e');
      return false;
    }
  }

  /// Get audit logs with pagination
  Future<List<Map<String, dynamic>>> getAuditLogs({
    int limit = 50,
    int offset = 0,
    String? actionFilter,
  }) async {
    try {
      final request = supabase
          .from('admin_audit_log')
          .select('''
            *,
            actor:profiles!admin_audit_log_actor_id_fkey(id, email, name)
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (actionFilter != null && actionFilter.isNotEmpty) {
        // Note: Action filtering would need to be implemented differently
        // For now, we'll return all logs and filter client-side
      }

      final response = await request;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting audit logs: $e');
      return [];
    }
  }
}
