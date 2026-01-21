import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/messages_service.dart';
import 'client_messenger_screen.dart';

class ClientThreadsScreen extends StatefulWidget {
  const ClientThreadsScreen({super.key});

  @override
  State<ClientThreadsScreen> createState() => _ClientThreadsScreenState();
}

class _ClientThreadsScreenState extends State<ClientThreadsScreen> {
  final MessagesService _messagesService = MessagesService();
  
  List<Map<String, dynamic>> _threads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get coach ID from existing link tables
      final coachId = await _getCoachId(user.id);
      if (coachId == null) {
        setState(() => _loading = false);
        return;
      }

      // Get coach profile
      final coachProfile = await _getCoachProfile(coachId);
      
      // Get thread info
      final threadId = await _messagesService.ensureThread(
        coachId: coachId,
        clientId: user.id,
      );

      // Get last message for preview
      final lastMessage = await _getLastMessage(threadId);
      
      // Get unread count
      final unreadCount = await _getUnreadCount(threadId, user.id);

      setState(() {
        _threads = [{
          'thread_id': threadId,
          'coach_id': coachId,
          'coach_profile': coachProfile,
          'last_message': lastMessage,
          'unread_count': unreadCount,
          'last_message_at': lastMessage?['created_at'] ?? DateTime.now().toIso8601String(),
        }];
        _loading = false;
      });

      // Subscribe to thread updates
      _subscribeToThreadUpdates(threadId);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load threads: $e')),
        );
      }
    }
  }

  Future<String?> _getCoachId(String clientId) async {
    try {
      // Try coach_clients table first
      var response = await Supabase.instance.client
          .from('coach_clients')
          .select('coach_id')
          .eq('client_id', clientId)
          .single();
      
      if (response['coach_id'] != null) {
        return response['coach_id'];
      }

      // Try coach_client_links table
      response = await Supabase.instance.client
          .from('coach_client_links')
          .select('coach_id')
          .eq('client_id', clientId)
          .single();
      
      if (response['coach_id'] != null) {
        return response['coach_id'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getCoachProfile(String coachId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', coachId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getLastMessage(String threadId) async {
    // Skip if using local thread (no database connection)
    if (threadId.startsWith('local_')) return null;
    
    try {
      // Try thread_id column first (new schema)
      try {
        final response = await Supabase.instance.client
            .from('messages')
            .select('*')
            .eq('thread_id', threadId)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false)
            .limit(1)
            .single();
        return response;
      } catch (threadError) {
        // Fallback: Get messages from conversation using sender_id/recipient_id
        final conv = await Supabase.instance.client
            .from('conversations')
            .select('coach_id, client_id')
            .eq('id', threadId)
            .maybeSingle();
        
        if (conv == null) return null;
        
        final coachId = conv['coach_id'] as String;
        final clientId = conv['client_id'] as String;
        
        final response = await Supabase.instance.client
            .from('messages')
            .select('*')
            .or('and(sender_id.eq.$coachId,recipient_id.eq.$clientId),and(sender_id.eq.$clientId,recipient_id.eq.$coachId)')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        return response;
      }
    } catch (e) {
      return null;
    }
  }

  Future<int> _getUnreadCount(String threadId, String userId) async {
    // Skip if using local thread (no database connection)
    if (threadId.startsWith('local_')) return 0;
    
    try {
      final response = await Supabase.instance.client
          .rpc('get_unread_counts', params: {'uid': userId});
      
      if (response is Map<String, dynamic>) {
        return response[threadId] ?? 0;
      }
      return 0;
    } catch (e) {
      // Fallback: Try thread_id column first, then legacy schema
      try {
        final rows = await Supabase.instance.client
            .from('messages')
            .select('id')
            .eq('thread_id', threadId)
            .neq('sender_id', userId)
            .isFilter('seen_at', null)
            .isFilter('deleted_at', null);
        
        return rows.length;
      } catch (threadError) {
        // Legacy schema fallback: count unread messages by recipient_id
        try {
          final rows = await Supabase.instance.client
              .from('messages')
              .select('id')
              .eq('recipient_id', userId)
              .eq('is_read', false);
          
          return rows.length;
        } catch (e) {
          return 0;
        }
      }
    }
  }

  void _subscribeToThreadUpdates(String threadId) {
    // Subscribe to new messages to update thread list
    _messagesService.subscribeMessages(threadId).listen((messages) {
      if (messages.isNotEmpty) {
        final lastMessage = messages.last;
        setState(() {
          final threadIndex = _threads.indexWhere((t) => t['thread_id'] == threadId);
          if (threadIndex != -1) {
            _threads[threadIndex]['last_message'] = {
              'text': lastMessage.text,
              'attachments': lastMessage.attachments,
              'created_at': lastMessage.createdAt.toIso8601String(),
            };
            _threads[threadIndex]['last_message_at'] = lastMessage.createdAt.toIso8601String();
            
            // Move thread to top
            final thread = _threads.removeAt(threadIndex);
            _threads.insert(0, thread);
          }
        });
      }
    });
  }

  String _getMessagePreview(Map<String, dynamic>? lastMessage) {
    if (lastMessage == null) return 'No messages yet';
    
    final text = lastMessage['text']?.toString() ?? '';
    final attachments = lastMessage['attachments'] as List<dynamic>? ?? [];
    
    if (text.isNotEmpty) {
      return text.length > 50 ? '${text.substring(0, 50)}...' : text;
    } else if (attachments.isNotEmpty) {
      return '📎 Attachment';
    }
    
    return 'No messages yet';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _threads.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Connect with a coach to start messaging',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _threads.length,
                  itemBuilder: (context, index) {
                    final thread = _threads[index];
                    final coachProfile = thread['coach_profile'] as Map<String, dynamic>?;
                    final lastMessage = thread['last_message'] as Map<String, dynamic>?;
                    final unreadCount = thread['unread_count'] as int? ?? 0;
                    final lastMessageAt = DateTime.tryParse(thread['last_message_at'] ?? '') ?? DateTime.now();
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[300],
                        child: Text(
                          (coachProfile?['name']?.toString() ?? 'C')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        coachProfile?['name']?.toString() ?? 'Coach',
                        style: TextStyle(
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        _getMessagePreview(lastMessage),
                        style: TextStyle(
                          color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(lastMessageAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: unreadCount > 0 ? Colors.blue : Colors.grey[600],
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ClientMessengerScreen(),
                          ),
                        ).then((_) {
                          // Refresh threads when returning
                          _loadThreads();
                        });
                      },
                    );
                  },
                ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
