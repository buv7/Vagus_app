import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _sb = Supabase.instance.client;

/// Represents a conversation in the messaging system
class Conversation {
  final String id;
  final String coachId;
  final String clientId;
  final String clientName;
  final String? clientAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isOnline;

  Conversation({
    required this.id,
    required this.coachId,
    required this.clientId,
    required this.clientName,
    this.clientAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    required this.isOnline,
  });

  factory Conversation.fromMap(Map<String, dynamic> data) {
    return Conversation(
      id: data['id'] as String,
      coachId: data['coach_id'] as String,
      clientId: data['client_id'] as String,
      clientName: data['client_name'] as String? ?? 'Unknown Client',
      clientAvatarUrl: data['client_avatar_url'] as String?,
      lastMessage: data['last_message'] as String?,
      lastMessageAt: data['last_message_at'] != null 
          ? DateTime.tryParse(data['last_message_at'].toString()) 
          : null,
      unreadCount: (data['unread_count'] as num?)?.toInt() ?? 0,
      isOnline: (data['is_online'] as bool?) ?? false,
    );
  }
}

/// Represents a message in the conversation
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String messageType;
  final bool isRead;
  final DateTime createdAt;
  final String? attachmentUrl;
  final String? attachmentName;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
    this.attachmentUrl,
    this.attachmentName,
  });

  factory Message.fromMap(Map<String, dynamic> data) {
    return Message(
      id: data['id'] as String,
      conversationId: data['conversation_id'] as String,
      senderId: data['sender_id'] as String,
      content: data['content'] as String,
      messageType: data['message_type'] as String? ?? 'text',
      isRead: (data['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(data['created_at'] as String),
      attachmentUrl: data['attachment_url'] as String?,
      attachmentName: data['attachment_name'] as String?,
    );
  }
}

/// Represents a smart reply suggestion
class SmartReply {
  final String id;
  final String text;
  final String category;
  final double confidence;

  SmartReply({
    required this.id,
    required this.text,
    required this.category,
    required this.confidence,
  });
}

/// Service for managing coach messaging
class CoachMessagingService {
  static final CoachMessagingService _instance = CoachMessagingService._internal();
  factory CoachMessagingService() => _instance;
  CoachMessagingService._internal();

  // Cache for conversations and messages
  final Map<String, List<Conversation>> _conversationsCache = {};
  final Map<String, List<Message>> _messagesCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Get all conversations for a coach
  Future<List<Conversation>> getConversations(String coachId) async {
    try {
      // Check cache first
      if (_conversationsCache.containsKey(coachId) && _isCacheValid('conversations_$coachId')) {
        return _conversationsCache[coachId]!;
      }

      // Get conversations where coach is involved
      final response = await _sb
          .from('conversations')
          .select('id, coach_id, client_id, last_message_at')
          .eq('coach_id', coachId)
          .order('last_message_at', ascending: false);

      final conversations = <Conversation>[];
      for (final row in response as List<dynamic>) {
        final clientId = row['client_id'] as String;

        // Get client profile
        final profileResponse = await _sb
            .from('profiles')
            .select('name, full_name')
            .eq('id', clientId)
            .maybeSingle();

        if (profileResponse == null) continue;

        final clientName = (profileResponse['full_name'] as String?) ??
                          (profileResponse['name'] as String?) ??
                          'Unknown Client';

        // Get last message between coach and client using the existing schema (sender_id/recipient_id)
        final lastMessageResponse = await _sb
            .from('messages')
            .select('content, created_at, is_read, sender_id')
            .or('and(sender_id.eq.$coachId,recipient_id.eq.$clientId),and(sender_id.eq.$clientId,recipient_id.eq.$coachId)')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        final lastMessage = lastMessageResponse?['content'] as String?;
        final lastMessageAt = lastMessageResponse?['created_at'] != null
            ? DateTime.tryParse(lastMessageResponse!['created_at'].toString())
            : null;

        // Count unread messages from client to coach
        final unreadResponse = await _sb
            .from('messages')
            .select('id')
            .eq('sender_id', clientId)
            .eq('recipient_id', coachId)
            .eq('is_read', false)
            .count();

        final unreadCount = unreadResponse.count;

        final conversation = Conversation.fromMap({
          'id': row['id'],
          'coach_id': row['coach_id'],
          'client_id': clientId,
          'client_name': clientName,
          'client_avatar_url': null,
          'last_message': lastMessage,
          'last_message_at': lastMessageAt?.toIso8601String() ?? row['last_message_at'],
          'unread_count': unreadCount,
          'is_online': false,
        });

        conversations.add(conversation);
      }

      // Cache results
      _conversationsCache[coachId] = conversations;
      _cacheTimestamps['conversations_$coachId'] = DateTime.now();

      return conversations;
    } catch (e) {
      debugPrint('CoachMessagingService: Error getting conversations - $e');
      return [];
    }
  }

  /// Get messages for a specific conversation
  Future<List<Message>> getMessages({
    required String conversationId,
    required String coachId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final cacheKey = 'messages_$conversationId';

      // Check cache first
      if (_messagesCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
        final cached = _messagesCache[cacheKey]!;
        return cached.skip(offset).take(limit).toList();
      }

      // Get client_id from conversation
      final convResponse = await _sb
          .from('conversations')
          .select('client_id')
          .eq('id', conversationId)
          .maybeSingle();

      if (convResponse == null) {
        return [];
      }

      final clientId = convResponse['client_id'] as String;

      // Get messages between coach and client using sender_id/recipient_id schema
      final response = await _sb
          .from('messages')
          .select('''
            id,
            sender_id,
            recipient_id,
            content,
            message_type,
            is_read,
            created_at,
            message_attachments(
              file_url,
              file_name
            )
          ''')
          .or('and(sender_id.eq.$coachId,recipient_id.eq.$clientId),and(sender_id.eq.$clientId,recipient_id.eq.$coachId)')
          .order('created_at', ascending: false)
          .limit(limit + offset);

      final messages = <Message>[];
      for (final row in response as List<dynamic>) {
        final attachments = row['message_attachments'] as List<dynamic>?;
        final attachment = attachments?.isNotEmpty == true ? attachments?.first : null;

        final message = Message.fromMap({
          'id': row['id'],
          'conversation_id': conversationId, // Use conversationId for compatibility
          'sender_id': row['sender_id'],
          'content': row['content'],
          'message_type': row['message_type'] ?? 'text',
          'is_read': row['is_read'],
          'created_at': row['created_at'],
          'attachment_url': attachment?['file_url'],
          'attachment_name': attachment?['file_name'],
        });

        messages.add(message);
      }

      // Cache results
      _messagesCache[cacheKey] = messages;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return messages.skip(offset).take(limit).toList();
    } catch (e) {
      debugPrint('CoachMessagingService: Error getting messages - $e');
      return [];
    }
  }

  /// Send a message
  Future<bool> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String messageType = 'text',
    String? attachmentUrl,
    String? attachmentName,
  }) async {
    try {
      // Get recipient_id from conversation
      final convResponse = await _sb
          .from('conversations')
          .select('coach_id, client_id')
          .eq('id', conversationId)
          .maybeSingle();

      if (convResponse == null) {
        debugPrint('CoachMessagingService: Conversation not found');
        return false;
      }

      final coachId = convResponse['coach_id'] as String;
      final clientId = convResponse['client_id'] as String;
      final recipientId = senderId == coachId ? clientId : coachId;

      // Insert message using sender_id/recipient_id schema
      final messageResponse = await _sb.from('messages').insert({
        'sender_id': senderId,
        'recipient_id': recipientId,
        'content': content,
        'message_type': messageType,
        'is_read': false,
      }).select('id').single();

      final messageId = messageResponse['id'] as String;

      // Insert attachment if provided
      if (attachmentUrl != null) {
        await _sb.from('message_attachments').insert({
          'message_id': messageId,
          'file_url': attachmentUrl,
          'file_name': attachmentName,
          'file_type': _getFileTypeFromUrl(attachmentUrl),
        });
      }

      // Update conversation last_message_at
      await _sb
          .from('conversations')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);

      // Clear cache for this conversation
      _clearCacheForConversation(conversationId);

      return true;
    } catch (e) {
      debugPrint('CoachMessagingService: Error sending message - $e');
      return false;
    }
  }

  /// Mark messages as read
  Future<bool> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      // Get client_id from conversation
      final convResponse = await _sb
          .from('conversations')
          .select('coach_id, client_id')
          .eq('id', conversationId)
          .maybeSingle();

      if (convResponse == null) {
        return false;
      }

      final coachId = convResponse['coach_id'] as String;
      final clientId = convResponse['client_id'] as String;
      final otherUserId = userId == coachId ? clientId : coachId;

      // Mark messages from other user as read using sender_id/recipient_id schema
      await _sb
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', otherUserId)
          .eq('recipient_id', userId)
          .eq('is_read', false);

      // Clear cache
      _clearCacheForConversation(conversationId);

      return true;
    } catch (e) {
      debugPrint('CoachMessagingService: Error marking messages as read - $e');
      return false;
    }
  }

  /// Get smart reply suggestions
  Future<List<SmartReply>> getSmartReplies({
    required String conversationId,
    required String lastMessage,
  }) async {
    try {
      // TODO: Implement AI-powered smart replies
      // For now, return some common coach replies
      return [
        SmartReply(
          id: '1',
          text: 'Great job! Keep up the excellent work.',
          category: 'encouragement',
          confidence: 0.9,
        ),
        SmartReply(
          id: '2',
          text: 'How are you feeling about your progress?',
          category: 'check-in',
          confidence: 0.8,
        ),
        SmartReply(
          id: '3',
          text: 'Let\'s schedule a check-in call this week.',
          category: 'scheduling',
          confidence: 0.7,
        ),
        SmartReply(
          id: '4',
          text: 'Remember to stay hydrated and get enough sleep.',
          category: 'reminder',
          confidence: 0.6,
        ),
      ];
    } catch (e) {
      debugPrint('CoachMessagingService: Error getting smart replies - $e');
      return [];
    }
  }

  /// Get last message and unread count for a conversation
  Future<Map<String, dynamic>> _getLastMessageAndUnreadCount(String conversationId, String coachId) async {
    try {
      final response = await _sb
          .from('messages')
          .select('content, sender_id, is_read')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        return {'last_message': null, 'unread_count': 0};
      }

      final lastMessage = response.first;
      final lastMessageContent = lastMessage['content'] as String?;

      // Count unread messages (messages not sent by coach)
      final unreadResponse = await _sb
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .eq('is_read', false)
          .neq('sender_id', coachId);

      return {
        'last_message': lastMessageContent,
        'unread_count': (unreadResponse as List<dynamic>).length,
      };
    } catch (e) {
      debugPrint('CoachMessagingService: Error getting last message - $e');
      return {'last_message': null, 'unread_count': 0};
    }
  }

  /// Get file type from URL
  String _getFileTypeFromUrl(String url) {
    final extension = url.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'image';
      case 'mp4':
      case 'avi':
      case 'mov':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'm4a':
        return 'audio';
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
        return 'document';
      default:
        return 'file';
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Clear cache for a specific conversation
  void _clearCacheForConversation(String conversationId) {
    _messagesCache.remove('messages_$conversationId');
    _cacheTimestamps.remove('messages_$conversationId');
    
    // Also clear conversations cache since unread counts may have changed
    _conversationsCache.clear();
    _cacheTimestamps.removeWhere((key, value) => key.startsWith('conversations_'));
  }

  /// Clear all cache
  void clearAllCache() {
    _conversationsCache.clear();
    _messagesCache.clear();
    _cacheTimestamps.clear();
  }
}
