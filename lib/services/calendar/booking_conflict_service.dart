import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../core/result.dart';

/// Service to check calendar conflicts before booking
class BookingConflictService {
  static final BookingConflictService _instance = BookingConflictService._internal();
  static BookingConflictService get instance => _instance;
  BookingConflictService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Check for conflicts by calling the edge function
  Future<Result<ConflictCheckResult, String>> checkConflicts({
    required String coachId,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    try {
      Logger.info('Checking calendar conflicts', data: {
        'coachId': coachId,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
      });

      final response = await _supabase.functions.invoke(
        'calendar-conflicts',
        body: {
          'coachId': coachId,
          'startAt': startAt.toIso8601String(),
          'endAt': endAt.toIso8601String(),
        },
      );

      if (response.status != 200) {
        Logger.error('Conflict check failed', data: {
          'status': response.status,
          'data': response.data,
        });
        return Result.failure('Conflict check failed: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      final hasConflict = data['hasConflict'] as bool? ?? false;
      final conflicts = (data['conflicts'] as List<dynamic>?)
              ?.map((c) => ConflictingEvent.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [];

      Logger.info('Conflict check result', data: {
        'hasConflict': hasConflict,
        'conflictCount': conflicts.length,
      });

      return Result.success(ConflictCheckResult(
        hasConflict: hasConflict,
        conflicts: conflicts,
      ));
    } catch (e, st) {
      Logger.error('Error checking conflicts', error: e, stackTrace: st);
      return Result.failure('Failed to check conflicts: $e');
    }
  }

  /// Create a booking request after conflict check passes
  Future<Result<String, String>> createBookingRequest({
    required String coachId,
    required String clientId,
    required DateTime startAt,
    required DateTime endAt,
    String? note,
    String? eventId,
  }) async {
    try {
      // First, check for conflicts
      final conflictResult = await checkConflicts(
        coachId: coachId,
        startAt: startAt,
        endAt: endAt,
      );

      if (conflictResult.isFailure) {
        return Result.failure(conflictResult.error);
      }

      final conflictData = conflictResult.value;
      if (conflictData.hasConflict) {
        return Result.failure(
          'Coach has ${conflictData.conflicts.length} conflicting events at this time',
        );
      }

      // No conflicts, create booking request
      final data = await _supabase.from('booking_requests').insert({
        'coach_id': coachId,
        'client_id': clientId,
        'event_id': eventId,
        'status': 'pending',
        'note': note,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final bookingId = data['id'] as String;

      Logger.info('Booking request created', data: {
        'bookingId': bookingId,
        'coachId': coachId,
      });

      return Result.success(bookingId);
    } catch (e, st) {
      Logger.error('Failed to create booking request', error: e, stackTrace: st);
      return Result.failure('Failed to create booking: $e');
    }
  }

  /// Approve a booking request (coach only)
  Future<Result<void, String>> approveBooking(String bookingId) async {
    try {
      await _supabase
          .from('booking_requests')
          .update({'status': 'approved', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', bookingId);

      Logger.info('Booking approved', data: {'bookingId': bookingId});
      return Result.success(null);
    } catch (e, st) {
      Logger.error('Failed to approve booking', error: e, stackTrace: st);
      return Result.failure('Failed to approve: $e');
    }
  }

  /// Reject a booking request (coach only)
  Future<Result<void, String>> rejectBooking(String bookingId) async {
    try {
      await _supabase
          .from('booking_requests')
          .update({'status': 'rejected', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', bookingId);

      Logger.info('Booking rejected', data: {'bookingId': bookingId});
      return Result.success(null);
    } catch (e, st) {
      Logger.error('Failed to reject booking', error: e, stackTrace: st);
      return Result.failure('Failed to reject: $e');
    }
  }
}

/// Result of conflict check
class ConflictCheckResult {
  final bool hasConflict;
  final List<ConflictingEvent> conflicts;

  ConflictCheckResult({
    required this.hasConflict,
    required this.conflicts,
  });
}

/// Conflicting event details
class ConflictingEvent {
  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;

  ConflictingEvent({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
  });

  factory ConflictingEvent.fromJson(Map<String, dynamic> json) {
    return ConflictingEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
    );
  }
}

