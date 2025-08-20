import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:postgrest/postgrest.dart';

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

  CalendarEventInstance({
    required this.eventId,
    required this.startAt,
    required this.endAt,
    required this.title,
    this.description,
    this.location,
    required this.status,
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

  List<CalendarEventInstance> expandRecurrence(
    CalendarEvent base,
    DateTime start,
    DateTime end,
  ) {
    if (base.recurrenceRule == null || base.recurrenceRule!.isEmpty) {
      // Single event
      if (base.startAt.isAfter(start) && base.startAt.isBefore(end)) {
        return [
          CalendarEventInstance(
            eventId: base.id,
            startAt: base.startAt,
            endAt: base.endAt,
            title: base.title,
            description: base.description,
            location: base.location,
            status: base.status,
          ),
        ];
      }
      return [];
    }

    final instances = <CalendarEventInstance>[];
    final rule = _parseRRule(base.recurrenceRule!);
    
    if (rule == null) return [];

    DateTime currentStart = base.startAt;
    DateTime currentEnd = base.endAt;
    final duration = base.endAt.difference(base.startAt);
    int count = 0;
    const maxInstances = 300;

    while (currentStart.isBefore(end) && count < maxInstances) {
      if (currentStart.isAfter(start)) {
        instances.add(CalendarEventInstance(
          eventId: base.id,
          startAt: currentStart,
          endAt: currentEnd,
          title: base.title,
          description: base.description,
          location: base.location,
          status: base.status,
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

      currentEnd = currentStart.add(duration);
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
}

class CalendarDateTimeRange {
  final DateTime start;
  final DateTime end;

  CalendarDateTimeRange({required this.start, required this.end});
}
