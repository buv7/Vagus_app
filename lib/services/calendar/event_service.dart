import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../notifications/notification_helper.dart';

class Event {
  final String id;
  final String createdBy;
  final String? coachId;
  final String? clientId;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final bool allDay;
  final String? location;
  final String? notes;
  final List<String> tags;
  final List<Map<String, dynamic>> attachments;
  final String visibility;
  final String status;
  final bool isBookingSlot;
  final int capacity;
  final String? recurrenceRule;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.createdBy,
    this.coachId,
    this.clientId,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.allDay = false,
    this.location,
    this.notes,
    this.tags = const [],
    this.attachments = const [],
    this.visibility = 'private',
    this.status = 'scheduled',
    this.isBookingSlot = false,
    this.capacity = 1,
    this.recurrenceRule,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      createdBy: map['created_by'],
      coachId: map['coach_id'],
      clientId: map['client_id'],
      title: map['title'],
      startAt: EventService.utcToLocal(DateTime.parse(map['start_at'])),
      endAt: EventService.utcToLocal(DateTime.parse(map['end_at'])),
      allDay: map['all_day'] ?? false,
      location: map['location'],
      notes: map['notes'],
      tags: List<String>.from(map['tags'] ?? []),
      attachments: List<Map<String, dynamic>>.from(map['attachments'] ?? []),
      visibility: map['visibility'] ?? 'private',
      status: map['status'] ?? 'scheduled',
      isBookingSlot: map['is_booking_slot'] ?? false,
      capacity: map['capacity'] ?? 1,
      recurrenceRule: map['recurrence_rule'],
      createdAt: EventService.utcToLocal(DateTime.parse(map['created_at'])),
      updatedAt: EventService.utcToLocal(DateTime.parse(map['updated_at'])),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_by': createdBy,
      'coach_id': coachId,
      'client_id': clientId,
      'title': title,
      'start_at': EventService.localToUtc(startAt).toIso8601String(),
      'end_at': EventService.localToUtc(endAt).toIso8601String(),
      'all_day': allDay,
      'location': location,
      'notes': notes,
      'tags': tags,
      'attachments': attachments,
      'visibility': visibility,
      'status': status,
      'is_booking_slot': isBookingSlot,
      'capacity': capacity,
      'recurrence_rule': recurrenceRule,
      'created_at': EventService.localToUtc(createdAt).toIso8601String(),
      'updated_at': EventService.localToUtc(updatedAt).toIso8601String(),
    };
  }

  Event copyWith({
    String? id,
    String? createdBy,
    String? coachId,
    String? clientId,
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    bool? allDay,
    String? location,
    String? notes,
    List<String>? tags,
    List<Map<String, dynamic>>? attachments,
    String? visibility,
    String? status,
    bool? isBookingSlot,
    int? capacity,
    String? recurrenceRule,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      coachId: coachId ?? this.coachId,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      allDay: allDay ?? this.allDay,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      isBookingSlot: isBookingSlot ?? this.isBookingSlot,
      capacity: capacity ?? this.capacity,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert Event to UiCalendarEvent for UI display
  /// This adapter ensures capacity is treated as nullable-safe
  Map<String, dynamic> toUiCalendarEvent() {
    return {
      'id': id,
      'title': title,
      'description': notes,
      'location': location,
      'startAt': startAt,
      'endAt': endAt,
      'clientId': clientId,
      'tags': tags,
      'capacity': capacity > 0 ? capacity : null, // Nullable-safe: null if 0 or negative
      'attendees': [], // Event class doesn't have attendees, use empty list
      'recurrenceRule': recurrenceRule,
      'allDay': allDay,
      'status': status,
      'visibility': visibility,
      'isBookingSlot': isBookingSlot,
    };
  }

  /// Convert Event to legacy CalendarEvent format for backward compatibility
  /// This maintains compatibility with existing code that expects CalendarEvent
  Map<String, dynamic> toLegacyCalendarEvent() {
    return {
      'id': id,
      'coach_id': coachId,
      'client_id': clientId,
      'title': title,
      'description': notes,
      'location': location,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'timezone': null, // Event doesn't store timezone
      'recurrence_rule': recurrenceRule,
      'status': status,
      'attachments': attachments,
      'metadata': {
        'capacity': capacity,
        'visibility': visibility,
        'is_booking_slot': isBookingSlot,
        'tags': tags,
      },
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Timezone helpers - simplified for MVP
  /// Convert UTC DateTime to local timezone for display
  static DateTime utcToLocal(DateTime utcTime) {
    // For MVP, assume device timezone is local
    return utcTime.toLocal();
  }
  
  /// Convert local DateTime to UTC for storage
  static DateTime localToUtc(DateTime localTime) {
    // For MVP, convert to UTC
    return localTime.toUtc();
  }

  /// List upcoming events for a user based on their role
  Future<List<Event>> listUpcomingForUser({
    required String userId,
    required String role,
    int limit = 20,
  }) async {
    try {
      List<Map<String, dynamic>> response;
      
      if (role == 'coach') {
        // Coaches see their own events and events they're hosting
        response = await _supabase
            .from('calendar_events')
            .select()
            .or('created_by.eq.$userId,coach_id.eq.$userId')
            .gte('start_at', DateTime.now().toIso8601String())
            .order('start_at')
            .limit(limit);
      } else {
        // Clients see their own events and events they're attending
        response = await _supabase
            .from('calendar_events')
            .select()
            .or('created_by.eq.$userId,client_id.eq.$userId')
            .gte('start_at', DateTime.now().toIso8601String())
            .order('start_at')
            .limit(limit);
      }

      return response.map((map) => Event.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error listing upcoming events: $e');
      return [];
    }
  }

  /// Fetch events in a date range for a user (compatibility method)
  Future<List<Event>> fetchEvents({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;
      if (user == null) return [];

      final response = await _supabase
          .from('calendar_events')
          .select()
          .or('created_by.eq.$user,coach_id.eq.$user,client_id.eq.$user')
          .gte('start_at', start.toIso8601String())
          .lte('start_at', end.toIso8601String())
          .order('start_at');

      return response.map((map) => Event.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching events in date range: $e');
      return [];
    }
  }

  /// Create or update an event
  Future<Event> createOrUpdate(Event event) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final Map<String, dynamic> eventData = event.toMap();
      eventData['updated_at'] = DateTime.now().toIso8601String();

      if (event.id.isEmpty) {
        // Create new event
        eventData['id'] = const Uuid().v4();
        eventData['created_by'] = user.id;
        eventData['created_at'] = DateTime.now().toIso8601String();
        
        final response = await _supabase
            .from('calendar_events')
            .insert(eventData)
            .select()
            .single();
        
        return Event.fromMap(response);
      } else {
        // Update existing event
        final response = await _supabase
            .from('calendar_events')
            .update(eventData)
            .select()
            .single();
        
        return Event.fromMap(response);
      }
    } catch (e) {
      debugPrint('Error creating/updating event: $e');
      rethrow;
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String id) async {
    try {
      await _supabase
          .from('calendar_events')
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('Error deleting event: $e');
      rethrow;
    }
  }

  /// Find conflicts for a user in a time window
  Future<List<Event>> findConflicts({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final response = await _supabase
          .from('calendar_events')
          .select()
          .or('created_by.eq.$userId,coach_id.eq.$userId,client_id.eq.$userId')
          .neq('status', 'cancelled')
          .or('start_at.lt.${end.toIso8601String()},end_at.gt.${start.toIso8601String()}')
          .order('start_at');

      return response.map((map) => Event.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error finding conflicts: $e');
      return [];
    }
  }

  /// Book a slot (add user as participant)
  Future<void> bookSlot({
    required String eventId,
    required String userId,
  }) async {
    try {
      // Check if event exists and is a booking slot
      final event = await getById(eventId);
      if (event == null || !event.isBookingSlot) {
        throw Exception('Event not found or not a booking slot');
      }

      // Check capacity using RPC function
      final hasCapacity = await checkCapacity(eventId);
      if (!hasCapacity) {
        throw Exception('Event is at full capacity');
      }

      // Check for conflicts using RPC function
      final hasConflict = await hasConflicts(
        userId: userId,
        start: event.startAt,
        end: event.endAt,
      );

      if (hasConflict) {
        throw Exception('You have a scheduling conflict');
      }

      // Add participant
      await _supabase
          .from('event_participants')
          .insert({
            'event_id': eventId,
            'user_id': userId,
            'role': 'attendee',
            'status': 'confirmed',
          });

      // Schedule reminder for the booking
      final reminderStatus = await scheduleReminder(
        eventId: eventId,
        eventTitle: event.title,
        eventTime: event.startAt,
        userId: userId,
      );
      
      // Log reminder status for debugging
      if (reminderStatus == 'skipped_too_close') {
        debugPrint('⚠️ Reminder skipped for booking - too close to current time');
      } else if (reminderStatus == 'not_ready') {
        debugPrint('⚠️ Reminder not scheduled for booking - notifications not ready');
      } else if (reminderStatus != null) {
        debugPrint('✅ Reminder scheduled for booking');
      } else {
        debugPrint('❌ Failed to schedule reminder for booking');
      }

    } catch (e) {
      debugPrint('Error booking slot: $e');
      rethrow;
    }
  }

  /// Cancel a booking (remove user as participant)
  Future<void> cancelBooking({
    required String eventId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('event_participants')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);

      // Cancel reminder for the booking
      await cancelReminder(
        eventId: eventId,
        userId: userId,
      );
    } catch (e) {
      debugPrint('Error canceling booking: $e');
      rethrow;
    }
  }

  /// Get event participants
  Future<List<Map<String, dynamic>>> getEventParticipants(String eventId) async {
    try {
      final response = await _supabase
          .from('event_participants')
          .select('*, profiles:user_id(*)')
          .eq('event_id', eventId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting event participants: $e');
      return [];
    }
  }

  /// Get booking slots for a coach
  Future<List<Event>> getBookingSlots(String coachId) async {
    try {
      final response = await _supabase
          .from('calendar_events')
          .select()
          .eq('coach_id', coachId)
          .eq('is_booking_slot', true)
          .gte('start_at', DateTime.now().toIso8601String())
          .order('start_at');

      return response.map((map) => Event.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting booking slots: $e');
      return [];
    }
  }

  /// Get event by ID
  Future<Event?> getById(String id) async {
    try {
      final response = await _supabase
          .from('calendar_events')
          .select()
          .eq('id', id)
          .single();

      return Event.fromMap(response);
    } catch (e) {
      debugPrint('Error getting event by ID: $e');
      return null;
    }
  }

  /// Check if user has conflicts using RPC function (fallback to client-side)
  Future<bool> hasConflicts({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      // Try RPC function first
      final result = await _supabase.rpc('check_booking_conflicts', params: {
        'p_user_id': userId,
        'p_start_at': start.toIso8601String(),
        'p_end_at': end.toIso8601String(),
      });
      
      return result as bool;
    } catch (e) {
      debugPrint('RPC conflict check failed, falling back to client-side: $e');
      
      // Fallback to client-side check
      final conflicts = await findConflicts(
        userId: userId,
        start: start,
        end: end,
      );
      
      return conflicts.isNotEmpty;
    }
  }

  /// Check event capacity using RPC function
  Future<bool> checkCapacity(String eventId) async {
    try {
      final result = await _supabase.rpc('check_event_capacity', params: {
        'p_event_id': eventId,
      });
      
      return result as bool;
    } catch (e) {
      debugPrint('RPC capacity check failed: $e');
      return false;
    }
  }

  /// Schedule reminder for an event
  /// Returns status: 'scheduled', 'skipped_too_close', 'not_ready', or null for error
  Future<String?> scheduleReminder({
    required String eventId,
    required String eventTitle,
    required DateTime eventTime,
    required String userId,
    Duration reminderOffset = const Duration(minutes: 60),
  }) async {
    try {
      // Convert UTC eventTime to local DateTime for scheduling
      final localEventTime = eventTime.toLocal();
      
      // Schedule local notification reminder
      final reminderId = await NotificationHelper.instance.scheduleCalendarReminder(
        eventId: eventId,
        userId: userId,
        eventTitle: eventTitle,
        eventTime: localEventTime,
        reminderOffset: reminderOffset,
      );
      
      if (reminderId != null && reminderId != 'skipped_too_close' && reminderId != 'not_ready') {
        // Also send immediate notification for immediate feedback
        await NotificationHelper.instance.sendCalendarReminder(
          userId: userId,
          eventTitle: eventTitle,
          eventTime: eventTime,
          eventId: eventId,
        );
      }
      
      return reminderId;
    } catch (e) {
      debugPrint('Failed to schedule reminder: $e');
      return null;
    }
  }

  /// Cancel reminder for an event
  Future<void> cancelReminder({
    required String eventId,
    required String userId,
  }) async {
    try {
      // Cancel local notification reminder
      final reminderId = '$eventId:$userId';
      await NotificationHelper.instance.cancelCalendarReminder(reminderId);
    } catch (e) {
      debugPrint('Failed to cancel reminder: $e');
    }
  }

  /// Reschedule reminder for an event (useful when event time changes)
  Future<void> rescheduleReminder({
    required String eventId,
    required String eventTitle,
    required DateTime newEventTime,
    required String userId,
    Duration reminderOffset = const Duration(minutes: 60),
  }) async {
    try {
      final oldReminderId = '$eventId:$userId';
      final newReminderId = await NotificationHelper.instance.rescheduleCalendarReminder(
        oldReminderId: oldReminderId,
        eventId: eventId,
        userId: userId,
        eventTitle: eventTitle,
        newEventTime: newEventTime,
        reminderOffset: reminderOffset,
      );
      
      if (newReminderId != null) {
        debugPrint('Reminder rescheduled for event $eventId, user $userId');
      }
    } catch (e) {
      debugPrint('Failed to reschedule reminder: $e');
    }
  }

  /// Get event capacity (nullable-safe)
  Future<int?> getCapacity(String eventId) async {
    try {
      final response = await _supabase
          .from('calendar_events')
          .select('capacity')
          .eq('id', eventId)
          .single();
      
      final capacity = response['capacity'] as int?;
      return capacity != null && capacity > 0 ? capacity : null;
    } catch (e) {
      debugPrint('Error getting event capacity: $e');
      return null;
    }
  }

  /// Get supplement events for calendar overlay
  Future<List<Map<String, dynamic>>> getSupplementEvents({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) async {
    try {
      // TODO: Implement supplement events integration
      // For now, return empty list to avoid circular dependencies
      debugPrint('Supplement events not yet integrated with calendar');
      return [];
    } catch (e) {
      debugPrint('Error getting supplement events: $e');
      return [];
    }
  }

  /// Get confirmed participant count for an event
  Future<int> getConfirmedCount(String eventId) async {
    try {
      final response = await _supabase
          .from('event_participants')
          .select('id')
          .eq('event_id', eventId)
          .eq('status', 'confirmed');
      
      return response.length;
    } catch (e) {
      debugPrint('Error getting confirmed count: $e');
      return 0;
    }
  }

  /// Stream confirmed participant count for real-time updates
  Stream<int> streamConfirmedCount(String eventId) {
    try {
      return _supabase
          .from('event_participants')
          .stream(primaryKey: ['id'])
          .map((response) => response
              .where((participant) => 
                  participant['event_id'] == eventId && 
                  participant['status'] == 'confirmed')
              .length);
    } catch (e) {
      debugPrint('Realtime stream failed, falling back to polling: $e');
      // Fallback to polling if realtime fails
      return Stream.periodic(
        const Duration(seconds: 15),
        (_) => getConfirmedCount(eventId),
      ).asyncMap((future) => future);
    }
  }
}
