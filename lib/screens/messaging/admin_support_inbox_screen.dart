import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_support_chat_screen.dart';
import '../../services/messages_service.dart';

class AdminSupportInboxScreen extends StatefulWidget {
  const AdminSupportInboxScreen({super.key});

  @override
  State<AdminSupportInboxScreen> createState() => _AdminSupportInboxScreenState();
}

class _AdminSupportInboxScreenState extends State<AdminSupportInboxScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _threads = [];
  Map<String, int> _unreadCounts = {};
  String _query = '';
  RealtimeChannel? _channel;
  bool _showAllAdmins = false;
  bool _showUnassignedOnly = false;

  @override
  void initState() {
    super.initState();
    // ignore: unawaited_futures
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    final supabase = Supabase.instance.client;
    final me = supabase.auth.currentUser;
    if (me == null) {
      setState(() { _loading = false; });
      return;
    }

    try {
      final selectCols = 'id, client:client_id(id, name, email, avatar_url), last_message_at';
      List<dynamic> rows;

      if (_showAllAdmins) {
        // Team inbox: fetch all support threads for any admin
        rows = await supabase
            .from('message_threads')
            .select(selectCols)
            .order('last_message_at', ascending: false);
      } else {
        // My inbox: fetch threads assigned to me OR unassigned threads I can pick up
        final myThreads = await supabase
            .from('message_threads')
            .select(selectCols)
            .eq('coach_id', me.id)
            .order('last_message_at', ascending: false);
            
                 // Also get unassigned threads (where coach_id is null) that I can pick up
         final unassignedThreads = await supabase
             .from('message_threads')
             .select(selectCols)
             .filter('coach_id', 'is', null)
             .order('last_message_at', ascending: false);
            
        // Combine both lists, prioritizing my assigned threads
        rows = [...myThreads, ...unassignedThreads];
      }

      setState(() {
        _threads = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });

      // Load unread counts via RPC fallback from MessagesService helper
      final counts = await MessagesService().getUnreadCounts(me.id);
      setState(() => _unreadCounts = counts);

      // Subscribe for live updates (Supabase v2 API)
      unawaited(_channel?.unsubscribe());
      _channel = supabase.channel('inbox_${me.id}');
      _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            unawaited(_loadInbox());
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            unawaited(_loadInbox());
          },
        )
        .subscribe();
    } catch (_) {
      setState(() { _loading = false; });
    }
  }



  Future<void> _createTestSupportThread() async {
    final supabase = Supabase.instance.client;
    final me = supabase.auth.currentUser;
    if (me == null) return;

    try {
      // Find a client user to create a support thread with
      final clients = await supabase
          .from('profiles')
          .select('id, name, email')
          .eq('role', 'client')
          .limit(1);

      if (clients.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No client users found to create support thread with')),
          );
        }
        return;
      }

      final client = clients.first;
      
      // Check if thread already exists to avoid duplicate key error
      final existingThread = await supabase
          .from('message_threads')
          .select('id')
          .eq('coach_id', me.id)
          .eq('client_id', client['id'])
          .maybeSingle();

      if (existingThread != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Support thread already exists with ${client['name']}')),
          );
          // Reload the inbox to show existing thread
          unawaited(_loadInbox());
        }
        return;
      }
      
      // Create a support thread (unassigned initially)
      final threadResponse = await supabase
          .from('message_threads')
          .insert({
            'client_id': client['id'],
            'last_message_at': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            // Note: coach_id is null initially, making it unassigned
          })
          .select('id')
          .single();

      final threadId = threadResponse['id'] as String;

      // Add a test message from the client
      await supabase
          .from('messages')
          .insert({
            'thread_id': threadId,
            'sender_id': client['id'],
            'text': 'Hello! I need help with my workout plan. Can you assist me?',
            'attachments': [],
            'created_at': DateTime.now().toIso8601String(),
          });

      // Update thread's last_message_at
      await supabase
          .from('message_threads')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', threadId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Created test support thread with ${client['name']}')),
        );
        // Reload the inbox
        // ignore: unawaited_futures
        _loadInbox();
      }
    } catch (e) {
      debugPrint('❌ Error creating test support thread: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to create test thread: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add), 
            tooltip: 'Create test support thread',
            onPressed: _createTestSupportThread,
          ),
          IconButton(
            icon: Icon(_showUnassignedOnly ? Icons.assignment : Icons.assignment_ind),
            tooltip: _showUnassignedOnly ? 'Show all threads' : 'Show unassigned only',
            onPressed: () {
              setState(() => _showUnassignedOnly = !_showUnassignedOnly);
              // ignore: unawaited_futures
              _loadInbox();
            },
          ),
          IconButton(
            icon: const Icon(Icons.group), 
            tooltip: _showAllAdmins ? 'Show my inbox' : 'Show all admins', 
            onPressed: () {
              setState(() => _showAllAdmins = !_showAllAdmins);
              // ignore: unawaited_futures
              _loadInbox();
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            // ignore: unawaited_futures
            _loadInbox();
          }),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search clients by name or email',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No support requests yet.', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _createTestSupportThread,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Test Support Thread'),
                      ),
                      const SizedBox(height: 8),
                      const Text('This will create a sample support request for testing', 
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final t = _filtered[index];
                    final client = t['client'] as Map<String, dynamic>?;
                    final clientName = client?['name'] ?? 'Client';
                    final avatarUrl = client?['avatar_url']?.toString() ?? '';
                    final hasAvatar = avatarUrl.isNotEmpty;
                    final count = _unreadCounts[t['id']] ?? 0;

                    final isUnassigned = t['coach_id'] == null;
                    
                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                            child: !hasAvatar ? const Icon(Icons.person) : null,
                          ),
                          if (isUnassigned)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.priority_high,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(clientName)),
                          if (isUnassigned)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'UNASSIGNED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(client?['email']?.toString() ?? ''),
                          if (isUnassigned)
                            const Text(
                              'Tap to claim this support request',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      trailing: count > 0
                          ? CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            )
                          : const Icon(Icons.chevron_right),
                                             onTap: () async {
                         final navigator = Navigator.of(context);
                         final scaffoldMessenger = ScaffoldMessenger.of(context);
                         final clientId = client?['id']?.toString();
                         if (clientId == null) return;

                         // If unassigned, claim it first
                         if (isUnassigned) {
                           try {
                             final supabase = Supabase.instance.client;
                             final me = supabase.auth.currentUser;
                             if (me == null) return;

                             await supabase
                                 .from('message_threads')
                                 .update({'coach_id': me.id})
                                 .eq('id', t['id']);

                             if (mounted) {
                               scaffoldMessenger.showSnackBar(
                                 SnackBar(content: Text('✅ Claimed support request from $clientName')),
                               );
                             }
                           } catch (e) {
                             debugPrint('❌ Error claiming thread: $e');
                             if (mounted) {
                               scaffoldMessenger.showSnackBar(
                                 const SnackBar(content: Text('❌ Failed to claim request')),
                               );
                             }
                             return;
                           }
                         }

                         unawaited(navigator.push(
                           MaterialPageRoute(
                             builder: (_) => AdminSupportChatScreen(clientId: clientId),
                           ),
                         ).then((_) {
                           unawaited(_loadInbox());
                         }));
                       },
                    );
                  },
                ),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    List<Map<String, dynamic>> filtered = _threads;
    
    // Apply unassigned filter first
    if (_showUnassignedOnly) {
      filtered = filtered.where((t) => t['coach_id'] == null).toList();
    }
    
    // Then apply search filter
    if (_query.isNotEmpty) {
      filtered = filtered.where((t) {
        final client = t['client'] as Map<String, dynamic>?;
        final name = (client?['name'] ?? '').toString().toLowerCase();
        final email = (client?['email'] ?? '').toString().toLowerCase();
        return name.contains(_query) || email.contains(_query);
      }).toList();
    }
    
    return filtered;
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}


