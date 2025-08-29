import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IcsImportService {
  static final _supabase = Supabase.instance.client;

  /// Parse a single event from ICS content
  static Map<String, dynamic>? parseSingleEvent(String icsContent) {
    try {
      final lines = icsContent.split('\n');
      final eventData = <String, dynamic>{};
      bool inEvent = false;
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        
        if (trimmedLine == 'BEGIN:VEVENT') {
          inEvent = true;
          continue;
        }
        
        if (trimmedLine == 'END:VEVENT') {
          inEvent = false;
          break;
        }
        
        if (!inEvent) continue;
        
        final colonIndex = trimmedLine.indexOf(':');
        if (colonIndex == -1) continue;
        
        final key = trimmedLine.substring(0, colonIndex);
        final value = trimmedLine.substring(colonIndex + 1);
        
        switch (key) {
          case 'UID':
            eventData['uid'] = value;
            break;
          case 'DTSTART':
            eventData['start_at'] = _parseIcsDateTime(value);
            break;
          case 'DTEND':
            eventData['end_at'] = _parseIcsDateTime(value);
            break;
          case 'SUMMARY':
            eventData['title'] = _unescapeIcsText(value);
            break;
          case 'DESCRIPTION':
            eventData['description'] = _unescapeIcsText(value);
            break;
          case 'LOCATION':
            eventData['location'] = _unescapeIcsText(value);
            break;
          case 'RRULE':
            eventData['recurrence_rule'] = value;
            break;
        }
      }
      
      return eventData.isNotEmpty ? eventData : null;
    } catch (e) {
      debugPrint('Error parsing single ICS event: $e');
      return null;
    }
  }

  /// Parse multiple events from ICS content
  static List<Map<String, dynamic>> parseEvents(String icsContent) {
    try {
      final events = <Map<String, dynamic>>[];
      final lines = icsContent.split('\n');
      bool inEvent = false;
      final currentEvent = <String, dynamic>{};
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        
        if (trimmedLine == 'BEGIN:VEVENT') {
          inEvent = true;
          currentEvent.clear();
          continue;
        }
        
        if (trimmedLine == 'END:VEVENT') {
          inEvent = false;
          if (currentEvent.isNotEmpty) {
            events.add(Map<String, dynamic>.from(currentEvent));
          }
          continue;
        }
        
        if (!inEvent) continue;
        
        final colonIndex = trimmedLine.indexOf(':');
        if (colonIndex == -1) continue;
        
        final key = trimmedLine.substring(0, colonIndex);
        final value = trimmedLine.substring(colonIndex + 1);
        
        switch (key) {
          case 'UID':
            currentEvent['uid'] = value;
            break;
          case 'DTSTART':
            currentEvent['start_at'] = _parseIcsDateTime(value);
            break;
          case 'DTEND':
            currentEvent['end_at'] = _parseIcsDateTime(value);
            break;
          case 'SUMMARY':
            currentEvent['title'] = _unescapeIcsText(value);
            break;
          case 'DESCRIPTION':
            currentEvent['description'] = _unescapeIcsText(value);
            break;
          case 'LOCATION':
            currentEvent['location'] = _unescapeIcsText(value);
            break;
          case 'RRULE':
            currentEvent['recurrence_rule'] = value;
            break;
        }
      }
      
      return events;
    } catch (e) {
      debugPrint('Error parsing ICS events: $e');
      return [];
    }
  }

  /// Convert parsed ICS event to CalendarEvent payload
  static Map<String, dynamic> toCalendarEventPayload(Map<String, dynamic> icsEvent) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    return {
      'title': icsEvent['title'] ?? 'Imported Event',
      'description': icsEvent['description'],
      'location': icsEvent['location'],
      'start_at': icsEvent['start_at']?.toIso8601String(),
      'end_at': icsEvent['end_at']?.toIso8601String(),
      'recurrence_rule': icsEvent['recurrence_rule'],
      'created_by': userId,
      'metadata': {
        'imported_from_ics': true,
        'original_uid': icsEvent['uid'],
      },
    };
  }

  /// Parse ICS datetime string to DateTime
  static DateTime? _parseIcsDateTime(String icsDateTime) {
    try {
      // Handle different ICS datetime formats
      if (icsDateTime.contains('T')) {
        // Format: 20231201T120000Z or 20231201T120000
        final cleanDateTime = icsDateTime.replaceAll('Z', '');
        return DateTime.parse(cleanDateTime);
      } else {
        // Format: 20231201 (date only)
        return DateTime.parse(icsDateTime);
      }
    } catch (e) {
      debugPrint('Error parsing ICS datetime: $icsDateTime - $e');
      return null;
    }
  }

  /// Unescape ICS text (basic implementation)
  static String _unescapeIcsText(String text) {
    return text
        .replaceAll('\\n', '\n')
        .replaceAll('\\t', '\t')
        .replaceAll('\\,', ',')
        .replaceAll('\\;', ';')
        .replaceAll('\\\\', '\\');
  }
}
