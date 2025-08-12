import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Helper service for sending notifications from within the VAGUS app
/// This service calls Supabase Edge Functions to send OneSignal notifications
class NotificationHelper {
  NotificationHelper._();
  static final NotificationHelper instance = NotificationHelper._();

  final supabase = Supabase.instance.client;

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
}
