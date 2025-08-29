import 'package:flutter/material.dart';
import 'settings_service.dart';

/// Controller for managing live app settings state
class SettingsController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  Map<String, dynamic> _reminderDefaults = const {};

  // Getters
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  Map<String, dynamic> get reminderDefaults => _reminderDefaults;

  /// Load settings from service
  Future<void> load() async {
    try {
      final settings = await SettingsService.instance.loadForCurrentUser();
      
      _themeMode = _parseThemeMode(settings['theme_mode'] ?? 'system');
      _locale = _parseLocale(settings['language_code'] ?? 'en');
      _reminderDefaults = Map<String, dynamic>.from(settings['reminder_defaults'] ?? {});
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading settings in controller: $e');
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    await SettingsService.instance.saveThemeMode(_themeModeToString(mode));
  }

  /// Set language
  Future<void> setLanguage(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    await SettingsService.instance.saveLanguageCode(locale.languageCode);
  }

  /// Set reminder defaults
  Future<void> setReminderDefaults(Map<String, dynamic> json) async {
    _reminderDefaults.addAll(json);
    notifyListeners();
    
    await SettingsService.instance.saveReminderDefaults(json);
  }

  /// Parse theme mode from string
  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  /// Parse locale from language code
  Locale _parseLocale(String code) {
    switch (code) {
      case 'ar':
        return const Locale('ar');
      case 'ku':
        return const Locale('ku');
      case 'en':
        return const Locale('en');
      default:
        return const Locale('en');
    }
  }

  /// Convert theme mode to string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
