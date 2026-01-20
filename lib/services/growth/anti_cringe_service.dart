import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/feature_flags.dart';

enum CringeCheckStatus {
  allow,
  warn,
  block,
}

class CringeCheckResult {
  final CringeCheckStatus status;
  final String? modifiedText;
  final String? reason;

  const CringeCheckResult({
    required this.status,
    this.modifiedText,
    this.reason,
  });
}

class AntiCringeService {
  AntiCringeService._();
  static final AntiCringeService I = AntiCringeService._();

  final _db = Supabase.instance.client;

  /// Check share text for cringe content
  Future<CringeCheckResult> checkShareForCringe({
    required String text,
    Map<String, dynamic>? context,
  }) async {
    try {
      final isEnabled = await FeatureFlags.instance.isEnabled(FeatureFlags.antiCringeSafeguards);
      if (!isEnabled) {
        return const CringeCheckResult(status: CringeCheckStatus.allow);
      }

      // Get active anti-cringe rules
      final rules = await _getActiveRules();

      String currentText = text;
      CringeCheckStatus finalStatus = CringeCheckStatus.allow;
      String? finalReason;

      // Check each rule
      for (final rule in rules) {
        final matches = _checkRuleConditions(rule, currentText, context);
        if (matches) {
          switch (rule['rule_type'] as String) {
            case 'prevent_share':
              finalStatus = CringeCheckStatus.block;
              finalReason = rule['rule_action']['reason'] as String? ?? 'Content blocked by anti-cringe rule';
              return CringeCheckResult(
                status: finalStatus,
                reason: finalReason,
              );
            case 'modify_share':
              final action = rule['rule_action'] as Map<String, dynamic>;
              final replacements = action['replacements'] as Map<String, dynamic>? ?? {};
              
              // Apply text replacements
              for (final entry in replacements.entries) {
                currentText = currentText.replaceAll(entry.key, entry.value as String);
              }
              
              if (finalStatus == CringeCheckStatus.allow) {
                finalStatus = CringeCheckStatus.warn;
                finalReason = 'Content modified by anti-cringe rule';
              }
              break;
            case 'warn':
              if (finalStatus == CringeCheckStatus.allow) {
                finalStatus = CringeCheckStatus.warn;
                finalReason = rule['rule_action']['message'] as String? ?? 'Content may be inappropriate';
              }
              break;
          }
        }
      }

      return CringeCheckResult(
        status: finalStatus,
        modifiedText: currentText != text ? currentText : null,
        reason: finalReason,
      );
    } catch (e) {
      debugPrint('Failed to check share for cringe: $e');
      // On error, allow (fail-open for non-destructive)
      return const CringeCheckResult(status: CringeCheckStatus.allow);
    }
  }

  /// Get active anti-cringe rules
  Future<List<Map<String, dynamic>>> _getActiveRules() async {
    try {
      final res = await _db
          .from('anti_cringe_rules')
          .select()
          .eq('enabled', true)
          .order('created_at', ascending: true);

      return (res as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Failed to get anti-cringe rules: $e');
      return [];
    }
  }

  /// Check if rule conditions match
  bool _checkRuleConditions(
    Map<String, dynamic> rule,
    String text,
    Map<String, dynamic>? context,
  ) {
    try {
      final conditions = rule['rule_conditions'] as Map<String, dynamic>? ?? {};
      if (conditions.isEmpty) return false;

      // Check keyword conditions
      if (conditions.containsKey('keywords')) {
        final keywords = conditions['keywords'] as List<dynamic>? ?? [];
        final textLower = text.toLowerCase();
        for (final keyword in keywords) {
          if (textLower.contains(keyword.toString().toLowerCase())) {
            return true;
          }
        }
      }

      // Check length conditions
      if (conditions.containsKey('max_length')) {
        final maxLength = conditions['max_length'] as int?;
        if (maxLength != null && text.length > maxLength) {
          return true;
        }
      }

      // Check pattern conditions (regex-like)
      if (conditions.containsKey('patterns')) {
        final patterns = conditions['patterns'] as List<dynamic>? ?? [];
        final textLower = text.toLowerCase();
        for (final pattern in patterns) {
          if (textLower.contains(pattern.toString().toLowerCase())) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('Failed to check rule conditions: $e');
      return false;
    }
  }
}
