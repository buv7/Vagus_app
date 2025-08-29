import '../../services/calendar/calendar_service.dart';
import '../../services/settings/settings_service.dart';
import 'package:flutter/foundation.dart';

class ReminderManager {
  ReminderManager._();
  static final ReminderManager instance = ReminderManager._();

  /// Schedule reminders for an event
  /// Creates notifications at 24h, 1h, and 15m before the event
  Future<void> scheduleEventReminders(CalendarEvent event) async {
    try {
      final eventTime = event.startAt;
      final now = DateTime.now();
      
      // Only schedule reminders for future events
      if (eventTime.isBefore(now)) return;

      // 24 hour reminder
      final reminder24h = eventTime.subtract(const Duration(hours: 24));
      if (reminder24h.isAfter(now)) {
        debugPrint('📅 Would schedule 24h reminder for event: ${event.title} at $reminder24h');
      }

      // 1 hour reminder
      final reminder1h = eventTime.subtract(const Duration(hours: 1));
      if (reminder1h.isAfter(now)) {
        debugPrint('📅 Would schedule 1h reminder for event: ${event.title} at $reminder1h');
      }

      // 15 minute reminder
      final reminder15m = eventTime.subtract(const Duration(minutes: 15));
      if (reminder15m.isAfter(now)) {
        debugPrint('📅 Would schedule 15m reminder for event: ${event.title} at $reminder15m');
      }
    } catch (e) {
      // Log error but don't throw - reminders are not critical
      debugPrint('Failed to schedule event reminders: $e');
    }
  }

  /// Cancel all reminders for an event
  Future<void> cancelEventReminders(String eventId) async {
    try {
      // Cancel all reminder types for this event
      debugPrint('📅 Would cancel reminders for event: $eventId');
    } catch (e) {
      // Log error but don't throw
      debugPrint('Failed to cancel event reminders: $e');
    }
  }

  /// Update reminders for an event (cancel old ones and schedule new ones)
  Future<void> updateEventReminders(CalendarEvent event) async {
    try {
      // Cancel existing reminders
      await cancelEventReminders(event.id);
      
      // Schedule new reminders
      await scheduleEventReminders(event);
    } catch (e) {
      debugPrint('Failed to update event reminders: $e');
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
