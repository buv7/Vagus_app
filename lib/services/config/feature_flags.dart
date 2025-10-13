import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';

/// Centralized feature flags for safe rollout and rollback
///
/// All new features should be behind flags until verified in production.
///
/// Usage:
/// ```dart
/// if (await FeatureFlags.instance.isEnabled(FeatureFlags.calendarAI)) {
///   // Use AI calendar features
/// }
/// ```
class FeatureFlags {
  static final FeatureFlags _instance = FeatureFlags._internal();
  static FeatureFlags get instance => _instance;

  FeatureFlags._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, bool> _cache = {};
  final Map<String, bool> _localOverrides = {};

  // ============================================================
  // SPRINT FEATURE FLAGS (Organized by Sprint)
  // ============================================================

  // Sprint 1: Auth System
  static const String passwordReset = 'auth_password_reset';
  static const String emailVerification = 'auth_email_verification';
  static const String biometrics = 'auth_biometrics';
  static const String deviceManagement = 'auth_device_management';
  static const String becomeCoach = 'auth_become_coach';

  // Sprint 2: AI Core
  static const String aiNutrition = 'ai_nutrition';
  static const String aiWorkout = 'ai_workout';
  static const String aiNotes = 'ai_notes';
  static const String aiCalendar = 'ai_calendar';
  static const String aiMessaging = 'ai_messaging';
  static const String aiTranscription = 'ai_transcription';
  static const String aiEmbeddings = 'ai_embeddings';

  // Sprint 3: Files & Media
  static const String filePreview = 'files_preview';
  static const String fileTags = 'files_tags';
  static const String fileComments = 'files_comments';
  static const String fileVersions = 'files_versions';
  static const String filePinning = 'files_pinning';

  // Sprint 4: Coach Notes
  static const String notesVoiceTranscription = 'notes_voice_transcription';
  static const String notesVersioning = 'notes_versioning';
  static const String notesDuplicateDetection = 'notes_duplicate_detection';

  // Sprint 5: Progress Analytics
  static const String progressCharts = 'progress_charts';
  static const String complianceTracking = 'progress_compliance';
  static const String checkinCalendar = 'progress_checkin_calendar';
  static const String coachFeedback = 'progress_coach_feedback';

  // Sprint 6: Messaging Features
  static const String messagingThreads = 'messaging_threads';
  static const String messagingSmartReplies = 'messaging_smart_replies';
  static const String messagingReadReceipts = 'messaging_read_receipts';
  static const String messagingPinning = 'messaging_pinning';
  static const String messagingSearch = 'messaging_search';
  static const String messagingTranslation = 'messaging_translation';

  // Sprint 7: Calendar & Booking
  static const String calendar = 'calendar_enabled';
  static const String calendarRecurring = 'calendar_recurring';
  static const String calendarBooking = 'calendar_booking';
  static const String calendarAI = 'calendar_ai';
  static const String calendarReminders = 'calendar_reminders';

  // Sprint 8: Admin Panels
  static const String adminUserManagement = 'admin_user_management';
  static const String adminCoachApproval = 'admin_coach_approval';
  static const String adminAIConfig = 'admin_ai_config';
  static const String adminBilling = 'admin_billing';
  static const String adminFileModeration = 'admin_file_moderation';

  // Sprint 9: Billing & Monetization
  static const String billing = 'billing_enabled';
  static const String subscriptions = 'billing_subscriptions';
  static const String planGating = 'billing_plan_gating';
  static const String coupons = 'billing_coupons';

  // Sprint 10: Settings & Themes
  static const String themeToggle = 'settings_theme_toggle';
  static const String languageSelector = 'settings_language_selector';
  static const String dataExport = 'settings_data_export';
  static const String accountDeletion = 'settings_account_deletion';

  // Supplements Module
  static const String supplementsModule = 'supplements_module';
  static const String supplementsView = 'supplements_view';
  static const String supplementsEdit = 'supplements_edit';

  // Existing Nutrition v2 flags
  static const String nutritionV2 = 'nutrition_v2_enabled';
  static const String mealPrep = 'nutrition_v2_meal_prep';
  static const String gamification = 'nutrition_v2_gamification';
  static const String restaurantMode = 'nutrition_v2_restaurant_mode';
  static const String macroCycling = 'nutrition_v2_macro_cycling';
  static const String allergyTracking = 'nutrition_v2_allergy_tracking';
  static const String advancedAnalytics = 'nutrition_v2_advanced_analytics';
  static const String integrations = 'nutrition_v2_integrations';
  static const String voiceInterface = 'nutrition_v2_voice';
  static const String collaboration = 'nutrition_v2_collaboration';
  static const String sustainability = 'nutrition_v2_sustainability';

  // Existing general flags
  static const String streaks = 'show_streaks';
  static const String announcements = 'enable_announcements';
  static const String confetti = 'enable_confetti';
  static const String animatedFeedback = 'enable_animated_feedback';
  static const String periodCountdown = 'enable_period_countdown';
  static const String checkinComparison = 'enable_checkin_comparison';
  static const String coachPortfolio = 'enable_coach_portfolio';
  static const String intakeForms = 'enable_intake_forms';

  // ============================================================
  // CORE METHODS
  // ============================================================

  /// Check if a feature is enabled (with caching)
  Future<bool> isEnabled(
    String featureKey, {
    bool defaultValue = false,
    bool forceRefresh = false,
  }) async {
    try {
      // Check local override first (for testing)
      if (_localOverrides.containsKey(featureKey)) {
        return _localOverrides[featureKey]!;
      }

      // Check cache
      if (!forceRefresh && _cache.containsKey(featureKey)) {
        return _cache[featureKey]!;
      }

      // Fetch from database
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return _getDefaultValue(featureKey, defaultValue);
      }

      final response = await _supabase
          .from('user_feature_flags')
          .select('enabled')
          .eq('user_id', user.id)
          .eq('feature_key', featureKey)
          .maybeSingle();

      if (response == null) {
        final value = _getDefaultValue(featureKey, defaultValue);
        _cache[featureKey] = value;
        return value;
      }

      final enabled = response['enabled'] as bool;
      _cache[featureKey] = enabled;
      return enabled;
    } catch (e, st) {
      Logger.error('Failed to check feature flag: $featureKey', error: e, stackTrace: st);
      return _getDefaultValue(featureKey, defaultValue);
    }
  }

  /// Set a feature flag value
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

      // Update cache
      _cache[key] = enabled;
      Logger.info('Feature flag updated: $key = $enabled');
    } catch (e, st) {
      Logger.error('Failed to set feature flag: $key', error: e, stackTrace: st);
    }
  }

  /// Get all flags for current user
  Future<Map<String, bool>> getAllFlags() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return _getDefaultFlags();

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

      return {..._getDefaultFlags(), ...flags};
    } catch (e, st) {
      Logger.error('Failed to get all feature flags', error: e, stackTrace: st);
      return _getDefaultFlags();
    }
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    Logger.debug('Feature flags cache cleared');
  }

  /// Preload important flags (call on app start)
  Future<void> preloadFlags() async {
    Logger.info('Preloading feature flags...');
    await Future.wait([
      // Sprint 2 AI flags
      isEnabled(aiNutrition),
      isEnabled(aiWorkout),
      isEnabled(aiNotes),
      
      // Sprint 7 Calendar flags
      isEnabled(calendar),
      isEnabled(calendarBooking),
      
      // Sprint 9 Billing flags
      isEnabled(billing),
      isEnabled(planGating),
      
      // Existing critical flags
      isEnabled(nutritionV2),
      isEnabled(coachPortfolio),
    ]);
    Logger.info('Feature flags preloaded');
  }

  // ============================================================
  // LOCAL OVERRIDES (for testing)
  // ============================================================

  /// Set a local override for testing
  void setLocalOverride(String featureKey, bool enabled) {
    _localOverrides[featureKey] = enabled;
    if (kDebugMode) {
      Logger.debug('Feature flag override: $featureKey = $enabled');
    }
  }

  /// Clear all local overrides
  void clearAllLocalOverrides() {
    _localOverrides.clear();
    Logger.debug('All feature flag overrides cleared');
  }

  /// Enable all Sprint features locally (testing mode)
  void enableAllSprintFeaturesLocally() {
    if (!kDebugMode) return;

    // Sprint 1
    setLocalOverride(passwordReset, true);
    setLocalOverride(emailVerification, true);
    setLocalOverride(biometrics, true);
    
    // Sprint 2
    setLocalOverride(aiNutrition, true);
    setLocalOverride(aiWorkout, true);
    setLocalOverride(aiNotes, true);
    
    // Sprint 3
    setLocalOverride(filePreview, true);
    setLocalOverride(fileTags, true);
    
    Logger.info('All sprint features enabled locally (debug mode)');
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  Map<String, bool> _getDefaultFlags() {
    return {
      // ============================================================
      // PRODUCTION SETTINGS (Oct 11, 2025 Launch)
      // ============================================================
      
      // Sprint 1: Auth (All SAFE - Enable)
      passwordReset: true,
      emailVerification: true,
      biometrics: true,
      deviceManagement: true,
      becomeCoach: true,
      
      // Sprint 2: AI Core (Gradual Rollout - OFF initially)
      aiNutrition: false,        // Enable after calendar soak test
      aiWorkout: false,          // Enable for pilot users
      aiNotes: false,            // Enable after testing
      aiCalendar: false,         // Turn on after calendar soak test
      aiMessaging: false,        // Enable after messaging testing
      
      // Sprint 3: Files & Media (All SAFE - Enable)
      filePreview: true,
      fileTags: true,
      fileComments: true,
      fileVersions: true,
      filePinning: true,
      
      // Sprint 4: Coach Notes (All SAFE - Enable)
      notesVoiceTranscription: true,
      notesVersioning: true,
      notesDuplicateDetection: true,
      
      // Sprint 5: Progress (All SAFE - Enable)
      progressCharts: true,
      complianceTracking: true,
      checkinCalendar: true,
      coachFeedback: true,
      
      // Sprint 6: Messaging (All SAFE - Enable)
      messagingThreads: true,
      messagingSmartReplies: true,
      messagingReadReceipts: true,
      messagingPinning: true,
      messagingSearch: true,
      messagingTranslation: true,
      
      // Sprint 7: Calendar & Booking (SAFE - All Enable)
      calendar: true,
      calendarRecurring: true,
      calendarBooking: true,
      calendarAI: false,         // Enable after soak test (uses edge function)
      calendarReminders: true,
      
      // Sprint 8: Admin Panels (All SAFE - Enable)
      adminUserManagement: true,
      adminCoachApproval: true,
      adminAIConfig: true,
      adminBilling: true,
      adminFileModeration: true,
      
      // Sprint 9: Billing (Manual admin for now)
      billing: true,
      subscriptions: true,
      planGating: true,
      coupons: true,
      
      // Sprint 10: Settings (GDPR compliant - Enable)
      themeToggle: true,
      languageSelector: true,
      dataExport: true,          // Uses deployed edge function
      accountDeletion: true,     // Uses deployed edge function
      
      // Supplements Module (Enable for all)
      supplementsModule: true,
      supplementsView: true,
      supplementsEdit: true,
      
      // Existing features stay ON
      streaks: true,
      announcements: true,
      confetti: true,
      animatedFeedback: true,
      periodCountdown: true,
      checkinComparison: true,
      coachPortfolio: true,
      intakeForms: true,
      
      // Nutrition v2 (Gradual rollout)
      nutritionV2: false,        // Enable after sprint completion
      mealPrep: false,
      gamification: false,
      restaurantMode: false,
    };
  }

  bool _getDefaultValue(String key, bool defaultValue) {
    final defaults = _getDefaultFlags();
    return defaults[key] ?? defaultValue;
  }
}

