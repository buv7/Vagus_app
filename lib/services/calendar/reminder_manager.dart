import '../../services/calendar/calendar_service.dart';
import '../../services/settings/settings_service.dart';
import '../core/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class ReminderManager {
  ReminderManager._();
  static final ReminderManager instance = ReminderManager._();
  
  final FlutterLocalNotificationsPlugin _flnPlugin = FlutterLocalNotificationsPlugin();

  /// Schedule reminders for an event based on reminder_minutes array
  Future<void> scheduleEventReminders({
    required String eventId,
    required DateTime startAt,
    required List<int> minutesBefore,
    required String title,
    String? body,
  }) async {
    try {
      final now = DateTime.now();
      
      // Only schedule reminders for future events
      if (startAt.isBefore(now)) return;

      // Deduplicate reminder times
      final uniqueMinutes = minutesBefore.toSet().toList();
      
      for (final minutes in uniqueMinutes) {
        final reminderTime = startAt.subtract(Duration(minutes: minutes));
        
        if (reminderTime.isAfter(now)) {
          final notificationId = _generateNotificationId(eventId, minutes);
          
          await _flnPlugin.zonedSchedule(
            notificationId,
            title,
            body ?? 'Starting in $minutes minutes',
            tz.TZDateTime.from(reminderTime, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'calendar',
                'Calendar Reminders',
                channelDescription: 'Reminders for calendar events',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: 
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          
          Logger.debug('Scheduled reminder', data: {
            'eventId': eventId,
            'minutes': minutes,
            'at': reminderTime.toIso8601String(),
          });
        }
      }
    } catch (e, st) {
      Logger.error('Failed to schedule event reminders', error: e, stackTrace: st);
    }
  }
  
  /// Generate stable notification ID from event ID and minutes
  int _generateNotificationId(String eventId, int minutes) {
    return ('$eventId-$minutes').hashCode & 0x7fffffff;
  }

  /// Cancel all reminders for an event
  Future<void> cancelEventReminders(String eventId) async {
    try {
      // Cancel common reminder offsets
      final commonOffsets = [5, 15, 30, 60, 120, 1440]; // 5m, 15m, 30m, 1h, 2h, 24h
      
      for (final minutes in commonOffsets) {
        final notificationId = _generateNotificationId(eventId, minutes);
        await _flnPlugin.cancel(notificationId);
      }
      
      Logger.debug('Cancelled reminders for event', data: {'eventId': eventId});
    } catch (e, st) {
      Logger.error('Failed to cancel event reminders', error: e, stackTrace: st);
    }
  }

  /// Update reminders for an event (cancel old ones and schedule new ones)
  Future<void> updateEventReminders(CalendarEvent event) async {
    try {
      // Cancel existing reminders
      await cancelEventReminders(event.id);
      
      // Schedule new reminders with event data
      await scheduleEventReminders(
        eventId: event.id,
        startAt: event.startAt,
        minutesBefore: [30, 15], // Default reminders
        title: event.title,
        body: 'Event starting soon',
      );
    } catch (e, st) {
      Logger.error('Failed to update event reminders', error: e, stackTrace: st);
    }
  }

  /// Schedule a custom reminder for an event
  Future<void> scheduleCustomReminder({
    required String eventId,
    required String eventTitle,
    required DateTime eventTime,
    required Duration reminderOffset,
    String? customMessage,
  }) async {
    try {
      final reminderTime = eventTime.subtract(reminderOffset);
      final now = DateTime.now();
      
      if (reminderTime.isBefore(now)) return;



      debugPrint('📅 Would schedule custom reminder for event: $eventTitle at $reminderTime');
    } catch (e) {
      debugPrint('Failed to schedule custom reminder: $e');
    }
  }

  /// Get all scheduled reminders for an event
  Future<List<Map<String, dynamic>>> getEventReminders(String eventId) async {
    try {
      // This would require the notification helper to expose scheduled notifications
      // For now, return an empty list
      return [];
    } catch (e) {
      debugPrint('Failed to get event reminders: $e');
      return [];
    }
  }



  // === Calendar Polish v1.1 Extensions ===

  /// Schedule custom reminders for an event using minute offsets
  Future<void> scheduleCustomReminders(CalendarEvent event, List<int> offsetsMin) async {
    try {
      final eventTime = event.startAt;
      final now = DateTime.now();
      
      // Only schedule reminders for future events
      if (eventTime.isBefore(now)) return;

      for (final offsetMin in offsetsMin) {
        final reminderTime = eventTime.subtract(Duration(minutes: offsetMin));
        
        if (reminderTime.isAfter(now)) {
          debugPrint('📅 Would schedule custom reminder for event: ${event.title} at $reminderTime (${offsetMin}m before)');
        }
      }
    } catch (e) {
      debugPrint('Failed to schedule custom reminders: $e');
    }
  }

  /// Schedule reminders using user settings defaults if no custom reminders are set
  Future<void> scheduleEventRemindersWithDefaults(CalendarEvent event) async {
    try {
      // Check if event has custom reminders
      List<int> reminderOffsets = [];
      
      // Try to get reminders from event metadata or reminders field
      if (event.metadata != null && event.metadata!['reminders'] != null) {
        reminderOffsets = List<int>.from(event.metadata!['reminders']);
      }
      
      // If no custom reminders, get defaults from user settings
      if (reminderOffsets.isEmpty) {
        final settings = await SettingsService.instance.loadForCurrentUser();
        final reminderDefaults = settings['reminder_defaults'] as Map<String, dynamic>? ?? {};
        
        // Extract default offsets (in minutes)
        final defaultOffsets = reminderDefaults['calendar_reminders'] as List<dynamic>?;
        if (defaultOffsets != null) {
          reminderOffsets = defaultOffsets.cast<int>();
        } else {
          // Fallback to default reminders
          reminderOffsets = [24 * 60, 60, 15]; // 24h, 1h, 15m
        }
      }

      // Schedule the reminders
      await scheduleCustomReminders(event, reminderOffsets);
    } catch (e) {
      debugPrint('Failed to schedule event reminders with defaults: $e');
    }
  }

  /// Get default reminder offsets from user settings
  Future<List<int>> getDefaultReminderOffsets() async {
    try {
      final settings = await SettingsService.instance.loadForCurrentUser();
      final reminderDefaults = settings['reminder_defaults'] as Map<String, dynamic>? ?? {};
      
      final defaultOffsets = reminderDefaults['calendar_reminders'] as List<dynamic>?;
      if (defaultOffsets != null) {
        return defaultOffsets.cast<int>();
      }
      
      // Fallback defaults
      return [24 * 60, 60, 15]; // 24h, 1h, 15m
    } catch (e) {
      debugPrint('Failed to get default reminder offsets: $e');
      return [24 * 60, 60, 15];
    }
  }
}
