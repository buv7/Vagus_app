import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/messages_service.dart';
import 'coach_messenger_screen.dart';

class CoachThreadsScreen extends StatefulWidget {
  const CoachThreadsScreen({super.key});

  @override
  State<CoachThreadsScreen> createState() => _CoachThreadsScreenState();
}

class _CoachThreadsScreenState extends State<CoachThreadsScreen> {
  final MessagesService _messagesService = MessagesService();
  
  List<Map<String, dynamic>> _threads = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get all clients for this coach
      final clients = await _getCoachClients(user.id);
      
      final threads = <Map<String, dynamic>>[];
      
      for (final client in clients) {
        final clientId = client['client_id'] ?? client['id'];
        final clientProfile = client['profile'] ?? client;
        
        // Ensure thread exists
        final threadId = await _messagesService.ensureThread(
          coachId: user.id,
          clientId: clientId,
        );

        // Get last message for preview
        final lastMessage = await _getLastMessage(threadId);
        
        // Get unread count
        final unreadCount = await _getUnreadCount(threadId, user.id);

        threads.add({
          'thread_id': threadId,
          'client_id': clientId,
          'client_profile': clientProfile,
          'last_message': lastMessage,
          'unread_count': unreadCount,
          'last_message_at': lastMessage?['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }

      // Sort by last message time (newest first)
      threads.sort((a, b) {
        final aTime = DateTime.tryParse(a['last_message_at'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['last_message_at'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      setState(() {
        _threads = threads;
        _loading = false;
      });

      // Subscribe to updates for all threads
      for (final thread in threads) {
        _subscribeToThreadUpdates(thread['thread_id']);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load threads: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getCoachClients(String coachId) async {
    try {
      // Try coach_clients table first
      var links = await Supabase.instance.client
          .from('coach_clients')
          .select('client_id')
          .eq('coach_id', coachId);
      
      if (links.isNotEmpty) {
        final clientIds = links.map((row) => row['client_id'] as String).toList();
        
        final profiles = await Supabase.instance.client
            .from('profiles')
            .select('id, name, email')
            .inFilter('id', clientIds);
        
        return profiles.map((profile) => {
          'client_id': profile['id'],
          'profile': profile,
        }).toList();
      }

      // Try coach_client_links table
      var response = await Supabase.instance.client
          .from('coach_client_links')
          .select('''
            client_id,
            profiles!coach_client_links_client_id_fkey (
              id,
              name,
              email
            )
          ''')
          .eq('coach_id', coachId);
      
      if (response.isNotEmpty) {
        return response.map((row) => {
          'client_id': row['client_id'],
          'profile': row['profiles'],
        }).toList();
      }

      // Fallback: get clients from workout/nutrition plans
      final workoutClients = await Supabase.instance.client
          .from('workout_plans')
          .select('client_id')
          .eq('created_by', coachId);
      
      final nutritionClients = await Supabase.instance.client
          .from('nutrition_plans')
          .select('client_id')
          .eq('created_by', coachId);
      
      final allClientIds = <String>{};
      for (final row in workoutClients) {
        if (row['client_id'] != null) allClientIds.add(row['client_id']);
      }
      for (final row in nutritionClients) {
        if (row['client_id'] != null) allClientIds.add(row['client_id']);
      }
      
      final clients = <Map<String, dynamic>>[];
      for (final clientId in allClientIds) {
        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('*')
              .eq('id', clientId)
              .single();
          
          clients.add({
            'client_id': clientId,
            'profile': profile,
          });
        } catch (e) {
          // Skip if profile not found
        }
      }
      
      return clients;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> _getLastMessage(String threadId) async {
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
    } catch (e) {
      return null;
    }
  }

  Future<int> _getUnreadCount(String threadId, String userId) async {
    try {
      final response = await Supabase.instance.client
          .rpc('get_unread_counts', params: {'uid': userId});
      
      if (response is Map<String, dynamic>) {
        return response[threadId] ?? 0;
      }
      return 0;
    } catch (e) {
      // Fallback: count messages not seen by current user
      try {
        final rows = await Supabase.instance.client
            .from('messages')
            .select('id')
            .eq('thread_id', threadId)
            .neq('sender_id', userId)
            .isFilter('seen_at', null)
            .isFilter('deleted_at', null);
        
        return rows.length;
      } catch (e) {
        return 0;
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

  List<Map<String, dynamic>> get _filteredThreads {
    if (_searchQuery.isEmpty) return _threads;
    
    return _threads.where((thread) {
      final clientProfile = thread['client_profile'] as Map<String, dynamic>?;
      final clientName = clientProfile?['name']?.toString().toLowerCase() ?? '';
      final clientEmail = clientProfile?['email']?.toString().toLowerCase() ?? '';
      final lastMessage = thread['last_message'] as Map<String, dynamic>?;
      final messageText = lastMessage?['text']?.toString().toLowerCase() ?? '';
      
      final query = _searchQuery.toLowerCase();
      return clientName.contains(query) || 
             clientEmail.contains(query) || 
             messageText.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
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
                        'No client conversations yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Clients will appear here when they connect',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Searching: "$_searchQuery"',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredThreads.length,
                        itemBuilder: (context, index) {
                          final thread = _filteredThreads[index];
                          final clientProfile = thread['client_profile'] as Map<String, dynamic>?;
                          final lastMessage = thread['last_message'] as Map<String, dynamic>?;
                          final unreadCount = thread['unread_count'] as int? ?? 0;
                          final lastMessageAt = DateTime.tryParse(thread['last_message_at'] ?? '') ?? DateTime.now();
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[300],
                              child: Text(
                                (clientProfile?['name']?.toString() ?? 'C')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              clientProfile?['name']?.toString() ?? 'Client',
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
                                  builder: (_) => CoachMessengerScreen(
                                    client: {
                                      'id': thread['client_id'],
                                      'name': clientProfile?['name'] ?? 'Client',
                                      'email': clientProfile?['email'],
                                    },
                                  ),
                                ),
                              ).then((_) {
                                // Refresh threads when returning
                                _loadThreads();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Conversations'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by client name, email, or message content...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
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
