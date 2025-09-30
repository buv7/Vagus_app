import 'package:flutter/foundation.dart';
import 'calendar_quick_book_service.dart';
import 'calendar_peek_service.dart';
import 'quickbook_autoconfirm_service.dart';

/// Result of a reschedule suggestion operation
class ReschedResult {
  final bool ok;
  final String message;
  final List<QuickBookSlot> options;
  
  ReschedResult(this.ok, this.message, this.options);
  
  static ReschedResult success(String message, List<QuickBookSlot> options) => 
      ReschedResult(true, message, options);
  static ReschedResult failure(String message) => 
      ReschedResult(false, message, []);
}

/// Service for handling reschedule requests and suggestions
class QuickBookRescheduleService {
  static final QuickBookRescheduleService instance = QuickBookRescheduleService._();
  QuickBookRescheduleService._();

  final CalendarPeekService _peek = CalendarPeekService();
  final CalendarQuickBookService _qb = CalendarQuickBookService();

  /// Detects if text indicates reschedule intent
  bool isRescheduleIntent(String text) {
    final t = text.toLowerCase().trim();
    const keys = [
      'can\'t make', 'cant make', 'cannot make', 'need to move', 'resched', 'reschedule', 
      'push it', 'change time', 'later time', 'earlier time', 'can we move', 'delay', 
      'postpone', 'move it', 'shift it', 'reschedule it', 'change it', 'different time',
      'أجل', 'تأجيل', 'غير الموعد', 'مو أگدر', 'تغيير الموعد', 'تأخير' // Arabic/Kurdish
    ];
    return keys.any((k) => t.contains(k));
  }

  /// Suggests 2 alternative time slots
  Future<ReschedResult> suggestAlternatives({
    required String coachId,
    required String clientId,
    Duration duration = const Duration(minutes: 15),
  }) async {
    try {
      final now = DateTime.now();
      final options = <QuickBookSlot>[];

      // Try free blocks first (prefer 48h peek)
      final events = await _peek.upcomingCoachEvents(coachId: coachId, hours: 48);
      final blocks = _peek.computeFreeBlocks(
        events: events, 
        anchor: now, 
        hours: 48,
        minBlock: duration,
      );

      // Convert free blocks to slots
      for (final block in blocks) {
        final blockDuration = block.end.difference(block.start);
        if (blockDuration >= duration) {
          options.add(QuickBookSlot(block.start, duration));
        }
        if (options.length >= 2) break;
      }

      // If not enough free blocks, fallback to default suggestions
      if (options.length < 2) {
        final suggestions = await _qb.suggestSlots(
          coachId: coachId,
          clientId: clientId,
          daysLookahead: 4,
          duration: duration,
        );
        
        // Add suggestions up to 2 total options
        for (final suggestion in suggestions) {
          if (options.length >= 2) break;
          options.add(suggestion);
        }
      }

      if (options.isEmpty) {
        return ReschedResult.failure('No alternative times available in the next 48 hours.');
      }

      return ReschedResult.success(
        'Found ${options.length} alternative time${options.length == 1 ? '' : 's'}.', 
        options.take(2).toList()
      );
    } catch (e) {
      debugPrint('QuickBookRescheduleService: Error suggesting alternatives - $e');
      return ReschedResult.failure('Failed to find alternatives: $e');
    }
  }

  /// Sends a reschedule suggestion message with 2 options
  Future<void> sendRescheduleMessage({
    required String clientId,
    required String coachId,
    required String conversationId,
    required List<QuickBookSlot> options,
  }) async {
    if (options.isEmpty) return;

    try {
      // Build the reschedule message
      final message = _buildRescheduleMessage(options);
      
      // Send the message using the existing messaging service
      await _sendRescheduleText(conversationId, message);

      // Track the first option as the 'active' proposal for auto-confirmation
      if (options.isNotEmpty) {
        QuickBookAutoConfirmService.instance.trackProposal(
          ProposedSlot(
            conversationId: conversationId,
            clientId: clientId,
            coachId: coachId,
            start: options.first.start,
            duration: options.first.duration,
            sentAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      debugPrint('QuickBookRescheduleService: Error sending reschedule message - $e');
    }
  }

  /// Builds the reschedule message text
  String _buildRescheduleMessage(List<QuickBookSlot> options) {
    final lines = <String>['🔁 Reschedule options:'];
    
    for (int i = 0; i < options.length; i++) {
      final slot = options[i];
      final formattedTime = _formatDateTime(slot.start);
      final durationText = slot.duration.inMinutes == 15 ? '15 min' : '${slot.duration.inMinutes} min';
      lines.add('• Option ${i + 1}: $formattedTime ($durationText)');
    }
    
    lines.add('Reply \'option 1\' or \'option 2\', or propose another time.');
    
    return lines.join('\n');
  }

  /// Sends reschedule text message
  Future<void> _sendRescheduleText(String conversationId, String message) async {
    // This would use your existing messaging service
    // For now, we'll use the CalendarQuickBookService as a fallback
    // In a real implementation, you'd call your messaging service directly
    debugPrint('Reschedule message: $message');
  }

  /// Parses option selection from text (option 1, option 2, etc.)
  /// Hardened to avoid re-triggering on earlier history
  int? parseOptionSelection(String text) {
    final t = text.toLowerCase().trim();
    
    // Early return for empty or whitespace-only text
    if (t.isEmpty) return null;
    
    // Check for various option patterns with improved specificity
    if (t.contains('option 1') || t.contains('option one') || t.contains('1') || t.contains('١')) {
      return 1;
    }
    if (t.contains('option 2') || t.contains('option two') || t.contains('2') || t.contains('٢')) {
      return 2;
    }
    
    // Check for 'first' and 'second' patterns
    if (t.contains('first') || t.contains('أول')) return 1;
    if (t.contains('second') || t.contains('ثاني')) return 2;
    
    return null;
  }

  /// Parses option selection from the last inbound message only
  /// This prevents re-triggering on earlier message history
  int? parseOptionFromLastMessage(List<String> messageHistory) {
    if (messageHistory.isEmpty) return null;
    
    // Only parse the last message to avoid re-triggering on earlier history
    final lastMessage = messageHistory.last;
    return parseOptionSelection(lastMessage);
  }

  /// Gets the selected option from a list of options
  QuickBookSlot? getSelectedOption(List<QuickBookSlot> options, int selection) {
    if (selection < 1 || selection > options.length) return null;
    return options[selection - 1];
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

  /// Checks if a message is a reschedule request
  bool isRescheduleRequest(String message) {
    return isRescheduleIntent(message);
  }

  /// Gets alternative suggestions for a specific time range
  Future<ReschedResult> suggestAlternativesInRange({
    required String coachId,
    required String clientId,
    required DateTime startTime,
    required DateTime endTime,
    Duration duration = const Duration(minutes: 15),
  }) async {
    try {
      final options = <QuickBookSlot>[];

      // Get events in the specified range
      final events = await _peek.upcomingCoachEvents(coachId: coachId, hours: 48);
      final rangeEvents = events.where((e) => 
        e.start.isAfter(startTime) && e.start.isBefore(endTime)
      ).toList();

      // Compute free blocks in the range
      final blocks = _peek.computeFreeBlocks(
        events: rangeEvents,
        anchor: startTime,
        hours: endTime.difference(startTime).inHours,
        minBlock: duration,
      );

      // Convert to slots
      for (final block in blocks) {
        final blockDuration = block.end.difference(block.start);
        if (blockDuration >= duration) {
          options.add(QuickBookSlot(block.start, duration));
        }
        if (options.length >= 2) break;
      }

      if (options.isEmpty) {
        return ReschedResult.failure('No available times in the specified range.');
      }

      return ReschedResult.success(
        'Found ${options.length} alternative time${options.length == 1 ? '' : 's'} in range.', 
        options.take(2).toList()
      );
    } catch (e) {
      debugPrint('QuickBookRescheduleService: Error suggesting alternatives in range - $e');
      return ReschedResult.failure('Failed to find alternatives in range: $e');
    }
  }

  /// Suggests alternatives with specific preferences
  Future<ReschedResult> suggestAlternativesWithPreferences({
    required String coachId,
    required String clientId,
    List<int> preferredHours = const [10, 14, 18], // 10 AM, 2 PM, 6 PM
    Duration duration = const Duration(minutes: 15),
  }) async {
    try {
      final now = DateTime.now();
      final options = <QuickBookSlot>[];

      // Try each preferred hour for the next 3 days
      for (int dayOffset = 1; dayOffset <= 3; dayOffset++) {
        final targetDate = now.add(Duration(days: dayOffset));
        
        for (final hour in preferredHours) {
          final slotTime = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, 0);
          
          // Skip if in the past
          if (slotTime.isBefore(now)) continue;
          
          // Skip weekends
          if (slotTime.weekday == 6 || slotTime.weekday == 7) continue;
          
          options.add(QuickBookSlot(slotTime, duration));
          
          if (options.length >= 2) break;
        }
        
        if (options.length >= 2) break;
      }

      if (options.isEmpty) {
        // Fallback to default suggestions
        return await suggestAlternatives(
          coachId: coachId,
          clientId: clientId,
          duration: duration,
        );
      }

      return ReschedResult.success(
        'Found ${options.length} preferred time${options.length == 1 ? '' : 's'}.', 
        options.take(2).toList()
      );
    } catch (e) {
      debugPrint('QuickBookRescheduleService: Error suggesting alternatives with preferences - $e');
      return ReschedResult.failure('Failed to find preferred alternatives: $e');
    }
  }
}
