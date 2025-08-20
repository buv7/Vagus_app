import '../../services/calendar/calendar_service.dart';
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
        debugPrint('📅 Would schedule 24h reminder for event: ${event.title} at ${reminder24h}');
      }

      // 1 hour reminder
      final reminder1h = eventTime.subtract(const Duration(hours: 1));
      if (reminder1h.isAfter(now)) {
        debugPrint('📅 Would schedule 1h reminder for event: ${event.title} at ${reminder1h}');
      }

      // 15 minute reminder
      final reminder15m = eventTime.subtract(const Duration(minutes: 15));
      if (reminder15m.isAfter(now)) {
        debugPrint('📅 Would schedule 15m reminder for event: ${event.title} at ${reminder15m}');
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

      final reminderId = '${eventId}_custom_${reminderOffset.inMinutes}';
      final message = customMessage ?? 'Your event starts in ${_formatDuration(reminderOffset)}';

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

  /// Format duration for display
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    } else {
      return '${duration.inSeconds} second${duration.inSeconds == 1 ? '' : 's'}';
    }
  }
}
