import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
// TODO: Add onesignal_flutter package to pubspec.yaml
// import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../config/env_config.dart';
import '../../models/notifications/workout_notification_types.dart';

// Stub classes until OneSignal is added
class OneSignal {
  static Future<void> initialize(String appId) async {}
  static Future<void> login(String userId) async {}
  static Future<void> logout() async {}
  static _NotificationsStub get Notifications => _NotificationsStub();
  static _UserStub get User => _UserStub();
}

class _NotificationsStub {
  void addPermissionObserver(Function callback) {}
  void addClickListener(Function callback) {}
  void addForegroundWillDisplayListener(Function callback) {}
  Future<bool> requestPermission(bool fallbackToSettings) async => true;
}

class _UserStub {
  Future<void> addTag(String key, String value) async {}
  Future<void> addTags(Map<String, String> tags) async {}
  Future<void> removeTag(String key) async {}
  Future<void> removeTags(List<String> keys) async {}
  Future<String?> getOnesignalId() async => null;
}

class OSNotificationClickEvent {
  dynamic notification;
}

class OSNotificationWillDisplayEvent {
  dynamic notification;
  void preventDefault() {}
}

/// OneSignal notification service for VAGUS
/// Handles push notifications, device registration, and workout-specific notifications
class OneSignalService {
  OneSignalService._();
  static final OneSignalService instance = OneSignalService._();

  bool _initialized = false;
  String? _currentPlayerId;
  final supabase = Supabase.instance.client;

  /// Initialize OneSignal service
  /// Call this once in main() after Supabase initialization
  Future<void> init() async {
    if (_initialized) return;

    // Get OneSignal App ID from environment
    final appId = EnvConfig.oneSignalAppId;

    // Skip initialization if OneSignal is not configured
    if (appId.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️  OneSignal App ID not configured in .env file');
        debugPrint('   Push notifications will be disabled');
      }
      return;
    }

    try {
      // Initialize OneSignal
      OneSignal.initialize(appId);

      // Request notification permissions
      await OneSignal.Notifications.requestPermission(true);

      // Set up notification click handler
      OneSignal.Notifications.addClickListener(_handleNotificationClick);

      // Set up notification received handler (foreground)
      OneSignal.Notifications.addForegroundWillDisplayListener(_handleForegroundNotification);

      // Get player ID
      final deviceState = await OneSignal.User.getOnesignalId();
      _currentPlayerId = deviceState;

      // Sync with Supabase
      if (_currentPlayerId != null) {
        await _syncPlayerIdWithSupabase(_currentPlayerId!);
      }

      _initialized = true;
      debugPrint('✅ OneSignal initialized with player ID: $_currentPlayerId');
    } catch (e) {
      debugPrint('❌ OneSignal initialization failed: $e');
    }
  }

  /// Handle notification click events
  void _handleNotificationClick(OSNotificationClickEvent event) {
    debugPrint('📱 Notification clicked: ${event.notification.additionalData}');

    final additionalData = event.notification.additionalData;
    if (additionalData == null) return;

    final type = additionalData['type'] as String?;
    if (type == null) return;

    final notificationType = WorkoutNotificationType.fromString(type);
    _handleDeepLink(notificationType, additionalData);
  }

  /// Handle foreground notification display
  void _handleForegroundNotification(OSNotificationWillDisplayEvent event) {
    debugPrint('📬 Foreground notification: ${event.notification.title}');
    // Allow notification to display
    event.notification;
  }

  /// Handle deep linking based on notification type
  void _handleDeepLink(
    WorkoutNotificationType type,
    Map<String, dynamic> data,
  ) {
    // This will be called by the app's navigation service
    // For now, just log the intent
    debugPrint('🔗 Deep link: $type with data: $data');
    // TODO: Implement navigation via NavigationService
  }

  /// Sync OneSignal player ID with Supabase
  Future<void> _syncPlayerIdWithSupabase(String playerId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('profiles').upsert({
        'id': userId,
        'onesignal_player_id': playerId,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Synced player ID with Supabase');
    } catch (e) {
      debugPrint('❌ Failed to sync player ID: $e');
    }
  }

  /// Set external user ID (Supabase user ID)
  Future<void> setExternalUserId(String userId) async {
    if (!_initialized) return;

    try {
      await OneSignal.login(userId);
      debugPrint('✅ Set external user ID: $userId');
    } catch (e) {
      debugPrint('❌ Failed to set external user ID: $e');
    }
  }

  /// Remove external user ID (on logout)
  Future<void> removeExternalUserId() async {
    if (!_initialized) return;

    try {
      await OneSignal.logout();
      debugPrint('✅ Removed external user ID');
    } catch (e) {
      debugPrint('❌ Failed to remove external user ID: $e');
    }
  }

  // ==================== Workout Notification Methods ====================

  /// Send workout reminder notification
  Future<void> sendWorkoutReminder(
    String clientId,
    String dayLabel,
    DateTime scheduledTime, {
    int? exerciseCount,
    int? estimatedDuration,
    List<String>? muscleGroups,
  }) async {
    try {
      final notification = WorkoutReminderNotification(
        dayId: '', // Will be set by backend
        dayLabel: dayLabel,
        scheduledTime: scheduledTime,
        exerciseCount: exerciseCount ?? 0,
        estimatedDuration: estimatedDuration ?? 60,
        muscleGroups: muscleGroups ?? [],
      );

      await _sendNotificationViaAPI(
        userIds: [clientId],
        title: notification.title,
        body: notification.body,
        data: {
          'type': WorkoutNotificationType.workoutReminder.value,
          'payload': notification.toJson(),
        },
        buttons: [
          {'id': 'start', 'text': 'Start Workout'},
          {'id': 'snooze', 'text': 'Snooze 15min'},
        ],
      );

      debugPrint('✅ Sent workout reminder to $clientId');
    } catch (e) {
      debugPrint('❌ Failed to send workout reminder: $e');
      rethrow;
    }
  }

  /// Send plan assigned notification
  Future<void> sendPlanAssignedNotification(
    String clientId,
    String planName,
    String coachName, {
    required String planId,
    required int totalWeeks,
    required DateTime startDate,
  }) async {
    try {
      final notification = PlanAssignedNotification(
        planId: planId,
        planName: planName,
        coachId: '', // Will be set by backend
        coachName: coachName,
        totalWeeks: totalWeeks,
        startDate: startDate,
      );

      await _sendNotificationViaAPI(
        userIds: [clientId],
        title: notification.title,
        body: notification.body,
        data: {
          'type': WorkoutNotificationType.planAssigned.value,
          'payload': notification.toJson(),
        },
        buttons: [
          {'id': 'view', 'text': 'View Plan'},
        ],
      );

      debugPrint('✅ Sent plan assigned notification to $clientId');
    } catch (e) {
      debugPrint('❌ Failed to send plan assigned notification: $e');
      rethrow;
    }
  }

  /// Send PR celebration notification
  Future<void> sendPRCelebration(
    String clientId,
    String exerciseName,
    String achievement, {
    required String prType,
    required double previousValue,
    required double newValue,
    required double improvement,
  }) async {
    try {
      final notification = PRCelebrationNotification(
        exerciseName: exerciseName,
        prType: prType,
        previousValue: previousValue,
        newValue: newValue,
        improvement: improvement,
        achievedDate: DateTime.now(),
      );

      await _sendNotificationViaAPI(
        userIds: [clientId],
        title: notification.title,
        body: notification.body,
        data: {
          'type': WorkoutNotificationType.prCelebration.value,
          'payload': notification.toJson(),
        },
        largeIcon: 'ic_trophy', // Custom icon for celebration
        sound: 'celebration.wav',
      );

      debugPrint('✅ Sent PR celebration to $clientId');
    } catch (e) {
      debugPrint('❌ Failed to send PR celebration: $e');
      rethrow;
    }
  }

  /// Send coach feedback notification
  Future<void> sendCoachFeedback(
    String clientId,
    String exerciseName,
    String comment, {
    required String coachId,
    required String coachName,
    required String exerciseId,
    String? videoUrl,
  }) async {
    try {
      final notification = CoachFeedbackNotification(
        coachId: coachId,
        coachName: coachName,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        comment: comment,
        videoUrl: videoUrl,
        commentedAt: DateTime.now(),
      );

      await _sendNotificationViaAPI(
        userIds: [clientId],
        title: notification.title,
        body: notification.body,
        data: {
          'type': WorkoutNotificationType.coachFeedback.value,
          'payload': notification.toJson(),
        },
        buttons: [
          {'id': 'reply', 'text': 'Reply'},
          {'id': 'view', 'text': 'View Exercise'},
        ],
      );

      debugPrint('✅ Sent coach feedback to $clientId');
    } catch (e) {
      debugPrint('❌ Failed to send coach feedback: $e');
      rethrow;
    }
  }

  /// Send weekly summary notification
  Future<void> sendWeeklySummary(
    String clientId,
    Map<String, dynamic> summaryData,
  ) async {
    try {
      final notification = WeeklySummaryNotification(
        weekNumber: summaryData['week_number'] ?? 0,
        weekStart: DateTime.parse(summaryData['week_start']),
        weekEnd: DateTime.parse(summaryData['week_end']),
        completedSessions: summaryData['completed_sessions'] ?? 0,
        totalSessions: summaryData['total_sessions'] ?? 0,
        totalVolume: summaryData['total_volume']?.toDouble() ?? 0.0,
        newPRs: summaryData['new_prs'] ?? 0,
        consistencyScore: summaryData['consistency_score']?.toDouble() ?? 0.0,
        summaryText: summaryData['summary_text'] ?? '',
      );

      await _sendNotificationViaAPI(
        userIds: [clientId],
        title: notification.title,
        body: notification.body,
        data: {
          'type': WorkoutNotificationType.weeklySummary.value,
          'payload': notification.toJson(),
        },
        buttons: [
          {'id': 'view_details', 'text': 'View Details'},
        ],
      );

      debugPrint('✅ Sent weekly summary to $clientId');
    } catch (e) {
      debugPrint('❌ Failed to send weekly summary: $e');
      rethrow;
    }
  }

  /// Send rest day reminder
  Future<void> sendRestDayReminder(
    String clientId,
    String motivationalMessage, {
    bool isActiveRecovery = false,
    List<String>? recoveryActivities,
  }) async {
    try {
      final notification = RestDayNotification(
        date: DateTime.now(),
        motivationalMessage: motivationalMessage,
        isActiveRecovery: isActiveRecovery,
        recoveryActivities: recoveryActivities,
      );

      await _sendNotificationViaAPI(
        userIds: [clientId],
        title: notification.title,
        body: notification.body,
        data: {
          'type': WorkoutNotificationType.restDayReminder.value,
          'payload': notification.toJson(),
        },
      );

      debugPrint('✅ Sent rest day reminder to $clientId');
    } catch (e) {
      debugPrint('❌ Failed to send rest day reminder: $e');
      rethrow;
    }
  }

  /// Send deload week alert
  Future<void> sendDeloadWeekAlert(
    String clientId,
    int weekNumber,
    String reason, {
    double intensityReduction = 0.5,
    List<String>? recommendations,
  }) async {
    try {
      final notification = DeloadWeekNotification(
        weekNumber: weekNumber,
        reason: reason,
        intensityReduction: intensityReduction,
        recommendations: recommendations ?? [],
      );

      await _sendNotificationViaAPI(
        userIds: [clientId],
        title: notification.title,
        body: notification.body,
        data: {
          'type': WorkoutNotificationType.deloadWeekAlert.value,
          'payload': notification.toJson(),
        },
      );

      debugPrint('✅ Sent deload week alert to $clientId');
    } catch (e) {
      debugPrint('❌ Failed to send deload week alert: $e');
      rethrow;
    }
  }

  /// Send missed workout follow-up
  Future<void> sendMissedWorkoutNotification(
    String clientId,
    String dayLabel, {
    required String dayId,
    required int consecutiveMissed,
  }) async {
    try {
      final motivationalMessages = [
        "Don't worry! Every champion has missed days. Let's get back on track! 💪",
        "You've got this! One workout at a time. 🎯",
        "Progress, not perfection. Let's make today count! 🔥",
        "Your future self will thank you for showing up today! 🌟",
      ];

      final notification = MissedWorkoutNotification(
        dayId: dayId,
        dayLabel: dayLabel,
        missedDate: DateTime.now(),
        consecutiveMissed: consecutiveMissed,
        motivationalMessage: motivationalMessages[consecutiveMissed.clamp(0, 3)],
      );

      await _sendNotificationViaAPI(
        userIds: [clientId],
        title: notification.title,
        body: notification.body,
        data: {
          'type': WorkoutNotificationType.missedWorkout.value,
          'payload': notification.toJson(),
        },
        buttons: [
          {'id': 'reschedule', 'text': 'Reschedule'},
          {'id': 'start_now', 'text': 'Start Now'},
        ],
      );

      debugPrint('✅ Sent missed workout notification to $clientId');
    } catch (e) {
      debugPrint('❌ Failed to send missed workout notification: $e');
      rethrow;
    }
  }

  /// Schedule workout reminders for a plan
  Future<void> scheduleWorkoutReminders(
    String planId,
    Map<String, dynamic> schedule,
  ) async {
    try {
      // Call Edge Function to schedule reminders
      final response = await supabase.functions.invoke(
        'schedule-workout-reminders',
        body: {
          'plan_id': planId,
          'schedule': schedule,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to schedule reminders: ${response.data}');
      }

      debugPrint('✅ Scheduled workout reminders for plan $planId');
    } catch (e) {
      debugPrint('❌ Failed to schedule workout reminders: $e');
      rethrow;
    }
  }

  /// Cancel scheduled reminders for a plan
  Future<void> cancelScheduledReminders(String planId) async {
    try {
      final response = await supabase.functions.invoke(
        'cancel-workout-reminders',
        body: {'plan_id': planId},
      );

      if (response.status != 200) {
        throw Exception('Failed to cancel reminders: ${response.data}');
      }

      debugPrint('✅ Cancelled reminders for plan $planId');
    } catch (e) {
      debugPrint('❌ Failed to cancel reminders: $e');
      rethrow;
    }
  }

  // ==================== Notification Preferences ====================

  /// Save notification preferences
  Future<void> saveNotificationPreferences(
    String userId,
    WorkoutNotificationPreferences preferences,
  ) async {
    try {
      await supabase.from('notification_preferences').upsert({
        'user_id': userId,
        'preferences': preferences.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update OneSignal tags based on preferences
      await _updateOneSignalTags(preferences);

      debugPrint('✅ Saved notification preferences');
    } catch (e) {
      debugPrint('❌ Failed to save notification preferences: $e');
      rethrow;
    }
  }

  /// Get notification preferences
  Future<WorkoutNotificationPreferences> getNotificationPreferences(
    String userId,
  ) async {
    try {
      final response = await supabase
          .from('notification_preferences')
          .select('preferences')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return WorkoutNotificationPreferences();
      }

      return WorkoutNotificationPreferences.fromJson(
        response['preferences'] as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Failed to get notification preferences: $e');
      return WorkoutNotificationPreferences();
    }
  }

  /// Update OneSignal tags based on preferences
  Future<void> _updateOneSignalTags(
    WorkoutNotificationPreferences preferences,
  ) async {
    try {
      await OneSignal.User.addTags({
        'workout_reminders': preferences.workoutRemindersEnabled.toString(),
        'rest_day_reminders': preferences.restDayRemindersEnabled.toString(),
        'pr_celebrations': preferences.prCelebrationEnabled.toString(),
        'coach_feedback': preferences.coachFeedbackEnabled.toString(),
        'missed_workout': preferences.missedWorkoutEnabled.toString(),
        'weekly_summary': preferences.weeklySummaryEnabled.toString(),
        'timezone': preferences.timezone,
      });

      debugPrint('✅ Updated OneSignal tags');
    } catch (e) {
      debugPrint('❌ Failed to update OneSignal tags: $e');
    }
  }

  // ==================== Utility Methods ====================

  /// Send notification via OneSignal REST API
  Future<void> _sendNotificationViaAPI({
    required List<String> userIds,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    List<Map<String, String>>? buttons,
    String? largeIcon,
    String? sound,
  }) async {
    try {
      // Use Supabase Edge Function to send via OneSignal API
      final response = await supabase.functions.invoke(
        'send-notification',
        body: {
          'user_ids': userIds,
          'title': title,
          'body': body,
          'data': data,
          'buttons': buttons,
          'large_icon': largeIcon,
          'sound': sound,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to send notification: ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ API notification send failed: $e');
      rethrow;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    if (!_initialized) return;

    try {
      await OneSignal.User.addTag(topic, 'true');
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_initialized) return;

    try {
      await OneSignal.User.removeTag(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic: $e');
    }
  }

  /// Add custom tags for user segmentation
  Future<void> addUserTag(String key, String value) async {
    if (!_initialized) return;

    try {
      await OneSignal.User.addTag(key, value);
      debugPrint('✅ Added user tag: $key = $value');
    } catch (e) {
      debugPrint('❌ Failed to add user tag: $e');
    }
  }

  /// Remove custom tags
  Future<void> removeUserTag(String key) async {
    if (!_initialized) return;

    try {
      await OneSignal.User.removeTag(key);
      debugPrint('✅ Removed user tag: $key');
    } catch (e) {
      debugPrint('❌ Failed to remove user tag: $e');
    }
  }

  /// Get current player ID
  String? get currentPlayerId => _currentPlayerId;

  /// Check if service is initialized
  bool get isInitialized => _initialized;

  /// Send test notification
  Future<void> sendTestNotification(String userId) async {
    await sendWorkoutReminder(
      userId,
      'Test Workout',
      DateTime.now().add(const Duration(minutes: 30)),
      exerciseCount: 5,
      estimatedDuration: 45,
      muscleGroups: ['Chest', 'Triceps'],
    );
  }
}
