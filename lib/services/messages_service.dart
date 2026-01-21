import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class Message {
  final String id;
  final String threadId;
  final String senderId;
  final String text;
  final List<Map<String, dynamic>> attachments;
  final String? replyTo;
  final String? parentMessageId;
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
    this.parentMessageId,
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
      parentMessageId: map['parent_message_id'],
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
      'parent_message_id': parentMessageId,
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
    String? parentMessageId,
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
      parentMessageId: parentMessageId ?? this.parentMessageId,
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
  
  // Schema detection cache
  static bool? _supportsThreadId;
  static bool _schemaChecked = false;
  
  /// Reset schema cache (call after database schema changes)
  static void resetSchemaCache() {
    _schemaChecked = false;
    _supportsThreadId = null;
    debugPrint('MessagesService: Schema cache reset');
  }
  
  /// Check if the messages table supports thread_id column
  Future<bool> _checkThreadIdSupport() async {
    if (_schemaChecked) return _supportsThreadId ?? false;
    
    try {
      // Try a simple query with thread_id - if it fails, schema doesn't support it
      await _supabase
          .from('messages')
          .select('id')
          .eq('thread_id', 'test_check')
          .limit(1);
      _supportsThreadId = true;
      debugPrint('MessagesService: thread_id column supported, using realtime subscriptions');
    } catch (e) {
      debugPrint('MessagesService: thread_id column not supported, using legacy schema');
      _supportsThreadId = false;
    }
    _schemaChecked = true;
    return _supportsThreadId ?? false;
  }

  // Ensure thread exists or create it
  // NOTE: Falls back to using conversations table if message_threads doesn't exist
  Future<String> ensureThread({
    required String coachId,
    required String clientId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Try message_threads table first (new schema)
      try {
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
      } catch (threadError) {
        // Fallback: Try conversations table (legacy schema)
        debugPrint('MessagesService: message_threads not available, trying conversations table');
        
        final existingConversation = await _supabase
            .from('conversations')
            .select('id')
            .eq('coach_id', coachId)
            .eq('client_id', clientId)
            .maybeSingle();

        if (existingConversation != null) {
          return existingConversation['id'] as String;
        }

        // Create new conversation
        final response = await _supabase.from('conversations').insert({
          'coach_id': coachId,
          'client_id': clientId,
          'last_message_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        }).select('id').single();

        return response['id'] as String;
      }
    } catch (e) {
      debugPrint('MessagesService: Failed to ensure thread: $e');
      // Return a generated thread ID to prevent crashes, messages will just not persist
      return 'local_${coachId}_$clientId';
    }
  }

  // Subscribe to messages in real-time
  // NOTE: Supports both thread_id (new schema) and conversation-based (legacy) queries
  Stream<List<Message>> subscribeMessages(String threadId) {
    // If it's a local thread (fallback), return empty stream
    if (threadId.startsWith('local_')) {
      debugPrint('MessagesService: Using local thread, returning empty stream');
      return Stream.value([]);
    }
    
    // Use async* generator to handle schema detection
    return _subscribeMessagesAsync(threadId);
  }
  
  Stream<List<Message>> _subscribeMessagesAsync(String threadId) async* {
    // Check if schema supports thread_id
    final supportsThreadId = await _checkThreadIdSupport();
    
    if (supportsThreadId) {
      // Use realtime subscription with thread_id
      yield* _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('thread_id', threadId)
          .order('created_at')
          .map((event) => event.map((map) => Message.fromMap(map)).toList());
    } else {
      // Legacy schema: Use polling with sender_id/recipient_id
      debugPrint('MessagesService: Using legacy schema polling for messages');
      
      // Get conversation details to find coach/client IDs
      final conv = await _supabase
          .from('conversations')
          .select('coach_id, client_id')
          .eq('id', threadId)
          .maybeSingle();
      
      if (conv == null) {
        yield [];
        return;
      }
      
      final coachId = conv['coach_id'] as String;
      final clientId = conv['client_id'] as String;
      
      // Poll for messages every 3 seconds
      while (true) {
        try {
          final response = await _supabase
              .from('messages')
              .select('*')
              .or('and(sender_id.eq.$coachId,recipient_id.eq.$clientId),and(sender_id.eq.$clientId,recipient_id.eq.$coachId)')
              .order('created_at');
          
          // Convert to Message objects with legacy field mapping
          final messages = (response as List<dynamic>).map((row) {
            return Message(
              id: row['id'] ?? '',
              threadId: threadId, // Use conversation ID as thread ID
              senderId: row['sender_id'] ?? '',
              text: row['content'] ?? row['text'] ?? '',
              attachments: [],
              reactions: {},
              createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
            );
          }).toList();
          
          yield messages;
        } catch (e) {
          debugPrint('MessagesService: Polling error: $e');
          yield [];
        }
        
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }

  // Send text message
  // NOTE: Falls back to sender_id/recipient_id schema if thread_id doesn't exist
  Future<void> sendText({
    required String threadId,
    required String text,
    String? replyTo,
    String? recipientId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Skip if using local thread (no database connection)
    if (threadId.startsWith('local_')) {
      debugPrint('MessagesService: Local thread, message not persisted');
      return;
    }

    try {
      // Try new schema with thread_id first
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
      } catch (threadError) {
        // Fallback: Try legacy schema with sender_id/recipient_id
        debugPrint('MessagesService: thread_id schema failed, trying legacy schema');
        
        // Get recipient from conversation
        String? recipient = recipientId;
        if (recipient == null) {
          final conv = await _supabase
              .from('conversations')
              .select('coach_id, client_id')
              .eq('id', threadId)
              .maybeSingle();
          
          if (conv != null) {
            recipient = conv['coach_id'] == user.id 
                ? conv['client_id'] as String
                : conv['coach_id'] as String;
          }
        }
        
        if (recipient != null) {
          await _supabase.from('messages').insert({
            'sender_id': user.id,
            'recipient_id': recipient,
            'content': text,
            'message_type': 'text',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          });

          // Update conversation's last_message_at
          await _supabase
              .from('conversations')
              .update({'last_message_at': DateTime.now().toIso8601String()})
              .eq('id', threadId);
        } else {
          throw Exception('Could not determine message recipient');
        }
      }
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

    // Skip if using local thread (no database connection)
    if (threadId.startsWith('local_')) {
      debugPrint('MessagesService: Local thread, attachment not persisted');
      return;
    }

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
      debugPrint('MessagesService: Failed to send attachment: $e');
      // Don't throw - allow graceful degradation
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

    // Skip if using local thread (no database connection)
    if (threadId.startsWith('local_')) {
      debugPrint('MessagesService: Local thread, voice message not persisted');
      return;
    }

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
      debugPrint('MessagesService: Failed to send voice message: $e');
      // Don't throw - allow graceful degradation
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
    if (user == null) return; // Silently fail for typing indicators

    // Skip if using local thread (no database connection)
    if (threadId.startsWith('local_')) return;

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
      debugPrint('Typing indicator error: $e');
    }
  }

  // Subscribe to typing indicators
  Stream<List<Map<String, dynamic>>> subscribeTyping(String threadId) {
    // Skip if using local thread (no database connection)
    if (threadId.startsWith('local_')) {
      return Stream.value([]);
    }

    // Return empty stream for legacy schema (typing indicators not supported)
    return _subscribeTypingAsync(threadId);
  }
  
  Stream<List<Map<String, dynamic>>> _subscribeTypingAsync(String threadId) async* {
    final supportsThreadId = await _checkThreadIdSupport();
    
    if (!supportsThreadId) {
      // Legacy schema doesn't support typing indicators
      yield [];
      return;
    }
    
    try {
      yield* _supabase
          .from('message_typing')
          .stream(primaryKey: ['thread_id', 'user_id'])
          .eq('thread_id', threadId)
          .map((event) => List<Map<String, dynamic>>.from(event));
    } catch (e) {
      debugPrint('MessagesService: Failed to subscribe to typing: $e');
      yield [];
    }
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
          ? '$additionalText\n\n--- Forwarded message ---\n${originalMessage['text']}'
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
      final queryBuilder = _supabase
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
      debugPrint('Draft save error: $e');
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
      debugPrint('Draft clear error: $e');
    }
  }

  // ===== MESSAGING POLISH FEATURES =====

  // Read receipts
  Future<void> markConversationRead({required String threadId, required DateTime upTo}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get unread messages up to the specified time
      final unreadMessages = await _supabase
          .from('messages')
          .select('id')
          .eq('thread_id', threadId)
          .neq('sender_id', user.id)
          .lte('created_at', upTo.toIso8601String())
          .isFilter('deleted_at', null);

      // Mark each message as read
      for (final message in unreadMessages) {
        await _supabase.from('message_reads').upsert({
          'message_id': message['id'],
          'reader_id': user.id,
          'read_at': DateTime.now().toIso8601String(),
        }, onConflict: 'message_id,reader_id');
      }
    } catch (e) {
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  Future<void> markMessageRead(String messageId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase.from('message_reads').upsert({
        'message_id': messageId,
        'reader_id': user.id,
        'read_at': DateTime.now().toIso8601String(),
      }, onConflict: 'message_id,reader_id');
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> onReadReceipts(String threadId) {
    // If it's a local thread (fallback), return empty stream
    if (threadId.startsWith('local_')) {
      return Stream.value([]);
    }
    
    return _onReadReceiptsAsync(threadId);
  }
  
  Stream<List<Map<String, dynamic>>> _onReadReceiptsAsync(String threadId) async* {
    final supportsThreadId = await _checkThreadIdSupport();
    
    if (!supportsThreadId) {
      // Legacy schema doesn't support read receipts stream
      yield [];
      return;
    }
    
    try {
      yield* _supabase
          .from('message_reads')
          .stream(primaryKey: ['id'])
          .eq('thread_id', threadId)
          .map((event) => List<Map<String, dynamic>>.from(event));
    } catch (e) {
      debugPrint('MessagesService: Failed to subscribe to read receipts: $e');
      yield [];
    }
  }

  Future<DateTime?> lastReadAtByOther(String threadId, String otherUserId) async {
    try {
      final response = await _supabase
          .from('message_reads')
          .select('read_at')
          .eq('reader_id', otherUserId)
          .order('read_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? DateTime.tryParse(response['read_at']) : null;
    } catch (e) {
      return null;
    }
  }

  // Pins
  Future<void> pinMessage(String messageId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase.from('message_pins').upsert({
        'message_id': messageId,
        'user_id': user.id,
        'pinned_at': DateTime.now().toIso8601String(),
      }, onConflict: 'message_id,user_id');
    } catch (e) {
      throw Exception('Failed to pin message: $e');
    }
  }

  Future<void> unpinMessage(String messageId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('message_pins')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to unpin message: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPinned(String threadId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('message_pins')
          .select('*, message:messages(*)')
          .eq('user_id', user.id)
          .eq('message.thread_id', threadId)
          .order('pinned_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Threads
  Future<String> sendReply({
    required String threadId,
    required String parentMessageId,
    required String content,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase.from('messages').insert({
        'thread_id': threadId,
        'sender_id': user.id,
        'text': content,
        'attachments': attachments ?? [],
        'parent_message_id': parentMessageId,
        'reactions': {},
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      // Update thread's last_message_at
      await _supabase
          .from('message_threads')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', threadId);

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to send reply: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchThread(String parentMessageId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('parent_message_id', parentMessageId)
          .order('created_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> onThreadUpdates(String parentMessageId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('parent_message_id', parentMessageId)
        .order('created_at')
        .map((event) => List<Map<String, dynamic>>.from(event));
  }

  // Search
  Future<List<Map<String, dynamic>>> searchLocal(String threadId, String query) async {
    try {
      final messages = await _supabase
          .from('messages')
          .select('*')
          .eq('thread_id', threadId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(100);

      final filteredMessages = messages.where((message) {
        final text = message['text']?.toString().toLowerCase() ?? '';
        final senderName = message['sender_name']?.toString().toLowerCase() ?? '';
        final attachments = message['attachments'] as List<dynamic>? ?? [];
        
        // Check text content
        if (text.contains(query.toLowerCase())) return true;
        
        // Check sender name
        if (senderName.contains(query.toLowerCase())) return true;
        
        // Check attachment filenames
        for (final attachment in attachments) {
          final fileName = attachment['name']?.toString().toLowerCase() ?? '';
          if (fileName.contains(query.toLowerCase())) return true;
        }
        
        return false;
      }).toList();

      return List<Map<String, dynamic>>.from(filteredMessages);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchServer(String threadId, String query) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('thread_id', threadId)
          .isFilter('deleted_at', null)
          .ilike('text', '%$query%')
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback to local search if server search fails
      return await searchLocal(threadId, query);
    }
  }
}
