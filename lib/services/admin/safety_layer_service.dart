import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/admin/admin_models.dart';
import '../config/feature_flags.dart';

class SafetyLayerService {
  SafetyLayerService._();
  static final SafetyLayerService I = SafetyLayerService._();

  final _db = Supabase.instance.client;

  /// Check if an action is allowed by safety rules
  Future<Map<String, dynamic>> checkSafetyRule({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    try {
      // Check if safety layer is enabled
      final isEnabled = await FeatureFlags.instance.isEnabled(FeatureFlags.adminSafetyLayer);
      if (!isEnabled) {
        return {
          'allowed': true,
          'rule': null,
          'reason': 'Safety layer disabled',
          'requireApproval': false,
        };
      }

      // Get active rules matching the action pattern
      final rules = await _getActiveRulesForAction(action);

      if (rules.isEmpty) {
        // No rules match - allow by default
        await _logAudit(
          action: action,
          payload: payload,
          result: SafetyAuditResult.allowed,
          reason: 'No matching rules',
        );
        return {
          'allowed': true,
          'rule': null,
          'reason': 'No matching rules',
          'requireApproval': false,
        };
      }

      // Check each rule
      for (final rule in rules) {
        final matches = _checkRuleConditions(rule, payload);
        if (matches) {
          // Rule matched - apply action
          SafetyAuditResult result;
          bool allowed;
          String reason;

          switch (rule.actionOnMatch) {
            case SafetyActionOnMatch.block:
              result = SafetyAuditResult.blocked;
              allowed = false;
              reason = 'Blocked by rule: ${rule.ruleName}';
              break;
            case SafetyActionOnMatch.requireApproval:
              result = SafetyAuditResult.requiresApproval;
              allowed = false;
              reason = 'Requires approval (level ${rule.approvalRequiredLevel}): ${rule.ruleName}';
              break;
            case SafetyActionOnMatch.warn:
              result = SafetyAuditResult.warned;
              allowed = true;
              reason = 'Warning from rule: ${rule.ruleName}';
              break;
          }

          await _logAudit(
            action: action,
            payload: payload,
            result: result,
            reason: reason,
            ruleId: rule.id,
          );

          return {
            'allowed': allowed,
            'rule': rule.ruleName,
            'reason': reason,
            'requireApproval': rule.actionOnMatch == SafetyActionOnMatch.requireApproval,
          };
        }
      }

      // No rules matched conditions - allow
      await _logAudit(
        action: action,
        payload: payload,
        result: SafetyAuditResult.allowed,
        reason: 'No matching conditions',
      );

      return {
        'allowed': true,
        'rule': null,
        'reason': 'No matching conditions',
        'requireApproval': false,
      };
    } catch (e) {
      debugPrint('Failed to check safety rule: $e');
      // ✅ VAGUS ADD: fail-closed for destructive actions START
      // For destructive actions, fail-closed (block on error) is safer
      final destructiveActions = ['update_user_role', 'disable_user', 'reset_user_ai_usage', 'approve_coach'];
      final isDestructive = destructiveActions.contains(action);
      
      if (isDestructive) {
        // Fail-closed: block on error
        await _logAudit(
          action: action,
          payload: payload,
          result: SafetyAuditResult.blocked,
          reason: 'Safety layer error - blocked for safety: $e',
        );
        return {
          'allowed': false,
          'rule': null,
          'reason': 'Safety layer error - action blocked for safety. Please contact system administrator.',
          'requireApproval': false,
        };
      } else {
        // Fail-open for non-destructive actions (warn-type)
        await _logAudit(
          action: action,
          payload: payload,
          result: SafetyAuditResult.warned,
          reason: 'Error checking rules: $e',
        );
        return {
          'allowed': true,
          'rule': null,
          'reason': 'Error checking rules (non-destructive action allowed)',
          'requireApproval': false,
        };
      }
      // ✅ VAGUS ADD: fail-closed for destructive actions END
    }
  }

  /// Get active rules matching an action pattern
  Future<List<SafetyLayerRule>> _getActiveRulesForAction(String action) async {
    try {
      final res = await _db
          .from('safety_layer_rules')
          .select()
          .eq('is_active', true)
          .like('action_pattern', '%$action%');

      return (res as List)
          .map((e) => SafetyLayerRule.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to get active rules: $e');
      return [];
    }
  }

  /// Check if rule conditions match payload
  bool _checkRuleConditions(SafetyLayerRule rule, Map<String, dynamic> payload) {
    try {
      final conditions = rule.conditions;
      if (conditions.isEmpty) return true; // No conditions = always match

      // Simple condition checking (can be enhanced)
      for (final entry in conditions.entries) {
        final key = entry.key;
        final expectedValue = entry.value;

        if (!payload.containsKey(key)) return false;
        if (payload[key] != expectedValue) return false;
      }

      return true;
    } catch (e) {
      debugPrint('Failed to check rule conditions: $e');
      return false;
    }
  }

  /// Log safety audit event
  Future<void> _logAudit({
    required String action,
    required Map<String, dynamic> payload,
    required SafetyAuditResult result,
    required String reason,
    String? ruleId,
  }) async {
    try {
      final currentUser = _db.auth.currentUser;
      if (currentUser == null) return;

      await _db.from('safety_layer_audit').insert({
        'rule_id': ruleId,
        'action': action,
        'payload': payload,
        'actor_id': currentUser.id,
        'result': result.toDb(),
        'reason': reason,
      });
    } catch (e) {
      debugPrint('Failed to log safety audit: $e');
    }
  }

  /// Get recent safety audit logs
  Future<List<SafetyLayerAudit>> getRecentAuditLogs({
    int limit = 20,
  }) async {
    try {
      final res = await _db
          .from('safety_layer_audit')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (res as List)
          .map((e) => SafetyLayerAudit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to get safety audit logs: $e');
      return [];
    }
  }
}
