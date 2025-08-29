import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CalendarEvent {
  final String id;
  final String? coachId;
  final String? clientId;
  final String title;
  final String? description;
  final String? location;
  final DateTime startAt;
  final DateTime endAt;
  final String? timezone;
  final String? recurrenceRule;
  final String status;
  final List<Map<String, dynamic>> attachments;
  final Map<String, dynamic>? metadata;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CalendarEvent({
    required this.id,
    this.coachId,
    this.clientId,
    required this.title,
    this.description,
    this.location,
    required this.startAt,
    required this.endAt,
    this.timezone,
    this.recurrenceRule,
    required this.status,
    required this.attachments,
    this.metadata,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'],
      coachId: map['coach_id'],
      clientId: map['client_id'],
      title: map['title'],
      description: map['description'],
      location: map['location'],
      startAt: DateTime.parse(map['start_at']),
      endAt: DateTime.parse(map['end_at']),
      timezone: map['timezone'],
      recurrenceRule: map['recurrence_rule'],
      status: map['status'],
      attachments: List<Map<String, dynamic>>.from(map['attachments'] ?? []),
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
      createdBy: map['created_by'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coach_id': coachId,
      'client_id': clientId,
      'title': title,
      'description': description,
      'location': location,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'timezone': timezone,
      'recurrence_rule': recurrenceRule,
      'status': status,
      'attachments': attachments,
      'metadata': metadata,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CalendarEventDraft {
  final String? coachId;
  final String? clientId;
  final String title;
  final String? description;
  final String? location;
  final DateTime startAt;
  final DateTime endAt;
  final String? timezone;
  final String? recurrenceRule;
  final Map<String, dynamic>? metadata;

  CalendarEventDraft({
    this.coachId,
    this.clientId,
    required this.title,
    this.description,
    this.location,
    required this.startAt,
    required this.endAt,
    this.timezone,
    this.recurrenceRule,
    this.metadata,
  });
}

class CalendarEventInstance {
  final String eventId;
  final DateTime startAt;
  final DateTime endAt;
  final String title;
  final String? description;
  final String? location;
  final String status;
  final CalendarEvent originalEvent;

  CalendarEventInstance({
    required this.eventId,
    required this.startAt,
    required this.endAt,
    required this.title,
    this.description,
    this.location,
    required this.status,
    required this.originalEvent,
  });
}

class BookingRequest {
  final String id;
  final String clientId;
  final String coachId;
  final DateTime requestedStartAt;
  final DateTime requestedEndAt;
  final String? message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingRequest({
    required this.id,
    required this.clientId,
    required this.coachId,
    required this.requestedStartAt,
    required this.requestedEndAt,
    this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingRequest.fromMap(Map<String, dynamic> map) {
    return BookingRequest(
      id: map['id'],
      clientId: map['client_id'],
      coachId: map['coach_id'],
      requestedStartAt: DateTime.parse(map['requested_start_at']),
      requestedEndAt: DateTime.parse(map['requested_end_at']),
      message: map['message'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

class BookingDraft {
  final String coachId;
  final DateTime requestedStartAt;
  final DateTime requestedEndAt;
  final String? message;

  BookingDraft({
    required this.coachId,
    required this.requestedStartAt,
    required this.requestedEndAt,
    this.message,
  });
}

class CalendarService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<CalendarEvent>> fetchEvents({
    DateTime? start,
    DateTime? end,
    String? coachId,
    String? clientId,
  }) async {
    try {
      final response = await _supabase
          .from('calendar_events')
          .select()
          .order('start_at');

      final events = (response as List)
          .map((event) => CalendarEvent.fromMap(event))
          .toList();

      // Apply filters in memory for now
      return events.where((event) {
        if (start != null && event.startAt.isBefore(start)) return false;
        if (end != null && event.startAt.isAfter(end)) return false;
        if (coachId != null && event.coachId != coachId) return false;
        if (clientId != null && event.clientId != clientId) return false;
        return true;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  Future<CalendarEvent> createEvent(CalendarEventDraft draft) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final eventId = const Uuid().v4();

      final eventData = {
        'id': eventId,
        'coach_id': draft.coachId,
        'client_id': draft.clientId,
        'title': draft.title,
        'description': draft.description,
        'location': draft.location,
        'start_at': draft.startAt.toIso8601String(),
        'end_at': draft.endAt.toIso8601String(),
        'timezone': draft.timezone,
        'recurrence_rule': draft.recurrenceRule,
        'created_by': userId,
      };

      final response = await _supabase
          .from('calendar_events')
          .insert(eventData)
          .select()
          .single();

      return CalendarEvent.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  Future<void> updateEvent(CalendarEvent event) async {
    try {
      final updateData = {
        'title': event.title,
        'description': event.description,
        'location': event.location,
        'start_at': event.startAt.toIso8601String(),
        'end_at': event.endAt.toIso8601String(),
        'timezone': event.timezone,
        'recurrence_rule': event.recurrenceRule,
        'status': event.status,
        'attachments': event.attachments,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('calendar_events')
          .update(updateData)
          .eq('id', event.id);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _supabase
          .from('calendar_events')
          .delete()
          .eq('id', eventId);
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  Future<bool> hasConflict({
    required DateTime start,
    required DateTime end,
    String? coachId,
    String? clientId,
    String? ignoreEventId,
  }) async {
    try {
      var query = _supabase
          .from('calendar_events')
          .select('id')
          .or('start_at.lt.${end.toIso8601String()},end_at.gt.${start.toIso8601String()}')
          .eq('status', 'scheduled');

      if (coachId != null) {
        query = query.eq('coach_id', coachId);
      }
      if (clientId != null) {
        query = query.eq('client_id', clientId);
      }
      if (ignoreEventId != null) {
        query = query.neq('id', ignoreEventId);
      }

      final response = await query;
      return (response as List).isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check conflicts: $e');
    }
  }

  Future<List<BookingRequest>> fetchBookingsForCoach(CalendarDateTimeRange range) async {
    try {
      final response = await _supabase
          .from('booking_requests')
          .select()
          .gte('requested_start_at', range.start.toIso8601String())
          .lte('requested_start_at', range.end.toIso8601String())
          .order('requested_start_at');

      return (response as List)
          .map((booking) => BookingRequest.fromMap(booking))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }

  Future<void> submitBooking(BookingDraft draft) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final bookingData = {
        'client_id': userId,
        'coach_id': draft.coachId,
        'requested_start_at': draft.requestedStartAt.toIso8601String(),
        'requested_end_at': draft.requestedEndAt.toIso8601String(),
        'message': draft.message,
      };

      await _supabase
          .from('booking_requests')
          .insert(bookingData);
    } catch (e) {
      throw Exception('Failed to submit booking: $e');
    }
  }

  Future<void> respondBooking({
    required String requestId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('booking_requests')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to respond to booking: $e');
    }
  }

  Future<List<CalendarEventInstance>> expandRecurrence(
    CalendarEvent base,
    DateTime start,
    DateTime end,
  ) async {
    return await _expandRecurrenceWithOverrides(base, start, end);
  }

  /// Expand recurrence with overrides applied
  Future<List<CalendarEventInstance>> _expandRecurrenceWithOverrides(
    CalendarEvent base,
    DateTime start,
    DateTime end,
  ) async {
    // Load overrides once per base event
    final overrides = await listOverrides(base.id);
    
    if (base.recurrenceRule == null || base.recurrenceRule!.isEmpty) {
      // Single event
      if (base.startAt.isAfter(start) && base.startAt.isBefore(end)) {
        final baseEventMap = base.toMap();
        final mergedEvent = applyOverridesToOccurrence(
          baseEvent: baseEventMap,
          occurDate: base.startAt,
          overrides: overrides,
        );
        
        // Skip if cancelled
        if (mergedEvent['cancelled'] == true) {
          return [];
        }
        
        return [
          CalendarEventInstance(
            eventId: base.id,
            startAt: DateTime.parse(mergedEvent['start_at']),
            endAt: DateTime.parse(mergedEvent['end_at']),
            title: mergedEvent['title'],
            description: mergedEvent['description'],
            location: mergedEvent['location'],
            status: mergedEvent['status'],
            originalEvent: base,
          ),
        ];
      }
      return [];
    }

    final instances = <CalendarEventInstance>[];
    final rule = _parseRRule(base.recurrenceRule!);
    
    if (rule == null) return [];

    DateTime currentStart = base.startAt;
    int count = 0;
    const maxInstances = 300;

    while (currentStart.isBefore(end) && count < maxInstances) {
      if (currentStart.isAfter(start)) {
        final baseEventMap = base.toMap();
        final mergedEvent = applyOverridesToOccurrence(
          baseEvent: baseEventMap,
          occurDate: currentStart,
          overrides: overrides,
        );
        
        // Skip if cancelled
        if (mergedEvent['cancelled'] == true) {
          // Continue to next occurrence
          count++;
          switch (rule['freq']) {
            case 'DAILY':
              currentStart = currentStart.add(const Duration(days: 1));
              break;
            case 'WEEKLY':
              currentStart = currentStart.add(const Duration(days: 7));
              break;
            case 'MONTHLY':
              currentStart = DateTime(
                currentStart.year,
                currentStart.month + 1,
                currentStart.day,
                currentStart.hour,
                currentStart.minute,
              );
              break;
            default:
              return instances;
          }
          continue;
        }
        
        instances.add(CalendarEventInstance(
          eventId: base.id,
          startAt: DateTime.parse(mergedEvent['start_at']),
          endAt: DateTime.parse(mergedEvent['end_at']),
          title: mergedEvent['title'],
          description: mergedEvent['description'],
          location: mergedEvent['location'],
          status: mergedEvent['status'],
          originalEvent: base,
        ));
      }

      // Calculate next occurrence
      switch (rule['freq']) {
        case 'DAILY':
          currentStart = currentStart.add(const Duration(days: 1));
          break;
        case 'WEEKLY':
          currentStart = currentStart.add(const Duration(days: 7));
          break;
        case 'MONTHLY':
          currentStart = DateTime(
            currentStart.year,
            currentStart.month + 1,
            currentStart.day,
            currentStart.hour,
            currentStart.minute,
          );
          break;
        default:
          return instances;
      }

      count++;

      // Check UNTIL condition
      if (rule['until'] != null) {
        final untilDate = DateTime.parse(rule['until']!);
        if (currentStart.isAfter(untilDate)) break;
      }

      // Check COUNT condition
      if (rule['count'] != null) {
        final maxCount = int.parse(rule['count']!);
        if (count >= maxCount) break;
      }
    }

    return instances;
  }

  Map<String, String>? _parseRRule(String rrule) {
    try {
      final parts = rrule.split(';');
      final rule = <String, String>{};

      for (final part in parts) {
        final keyValue = part.split('=');
        if (keyValue.length == 2) {
          rule[keyValue[0]] = keyValue[1];
        }
      }

      return rule;
    } catch (e) {
      return null;
    }
  }

  // === Calendar Polish v1.1 Extensions ===

  /// Set attendee status for an event
  Future<void> setAttendeeStatus(String eventId, String status) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('calendar_attendees').upsert({
        'event_id': eventId,
        'user_id': user.id,
        'status': status,
        'responded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to set attendee status: $e');
    }
  }

  /// List attendees for an event
  Future<List<Map<String, dynamic>>> listAttendees(String eventId) async {
    try {
      final response = await _supabase
          .from('calendar_attendees')
          .select('*, profiles!user_id(email, first_name, last_name)')
          .eq('event_id', eventId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to list attendees: $e');
    }
  }

  /// Upsert booking policy for a coach
  Future<void> upsertBookingPolicy(Map<String, dynamic> policyJson) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final policy = Map<String, dynamic>.from(policyJson);
      policy['coach_id'] = user.id;
      policy['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('booking_policies').upsert(policy);
    } catch (e) {
      throw Exception('Failed to upsert booking policy: $e');
    }
  }

  /// Get booking policy for a coach
  Future<Map<String, dynamic>?> getBookingPolicy(String coachId) async {
    try {
      final response = await _supabase
          .from('booking_policies')
          .select()
          .eq('coach_id', coachId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get booking policy: $e');
    }
  }

  /// Upsert event override (for recurring events)
  Future<void> upsertOverride({
    required String eventId,
    required DateTime occurDate,
    required Map<String, dynamic> overrideJson,
    String scope = 'single',
  }) async {
    try {
      final override = Map<String, dynamic>.from(overrideJson);
      
              await _supabase.from('calendar_event_overrides').upsert({
        'event_id': eventId,
        'occur_date': occurDate.toIso8601String().split('T')[0], // Date only
        'override': override,
        'scope': scope,
      });
    } catch (e) {
      throw Exception('Failed to upsert override: $e');
    }
  }

  /// List overrides for an event
  Future<List<Map<String, dynamic>>> listOverrides(String eventId) async {
    try {
      final response = await _supabase
          .from('calendar_event_overrides')
          .select()
          .eq('event_id', eventId)
          .order('occur_date');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to list overrides: $e');
    }
  }

  /// Set custom reminders for an event (minute offsets)
  Future<void> setReminders(String eventId, List<int> offsetsMin) async {
    try {
      await _supabase.from('calendar_events').update({
        'reminders': offsetsMin,
      }).eq('id', eventId);
    } catch (e) {
      throw Exception('Failed to set reminders: $e');
    }
  }

  /// Add attendee to event
  Future<void> addAttendee(String eventId, String userId, {String role = 'participant'}) async {
    try {
      await _supabase.from('calendar_attendees').upsert({
        'event_id': eventId,
        'user_id': userId,
        'role': role,
        'status': 'invited',
      });
    } catch (e) {
      throw Exception('Failed to add attendee: $e');
    }
  }

  /// Remove attendee from event
  Future<void> removeAttendee(String eventId, String userId) async {
    try {
      await _supabase
          .from('calendar_attendees')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to remove attendee: $e');
    }
  }

  // === Calendar v1.2: Recurrence Scopes & Overrides ===

  /// Delete series (non-destructive: create a 'following' override with cancelled=true)
  Future<void> deleteSeries({required String eventId}) async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await upsertOverride(
        eventId: eventId,
        occurDate: tomorrow,
        overrideJson: {'cancelled': true},
        scope: 'following',
      );
    } catch (e) {
      throw Exception('Failed to delete series: $e');
    }
  }

  /// Merge an event occurrence with applicable overrides
  Map<String, dynamic> applyOverridesToOccurrence({
    required Map<String, dynamic> baseEvent,
    required DateTime occurDate,
    required List<Map<String, dynamic>> overrides,
  }) {
    final result = Map<String, dynamic>.from(baseEvent);
    
    // Apply 'following' overrides first (if occurDate >= override date)
    for (final override in overrides) {
      if (override['scope'] == 'following') {
        final overrideDate = DateTime.parse(override['occur_date']);
        if (occurDate.isAfter(overrideDate) || occurDate.isAtSameMomentAs(overrideDate)) {
          result.addAll(Map<String, dynamic>.from(override['override']));
        }
      }
    }
    
    // Apply 'single' override last (if exact date match)
    for (final override in overrides) {
      if (override['scope'] == 'single') {
        final overrideDate = DateTime.parse(override['occur_date']);
        if (occurDate.year == overrideDate.year &&
            occurDate.month == overrideDate.month &&
            occurDate.day == overrideDate.day) {
          result.addAll(Map<String, dynamic>.from(override['override']));
        }
      }
    }
    
    return result;
  }

  /// Scoped edit helpers
  Future<void> editOccurrenceSingle({
    required String eventId,
    required DateTime occurDate,
    required Map<String, dynamic> changes,
  }) async {
    await upsertOverride(
      eventId: eventId,
      occurDate: occurDate,
      overrideJson: changes,
      scope: 'single',
    );
  }

  Future<void> editOccurrenceFollowing({
    required String eventId,
    required DateTime occurDate,
    required Map<String, dynamic> changes,
  }) async {
    await upsertOverride(
      eventId: eventId,
      occurDate: occurDate,
      overrideJson: changes,
      scope: 'following',
    );
  }

  Future<void> editSeries({
    required String eventId,
    required Map<String, dynamic> changes,
  }) async {
    try {
      await _supabase.from('calendar_events').update(changes).eq('id', eventId);
    } catch (e) {
      throw Exception('Failed to edit series: $e');
    }
  }

  /// Scoped delete helpers
  Future<void> deleteOccurrenceSingle({
    required String eventId,
    required DateTime occurDate,
  }) async {
    await upsertOverride(
      eventId: eventId,
      occurDate: occurDate,
      overrideJson: {'cancelled': true},
      scope: 'single',
    );
  }

  Future<void> deleteOccurrenceFollowing({
    required String eventId,
    required DateTime occurDate,
  }) async {
    await upsertOverride(
      eventId: eventId,
      occurDate: occurDate,
      overrideJson: {'cancelled': true},
      scope: 'following',
    );
  }

  Future<void> deleteSeriesSoft({required String eventId}) async {
    await deleteSeries(eventId: eventId);
  }
}

class CalendarDateTimeRange {
  final DateTime start;
  final DateTime end;

  CalendarDateTimeRange({required this.start, required this.end});
}
