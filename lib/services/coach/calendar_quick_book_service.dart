import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../messages_service.dart';

final _sb = Supabase.instance.client;

/// Quick book slot with start time and duration
class QuickBookSlot {
  final DateTime start;
  final Duration duration;
  
  QuickBookSlot(this.start, this.duration);
}

/// Result of a quick book operation
class QuickBookResult {
  final bool ok;
  final String message;
  
  QuickBookResult(this.ok, this.message);
  
  static QuickBookResult success(String message) => QuickBookResult(true, message);
  static QuickBookResult failure(String message) => QuickBookResult(false, message);
}

/// Service for quick booking calendar slots
class CalendarQuickBookService {
  static final CalendarQuickBookService _instance = CalendarQuickBookService._internal();
  factory CalendarQuickBookService() => _instance;
  CalendarQuickBookService._internal();

  final MessagesService _messagesService = MessagesService();

  /// Gets coach timezone (simplified - uses device timezone)
  Future<String> coachTimeZone(String coachId) async {
    return DateTime.now().timeZoneName;
  }

  /// Gets client timezone (simplified - uses device timezone)
  Future<String> clientTimeZone(String clientId) async {
    return DateTime.now().timeZoneName;
  }

  /// Suggests available slots for booking
  Future<List<QuickBookSlot>> suggestSlots({
    required String coachId,
    required String clientId,
    int daysLookahead = 3,
    Duration duration = const Duration(minutes: 15),
  }) async {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final List<QuickBookSlot> slots = [];

    // Default windows: 10:00 and 18:00 for next N days, skip past times today
    for (int d = 1; d <= daysLookahead; d++) {
      final day = base.add(Duration(days: d));
      
      // Skip weekends (Saturday = 6, Sunday = 7)
      if (day.weekday == 6 || day.weekday == 7) continue;
      
      for (final hour in [10, 18]) {
        final start = DateTime(day.year, day.month, day.day, hour, 0);
        if (start.isAfter(now)) {
          slots.add(QuickBookSlot(start, duration));
        }
      }
    }

    return slots.take(6).toList();
  }

  /// Creates a hold event (placeholder - would integrate with real calendar service)
  Future<QuickBookResult> createHoldEvent({
    required String clientId,
    required QuickBookSlot slot,
  }) async {
    try {
      // TODO: If you have an existing booking service, call it here
      // For now, just return success without persisting
      
      // In a real implementation, you would:
      // 1. Check coach availability
      // 2. Create a tentative booking
      // 3. Send confirmation to client
      // 4. Return actual booking ID
      
      return QuickBookResult.success('Hold created for ${_formatDateTime(slot.start)}');
    } catch (e) {
      print('CalendarQuickBookService: Error creating hold event - $e');
      return QuickBookResult.failure('Failed to create hold: $e');
    }
  }

  /// Sends a proposal message to the client
  Future<QuickBookResult> sendProposalMessage({
    required String clientId,
    required QuickBookSlot slot,
    bool includeCalendarLink = false,
  }) async {
    try {
      final user = _sb.auth.currentUser;
      if (user == null) {
        return QuickBookResult.failure('Not authenticated');
      }

      // Get or create thread
      final threadId = await _messagesService.ensureThread(
        coachId: user.id,
        clientId: clientId,
      );

      // Format the proposal message
      final local = slot.start;
      final text = _buildProposalMessage(local, slot.duration, includeCalendarLink);

      // Send message
      await _messagesService.sendText(
        threadId: threadId,
        text: text,
      );

      return QuickBookResult.success('Proposal sent');
    } catch (e) {
      print('CalendarQuickBookService: Error sending proposal - $e');
      return QuickBookResult.failure('Failed to send proposal: $e');
    }
  }

  /// Builds the proposal message text
  String _buildProposalMessage(DateTime slot, Duration duration, bool includeCalendarLink) {
    final formattedTime = _formatDateTime(slot);
    final durationText = duration.inMinutes == 15 ? '15 min' : '${duration.inMinutes} min';
    
    var message = '📞 Quick call proposal: $formattedTime for $durationText.\n'
        'Reply "yes" to confirm or suggest another time.';
    
    if (includeCalendarLink) {
      // In a real implementation, you would generate a calendar link here
      message += '\n\n📅 [Add to Calendar]'; // Placeholder
    }
    
    return message;
  }

  /// Formats DateTime for display
  String _formatDateTime(DateTime dt) {
    final dow = _getDayOfWeek(dt.weekday);
    final year = dt.year;
    final month = _pad(dt.month);
    final day = _pad(dt.day);
    final hour = _pad(dt.hour);
    final minute = _pad(dt.minute);
    
    return '$dow $year-$month-$day $hour:$minute';
  }

  /// Gets day of week abbreviation
  String _getDayOfWeek(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Pads single digits with leading zero
  String _pad(int x) => x < 10 ? '0$x' : '$x';

  /// Sends a quick call proposal with multiple time options
  Future<QuickBookResult> sendMultiOptionProposal({
    required String clientId,
    required List<QuickBookSlot> slots,
  }) async {
    try {
      final user = _sb.auth.currentUser;
      if (user == null) {
        return QuickBookResult.failure('Not authenticated');
      }

      final threadId = await _messagesService.ensureThread(
        coachId: user.id,
        clientId: clientId,
      );

      final text = _buildMultiOptionMessage(slots);

      await _messagesService.sendText(
        threadId: threadId,
        text: text,
      );

      return QuickBookResult.success('Multi-option proposal sent');
    } catch (e) {
      print('CalendarQuickBookService: Error sending multi-option proposal - $e');
      return QuickBookResult.failure('Failed to send proposal: $e');
    }
  }

  /// Builds multi-option proposal message
  String _buildMultiOptionMessage(List<QuickBookSlot> slots) {
    var message = '📞 Quick call proposal - here are some available times:\n\n';
    
    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final formattedTime = _formatDateTime(slot.start);
      final durationText = slot.duration.inMinutes == 15 ? '15 min' : '${slot.duration.inMinutes} min';
      message += '${i + 1}. $formattedTime ($durationText)\n';
    }
    
    message += '\nReply with the number of your preferred time, or suggest another time.';
    
    return message;
  }

  /// Checks if a time slot is in the past
  bool isSlotInPast(QuickBookSlot slot) {
    return slot.start.isBefore(DateTime.now());
  }

  /// Gets next business day at specified hour
  DateTime getNextBusinessDay(int hour) {
    var nextDay = DateTime.now().add(const Duration(days: 1));
    
    // Skip weekends
    while (nextDay.weekday == 6 || nextDay.weekday == 7) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    
    return DateTime(nextDay.year, nextDay.month, nextDay.day, hour, 0);
  }

  /// Validates a custom time slot
  QuickBookResult validateSlot(QuickBookSlot slot) {
    if (isSlotInPast(slot)) {
      return QuickBookResult.failure('Cannot book time in the past');
    }
    
    if (slot.start.weekday == 6 || slot.start.weekday == 7) {
      return QuickBookResult.failure('Weekend bookings not available');
    }
    
    if (slot.duration.inMinutes < 15) {
      return QuickBookResult.failure('Minimum booking duration is 15 minutes');
    }
    
    if (slot.duration.inMinutes > 120) {
      return QuickBookResult.failure('Maximum booking duration is 2 hours');
    }
    
    return QuickBookResult.success('Slot is valid');
  }
}
