import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ai/ai_usage_service.dart';
import '../../screens/billing/upgrade_screen.dart';

/// Manages plan-based access control and AI usage limits
class PlanAccessManager {
  PlanAccessManager._();
  static final PlanAccessManager instance = PlanAccessManager._();

  final supabase = Supabase.instance.client;
  final _aiUsageService = AIUsageService.instance;

  /// Feature matrix: which features are available to which plans
  final Map<String, Set<String>> _featureMatrix = {
    'supplements.view': {'free', 'premium_client', 'premium_coach', 'admin_override'},
    'supplements.edit': {'premium_coach', 'admin_override'},
    'supplements.advanced_scheduling': {'premium_coach', 'premium_client', 'admin_override'},
  };

  /// Check if user has access to a specific feature based on their plan
  Future<bool> hasFeatureAccess(String featureKey) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return false;

      // Get user's plan
      final entitlements = await supabase
          .from('entitlements_v')
          .select('plan_code')
          .eq('user_id', currentUser.id)
          .maybeSingle();
      
      if (entitlements == null) return false;
      
      final planCode = entitlements['plan_code'] as String? ?? 'free';
      
      // Check if plan has access to feature
      final allowedPlans = _featureMatrix[featureKey] ?? {};
      return allowedPlans.contains(planCode) || allowedPlans.contains('admin_override');
    } catch (e) {
      debugPrint('❌ Error checking feature access for $featureKey: $e');
      return false;
    }
  }

  /// Get remaining AI calls for current user
  Future<int> remainingAICalls() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return 0;

      // Get user's entitlements
      final entitlements = await supabase
          .from('entitlements_v')
          .select('ai_monthly_limit')
          .eq('user_id', currentUser.id)
          .maybeSingle();
      
      if (entitlements == null) return 0;
      
      final monthlyLimit = (entitlements['ai_monthly_limit'] as num?)?.toInt() ?? 200;
      
      // Get current month usage
      final usageData = await _aiUsageService.getCurrentMonthUsage();
      final currentUsage = (usageData?['requests_count'] as num?)?.toInt() ?? 0;
      
      final remaining = monthlyLimit - currentUsage;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      debugPrint('❌ Error getting remaining AI calls: $e');
      return 0;
    }
  }

  /// Check if a feature is enabled for current user
  Future<bool> isFeatureEnabled(String feature) async {
    // Placeholder for feature flags
    // In the future, this could check against plan features or admin settings
    return true;
  }

  /// Check if user is Pro
  Future<bool> isProUser() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return false;

      // Get user's entitlements
      final entitlements = await supabase
          .from('entitlements_v')
          .select('plan_code')
          .eq('user_id', currentUser.id)
          .maybeSingle();
      
      if (entitlements == null) return false;
      
      final planCode = entitlements['plan_code'] as String?;
      return planCode == 'pro' || planCode == 'premium';
    } catch (e) {
      debugPrint('❌ Error checking Pro status: $e');
      return false;
    }
  }

  /// Guard against paywall or redirect to upgrade
  void guardOrPaywall(BuildContext context, {required String feature}) {
    // Navigate to upgrade screen using existing navigation patterns
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UpgradeScreen(),
      ),
    );
  }
}
