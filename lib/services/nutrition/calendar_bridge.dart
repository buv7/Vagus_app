import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'text_normalizer.dart';

/// Internal model for prep alarms
class _PrepAlarm {
  final String title;
  final int minutesBefore;
  
  const _PrepAlarm({
    required this.title,
    required this.minutesBefore,
  });
}

/// Calendar bridge for generating ICS files with meal events and prep reminders
class NutritionCalendarBridge {
  
  /// Build ICS content for a day's meals with optional prep reminders
  static String buildIcsForDay({
    required DateTime dateLocal,
    required String title,
    required List<String> lines,
    List<_PrepAlarm> alarms = const [],
  }) {
    final buffer = StringBuffer();
    
    // VCALENDAR header
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//VAGUS Nutrition//Meal Calendar//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    
    // Main meal event
    _writeMealEvent(buffer, dateLocal, title, lines);
    
    // Prep alarm events
    for (final alarm in alarms) {
      _writePrepAlarmEvent(buffer, dateLocal, alarm);
    }
    
    // VCALENDAR footer
    buffer.writeln('END:VCALENDAR');
    
    return buffer.toString();
  }
  
  /// Write the main meal event
  static void _writeMealEvent(StringBuffer buffer, DateTime date, String title, List<String> lines) {
    final dateStr = _formatDate(date);
    final timestamp = _formatTimestamp(DateTime.now());
    
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('UID:${_generateUid()}-meal');
    buffer.writeln('DTSTAMP:$timestamp');
    buffer.writeln('DTSTART;VALUE=DATE:$dateStr');
    buffer.writeln('DTEND;VALUE=DATE:$dateStr');
    buffer.writeln('SUMMARY:$title');
    buffer.writeln('DESCRIPTION:${_escapeText(lines.join('\\n'))}');
    buffer.writeln('STATUS:CONFIRMED');
    buffer.writeln('TRANSP:TRANSPARENT');
    buffer.writeln('END:VEVENT');
  }
  
  /// Write a prep alarm event
  static void _writePrepAlarmEvent(StringBuffer buffer, DateTime date, _PrepAlarm alarm) {
    final dateStr = _formatDate(date);
    final timestamp = _formatTimestamp(DateTime.now());
    
    // Calculate alarm time (before the meal)
    final alarmTime = date.subtract(Duration(minutes: alarm.minutesBefore));
    final alarmDateTime = _formatDateTime(alarmTime);
    
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('UID:${_generateUid()}-prep-${alarm.minutesBefore}');
    buffer.writeln('DTSTAMP:$timestamp');
    buffer.writeln('DTSTART:$alarmDateTime');
    buffer.writeln('DTEND:$alarmDateTime');
    buffer.writeln('SUMMARY:${alarm.title}');
    buffer.writeln('DESCRIPTION:Prep ${alarm.minutesBefore} minutes before meal');
    buffer.writeln('STATUS:CONFIRMED');
    buffer.writeln('TRANSP:OPAQUE');
    
    // Add VALARM for notification
    buffer.writeln('BEGIN:VALARM');
    buffer.writeln('ACTION:DISPLAY');
    buffer.writeln('TRIGGER:-PT${alarm.minutesBefore}M');
    buffer.writeln('DESCRIPTION:Prep ${alarm.title} ${alarm.minutesBefore} minutes before');
    buffer.writeln('END:VALARM');
    
    buffer.writeln('END:VEVENT');
  }
  
  /// Save ICS content to file and return path
  static Future<String> saveIcs(String icsContent, String filename) async {
    try {
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      
      // Write ICS content
      await file.writeAsString(icsContent, encoding: utf8);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to save ICS file: $e');
    }
  }
  
  /// Share ICS file using system share sheet
  static Future<void> shareIcsFile(String filePath, {String? subject}) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'Meal Calendar',
        text: 'Meal calendar exported from VAGUS Nutrition',
      );
    } catch (e) {
      throw Exception('Failed to share ICS file: $e');
    }
  }
  
  /// Generate meal lines from meal data
  static List<String> generateMealLines({
    required Map<String, List<Map<String, dynamic>>> meals,
    required String language,
  }) {
    final lines = <String>[];
    
    // Define meal order and localized names
    final mealOrder = ['breakfast', 'lunch', 'dinner', 'snack'];
    final mealNames = _getMealNames(language);
    
    for (final mealType in mealOrder) {
      final mealItems = meals[mealType];
      if (mealItems != null && mealItems.isNotEmpty) {
        final mealName = mealNames[mealType] ?? mealType;
        final items = mealItems.map((item) => item['name'] ?? 'Unknown').join(', ');
        lines.add('$mealName: $items');
      }
    }
    
    return lines;
  }
  
  /// Generate prep alarms from recipe data
  static List<_PrepAlarm> generatePrepAlarms({
    required Map<String, List<Map<String, dynamic>>> meals,
    required String language,
  }) {
    final alarms = <_PrepAlarm>[];
    final mealNames = _getMealNames(language);
    
    for (final mealType in meals.keys) {
      final mealItems = meals[mealType] ?? [];
      final mealName = mealNames[mealType] ?? mealType;
      
      for (final item in mealItems) {
        final prepMinutes = item['prep_minutes'] as int? ?? 0;
        if (prepMinutes > 0) {
          final recipeName = item['name'] ?? 'Unknown Recipe';
          alarms.add(_PrepAlarm(
            title: 'Prep $recipeName for $mealName',
            minutesBefore: prepMinutes,
          ));
        }
      }
    }
    
    return alarms;
  }
  
  /// Get localized meal names
  static Map<String, String> _getMealNames(String language) {
    switch (language) {
      case 'ar':
        return {
          'breakfast': 'فطور',
          'lunch': 'غداء',
          'dinner': 'عشاء',
          'snack': 'وجبة خفيفة',
        };
      case 'ku':
        return {
          'breakfast': 'بەیانی',
          'lunch': 'نیوەڕۆ',
          'dinner': 'ئێوارە',
          'snack': 'لەقە',
        };
      default:
        return {
          'breakfast': 'Breakfast',
          'lunch': 'Lunch',
          'dinner': 'Dinner',
          'snack': 'Snack',
        };
    }
  }
  
  /// Format date for ICS (YYYYMMDD)
  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}'
           '${date.month.toString().padLeft(2, '0')}'
           '${date.day.toString().padLeft(2, '0')}';
  }
  
  /// Format date-time for ICS (YYYYMMDDTHHMMSSZ)
  static String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)}T'
           '${dateTime.hour.toString().padLeft(2, '0')}'
           '${dateTime.minute.toString().padLeft(2, '0')}'
           '${dateTime.second.toString().padLeft(2, '0')}Z';
  }
  
  /// Format timestamp for ICS
  static String _formatTimestamp(DateTime dateTime) {
    return _formatDateTime(dateTime);
  }
  
  /// Generate unique ID for ICS events
  static String _generateUid() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'vagus-nutrition-$timestamp-$random';
  }
  
  /// Escape text for ICS format
  static String _escapeText(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '');
  }
  
  /// Build complete ICS for a nutrition plan day
  static Future<String> buildAndSaveDayIcs({
    required DateTime date,
    required Map<String, List<Map<String, dynamic>>> meals,
    required String language,
    required String dayTitle,
    bool includePrepReminders = true,
  }) async {
    // Generate meal lines
    final lines = generateMealLines(meals: meals, language: language);
    
    // Generate prep alarms if requested
    final alarms = includePrepReminders 
        ? generatePrepAlarms(meals: meals, language: language)
        : <_PrepAlarm>[];
    
    // Build ICS content
    final icsContent = buildIcsForDay(
      dateLocal: date,
      title: dayTitle,
      lines: lines,
      alarms: alarms,
    );
    
    // Generate filename
    final dateStr = _formatDate(date);
    final filename = 'vagus_meals_$dateStr.ics';
    
    // Save and return path
    return await saveIcs(icsContent, filename);
  }
  
  /// Export day to calendar with share
  static Future<void> exportDayToCalendar({
    required DateTime date,
    required Map<String, List<Map<String, dynamic>>> meals,
    required String language,
    required String dayTitle,
    bool includePrepReminders = true,
  }) async {
    try {
      // Build and save ICS
      final filePath = await buildAndSaveDayIcs(
        date: date,
        meals: meals,
        language: language,
        dayTitle: dayTitle,
        includePrepReminders: includePrepReminders,
      );
      
      // Share the file
      await shareIcsFile(filePath, subject: dayTitle);
      
    } catch (e) {
      throw Exception('Failed to export day to calendar: $e');
    }
  }
}
