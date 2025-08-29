import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Service for generating ICS calendar files and uploading them to storage
class IcsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Generate ICS content for a calendar event
  static String eventToIcs(Map<String, dynamic> event, {List<Map<String, dynamic>>? attendees}) {
    final now = DateTime.now().toUtc();
    final eventId = event['id'] ?? '';
    final title = event['title'] ?? 'Event';
    final description = event['description'] ?? '';
    final location = event['location'] ?? '';
    
    // Parse start and end times, ensure UTC
    final DateTime startAt = DateTime.parse(event['start_at']).toUtc();
    final DateTime endAt = DateTime.parse(event['end_at']).toUtc();
    
    // Format dates for ICS (YYYYMMDDTHHMMSSZ format)
    String formatIcsDateTime(DateTime dt) {
      return '${dt.year.toString().padLeft(4, '0')}'
             '${dt.month.toString().padLeft(2, '0')}'
             '${dt.day.toString().padLeft(2, '0')}'
             'T${dt.hour.toString().padLeft(2, '0')}'
             '${dt.minute.toString().padLeft(2, '0')}'
             '${dt.second.toString().padLeft(2, '0')}Z';
    }

    final icsContent = StringBuffer();
    
    // ICS Header
    icsContent.writeln('BEGIN:VCALENDAR');
    icsContent.writeln('VERSION:2.0');
    icsContent.writeln('PRODID:-//VAGUS//Calendar//EN');
    icsContent.writeln('CALSCALE:GREGORIAN');
    icsContent.writeln('METHOD:PUBLISH');
    
    // Event
    icsContent.writeln('BEGIN:VEVENT');
    icsContent.writeln('UID:$eventId@vagus.app');
    icsContent.writeln('DTSTART:${formatIcsDateTime(startAt)}');
    icsContent.writeln('DTEND:${formatIcsDateTime(endAt)}');
    icsContent.writeln('DTSTAMP:${formatIcsDateTime(now)}');
    icsContent.writeln('SUMMARY:${_escapeIcsText(title)}');
    
    if (description.isNotEmpty) {
      icsContent.writeln('DESCRIPTION:${_escapeIcsText(description)}');
    }
    
    if (location.isNotEmpty) {
      icsContent.writeln('LOCATION:${_escapeIcsText(location)}');
    }
    
    // Add recurrence rule if present
    final recurrenceRule = event['recurrence_rule'];
    if (recurrenceRule != null && recurrenceRule.toString().isNotEmpty) {
      icsContent.writeln('RRULE:$recurrenceRule');
    }
    
    // Add attendees
    if (attendees != null && attendees.isNotEmpty) {
      for (final attendee in attendees) {
        final email = attendee['email'] ?? '';
        final role = attendee['role'] ?? 'participant';
        final status = attendee['status'] ?? 'NEEDS-ACTION';
        
        if (email.isNotEmpty) {
          final String icsStatus = _mapStatusToIcs(status);
          final String icsRole = _mapRoleToIcs(role);
          icsContent.writeln('ATTENDEE;ROLE=$icsRole;PARTSTAT=$icsStatus;RSVP=TRUE:mailto:$email');
        }
      }
    }
    
    icsContent.writeln('END:VEVENT');
    icsContent.writeln('END:VCALENDAR');
    
    return icsContent.toString();
  }

  /// Upload ICS file to Supabase storage and return public URL
  static Future<String?> uploadEventIcs(
    String eventId, 
    Map<String, dynamic> event, 
    {List<Map<String, dynamic>>? attendees}
  ) async {
    try {
      final icsContent = eventToIcs(event, attendees: attendees);
      final fileName = 'events/$eventId/invite.ics';
      
      // Upload to storage
      await _supabase.storage
          .from('vagus-media')
          .uploadBinary(
            fileName,
            utf8.encode(icsContent),
            fileOptions: const FileOptions(
              contentType: 'text/calendar',
              cacheControl: '3600',
              upsert: true,
            ),
          );
      
      // Get public URL
      final publicUrl = _supabase.storage
          .from('vagus-media')
          .getPublicUrl(fileName);
      
      debugPrint('📅 ICS file uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading ICS file: $e');
      return null;
    }
  }

  /// Escape special characters for ICS format
  static String _escapeIcsText(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }

  /// Map internal status to ICS PARTSTAT
  static String _mapStatusToIcs(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'ACCEPTED';
      case 'declined':
        return 'DECLINED';
      case 'tentative':
        return 'TENTATIVE';
      case 'cancelled':
        return 'DECLINED';
      default:
        return 'NEEDS-ACTION';
    }
  }

  /// Map internal role to ICS ROLE
  static String _mapRoleToIcs(String role) {
    switch (role.toLowerCase()) {
      case 'coach':
        return 'CHAIR';
      case 'client':
        return 'REQ-PARTICIPANT';
      case 'guest':
        return 'OPT-PARTICIPANT';
      default:
        return 'REQ-PARTICIPANT';
    }
  }
}
