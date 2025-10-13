import 'package:flutter/material.dart';
import '../core/logger.dart';

/// Handles recurring event expansion based on RRULE
///
/// Supports basic RFC 5545 recurrence:
/// - FREQ=DAILY|WEEKLY|MONTHLY
/// - BYDAY=MO,TU,WE,TH,FR,SA,SU
/// - COUNT=n or UNTIL=date
class RecurringEventHandler {
  static final RecurringEventHandler _instance = RecurringEventHandler._internal();
  static RecurringEventHandler get instance => _instance;
  RecurringEventHandler._internal();

  /// Expand RRULE instances within [rangeStart, rangeEnd]
  List<DateTimeRange> expandInstances({
    required DateTime start,
    required DateTime end,
    required String? rrule,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    // If no RRULE, return single instance
    if (rrule == null || rrule.isEmpty) {
      return [DateTimeRange(start: start, end: end)];
    }

    try {
      return _parseAndExpand(
        start: start,
        end: end,
        rrule: rrule,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
    } catch (e, st) {
      Logger.error('Failed to expand RRULE', error: e, stackTrace: st, data: {'rrule': rrule});
      // Fallback to single instance on parse error
      return [DateTimeRange(start: start, end: end)];
    }
  }

  List<DateTimeRange> _parseAndExpand({
    required DateTime start,
    required DateTime end,
    required String rrule,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    // Parse RRULE components
    final parts = <String, String>{};
    for (final segment in rrule.split(';')) {
      final keyValue = segment.split('=');
      if (keyValue.length == 2) {
        parts[keyValue[0].trim().toUpperCase()] = keyValue[1].trim().toUpperCase();
      }
    }

    final freq = parts['FREQ'] ?? 'WEEKLY';
    final until = parts.containsKey('UNTIL') 
        ? DateTime.tryParse(parts['UNTIL']!.replaceAll('Z', '')) 
        : null;
    final count = parts.containsKey('COUNT') 
        ? int.tryParse(parts['COUNT']!) 
        : null;
    final byDay = parts.containsKey('BYDAY')
        ? parts['BYDAY']!.split(',').where((e) => e.isNotEmpty).toList()
        : <String>[];

    final instances = <DateTimeRange>[];
    var cursorStart = start;
    var cursorEnd = end;
    int emitted = 0;
    final eventDuration = end.difference(start);

    bool within(DateTime d) =>
        d.isAfter(rangeStart.subtract(const Duration(seconds: 1))) &&
        d.isBefore(rangeEnd.add(const Duration(seconds: 1)));

    void addInstance() {
      if (within(cursorStart) || within(cursorEnd) ||
          (cursorStart.isBefore(rangeStart) && cursorEnd.isAfter(rangeEnd))) {
        instances.add(DateTimeRange(start: cursorStart, end: cursorEnd));
        emitted++;
      }
    }

    // Safety limit on iterations
    int iterations = 0;
    const maxIterations = 1000;

    while (iterations < maxIterations) {
      iterations++;

      // Check stop conditions
      if (until != null && cursorStart.isAfter(until)) break;
      if (count != null && emitted >= count) break;
      if (cursorStart.isAfter(rangeEnd.add(const Duration(days: 370)))) break;

      switch (freq) {
        case 'DAILY':
          addInstance();
          cursorStart = cursorStart.add(const Duration(days: 1));
          cursorEnd = cursorStart.add(eventDuration);
          break;

        case 'WEEKLY':
          if (byDay.isEmpty) {
            // Simple weekly recurrence
            addInstance();
            cursorStart = cursorStart.add(const Duration(days: 7));
            cursorEnd = cursorStart.add(eventDuration);
          } else {
            // Weekly on specific days (e.g., MO,WE,FR)
            final weekStart = _getWeekStart(cursorStart);
            for (final day in byDay) {
              final dayOffset = _getDayOffset(day);
              final instanceStart = weekStart.add(Duration(days: dayOffset));
              final instanceEnd = instanceStart.add(eventDuration);
              
              if (within(instanceStart) || within(instanceEnd)) {
                instances.add(DateTimeRange(start: instanceStart, end: instanceEnd));
                emitted++;
              }
              
              if (count != null && emitted >= count) break;
            }
            // Move to next week
            cursorStart = weekStart.add(const Duration(days: 7));
            cursorEnd = cursorStart.add(eventDuration);
          }
          break;

        case 'MONTHLY':
          addInstance();
          // Move to same day next month
          final nextMonth = cursorStart.month == 12 
              ? DateTime(cursorStart.year + 1, 1, cursorStart.day, cursorStart.hour, cursorStart.minute)
              : DateTime(cursorStart.year, cursorStart.month + 1, cursorStart.day, cursorStart.hour, cursorStart.minute);
          cursorStart = nextMonth;
          cursorEnd = cursorStart.add(eventDuration);
          break;

        default:
          // Unknown frequency, treat as weekly
          addInstance();
          cursorStart = cursorStart.add(const Duration(days: 7));
          cursorEnd = cursorStart.add(eventDuration);
      }
    }

    Logger.debug('RRULE expanded', data: {
      'rrule': rrule,
      'instances': instances.length,
      'iterations': iterations,
    });

    return instances;
  }

  DateTime _getWeekStart(DateTime date) {
    // Get Monday of the week
    final weekday = date.weekday; // 1=Monday, 7=Sunday
    return date.subtract(Duration(days: weekday - 1));
  }

  int _getDayOffset(String dayCode) {
    // Convert day code to offset from Monday
    switch (dayCode) {
      case 'MO': return 0;
      case 'TU': return 1;
      case 'WE': return 2;
      case 'TH': return 3;
      case 'FR': return 4;
      case 'SA': return 5;
      case 'SU': return 6;
      default: return 0;
    }
  }

  /// Helper to create common RRULE strings
  static String createWeeklyRRule({
    required List<String> days, // ['MO', 'WE', 'FR']
    int? count,
    DateTime? until,
  }) {
    final parts = ['FREQ=WEEKLY'];
    
    if (days.isNotEmpty) {
      parts.add('BYDAY=${days.join(',')}');
    }
    
    if (count != null) {
      parts.add('COUNT=$count');
    } else if (until != null) {
      parts.add('UNTIL=${until.toIso8601String()}');
    }
    
    return parts.join(';');
  }

  static String createDailyRRule({
    int? count,
    DateTime? until,
  }) {
    final parts = ['FREQ=DAILY'];
    
    if (count != null) {
      parts.add('COUNT=$count');
    } else if (until != null) {
      parts.add('UNTIL=${until.toIso8601String()}');
    }
    
    return parts.join(';');
  }

  static String createMonthlyRRule({
    int? count,
    DateTime? until,
  }) {
    final parts = ['FREQ=MONTHLY'];
    
    if (count != null) {
      parts.add('COUNT=$count');
    } else if (until != null) {
      parts.add('UNTIL=${until.toIso8601String()}');
    }
    
    return parts.join(';');
  }
}

