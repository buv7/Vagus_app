import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing user settings (theme, language, reminders)
class SettingsService {
  static final SettingsService instance = SettingsService._();
  SettingsService._();

  final supabase = Supabase.instance.client;

  /// Load settings for current user, merging with admin defaults
  Future<Map<String, dynamic>> loadForCurrentUser() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return _getDefaultSettings();
      }

      // Get user settings
      final userSettings = await supabase
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      // Get admin defaults
      final adminDefaults = await _getAdminDefaults();

      // Merge user settings with admin defaults
      final settings = Map<String, dynamic>.from(adminDefaults);
      if (userSettings != null) {
        settings.addAll({
          'theme_mode': userSettings['theme_mode'] ?? adminDefaults['theme_mode'],
          'language_code': userSettings['language_code'] ?? adminDefaults['language_code'],
          'reminder_defaults': userSettings['reminder_defaults'] ?? adminDefaults['reminder_defaults'],
        });
      }

      return settings;
    } catch (e) {
      debugPrint('❌ Error loading settings: $e');
      return _getDefaultSettings();
    }
  }

  /// Save theme mode
  Future<void> saveThemeMode(String mode) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('user_settings')
          .upsert({
            'user_id': user.id,
            'theme_mode': mode,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('❌ Error saving theme mode: $e');
    }
  }

  /// Save language code
  Future<void> saveLanguageCode(String code) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('user_settings')
          .upsert({
            'user_id': user.id,
            'language_code': code,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('❌ Error saving language code: $e');
    }
  }

  /// Save reminder defaults (additive upsert)
  Future<void> saveReminderDefaults(Map<String, dynamic> json) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Get current settings to merge
      final current = await loadForCurrentUser();
      final currentDefaults = Map<String, dynamic>.from(current['reminder_defaults'] ?? {});
      currentDefaults.addAll(json);

      await supabase
          .from('user_settings')
          .upsert({
            'user_id': user.id,
            'reminder_defaults': currentDefaults,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('❌ Error saving reminder defaults: $e');
    }
  }

  /// Get admin defaults
  Future<Map<String, dynamic>> _getAdminDefaults() async {
    try {
      final themeDefault = await supabase
          .from('admin_settings')
          .select('value')
          .eq('key', 'ui.default_theme')
          .maybeSingle();

      final languageDefault = await supabase
          .from('admin_settings')
          .select('value')
          .eq('key', 'ui.default_language')
          .maybeSingle();

      return {
        'theme_mode': (themeDefault?['value'] as Map<String, dynamic>?)?['mode'] ?? 'system',
        'language_code': (languageDefault?['value'] as Map<String, dynamic>?)?['code'] ?? 'en',
        'reminder_defaults': <String, dynamic>{},
      };
    } catch (e) {
      debugPrint('❌ Error loading admin defaults: $e');
      return _getDefaultSettings();
    }
  }

  /// Get default settings
  Map<String, dynamic> _getDefaultSettings() {
    return {
      'theme_mode': 'system',
      'language_code': 'en',
      'reminder_defaults': <String, dynamic>{},
    };
  }
}
