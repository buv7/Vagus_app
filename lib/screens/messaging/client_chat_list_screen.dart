import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/theme_colors.dart';
import '../../services/messages_service.dart';
import 'modern_messenger_screen.dart';
import 'message_settings_screen.dart';

/// WhatsApp-style chat list screen for clients
/// Shows all conversations before entering individual chats
class ClientChatListScreen extends StatefulWidget {
  final VoidCallback? onShowBottomNav;
  final VoidCallback? onHideBottomNav;

  const ClientChatListScreen({
    super.key,
    this.onShowBottomNav,
    this.onHideBottomNav,
  });

  @override
  State<ClientChatListScreen> createState() => _ClientChatListScreenState();
}

class _ClientChatListScreenState extends State<ClientChatListScreen> {
  final MessagesService _messagesService = MessagesService();
  final TextEditingController _searchController = TextEditingController();

  List<ChatThread> _threads = [];
  bool _loading = true;
  String _searchQuery = '';
  StreamSubscription? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
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
      
      // Check online status
      final isOnline = await _checkOnlineStatus(coachId);

      setState(() {
        _threads = [
          ChatThread(
            threadId: threadId,
            recipientId: coachId,
            recipientName: coachProfile?['full_name'] as String? ?? 'Coach',
            recipientAvatar: coachProfile?['avatar_url'] as String?,
            lastMessage: lastMessage?['text']?.toString(),
            lastMessageAt: DateTime.tryParse(
                    lastMessage?['created_at']?.toString() ?? '') ??
                DateTime.now(),
            unreadCount: unreadCount,
            isOnline: isOnline,
          ),
        ];
        _loading = false;
      });

      // Subscribe to thread updates
      _subscribeToThreadUpdates(threadId);
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Failed to load threads: $e');
    }
  }

  Future<String?> _getCoachId(String clientId) async {
    try {
      // Try coach_clients table first
      final links = await Supabase.instance.client
          .from('coach_clients')
          .select('coach_id')
          .eq('client_id', clientId);

      if (links.isNotEmpty) {
        return links.first['coach_id'] as String;
      }

      // Try coach_client_links table
      final response = await Supabase.instance.client
          .from('coach_client_links')
          .select('coach_id')
          .eq('client_id', clientId);

      if (response.isNotEmpty) {
        return response.first['coach_id'] as String;
      }

      // Fallback: get coach from workout plans
      final workoutPlans = await Supabase.instance.client
          .from('workout_plans')
          .select('created_by')
          .eq('client_id', clientId)
          .not('created_by', 'is', null);

      if (workoutPlans.isNotEmpty) {
        return workoutPlans.first['created_by'] as String;
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
          .select('full_name, avatar_url, last_seen')
          .eq('id', coachId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getLastMessage(String threadId) async {
    if (threadId.startsWith('local_')) return null;

    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('text, created_at, sender_id, attachments')
          .eq('thread_id', threadId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<int> _getUnreadCount(String threadId, String userId) async {
    if (threadId.startsWith('local_')) return 0;

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

  Future<bool> _checkOnlineStatus(String recipientId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('last_seen')
          .eq('id', recipientId)
          .maybeSingle();

      if (response != null) {
        final lastSeen =
            DateTime.tryParse(response['last_seen']?.toString() ?? '');
        return lastSeen != null &&
            DateTime.now().difference(lastSeen).inMinutes < 5;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _subscribeToThreadUpdates(String threadId) {
    _messagesSubscription?.cancel();
    _messagesSubscription =
        _messagesService.subscribeMessages(threadId).listen((messages) {
      if (messages.isNotEmpty && mounted) {
        final lastMessage = messages.last;
        setState(() {
          final threadIndex =
              _threads.indexWhere((t) => t.threadId == threadId);
          if (threadIndex != -1) {
            _threads[threadIndex] = _threads[threadIndex].copyWith(
              lastMessage: lastMessage.text.isNotEmpty
                  ? lastMessage.text
                  : (lastMessage.attachments.isNotEmpty ? '📎 Attachment' : ''),
              lastMessageAt: lastMessage.createdAt,
            );
          }
        });
      }
    });
  }

  List<ChatThread> get _filteredThreads {
    if (_searchQuery.isEmpty) return _threads;

    return _threads.where((thread) {
      final name = thread.recipientName.toLowerCase();
      final message = thread.lastMessage?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || message.contains(query);
    }).toList();
  }

  void _openChat(ChatThread thread) {
    // Hide bottom nav when entering chat
    widget.onHideBottomNav?.call();
    
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const ModernMessengerScreen(),
      ),
    )
        .then((_) {
      // Show bottom nav when returning from chat
      widget.onShowBottomNav?.call();
      // Refresh threads when returning
      _loadThreads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Search Bar
            _buildSearchBar(),

            // Chat List
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(tc.accent),
                      ),
                    )
                  : _threads.isEmpty
                      ? _buildEmptyState()
                      : _buildChatList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final tc = context.tc;
    final totalUnread =
        _threads.fold<int>(0, (sum, thread) => sum + thread.unreadCount);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space20,
        DesignTokens.space16,
        DesignTokens.space20,
        DesignTokens.space12,
      ),
      child: Row(
        children: [
          // Title with chat icon
          Row(
            children: [
              Icon(
                Icons.chat_bubble_rounded,
                color: tc.accent,
                size: 28,
              ),
              const SizedBox(width: DesignTokens.space12),
              Text(
                'Messages',
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (totalUnread > 0) ...[
                const SizedBox(width: DesignTokens.space8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space8,
                    vertical: DesignTokens.space4,
                  ),
                  decoration: BoxDecoration(
                    color: tc.danger,
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  ),
                  child: Text(
                    '$totalUnread',
                    style: TextStyle(
                      color: tc.textOnDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const Spacer(),

          // More options
          IconButton(
            onPressed: () => _showMoreOptions(),
            icon: Icon(
              Icons.more_vert,
              color: tc.iconSecondary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final tc = context.tc;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space20,
        vertical: DesignTokens.space8,
      ),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: tc.border,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: tc.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: TextStyle(color: tc.textSecondary),
          prefixIcon: Icon(
            Icons.search,
            color: tc.iconSecondary,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: tc.iconSecondary, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space14,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final tc = context.tc;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: tc.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: tc.accent,
                size: 48,
              ),
            ),
            const SizedBox(height: DesignTokens.space24),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: tc.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              'Connect with a coach to start messaging',
              style: TextStyle(
                color: tc.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    final filteredThreads = _filteredThreads;

    return RefreshIndicator(
      onRefresh: _loadThreads,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space8,
        ),
        itemCount: filteredThreads.length,
        itemBuilder: (context, index) {
          final thread = filteredThreads[index];
          return _buildChatItem(thread);
        },
      ),
    );
  }

  Widget _buildChatItem(ChatThread thread) {
    final tc = context.tc;
    final hasUnread = thread.unreadCount > 0;
    final initials = thread.recipientName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space8),
      decoration: BoxDecoration(
        color: hasUnread ? tc.accent.withValues(alpha: 0.05) : tc.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: hasUnread ? tc.accent.withValues(alpha: 0.3) : tc.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openChat(thread),
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: tc.accent,
                      backgroundImage: thread.recipientAvatar != null
                          ? NetworkImage(thread.recipientAvatar!)
                          : null,
                      child: thread.recipientAvatar == null
                          ? Text(
                              initials,
                              style: TextStyle(
                                color: tc.textOnDark,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    // Online indicator
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color:
                              thread.isOnline ? tc.success : tc.textSecondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tc.surface,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: DesignTokens.space16),

                // Chat info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and time row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              thread.recipientName,
                              style: TextStyle(
                                color: tc.textPrimary,
                                fontSize: 16,
                                fontWeight:
                                    hasUnread ? FontWeight.bold : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(thread.lastMessageAt),
                            style: TextStyle(
                              color: hasUnread ? tc.accent : tc.textTertiary,
                              fontSize: 12,
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: DesignTokens.space6),

                      // Last message and unread count row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              thread.lastMessage ?? 'No messages yet',
                              style: TextStyle(
                                color:
                                    hasUnread ? tc.textPrimary : tc.textSecondary,
                                fontSize: 14,
                                fontWeight:
                                    hasUnread ? FontWeight.w500 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: DesignTokens.space8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.space8,
                                vertical: DesignTokens.space4,
                              ),
                              decoration: BoxDecoration(
                                color: tc.accent,
                                borderRadius:
                                    BorderRadius.circular(DesignTokens.radius12),
                              ),
                              child: Text(
                                thread.unreadCount > 99
                                    ? '99+'
                                    : '${thread.unreadCount}',
                                style: TextStyle(
                                  color: tc.textOnDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreOptions() {
    final tc = context.tc;

    showModalBottomSheet(
      context: context,
      backgroundColor: tc.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final sheetTc = ThemeColors.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sheetTc.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: DesignTokens.space20),
                ListTile(
                  leading: Icon(Icons.mark_email_read, color: sheetTc.accent),
                  title: Text(
                    'Mark all as read',
                    style: TextStyle(color: sheetTc.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _markAllAsRead();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings, color: sheetTc.icon),
                  title: Text(
                    'Message settings',
                    style: TextStyle(color: sheetTc.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MessageSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _markAllAsRead() {
    setState(() {
      _threads = _threads
          .map((thread) => thread.copyWith(unreadCount: 0))
          .toList();
    });
    _showSnackBar('All messages marked as read');
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}

/// Represents a chat thread/conversation
class ChatThread {
  final String threadId;
  final String recipientId;
  final String recipientName;
  final String? recipientAvatar;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isOnline;

  ChatThread({
    required this.threadId,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatar,
    this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  ChatThread copyWith({
    String? threadId,
    String? recipientId,
    String? recipientName,
    String? recipientAvatar,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isOnline,
  }) {
    return ChatThread(
      threadId: threadId ?? this.threadId,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      recipientAvatar: recipientAvatar ?? this.recipientAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
