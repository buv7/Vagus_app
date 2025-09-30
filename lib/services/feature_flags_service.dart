import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Feature flags service for gradual rollout and emergency rollback.
///
/// Enhanced with Nutrition Platform 2.0 specific flags and rollout capabilities.
class FeatureFlagsService {
  static final FeatureFlagsService _instance = FeatureFlagsService._internal();
  static FeatureFlagsService get instance => _instance;

  FeatureFlagsService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, bool> _cache = {};
  final Map<String, bool> _localOverrides = {};

  // ============================================================
  // NUTRITION V2.0 FEATURE FLAGS
  // ============================================================

  /// Master kill switch for entire Nutrition v2.0 system
  static const String nutritionV2Enabled = 'nutrition_v2_enabled';

  /// Individual feature flags
  static const String mealPrepEnabled = 'nutrition_v2_meal_prep';
  static const String gamificationEnabled = 'nutrition_v2_gamification';
  static const String restaurantModeEnabled = 'nutrition_v2_restaurant_mode';
  static const String macroCyclingEnabled = 'nutrition_v2_macro_cycling';
  static const String allergyTrackingEnabled = 'nutrition_v2_allergy_tracking';
  static const String advancedAnalyticsEnabled = 'nutrition_v2_advanced_analytics';
  static const String integrationsEnabled = 'nutrition_v2_integrations';
  static const String voiceInterfaceEnabled = 'nutrition_v2_voice';
  static const String collaborationEnabled = 'nutrition_v2_collaboration';
  static const String sustainabilityEnabled = 'nutrition_v2_sustainability';

  /// Get all feature flags for the current user
  Future<Map<String, bool>> getFlagsForUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      final response = await _supabase
          .from('user_feature_flags')
          .select('feature_key, enabled')
          .eq('user_id', user.id);

      final flags = <String, bool>{};
      for (final row in response as List<dynamic>) {
        final key = row['feature_key'] as String;
        final enabled = row['enabled'] as bool;
        flags[key] = enabled;
      }

      return flags;
    } catch (e) {
      // Return default flags if there's an error
      return _getDefaultFlags();
    }
  }

  /// Set a feature flag for the current user
  Future<void> setFlag(String key, bool enabled) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('user_feature_flags').upsert({
        'user_id': user.id,
        'feature_key': key,
        'enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently handle errors - feature flags are not critical
      debugPrint('Failed to set feature flag $key: $e');
    }
  }

  /// Check if a specific feature flag is enabled for the current user
  Future<bool> isFeatureEnabled(String key) async {
    try {
      final flags = await getFlagsForUser();
      return flags[key] ?? _getDefaultFlagValue(key);
    } catch (e) {
      return _getDefaultFlagValue(key);
    }
  }

  /// Get default feature flags (fallback when database is unavailable)
  Map<String, bool> _getDefaultFlags() {
    return {
      'show_streaks': true,
      'enable_announcements': true,
      'enable_confetti': true,
      'enable_animated_feedback': true,
      'enable_period_countdown': true,
      'enable_checkin_comparison': true,
      'enable_coach_portfolio': true,
      'enable_intake_forms': true,
    };
  }

  /// Get default value for a specific feature flag
  bool _getDefaultFlagValue(String key) {
    final defaults = _getDefaultFlags();
    return defaults[key] ?? true; // Default to enabled for new features
  }

  /// Get available feature flags with descriptions
  Map<String, String> getAvailableFeatures() {
    return {
      'show_streaks': 'Show activity streaks and progress tracking',
      'enable_announcements': 'Display announcements and notifications',
      'enable_confetti': 'Show celebration animations for milestones',
      'enable_animated_feedback': 'Display animated feedback overlays',
      'enable_period_countdown': 'Show coaching period progress bars',
      'enable_checkin_comparison': 'Enable photo comparison features',
      'enable_coach_portfolio': 'Access to coach portfolio features',
      'enable_intake_forms': 'Access to intake form features',
    };
  }

  /// Reset all feature flags to default values
  Future<void> resetToDefaults() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final defaults = _getDefaultFlags();
      for (final entry in defaults.entries) {
        await setFlag(entry.key, entry.value);
      }
    } catch (e) {
      debugPrint('Failed to reset feature flags: $e');
    }
  }

  // ============================================================
  // NUTRITION V2.0 SPECIFIC METHODS
  // ============================================================

  /// Checks if a feature is enabled with caching and local overrides
  Future<bool> isEnabled(
    String featureKey, {
    bool defaultValue = false,
    bool forceRefresh = false,
  }) async {
    // Check local override first (for testing)
    if (_localOverrides.containsKey(featureKey)) {
      return _localOverrides[featureKey]!;
    }

    // Check cache
    if (!forceRefresh && _cache.containsKey(featureKey)) {
      return _cache[featureKey]!;
    }

    // Check master kill switch first
    if (featureKey != nutritionV2Enabled) {
      final masterEnabled = await isFeatureEnabled(nutritionV2Enabled);
      if (!masterEnabled) {
        _cache[featureKey] = false;
        return false;
      }
    }

    // Fetch from remote
    final enabled = await isFeatureEnabled(featureKey);
    _cache[featureKey] = enabled;
    return enabled;
  }

  /// Clears the cache
  void clearCache() {
    _cache.clear();
  }

  /// Preloads all nutrition v2 flags (call on app start)
  Future<void> preloadNutritionFlags() async {
    await Future.wait([
      isEnabled(nutritionV2Enabled),
      isEnabled(mealPrepEnabled),
      isEnabled(gamificationEnabled),
      isEnabled(restaurantModeEnabled),
      isEnabled(macroCyclingEnabled),
      isEnabled(allergyTrackingEnabled),
      isEnabled(advancedAnalyticsEnabled),
      isEnabled(integrationsEnabled),
      isEnabled(voiceInterfaceEnabled),
      isEnabled(collaborationEnabled),
      isEnabled(sustainabilityEnabled),
    ]);
  }

  /// Sets a local override for testing (bypasses remote config)
  void setLocalOverride(String featureKey, bool enabled) {
    _localOverrides[featureKey] = enabled;
    debugPrint('Feature flag override: $featureKey = $enabled');
  }

  /// Clears all local overrides
  void clearAllLocalOverrides() {
    _localOverrides.clear();
  }

  /// Enables all nutrition v2 features locally (testing mode)
  void enableAllNutritionFeaturesLocally() {
    setLocalOverride(nutritionV2Enabled, true);
    setLocalOverride(mealPrepEnabled, true);
    setLocalOverride(gamificationEnabled, true);
    setLocalOverride(restaurantModeEnabled, true);
    setLocalOverride(macroCyclingEnabled, true);
    setLocalOverride(allergyTrackingEnabled, true);
    setLocalOverride(advancedAnalyticsEnabled, true);
    setLocalOverride(integrationsEnabled, true);
    setLocalOverride(voiceInterfaceEnabled, true);
    setLocalOverride(collaborationEnabled, true);
    setLocalOverride(sustainabilityEnabled, true);
  }
}
