import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Helper service for sending notifications from within the VAGUS app
/// This service calls Supabase Edge Functions to send OneSignal notifications
class NotificationHelper {
  NotificationHelper._();
  static final NotificationHelper instance = NotificationHelper._();

  final supabase = Supabase.instance.client;
  
  // Local notifications plugin instance
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Flag to track if local notifications are ready
  bool _isReady = false;
  bool get isReady => _isReady;

  /// Initialize local notifications plugin
  Future<void> init() async {
    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      
      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false, // We'll request this on first use
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      // Initialize the plugin
      final bool? result = await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      if (result == true) {
        // Create Android notification channel
        await _createAndroidChannel();
        _isReady = true;
        debugPrint('✅ Local notifications initialized successfully');
      } else {
        debugPrint('❌ Failed to initialize local notifications');
      }
    } catch (e) {
      debugPrint('❌ Error initializing local notifications: $e');
      _isReady = false;
    }
  }

  /// Create Android notification channel for calendar reminders
  Future<void> _createAndroidChannel() async {
    const AndroidNotificationChannel calendarChannel = AndroidNotificationChannel(
      'calendar_reminders',
      'Calendar Reminders',
      description: 'Reminders for upcoming sessions and events',
      importance: Importance.high,
    );
    
    const AndroidNotificationChannel streakChannel = AndroidNotificationChannel(
      'streak_reminders',
      'Streak Reminders',
      description: 'Reminders to maintain your streak',
      importance: Importance.high,
    );
    
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(calendarChannel);
    await androidPlugin?.createNotificationChannel(streakChannel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    // TODO: Navigate to calendar or specific event if needed
  }

  /// Request notification permissions (iOS)
  Future<bool> _requestPermissions() async {
    try {
      // TODO: Implement iOS permission handling when flutter_local_notifications supports it
      debugPrint('⚠️ iOS permission handling not yet implemented');
      return false;
    } catch (e) {
      debugPrint('❌ Error requesting iOS permissions: $e');
      return false;
    }
  }

  /// Send notification to a specific user
  Future<bool> sendToUser({
    required String userId,
    required String title,
    required String message,
    String? route,
    String? screen,
    String? id,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'send-notification',
        body: {
          'type': 'user',
          'userId': userId,
          'title': title,
          'message': message,
          'route': route,
          'screen': screen,
          'id': id,
          'additionalData': additionalData,
        },
      );

      if (response.status == 200) {
        debugPrint('✅ Notification sent successfully to user: $userId');
        return true;
      } else {
        debugPrint('❌ Failed to send notification: ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Send notification to multiple users
  Future<bool> sendToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    String? route,
    String? screen,
    String? id,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'send-notification',
        body: {
          'type': 'users',
          'userIds': userIds,
          'title': title,
          'message': message,
          'route': route,
          'screen': screen,
          'id': id,
          'additionalData': additionalData,
        },
      );

      if (response.status == 200) {
        debugPrint('✅ Notification sent successfully to ${userIds.length} users');
        return true;
      } else {
        debugPrint('❌ Failed to send notification: ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Send notification to users by role
  Future<bool> sendToRole({
    required String role,
    required String title,
    required String message,
    String? route,
    String? screen,
    String? id,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'send-notification',
        body: {
          'type': 'role',
          'role': role,
          'title': title,
          'message': message,
          'route': route,
          'screen': screen,
          'id': id,
          'additionalData': additionalData,
        },
      );

      if (response.status == 200) {
        debugPrint('✅ Notification sent successfully to role: $role');
        return true;
      } else {
        debugPrint('❌ Failed to send notification: ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Send notification to topic/segment
  Future<bool> sendToTopic({
    required String topic,
    required String title,
    required String message,
    String? route,
    String? screen,
    String? id,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'send-notification',
        body: {
          'type': 'topic',
          'topic': topic,
          'title': title,
          'message': message,
          'route': route,
          'screen': screen,
          'id': id,
          'additionalData': additionalData,
        },
      );

      if (response.status == 200) {
        debugPrint('✅ Notification sent successfully to topic: $topic');
        return true;
      } else {
        debugPrint('❌ Failed to send notification: ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Send message notification
  Future<bool> sendMessageNotification({
    required String recipientId,
    required String senderName,
    required String message,
    String? threadId,
  }) async {
    return sendToUser(
      userId: recipientId,
      title: 'New message from $senderName',
      message: message,
      route: '/messages',
      screen: 'messages',
      id: threadId,
      additionalData: {
        'type': 'message',
        'senderName': senderName,
        'threadId': threadId,
      },
    );
  }

  /// Send workout plan notification
  Future<bool> sendWorkoutNotification({
    required String clientId,
    required String coachName,
    required String planName,
    String? planId,
  }) async {
    return sendToUser(
      userId: clientId,
      title: 'New workout plan from $coachName',
      message: 'Your new plan "$planName" is ready!',
      route: '/workout',
      screen: 'workout',
      id: planId,
      additionalData: {
        'type': 'workout_plan',
        'coachName': coachName,
        'planName': planName,
      },
    );
  }

  /// Send nutrition plan notification
  Future<bool> sendNutritionNotification({
    required String clientId,
    required String coachName,
    required String planName,
    String? planId,
  }) async {
    return sendToUser(
      userId: clientId,
      title: 'New nutrition plan from $coachName',
      message: 'Your new plan "$planName" is ready!',
      route: '/nutrition',
      screen: 'nutrition',
      id: planId,
      additionalData: {
        'type': 'nutrition_plan',
        'coachName': coachName,
        'planName': planName,
      },
    );
  }

  /// Send calendar reminder notification
  Future<bool> sendCalendarReminder({
    required String userId,
    required String eventTitle,
    required DateTime eventTime,
    String? eventId,
  }) async {
    final timeString = '${eventTime.hour.toString().padLeft(2, '0')}:${eventTime.minute.toString().padLeft(2, '0')}';
    
    return sendToUser(
      userId: userId,
      title: 'Calendar Reminder',
      message: '$eventTitle at $timeString',
      route: '/calendar',
      screen: 'calendar',
      id: eventId,
      additionalData: {
        'type': 'calendar_reminder',
        'eventTitle': eventTitle,
        'eventTime': eventTime.toIso8601String(),
      },
    );
  }

  /// Send coach request notification
  Future<bool> sendCoachRequestNotification({
    required String coachId,
    required String clientName,
  }) async {
    return sendToUser(
      userId: coachId,
      title: 'New coach request',
      message: '$clientName wants you to be their coach',
      route: '/coach-requests',
      screen: 'coach_requests',
      additionalData: {
        'type': 'coach_request',
        'clientName': clientName,
      },
    );
  }

  /// Send progress check-in reminder
  Future<bool> sendProgressReminder({
    required String userId,
    required String reminderType,
  }) async {
    String message;
    switch (reminderType) {
      case 'weight':
        message = 'Time to log your weight and measurements';
        break;
      case 'photos':
        message = 'Time to take your progress photos';
        break;
      case 'workout':
        message = 'Time to log your workout progress';
        break;
      default:
        message = 'Time for your progress check-in';
    }

    return sendToUser(
      userId: userId,
      title: 'Progress Reminder',
      message: message,
      route: '/progress',
      screen: 'progress',
      additionalData: {
        'type': 'progress_reminder',
        'reminderType': reminderType,
      },
    );
  }

  /// Schedule a local calendar reminder notification
  /// Returns the notification ID for cancellation
  Future<String?> scheduleCalendarReminder({
    required String eventId,
    required String userId,
    required String eventTitle,
    required DateTime eventTime,
    Duration reminderOffset = const Duration(minutes: 60),
  }) async {
    try {
      // Check if local notifications are ready
      if (!_isReady) {
        debugPrint('⚠️ Local notifications not ready, falling back to logging');
        return 'not_ready';
      }

      // Compute deterministic ID for this reminder
      final localNotificationId = '$eventId:$userId';
      
      // Calculate reminder time (event time minus offset)
      final reminderTime = eventTime.subtract(reminderOffset);
      
      // Check if reminder time is too close (within 30 seconds)
      if (reminderTime.isBefore(DateTime.now().add(const Duration(seconds: 30)))) {
        debugPrint('⚠️ Reminder time is too close, skipping: $reminderTime');
        return 'skipped_too_close';
      }

      // Request permissions on first use (iOS)
      if (eventTime.isAfter(DateTime.now())) {
        await _requestPermissions();
      }

      // Schedule the actual local notification
      final notificationId = localNotificationId.hashCode.abs();
      
      await _localNotifications.zonedSchedule(
        notificationId,
        'Calendar Reminder',
        '$eventTitle at ${eventTime.hour.toString().padLeft(2, '0')}:${eventTime.minute.toString().padLeft(2, '0')}',
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'calendar_reminders',
            'Calendar Reminders',
            channelDescription: 'Reminders for upcoming sessions and events',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: localNotificationId,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      debugPrint('✅ Scheduled reminder for event $eventId at $reminderTime');
      return localNotificationId;
    } catch (e) {
      debugPrint('❌ Error scheduling calendar reminder: $e');
      return null;
    }
  }

  /// Cancel a scheduled calendar reminder
  Future<bool> cancelCalendarReminder(String reminderId) async {
    try {
      // Check if local notifications are ready
      if (!_isReady) {
        debugPrint('⚠️ Local notifications not ready, falling back to logging');
        return false;
      }

      // Cancel the actual local notification
      final notificationId = reminderId.hashCode.abs();
      await _localNotifications.cancel(notificationId);
      
      debugPrint('✅ Cancelled reminder: $reminderId');
      return true;
    } catch (e) {
      debugPrint('❌ Error cancelling calendar reminder: $e');
      return false;
    }
  }

  /// Reschedule a calendar reminder (cancel old, schedule new)
  Future<String?> rescheduleCalendarReminder({
    required String oldReminderId,
    required String eventId,
    required String userId,
    required String eventTitle,
    required DateTime newEventTime,
    Duration reminderOffset = const Duration(minutes: 60),
  }) async {
    try {
      // Cancel the old reminder
      await cancelCalendarReminder(oldReminderId);
      
      // Schedule the new reminder
      return await scheduleCalendarReminder(
        eventId: eventId,
        userId: userId,
        eventTitle: eventTitle,
        eventTime: newEventTime,
        reminderOffset: reminderOffset,
      );
    } catch (e) {
      debugPrint('❌ Error rescheduling calendar reminder: $e');
      return null;
    }
  }

  // ===== STREAK REMINDERS =====

  /// Schedule daily streak reminder (20:00 "Don't break your streak")
  Future<String?> scheduleStreakReminder({
    required String userId,
    required DateTime reminderTime,
  }) async {
    try {
      // Check if local notifications are ready
      if (!_isReady) {
        debugPrint('⚠️ Local notifications not ready, falling back to logging');
        return 'not_ready';
      }

      // Compute deterministic ID for this reminder
      final reminderId = 'streak:daily:$userId';
      
      // Check if reminder time is too close (within 30 seconds)
      if (reminderTime.isBefore(DateTime.now().add(const Duration(seconds: 30)))) {
        debugPrint('⚠️ Streak reminder time is too close, skipping: $reminderTime');
        return 'skipped_too_close';
      }

      // Request permissions on first use (iOS)
      if (reminderTime.isAfter(DateTime.now())) {
        await _requestPermissions();
      }

      // Schedule the actual local notification
      final notificationId = reminderId.hashCode.abs();
      
      await _localNotifications.zonedSchedule(
        notificationId,
        '🔥 Don\'t Break Your Streak!',
        'Complete any activity today to keep your streak alive',
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_reminders',
            'Streak Reminders',
            channelDescription: 'Reminders to maintain your streak',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: reminderId,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      debugPrint('✅ Scheduled streak reminder for user $userId at $reminderTime');
      return reminderId;
    } catch (e) {
      debugPrint('❌ Error scheduling streak reminder: $e');
      return null;
    }
  }

  /// Schedule last call streak reminder (23:30 "Last call")
  Future<String?> scheduleLastCallReminder({
    required String userId,
    required DateTime reminderTime,
  }) async {
    try {
      // Check if local notifications are ready
      if (!_isReady) {
        debugPrint('⚠️ Local notifications not ready, falling back to logging');
        return 'not_ready';
      }

      // Compute deterministic ID for this reminder
      final reminderId = 'streak:lastcall:$userId';
      
      // Check if reminder time is too close (within 30 seconds)
      if (reminderTime.isBefore(DateTime.now().add(const Duration(seconds: 30)))) {
        debugPrint('⚠️ Last call reminder time is too close, skipping: $reminderTime');
        return 'skipped_too_close';
      }

      // Request permissions on first use (iOS)
      if (reminderTime.isAfter(DateTime.now())) {
        await _requestPermissions();
      }

      // Schedule the actual local notification
      final notificationId = reminderId.hashCode.abs();
      
      await _localNotifications.zonedSchedule(
        notificationId,
        '⏰ Last Call for Your Streak!',
        'Just 30 minutes left to complete an activity and save your streak',
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_reminders',
            'Streak Reminders',
            channelDescription: 'Reminders to maintain your streak',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: reminderId,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      debugPrint('✅ Scheduled last call reminder for user $userId at $reminderTime');
      return reminderId;
    } catch (e) {
      debugPrint('❌ Error scheduling last call reminder: $e');
      return null;
    }
  }

  /// Cancel streak reminders for a user
  Future<bool> cancelStreakReminders(String userId) async {
    try {
      // Check if local notifications are ready
      if (!_isReady) {
        debugPrint('⚠️ Local notifications not ready, falling back to logging');
        return false;
      }

      // Cancel both daily and last call reminders
      final dailyReminderId = 'streak:daily:$userId';
      final lastCallReminderId = 'streak:lastcall:$userId';
      
      await _localNotifications.cancel(dailyReminderId.hashCode.abs());
      await _localNotifications.cancel(lastCallReminderId.hashCode.abs());
      
      debugPrint('✅ Cancelled streak reminders for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error cancelling streak reminders: $e');
      return false;
    }
  }

}
