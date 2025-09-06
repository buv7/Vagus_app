import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureFlagsService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      print('Failed to set feature flag $key: $e');
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
      print('Failed to reset feature flags: $e');
    }
  }
}
