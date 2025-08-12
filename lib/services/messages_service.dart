import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class Message {
  final String id;
  final String threadId;
  final String senderId;
  final String text;
  final List<Map<String, dynamic>> attachments;
  final String? replyTo;
  final Map<String, String> reactions;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime? seenAt;

  Message({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.text,
    required this.attachments,
    this.replyTo,
    required this.reactions,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
    this.seenAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      threadId: map['thread_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      text: map['text'] ?? '',
      attachments: List<Map<String, dynamic>>.from(map['attachments'] ?? []),
      replyTo: map['reply_to'],
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      editedAt: map['edited_at'] != null ? DateTime.tryParse(map['edited_at']) : null,
      deletedAt: map['deleted_at'] != null ? DateTime.tryParse(map['deleted_at']) : null,
      seenAt: map['seen_at'] != null ? DateTime.tryParse(map['seen_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'thread_id': threadId,
      'sender_id': senderId,
      'text': text,
      'attachments': attachments,
      'reply_to': replyTo,
      'reactions': reactions,
      'created_at': createdAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'seen_at': seenAt?.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? threadId,
    String? senderId,
    String? text,
    List<Map<String, dynamic>>? attachments,
    String? replyTo,
    Map<String, String>? reactions,
    DateTime? createdAt,
    DateTime? editedAt,
    DateTime? deletedAt,
    DateTime? seenAt,
  }) {
    return Message(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      attachments: attachments ?? this.attachments,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      seenAt: seenAt ?? this.seenAt,
    );
  }
}

class MessagesService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // Ensure thread exists or create it
  Future<String> ensureThread({
    required String coachId,
    required String clientId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check if thread already exists
      final existingThread = await _supabase
          .from('message_threads')
          .select('id')
          .eq('coach_id', coachId)
          .eq('client_id', clientId)
          .maybeSingle();

      if (existingThread != null) {
        return existingThread['id'] as String;
      }

      // Create new thread
      final response = await _supabase.from('message_threads').insert({
        'coach_id': coachId,
        'client_id': clientId,
        'last_message_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to ensure thread: $e');
    }
  }

  // Subscribe to messages in real-time
  Stream<List<Message>> subscribeMessages(String threadId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', threadId)
        .order('created_at')
        .map((event) => event.map((map) => Message.fromMap(map)).toList());
  }

  // Send text message
  Future<void> sendText({
    required String threadId,
    required String text,
    String? replyTo,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase.from('messages').insert({
        'thread_id': threadId,
        'sender_id': user.id,
        'text': text,
        'attachments': [],
        'reply_to': replyTo,
        'reactions': {},
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update thread's last_message_at
      await _supabase
          .from('message_threads')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', threadId);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Upload attachment and send message
  Future<void> sendAttachment({
    required String threadId,
    required File file,
    String? replyTo,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Upload file to storage
      final attachment = await _uploadFile(file, threadId);

      // Send message with attachment
      await _supabase.from('messages').insert({
        'thread_id': threadId,
        'sender_id': user.id,
        'text': '',
        'attachments': [attachment],
        'reply_to': replyTo,
        'reactions': {},
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update thread's last_message_at
      await _supabase
          .from('message_threads')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', threadId);
    } catch (e) {
      throw Exception('Failed to send attachment: $e');
    }
  }

  // Send voice message
  Future<void> sendVoice({
    required String threadId,
    required File audioFile,
    String? replyTo,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Upload audio file to storage
      final attachment = await _uploadFile(audioFile, threadId);

      // Send message with audio attachment
      await _supabase.from('messages').insert({
        'thread_id': threadId,
        'sender_id': user.id,
        'text': '',
        'attachments': [attachment],
        'reply_to': replyTo,
        'reactions': {},
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update thread's last_message_at
      await _supabase
          .from('message_threads')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', threadId);
    } catch (e) {
      throw Exception('Failed to send voice message: $e');
    }
  }

  // Mark message as seen
  Future<void> markSeen({
    required String threadId,
    required String messageId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Only mark as seen if viewer is not the sender
      await _supabase
          .from('messages')
          .update({'seen_at': DateTime.now().toIso8601String()})
          .eq('id', messageId)
          .neq('sender_id', user.id);
    } catch (e) {
      throw Exception('Failed to mark message as seen: $e');
    }
  }

  // Set typing indicator
  Future<void> setTyping(String threadId, bool isTyping) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      if (isTyping) {
        // Upsert typing indicator
        await _supabase.from('message_typing').upsert({
          'thread_id': threadId,
          'user_id': user.id,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'thread_id,user_id');
      } else {
        // Remove typing indicator
        await _supabase
            .from('message_typing')
            .delete()
            .eq('thread_id', threadId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Ignore typing indicator errors to avoid blocking chat
      print('Typing indicator error: $e');
    }
  }

  // Subscribe to typing indicators
  Stream<List<Map<String, dynamic>>> subscribeTyping(String threadId) {
    return _supabase
        .from('message_typing')
        .stream(primaryKey: ['thread_id', 'user_id'])
        .eq('thread_id', threadId)
        .map((event) => List<Map<String, dynamic>>.from(event));
  }

  // Edit message
  Future<void> editMessage(String messageId, String newText) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('messages')
          .update({
            'text': newText,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('sender_id', user.id); // Only allow editing own messages
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  // Delete message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('messages')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', messageId)
          .eq('sender_id', user.id); // Only allow deleting own messages
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Add reaction to message
  Future<void> addReaction(String messageId, String emoji) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get current reactions
      final message = await _supabase
          .from('messages')
          .select('reactions')
          .eq('id', messageId)
          .single();

      final reactions = Map<String, String>.from(message['reactions'] ?? {});
      reactions[user.id] = emoji;

      await _supabase
          .from('messages')
          .update({'reactions': reactions})
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  // Remove reaction from message
  Future<void> removeReaction(String messageId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get current reactions
      final message = await _supabase
          .from('messages')
          .select('reactions')
          .eq('id', messageId)
          .single();

      final reactions = Map<String, String>.from(message['reactions'] ?? {});
      reactions.remove(user.id);

      await _supabase
          .from('messages')
          .update({'reactions': reactions})
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to remove reaction: $e');
    }
  }

  // Get thread info
  Future<Map<String, dynamic>?> getThreadInfo(String threadId) async {
    try {
      final thread = await _supabase
          .from('message_threads')
          .select('*, coach:coach_id(id, name, avatar_url), client:client_id(id, name, avatar_url)')
          .eq('id', threadId)
          .single();

      return thread;
    } catch (e) {
      return null;
    }
  }

  // Upload file to storage
  Future<Map<String, dynamic>> _uploadFile(File file, String threadId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final fileExt = file.path.split('.').last;
    final fileName = '${_uuid.v4()}.$fileExt';
    final filePath = 'messages/$threadId/$fileName';

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
      throw Exception('Failed to upload file: $e');
    }
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
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
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

  // ===== PHASE 1 ENHANCEMENTS =====

  // Get unread counts for all threads (RPC call)
  Future<Map<String, int>> getUnreadCounts(String userId) async {
    try {
      final response = await _supabase.rpc('get_unread_counts', params: {'uid': userId});
      if (response is Map<String, dynamic>) {
        return response.map((key, value) => MapEntry(key, value as int));
      }
      return {};
    } catch (e) {
      // Fallback: manual count
      return await _getUnreadCountsFallback(userId);
    }
  }

  // Fallback method for unread counts
  Future<Map<String, int>> _getUnreadCountsFallback(String userId) async {
    try {
      // Get all threads for this user
      final threads = await _supabase
          .from('message_threads')
          .select('id')
          .or('coach_id.eq.$userId,client_id.eq.$userId');

      final counts = <String, int>{};
      
      for (final thread in threads) {
        final threadId = thread['id'] as String;
        final rows = await _supabase
            .from('messages')
            .select('id')
            .eq('thread_id', threadId)
            .neq('sender_id', userId)
            .isFilter('seen_at', null)
            .isFilter('deleted_at', null);
        
        counts[threadId] = rows.length;
      }
      
      return counts;
    } catch (e) {
      return {};
    }
  }

  // Forward message to another thread
  Future<void> forwardMessage({
    required String messageId,
    required String targetThreadId,
    String? additionalText,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get original message
      final originalMessage = await _supabase
          .from('messages')
          .select('*')
          .eq('id', messageId)
          .single();

      // Create forwarded message
      final forwardedText = additionalText != null && additionalText.isNotEmpty
          ? '${additionalText}\n\n--- Forwarded message ---\n${originalMessage['text']}'
          : '--- Forwarded message ---\n${originalMessage['text']}';

      await _supabase.from('messages').insert({
        'thread_id': targetThreadId,
        'sender_id': user.id,
        'text': forwardedText,
        'attachments': originalMessage['attachments'] ?? [],
        'reply_to': null,
        'reactions': {},
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update thread's last_message_at
      await _supabase
          .from('message_threads')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', targetThreadId);
    } catch (e) {
      throw Exception('Failed to forward message: $e');
    }
  }

  // Copy message text to clipboard (client-side)
  String getMessageTextForCopy(String messageId, List<Message> messages) {
    final message = messages.firstWhere((m) => m.id == messageId);
    return message.text;
  }

  // Pin/Unpin thread
  Future<void> toggleThreadPin(String threadId, bool isPinned) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('message_threads')
          .update({'is_pinned': isPinned})
          .eq('id', threadId)
          .or('coach_id.eq.${user.id},client_id.eq.${user.id}');
    } catch (e) {
      throw Exception('Failed to toggle thread pin: $e');
    }
  }

  // Mute thread
  Future<void> muteThread(String threadId, {DateTime? until}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('message_threads')
          .update({
            'muted_until': until?.toIso8601String(),
            'is_muted': until != null,
          })
          .eq('id', threadId)
          .or('coach_id.eq.${user.id},client_id.eq.${user.id}');
    } catch (e) {
      throw Exception('Failed to mute thread: $e');
    }
  }

  // Archive thread
  Future<void> archiveThread(String threadId, bool isArchived) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('message_threads')
          .update({'is_archived': isArchived})
          .eq('id', threadId)
          .or('coach_id.eq.${user.id},client_id.eq.${user.id}');
    } catch (e) {
      throw Exception('Failed to archive thread: $e');
    }
  }

  // Star/Unstar message
  Future<void> toggleMessageStar(String messageId, bool isStarred) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      if (isStarred) {
        await _supabase.from('starred_messages').upsert({
          'message_id': messageId,
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        }, onConflict: 'message_id,user_id');
      } else {
        await _supabase
            .from('starred_messages')
            .delete()
            .eq('message_id', messageId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      throw Exception('Failed to toggle message star: $e');
    }
  }

  // Get starred messages for a thread
  Stream<List<Message>> getStarredMessages(String threadId) {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('starred_messages')
        .stream(primaryKey: ['message_id', 'user_id'])
        .eq('user_id', user.id)
        .map((event) => event.map((map) => Message.fromMap(map)).toList());
  }

  // Search messages in thread
  Future<List<Message>> searchMessagesInThread({
    required String threadId,
    required String query,
    String? attachmentType, // 'image', 'video', 'audio', 'document'
  }) async {
    try {
      var queryBuilder = _supabase
          .from('messages')
          .select('*')
          .eq('thread_id', threadId)
          .isFilter('deleted_at', null)
          .ilike('text', '%$query%')
          .order('created_at', ascending: false);

      final messages = await queryBuilder;
      
      List<Map<String, dynamic>> filteredMessages = messages;
      
      // Filter by attachment type if specified
      if (attachmentType != null) {
        filteredMessages = messages.where((message) {
          final attachments = message['attachments'] as List<dynamic>? ?? [];
          return attachments.any((attachment) {
            final mime = attachment['mime']?.toString() ?? '';
            switch (attachmentType) {
              case 'image':
                return mime.startsWith('image/');
              case 'video':
                return mime.startsWith('video/');
              case 'audio':
                return mime.startsWith('audio/');
              case 'document':
                return mime == 'application/pdf' || mime.startsWith('text/');
              default:
                return true;
            }
          });
        }).toList();
      }

      return filteredMessages.map((map) => Message.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  // Save draft for a thread
  Future<void> saveDraft(String threadId, String draftText) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase.from('message_drafts').upsert({
        'thread_id': threadId,
        'user_id': user.id,
        'draft_text': draftText,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'thread_id,user_id');
    } catch (e) {
      // Ignore draft save errors to avoid blocking chat
      print('Draft save error: $e');
    }
  }

  // Get draft for a thread
  Future<String?> getDraft(String threadId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('message_drafts')
          .select('draft_text')
          .eq('thread_id', threadId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response?['draft_text'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Clear draft for a thread
  Future<void> clearDraft(String threadId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('message_drafts')
          .delete()
          .eq('thread_id', threadId)
          .eq('user_id', user.id);
    } catch (e) {
      // Ignore draft clear errors
      print('Draft clear error: $e');
    }
  }
}
