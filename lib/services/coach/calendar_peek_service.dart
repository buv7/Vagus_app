import 'dart:math';
import 'package:flutter/material.dart';

/// Represents a calendar event for peek functionality
class PeekEvent {
  final DateTime start;
  final DateTime end;
  final String title;
  
  PeekEvent({
    required this.start,
    required this.end,
    required this.title,
  });
}

/// Represents a free time block
class PeekBlock {
  final DateTime start;
  final DateTime end;
  
  PeekBlock(this.start, this.end);
  
  /// Duration of this free block
  Duration get duration => end.difference(start);
  
  /// Whether this block is long enough for the minimum duration
  bool isLongEnough(Duration minDuration) => duration >= minDuration;
}

/// Service for calendar availability peeking
class CalendarPeekService {
  static final CalendarPeekService _instance = CalendarPeekService._internal();
  factory CalendarPeekService() => _instance;
  CalendarPeekService._internal();

  /// Returns events in the next [hours] for this coach (local TZ)
  Future<List<PeekEvent>> upcomingCoachEvents({
    required String coachId,
    int hours = 48,
  }) async {
    try {
      // TODO: Replace with your real calendar fetch if present
      // For now, return mock data to demonstrate the feature
      return _generateMockEvents(hours);
    } catch (e) {
      print('CalendarPeekService: Error fetching events - $e');
      return [];
    }
  }

  /// Computes free blocks given business window constraints
  /// Handles DST transitions by normalizing with local TZ but comparing with UTC
  List<PeekBlock> computeFreeBlocks({
    required List<PeekEvent> events,
    required DateTime anchor,
    int hours = 48,
    int dayStartHour = 8,
    int dayEndHour = 20,
    Duration minBlock = const Duration(minutes: 15),
  }) {
    final blocks = <PeekBlock>[];
    
    // Normalize anchor to local timezone for day calculations
    final localAnchor = DateTime(anchor.year, anchor.month, anchor.day, anchor.hour, anchor.minute);
    final endHorizon = localAnchor.add(Duration(hours: hours));

    DateTime cursor = localAnchor;
    while (cursor.isBefore(endHorizon)) {
      final dayStart = DateTime(cursor.year, cursor.month, cursor.day, dayStartHour);
      final dayEnd = DateTime(cursor.year, cursor.month, cursor.day, dayEndHour);
      final windowStart = cursor.isAfter(dayStart) ? cursor : dayStart;
      final windowEnd = dayEnd.isBefore(endHorizon) ? dayEnd : endHorizon;

      if (windowEnd.isAfter(windowStart)) {
        // Find events that overlap with this window
        // Use UTC comparison to avoid DST edge cases
        final todaysEvents = events
            .where((e) => e.end.toUtc().isAfter(windowStart.toUtc()) && 
                         e.start.toUtc().isBefore(windowEnd.toUtc()))
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));

        DateTime freeStart = windowStart;
        for (final event in todaysEvents) {
          if (event.start.isAfter(freeStart)) {
            final gap = PeekBlock(freeStart, event.start);
            if (gap.isLongEnough(minBlock)) {
              blocks.add(gap);
            }
          }
          if (event.end.isAfter(freeStart)) {
            freeStart = event.end;
          }
        }
        
        // Check for free time at the end of the day
        if (freeStart.isBefore(windowEnd)) {
          final tail = PeekBlock(freeStart, windowEnd);
          if (tail.isLongEnough(minBlock)) {
            blocks.add(tail);
          }
        }
      }
      
      // Move to next day (local timezone)
      cursor = DateTime(cursor.year, cursor.month, cursor.day).add(const Duration(days: 1));
    }
    
    return blocks;
  }

  /// Generates mock events for demonstration
  List<PeekEvent> _generateMockEvents(int hours) {
    final now = DateTime.now();
    final events = <PeekEvent>[];
    final random = Random();
    
    // Generate 2-4 mock events over the next 48 hours
    final eventCount = 2 + random.nextInt(3);
    
    for (int i = 0; i < eventCount; i++) {
      // Random start time within next 48 hours
      final startOffset = Duration(
        hours: random.nextInt(hours),
        minutes: random.nextInt(60),
      );
      final start = now.add(startOffset);
      
      // Random duration between 30 minutes and 2 hours
      final duration = Duration(
        minutes: 30 + random.nextInt(90),
      );
      final end = start.add(duration);
      
      // Only add if it's in the future and within business hours
      if (start.isAfter(now) && 
          start.hour >= 8 && 
          start.hour <= 20 &&
          start.weekday >= 1 && 
          start.weekday <= 5) {
        events.add(PeekEvent(
          start: start,
          end: end,
          title: _getMockEventTitle(random),
        ));
      }
    }
    
    // Sort by start time
    events.sort((a, b) => a.start.compareTo(b.start));
    return events;
  }

  /// Gets a random mock event title
  String _getMockEventTitle(Random random) {
    const titles = [
      'Client Call',
      'Team Meeting',
      'Training Session',
      'Review Meeting',
      'Planning Session',
      'Follow-up Call',
      'Strategy Discussion',
      'Progress Review',
    ];
    return titles[random.nextInt(titles.length)];
  }

  /// Gets the next business day start time
  DateTime getNextBusinessDayStart(int hour) {
    var nextDay = DateTime.now().add(const Duration(days: 1));
    
    // Skip weekends
    while (nextDay.weekday == 6 || nextDay.weekday == 7) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    
    return DateTime(nextDay.year, nextDay.month, nextDay.day, hour, 0);
  }

  /// Checks if a time is within business hours
  bool isBusinessHours(DateTime time) {
    return time.hour >= 8 && time.hour <= 20 && 
           time.weekday >= 1 && time.weekday <= 5;
  }

  /// Gets the business hours for a given date
  DateTimeRange getBusinessHours(DateTime date) {
    final start = DateTime(date.year, date.month, date.day, 8, 0);
    final end = DateTime(date.year, date.month, date.day, 20, 0);
    return DateTimeRange(start: start, end: end);
  }

  /// Formats a time block for display
  String formatTimeBlock(PeekBlock block) {
    final start = block.start;
    final end = block.end;
    final duration = block.duration;
    
    final startStr = _formatTime(start);
    final endStr = _formatTime(end);
    final durationStr = _formatDuration(duration);
    
    return '$startStr - $endStr ($durationStr)';
  }

  /// Formats a DateTime for display
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formats a Duration for display
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Gets the day of week abbreviation
  String getDayOfWeek(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Formats a DateTime for compact display
  String formatCompactTime(DateTime time) {
    final dow = getDayOfWeek(time.weekday);
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    
    return '$dow $month-$day $hour:$minute';
  }
}
