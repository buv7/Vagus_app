import 'dart:math';

/// Represents a parsed time with start, duration, and source text
class ParsedTime {
  final DateTime start;
  final Duration duration;
  final String source;
  
  ParsedTime({
    required this.start,
    required this.duration,
    required this.source,
  });
}

/// Natural language time parser for English and Arabic
class NaturalTimeParser {
  // Arabic digit mapping
  static const Map<String, String> _arabicDigits = {
    '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
    '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
  };

  // Weekday mapping (English and Arabic)
  static const Map<String, int> _weekdays = {
    // English
    'monday': 1, 'mon': 1,
    'tuesday': 2, 'tue': 2,
    'wednesday': 3, 'wed': 3,
    'thursday': 4, 'thu': 4,
    'friday': 5, 'fri': 5,
    'saturday': 6, 'sat': 6,
    'sunday': 7, 'sun': 7,
    // Arabic
    'الاثنين': 1, 'اثنين': 1,
    'الثلاثاء': 2, 'ثلاثاء': 2,
    'الاربعاء': 3, 'اربعاء': 3,
    'الخميس': 4, 'خميس': 4,
    'الجمعة': 5, 'جمعة': 5,
    'السبت': 6, 'سبت': 6,
    'الاحد': 7, 'احد': 7,
  };

  // Relative time keywords
  static const Map<String, String> _relativeKeywords = {
    'now': 'now',
    'tmrw': 'tomorrow', 'tomorrow': 'tomorrow',
    'غدا': 'tomorrow', 'غداً': 'tomorrow', 'باجر': 'tomorrow',
    'today': 'today', 'اليوم': 'today',
  };

  /// Parses natural language time expressions
  static ParsedTime? parse(String text, {
    DateTime? anchor,
    Duration defaultDuration = const Duration(minutes: 15),
  }) {
    if (text.trim().isEmpty) return null;
    
    final now = anchor ?? DateTime.now();
    final normalized = _normalizeText(text);
    
    // Try different parsing patterns in order of specificity
    final patterns = [
      _parseRelativeTime,
      _parseTomorrowTime,
      _parseWeekdayTime,
      _parseTodayTime,
      _parseDateLite,
    ];
    
    for (final pattern in patterns) {
      final result = pattern(normalized, now, defaultDuration);
      if (result != null) {
        // Validate the parsed time
        if (_isValidTime(result.start, now)) {
          return result;
        }
      }
    }
    
    return null;
  }

  /// Normalizes input text
  static String _normalizeText(String text) {
    var normalized = text.toLowerCase().trim();
    
    // Convert Arabic digits to English
    for (final entry in _arabicDigits.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    
    // Collapse multiple spaces
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    
    return normalized;
  }

  /// Parses relative time expressions (e.g., "in 30 min", "بعد ساعة")
  static ParsedTime? _parseRelativeTime(String text, DateTime now, Duration defaultDuration) {
    final patterns = [
      // English patterns
      RegExp(r'in\s+(\d+)\s*(m|min|minute|minutes|h|hr|hour|hours)'),
      RegExp(r'(\d+)\s*(m|min|minute|minutes|h|hr|hour|hours)\s+from\s+now'),
      // Arabic patterns
      RegExp(r'بعد\s+(\d+)\s*(ساعة|س|دقيقة|د)'),
      RegExp(r'(\d+)\s*(ساعة|س|دقيقة|د)\s+من\s+الآن'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final value = int.tryParse(match.group(1) ?? '');
        final unit = match.group(2) ?? '';
        
        if (value != null) {
          Duration duration;
          if (unit.contains('h') || unit.contains('ساعة') || unit.contains('س')) {
            duration = Duration(hours: value);
          } else {
            duration = Duration(minutes: value);
          }
          
          final startTime = now.add(duration);
          return ParsedTime(
            start: startTime,
            duration: defaultDuration,
            source: match.group(0) ?? '',
          );
        }
      }
    }
    
    return null;
  }

  /// Parses tomorrow time expressions (e.g., "tmrw 6pm", "غداً 7")
  static ParsedTime? _parseTomorrowTime(String text, DateTime now, Duration defaultDuration) {
    final patterns = [
      // English patterns
      RegExp(r'(tmrw|tomorrow)\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?'),
      // Arabic patterns
      RegExp(r'(غدا|غداً|باجر)\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final hour = int.tryParse(match.group(2) ?? '');
        final minute = int.tryParse(match.group(3) ?? '0');
        final ampm = match.group(4);
        
        if (hour != null) {
          final tomorrow = now.add(const Duration(days: 1));
          final parsedHour = _parseHour(hour, ampm);
          final parsedMinute = minute ?? 0;
          
          final startTime = DateTime(
            tomorrow.year,
            tomorrow.month,
            tomorrow.day,
            parsedHour,
            parsedMinute,
          );
          
          return ParsedTime(
            start: startTime,
            duration: defaultDuration,
            source: match.group(0) ?? '',
          );
        }
      }
    }
    
    return null;
  }

  /// Parses weekday time expressions (e.g., "thu 7", "الخميس 18:15")
  static ParsedTime? _parseWeekdayTime(String text, DateTime now, Duration defaultDuration) {
    final patterns = [
      // English patterns
      RegExp(r'(next\s+)?(mon|tue|wed|thu|fri|sat|sun|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?'),
      // Arabic patterns
      RegExp(r'(الاثنين|الثلاثاء|الاربعاء|الخميس|الجمعة|السبت|الاحد|اثنين|ثلاثاء|اربعاء|خميس|جمعة|سبت|احد)\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final weekdayName = match.group(2) ?? match.group(1) ?? '';
        final hour = int.tryParse(match.group(3) ?? '');
        final minute = int.tryParse(match.group(4) ?? '0');
        final ampm = match.group(5);
        
        if (hour != null) {
          final weekday = _weekdays[weekdayName.toLowerCase()];
          if (weekday != null) {
            final parsedHour = _parseHour(hour, ampm);
            final parsedMinute = minute ?? 0;
            
            final startTime = _getNextWeekday(now, weekday, parsedHour, parsedMinute);
            
            return ParsedTime(
              start: startTime,
              duration: defaultDuration,
              source: match.group(0) ?? '',
            );
          }
        }
      }
    }
    
    return null;
  }

  /// Parses today time expressions (e.g., "today 6pm", "اليوم 18")
  static ParsedTime? _parseTodayTime(String text, DateTime now, Duration defaultDuration) {
    final patterns = [
      // English patterns
      RegExp(r'today\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?'),
      // Arabic patterns
      RegExp(r'اليوم\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final hour = int.tryParse(match.group(1) ?? '');
        final minute = int.tryParse(match.group(2) ?? '0');
        final ampm = match.group(3);
        
        if (hour != null) {
          final parsedHour = _parseHour(hour, ampm);
          final parsedMinute = minute ?? 0;
          
          final startTime = DateTime(
            now.year,
            now.month,
            now.day,
            parsedHour,
            parsedMinute,
          );
          
          // If time is in the past, move to next day
          if (startTime.isBefore(now)) {
            final nextDay = startTime.add(const Duration(days: 1));
            return ParsedTime(
              start: nextDay,
              duration: defaultDuration,
              source: match.group(0) ?? '',
            );
          }
          
          return ParsedTime(
            start: startTime,
            duration: defaultDuration,
            source: match.group(0) ?? '',
          );
        }
      }
    }
    
    return null;
  }

  /// Parses date lite expressions (e.g., "10/12 6pm", "12-10 18:00")
  static ParsedTime? _parseDateLite(String text, DateTime now, Duration defaultDuration) {
    final patterns = [
      RegExp(r'(\d{1,2})[/-](\d{1,2})\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final month = int.tryParse(match.group(1) ?? '');
        final day = int.tryParse(match.group(2) ?? '');
        final hour = int.tryParse(match.group(3) ?? '');
        final minute = int.tryParse(match.group(4) ?? '0');
        final ampm = match.group(5);
        
        if (month != null && day != null && hour != null) {
          final parsedHour = _parseHour(hour, ampm);
          final parsedMinute = minute ?? 0;
          
          // Assume current year
          final year = now.year;
          final startTime = DateTime(year, month, day, parsedHour, parsedMinute);
          
          // If date is in the past, move to next year
          if (startTime.isBefore(now)) {
            final nextYear = DateTime(year + 1, month, day, parsedHour, parsedMinute);
            return ParsedTime(
              start: nextYear,
              duration: defaultDuration,
              source: match.group(0) ?? '',
            );
          }
          
          return ParsedTime(
            start: startTime,
            duration: defaultDuration,
            source: match.group(0) ?? '',
          );
        }
      }
    }
    
    return null;
  }

  /// Parses hour with AM/PM handling
  static int _parseHour(int hour, String? ampm) {
    if (ampm == null) {
      // Heuristic: if hour <= 7, prefer PM
      if (hour <= 7) {
        return hour + 12;
      }
      return hour;
    }
    
    final lowerAmpm = ampm.toLowerCase();
    if (lowerAmpm == 'pm' && hour != 12) {
      return hour + 12;
    } else if (lowerAmpm == 'am' && hour == 12) {
      return 0;
    }
    
    return hour;
  }

  /// Gets the next occurrence of a weekday
  static DateTime _getNextWeekday(DateTime now, int targetWeekday, int hour, int minute) {
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If today is the target weekday and time hasn't passed, use today
    if (now.weekday == targetWeekday && target.isAfter(now)) {
      return target;
    }
    
    // Find next occurrence
    var daysUntilTarget = (targetWeekday - now.weekday) % 7;
    if (daysUntilTarget == 0) {
      daysUntilTarget = 7; // Next week
    }
    
    return target.add(Duration(days: daysUntilTarget));
  }

  /// Validates if the parsed time is within acceptable bounds
  static bool _isValidTime(DateTime time, DateTime now) {
    // Must be within next 14 days
    final maxTime = now.add(const Duration(days: 14));
    if (time.isAfter(maxTime)) {
      return false;
    }
    
    // Must be in the future (with small buffer for "now")
    final minTime = now.subtract(const Duration(minutes: 5));
    if (time.isBefore(minTime)) {
      return false;
    }
    
    // Optional: business hours check (8 AM - 8 PM)
    if (time.hour < 8 || time.hour > 20) {
      return false;
    }
    
    return true;
  }

  /// Formats a DateTime for display
  static String formatDateTime(DateTime dateTime) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[dateTime.weekday - 1];
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$weekday $month-$day $hour:$minute';
  }

  /// Gets timezone note for display
  static String getTimezoneNote(String? clientTz, String? coachTz) {
    if (clientTz == null || coachTz == null) return '';
    if (clientTz == coachTz) return '';
    
    return ' (Coach TZ: $coachTz, Client TZ: $clientTz)';
  }

  /// Checks if text contains time expressions
  static bool containsTimeExpression(String text) {
    final normalized = _normalizeText(text);
    
    // Check for common time indicators
    final timeIndicators = [
      'am', 'pm', ':', 'hour', 'minute', 'min', 'h', 'm',
      'ساعة', 'دقيقة', 'صباح', 'مساء', 'صباحاً', 'مساءً',
      'tmrw', 'tomorrow', 'today', 'غدا', 'غداً', 'اليوم',
      'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun',
      'الاثنين', 'الثلاثاء', 'الاربعاء', 'الخميس', 'الجمعة', 'السبت', 'الاحد',
    ];
    
    return timeIndicators.any((indicator) => normalized.contains(indicator));
  }

  /// Gets a human-readable description of the parsed time
  static String getTimeDescription(ParsedTime parsedTime) {
    final formatted = formatDateTime(parsedTime.start);
    final duration = parsedTime.duration.inMinutes;
    final durationText = duration == 15 ? '15m' : '${duration}m';
    
    return '$formatted ($durationText)';
  }
}
