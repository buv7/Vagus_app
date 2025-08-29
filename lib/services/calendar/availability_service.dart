import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service for computing coach availability slots based on policies and existing events
class AvailabilityService {
  static final AvailabilityService instance = AvailabilityService._();
  AvailabilityService._();

  final supabase = Supabase.instance.client;

  /// Returns available start times (DateTime) for a coach on a given day, local to coach TZ.
  Future<List<DateTime>> daySlots({
    required String coachId,
    required DateTime day,
  }) async {
    try {
      // Get coach booking policy
      final policy = await _getBookingPolicy(coachId);
      if (policy == null) {
        debugPrint('⚠️ No booking policy found for coach $coachId');
        return [];
      }

      // Check if day is a work day (1=Mon..7=Sun)
      final weekday = day.weekday; // Dart: 1=Mon..7=Sun
      final workDays = (policy['work_days'] as List<dynamic>?)?.cast<int>() ?? [1,2,3,4,5];
      if (!workDays.contains(weekday)) {
        return []; // Not a work day
      }

      // Calculate work hours in coach timezone
      final workStartMin = (policy['work_start_min'] as num?)?.toInt() ?? 9*60;  // 9:00 AM
      final workEndMin = (policy['work_end_min'] as num?)?.toInt() ?? 17*60;     // 5:00 PM
      final slotMinutes = (policy['slot_minutes'] as num?)?.toInt() ?? 60;
      final minLeadTimeMin = (policy['min_lead_time_min'] as num?)?.toInt() ?? 12*60;
      final bufferBeforeMin = (policy['buffer_before_min'] as num?)?.toInt() ?? 0;
      final bufferAfterMin = (policy['buffer_after_min'] as num?)?.toInt() ?? 0;

      // Generate potential slots
      final List<DateTime> slots = [];
      final dayStart = DateTime(day.year, day.month, day.day);
      
      for (int minute = workStartMin; minute + slotMinutes <= workEndMin; minute += slotMinutes) {
        final slotStart = dayStart.add(Duration(minutes: minute));
        slots.add(slotStart);
      }

      // Filter out slots that don't meet minimum lead time
      final now = DateTime.now();
      final minStartTime = now.add(Duration(minutes: minLeadTimeMin));
      final validSlots = slots.where((slot) => slot.isAfter(minStartTime)).toList();

      // Get existing events for the day
      final existingEvents = await _getEventsForDay(coachId, day);

      // Filter out slots that conflict with existing events (including buffers)
      final availableSlots = <DateTime>[];
      for (final slot in validSlots) {
        final slotEnd = slot.add(Duration(minutes: slotMinutes));
        final slotWithBufferStart = slot.subtract(Duration(minutes: bufferBeforeMin));
        final slotWithBufferEnd = slotEnd.add(Duration(minutes: bufferAfterMin));

        bool hasConflict = false;
        for (final event in existingEvents) {
          final eventStart = DateTime.parse(event['start_at']);
          final eventEnd = DateTime.parse(event['end_at']);

          // Check for overlap
          if (slotWithBufferStart.isBefore(eventEnd) && slotWithBufferEnd.isAfter(eventStart)) {
            hasConflict = true;
            break;
          }
        }

        if (!hasConflict) {
          availableSlots.add(slot);
        }
      }

      return availableSlots;
    } catch (e) {
      debugPrint('❌ Error getting day slots for coach $coachId: $e');
      return [];
    }
  }

  /// Bulk range (used by BookingForm)
  Future<Map<DateTime, List<DateTime>>> rangeSlots({
    required String coachId,
    required DateTime start,
    required DateTime end,
  }) async {
    final Map<DateTime, List<DateTime>> result = {};
    
    DateTime currentDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    while (!currentDay.isAfter(endDay)) {
      final slots = await daySlots(coachId: coachId, day: currentDay);
      if (slots.isNotEmpty) {
        result[currentDay] = slots;
      }
      currentDay = currentDay.add(const Duration(days: 1));
    }

    return result;
  }

  /// Get booking policy for a coach
  Future<Map<String, dynamic>?> _getBookingPolicy(String coachId) async {
    try {
      final response = await supabase
          .from('booking_policies')
          .select()
          .eq('coach_id', coachId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching booking policy: $e');
      return null;
    }
  }

  /// Get existing events for a specific day
  Future<List<Map<String, dynamic>>> _getEventsForDay(String coachId, DateTime day) async {
    try {
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final response = await supabase
          .from('calendar_events')
          .select('start_at, end_at')
          .eq('coach_id', coachId)
          .gte('start_at', dayStart.toIso8601String())
          .lt('start_at', dayEnd.toIso8601String())
          .neq('status', 'cancelled');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching events for day: $e');
      return [];
    }
  }
}
