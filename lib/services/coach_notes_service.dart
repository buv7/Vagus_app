import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class CoachNotesService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // Fetch notes for a specific client
  Future<List<Map<String, dynamic>>> fetchNotesForClient(String clientId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('coach_notes')
        .select()
        .eq('coach_id', user.id)
        .eq('client_id', clientId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Create a new note
  Future<void> createNote({
    required String clientId,
    String? title,
    required String body,
    List<String> tags = const [],
    Map<String, List<String>> linkedPlanIds = const {},
    DateTime? reminderAt,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase.from('coach_notes').insert({
      'coach_id': user.id,
      'client_id': clientId,
      'title': title,
      'body': body,
      'tags': tags,
      'linked_plan_ids': linkedPlanIds,
      'reminder_at': reminderAt?.toIso8601String(),
      'attachments': attachments,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Update an existing note
  Future<void> updateNote({
    required String noteId,
    String? title,
    String? body,
    List<String>? tags,
    Map<String, List<String>>? linkedPlanIds,
    DateTime? reminderAt,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (title != null) updateData['title'] = title;
    if (body != null) updateData['body'] = body;
    if (tags != null) updateData['tags'] = tags;
    if (linkedPlanIds != null) updateData['linked_plan_ids'] = linkedPlanIds;
    if (reminderAt != null) updateData['reminder_at'] = reminderAt.toIso8601String();
    if (attachments != null) updateData['attachments'] = attachments;

    await _supabase
        .from('coach_notes')
        .update(updateData)
        .eq('id', noteId)
        .eq('coach_id', user.id);
  }

  // Delete a note
  Future<void> deleteNote(String noteId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase
        .from('coach_notes')
        .delete()
        .eq('id', noteId)
        .eq('coach_id', user.id);
  }

  // Upload attachment to storage
  Future<Map<String, dynamic>> uploadAttachment({
    required File file,
    required String clientId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final fileExt = file.path.split('.').last;
    final fileName = '${_uuid.v4()}.$fileExt';
    final filePath = 'coach-notes/${user.id}/$clientId/$fileName';

    try {
      // Upload file to storage
      await _supabase.storage.from('vagus-media').upload(filePath, file);
      
      // Get file metadata
      final fileSize = await file.length();
      final mimeType = _getMimeType(fileExt);
      
      // Generate signed URL for access
      final signedUrl = await _supabase.storage
          .from('vagus-media')
          .createSignedUrl(filePath, 30 * 24 * 60 * 60); // 30 days in seconds

      return {
        'path': filePath,
        'mime': mimeType,
        'size': fileSize,
        'url': signedUrl,
        'name': file.path.split('/').last,
      };
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }

  // Delete attachment from storage
  Future<void> deleteAttachment(String filePath) async {
    try {
      await _supabase.storage.from('vagus-media').remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete attachment: $e');
    }
  }

  // Search notes
  Future<List<Map<String, dynamic>>> searchNotes({
    required String clientId,
    String? query,
    List<String>? tags,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final request = _supabase
        .from('coach_notes')
        .select()
        .eq('coach_id', user.id)
        .eq('client_id', clientId);

    // Note: Supabase doesn't support full-text search out of the box
    // This is a basic implementation - in production you might want to use
    // a search service like Algolia or implement full-text search in PostgreSQL
    
    final response = await request.order('created_at', ascending: false);
    final notes = List<Map<String, dynamic>>.from(response);

    // Client-side filtering
    return notes.where((note) {
      if (query != null && query.isNotEmpty) {
        final searchLower = query.toLowerCase();
        final title = (note['title'] ?? '').toString().toLowerCase();
        final body = (note['body'] ?? '').toString().toLowerCase();
        final noteTags = (note['tags'] as List<dynamic>? ?? [])
            .map((tag) => tag.toString().toLowerCase())
            .join(' ');
        
        if (!title.contains(searchLower) && 
            !body.contains(searchLower) && 
            !noteTags.contains(searchLower)) {
          return false;
        }
      }

      if (tags != null && tags.isNotEmpty) {
        final noteTags = (note['tags'] as List<dynamic>? ?? [])
            .map((tag) => tag.toString())
            .toList();
        
        if (!tags.any((tag) => noteTags.contains(tag))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Get MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'txt':
        return 'text/plain';
      case 'md':
        return 'text/markdown';
      case 'json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }
}
