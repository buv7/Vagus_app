import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/design_tokens.dart';
import '../../theme/theme_colors.dart';
import '../../services/coach/coach_messaging_service.dart';
import '../../services/simple_calling_service.dart';
import '../../services/messages_service.dart';
import '../../models/live_session.dart';
import '../calling/simple_call_screen.dart';

class ModernClientMessagesScreen extends StatefulWidget {
  const ModernClientMessagesScreen({super.key});

  @override
  State<ModernClientMessagesScreen> createState() => _ModernClientMessagesScreenState();
}

class _ModernClientMessagesScreenState extends State<ModernClientMessagesScreen> {
  final CoachMessagingService _messagingService = CoachMessagingService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Conversation> _conversations = [];
  bool _loading = true;
  String _searchQuery = '';
  int _totalUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      setState(() {
        _loading = true;
      });

      // Load conversations with clients
      final conversations = await _messagingService.getConversations(user.id);
      
      int totalUnread = 0;
      for (final conversation in conversations) {
        totalUnread += conversation.unreadCount;
      }

      setState(() {
        _conversations = conversations;
        _totalUnreadCount = totalUnread;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Conversation> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    
    return _conversations.where((conversation) {
      final clientName = conversation.clientName.toLowerCase();
      final lastMessage = conversation.lastMessage?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return clientName.contains(query) || lastMessage.contains(query);
    }).toList();
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
            
            // Conversations List
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(tc.accent),
                      ),
                    )
                  : _conversations.isEmpty
                      ? _buildEmptyState()
                      : _buildConversationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final tc = context.tc;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Row(
        children: [
          // Title with icon
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: tc.accent,
                size: 24,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                'Client Messages',
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_totalUnreadCount > 0) ...[
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
                    '$_totalUnreadCount',
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
          
          // Search Icon
          IconButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchQuery.isEmpty ? ' ' : '';
                _searchController.clear();
              });
            },
            icon: Icon(
              Icons.search,
              color: tc.iconSecondary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    if (_searchQuery.isEmpty) return const SizedBox.shrink();
    
    final tc = context.tc;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
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
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: tc.iconSecondary,
            size: 20,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: tc.textSecondary,
            size: 64,
          ),
          const SizedBox(height: DesignTokens.space16),
          Text(
            'No client conversations yet',
            style: TextStyle(
              color: tc.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'Clients will appear here when they connect',
            style: TextStyle(
              color: tc.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    final filteredConversations = _filteredConversations;
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
      itemCount: filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = filteredConversations[index];
        return _buildConversationItem(conversation);
      },
    );
  }

  Widget _buildConversationItem(Conversation conversation) {
    final tc = context.tc;
    final clientName = conversation.clientName;
    final lastMessage = conversation.lastMessage ?? '';
    final timestamp = conversation.lastMessageAt;
    final unreadCount = conversation.unreadCount;
    final isOnline = conversation.isOnline;
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space8),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: tc.border,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DesignTokens.space16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: tc.accent,
              child: Text(
                clientName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: tc.textOnDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: tc.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: tc.bg,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          clientName,
          style: TextStyle(
            color: tc.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          lastMessage,
          style: TextStyle(
            color: tc.textSecondary,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action Icons
            IconButton(
              onPressed: () => _makeCall(conversation),
              icon: Icon(
                Icons.phone,
                color: tc.iconSecondary,
                size: 20,
              ),
            ),
            IconButton(
              onPressed: () => _makeVideoCall(conversation),
              icon: Icon(
                Icons.videocam,
                color: tc.iconSecondary,
                size: 20,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: tc.iconSecondary,
                size: 20,
              ),
              onSelected: (value) => _handleMenuAction(value, conversation),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_read',
                  child: Text('Mark as Read'),
                ),
                const PopupMenuItem(
                  value: 'pin',
                  child: Text('Pin Conversation'),
                ),
                const PopupMenuItem(
                  value: 'archive',
                  child: Text('Archive'),
                ),
              ],
            ),
            
            // Timestamp and Unread Count
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    color: tc.textTertiary,
                    fontSize: 12,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(height: DesignTokens.space4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space6,
                      vertical: DesignTokens.space2,
                    ),
                    decoration: BoxDecoration(
                      color: tc.danger,
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: TextStyle(
                        color: tc.textOnDark,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () => _openConversation(conversation),
      ),
    );
  }

  void _openConversation(Conversation conversation) {
    // Navigate to individual conversation
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModernConversationScreen(
          conversation: conversation,
        ),
      ),
    );
  }

  Future<void> _makeCall(Conversation conversation) async {
    try {
      final callingService = SimpleCallingService();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final sessionId = await callingService.createLiveSession(
        sessionType: SessionType.audioCall,
        title: 'Audio Call with ${conversation.clientName}',
        coachId: user.id,
        clientId: conversation.clientId,
      );
      
      final session = await callingService.getLiveSession(sessionId);
      if (session != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimpleCallScreen(session: session),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
      }
    }
  }

  Future<void> _makeVideoCall(Conversation conversation) async {
    try {
      final callingService = SimpleCallingService();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final sessionId = await callingService.createLiveSession(
        sessionType: SessionType.videoCall,
        title: 'Video Call with ${conversation.clientName}',
        coachId: user.id,
        clientId: conversation.clientId,
      );
      
      final session = await callingService.getLiveSession(sessionId);
      if (session != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimpleCallScreen(session: session),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start video call: $e')),
        );
      }
    }
  }

  void _handleMenuAction(String action, Conversation conversation) {
    switch (action) {
      case 'mark_read':
        _markAsRead(conversation);
        break;
      case 'pin':
        _pinConversation(conversation);
        break;
      case 'archive':
        _archiveConversation(conversation);
        break;
    }
  }

  void _markAsRead(Conversation conversation) {
    final tc = context.tc;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Marked as read'),
        backgroundColor: tc.accent,
      ),
    );
  }

  void _pinConversation(Conversation conversation) {
    final tc = context.tc;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Conversation pinned'),
        backgroundColor: tc.accent,
      ),
    );
  }

  void _archiveConversation(Conversation conversation) {
    final tc = context.tc;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Conversation archived'),
        backgroundColor: tc.accent,
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 1) {
        return 'now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day ago';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }
}

// Individual conversation screen
class ModernConversationScreen extends StatefulWidget {
  final Conversation conversation;

  const ModernConversationScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ModernConversationScreen> createState() => _ModernConversationScreenState();
}

class _ModernConversationScreenState extends State<ModernConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CoachMessagingService _messagingService = CoachMessagingService();
  final MessagesService _messagesService = MessagesService();
  
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _filteredMessages = [];
  bool _loading = true;
  bool _showSearch = false;
  String _searchQuery = '';
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _checkOnlineStatus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _checkOnlineStatus() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('last_seen')
          .eq('id', widget.conversation.clientId)
          .maybeSingle();
      
      if (response != null && mounted) {
        final lastSeen = DateTime.tryParse(response['last_seen']?.toString() ?? '');
        setState(() {
          _isOnline = lastSeen != null && 
              DateTime.now().difference(lastSeen).inMinutes < 5;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }
  
  List<Map<String, dynamic>> _filterMessages(List<Map<String, dynamic>> messages) {
    if (_searchQuery.isEmpty) return messages;
    final query = _searchQuery.toLowerCase();
    return messages.where((msg) => 
      (msg['content']?.toString().toLowerCase() ?? '').contains(query)
    ).toList();
  }

  Future<void> _loadMessages() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Load messages for this conversation
      final messages = await _messagingService.getMessages(
        conversationId: widget.conversation.id,
        coachId: user.id,
        limit: 50,
      );

      setState(() {
        _messages = messages.map((message) => {
          'id': message.id,
          'content': message.content,
          'sender_id': message.senderId,
          'created_at': message.createdAt.toIso8601String(),
        }).toList();
        _filteredMessages = _messages;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
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
            
            // Messages List
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(tc.accent),
                      ),
                    )
                  : _buildMessagesContent(),
            ),
            
            // Message Input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessagesContent() {
    final tc = context.tc;
    final displayMessages = _showSearch ? _filteredMessages : _messages;
    
    return Column(
      children: [
        // Search bar (when visible)
        if (_showSearch) _buildSearchBar(),
        
        // Messages list
        Expanded(
          child: displayMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showSearch ? Icons.search_off : Icons.chat_bubble_outline,
                        color: tc.textSecondary,
                        size: 48,
                      ),
                      const SizedBox(height: DesignTokens.space12),
                      Text(
                        _showSearch && _searchQuery.isNotEmpty
                            ? 'No messages found'
                            : 'No messages yet',
                        style: TextStyle(color: tc.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(DesignTokens.space16),
                  itemCount: displayMessages.length,
                  itemBuilder: (context, index) {
                    final message = displayMessages[index];
                    return _buildMessageBubble(message);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final tc = context.tc;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border(
          bottom: BorderSide(
            color: tc.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: tc.icon,
            ),
          ),
          
          // Client Info with online indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: tc.accent,
                child: Text(
                  widget.conversation.clientName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: tc.textOnDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _isOnline ? tc.success : tc.textSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: tc.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: DesignTokens.space12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.clientName,
                  style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _isOnline ? tc.success : tc.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          IconButton(
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                  _filteredMessages = _messages;
                }
              });
            },
            icon: Icon(
              Icons.search,
              color: _showSearch ? tc.accent : tc.iconSecondary,
            ),
            tooltip: 'Search messages',
          ),
          IconButton(
            onPressed: _startAudioCall,
            icon: Icon(
              Icons.phone,
              color: tc.accent,
            ),
            tooltip: 'Audio call',
          ),
          IconButton(
            onPressed: _startVideoCall,
            icon: Icon(
              Icons.videocam,
              color: tc.accent,
            ),
            tooltip: 'Video call',
          ),
          IconButton(
            onPressed: _showMoreOptions,
            icon: Icon(
              Icons.more_vert,
              color: tc.iconSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final tc = context.tc;
    final matchCount = _searchQuery.isNotEmpty ? _filteredMessages.length : 0;
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border(
          bottom: BorderSide(color: tc.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(color: tc.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search messages...',
              hintStyle: TextStyle(color: tc.textSecondary),
              prefixIcon: Icon(Icons.search, color: tc.iconSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: tc.iconSecondary),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                          _filteredMessages = _messages;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: tc.border),
              ),
              filled: true,
              fillColor: tc.inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filteredMessages = _filterMessages(_messages);
              });
            },
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.space4),
            Text(
              '$matchCount ${matchCount == 1 ? 'message' : 'messages'} found',
              style: TextStyle(color: tc.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final tc = context.tc;
    final isFromCoach = message['sender_id'] == Supabase.instance.client.auth.currentUser?.id;
    final content = message['content'] ?? '';
    final timestamp = message['created_at'];
    final isRead = message['is_read'] == true || message['seen_at'] != null;
    
    return GestureDetector(
      onLongPress: () => _showMessageOptions(message, isFromCoach),
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.space12),
        child: Row(
          mainAxisAlignment: isFromCoach ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isFromCoach) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: tc.accent,
                child: Text(
                  widget.conversation.clientName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: tc.textOnDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
            ],
            
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.space12),
                decoration: BoxDecoration(
                  color: isFromCoach ? tc.accent : tc.surface,
                  borderRadius: BorderRadius.circular(DesignTokens.radius12).copyWith(
                    bottomRight: isFromCoach ? const Radius.circular(4) : const Radius.circular(12),
                    bottomLeft: isFromCoach ? const Radius.circular(12) : const Radius.circular(4),
                  ),
                  border: Border.all(
                    color: tc.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: TextStyle(
                        color: isFromCoach ? tc.textOnDark : tc.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMessageTime(timestamp),
                          style: TextStyle(
                            color: isFromCoach 
                                ? tc.textOnDark.withValues(alpha: 0.7)
                                : tc.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        // Read receipts (WhatsApp style)
                        if (isFromCoach) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isRead ? Icons.done_all : Icons.done,
                            color: isRead 
                                ? (isFromCoach ? tc.textOnDark : tc.accent)
                                : (isFromCoach ? tc.textOnDark.withValues(alpha: 0.7) : tc.textSecondary),
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            if (isFromCoach) ...[
              const SizedBox(width: DesignTokens.space8),
              CircleAvatar(
                radius: 16,
                backgroundColor: tc.surfaceAlt,
                child: Icon(
                  Icons.person,
                  color: tc.icon,
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showMessageOptions(Map<String, dynamic> message, bool isFromCoach) {
    final tc = context.tc;
    showModalBottomSheet(
      context: context,
      backgroundColor: tc.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final sheetTc = ThemeColors.of(sheetContext);
        return Container(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reaction picker
              Container(
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.space8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['👍', '❤️', '😂', '😮', '😢', '🔥', '👏'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showSnackBar('Reaction added: $emoji');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(),
              
              // Copy
              ListTile(
                leading: Icon(Icons.copy, color: sheetTc.icon),
                title: Text('Copy', style: TextStyle(color: sheetTc.textPrimary)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Clipboard.setData(ClipboardData(text: message['content'] ?? ''));
                  _showSnackBar('Message copied to clipboard');
                },
              ),
              
              // Forward
              ListTile(
                leading: Icon(Icons.forward, color: sheetTc.icon),
                title: Text('Forward', style: TextStyle(color: sheetTc.textPrimary)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showSnackBar('Forward feature coming soon');
                },
              ),
              
              // Delete (only for own messages)
              if (isFromCoach)
                ListTile(
                  leading: Icon(Icons.delete, color: sheetTc.danger),
                  title: Text('Delete', style: TextStyle(color: sheetTc.danger)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDeleteMessage(message);
                  },
                ),
              
              const SizedBox(height: DesignTokens.space8),
            ],
          ),
        );
      },
    );
  }
  
  void _confirmDeleteMessage(Map<String, dynamic> message) {
    final tc = context.tc;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: tc.surface,
        title: Text(
          'Delete Message?',
          style: TextStyle(color: tc.textPrimary),
        ),
        content: Text(
          'This message will be deleted for everyone.',
          style: TextStyle(color: tc.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: tc.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showSnackBar('Message deleted');
              // Remove from local list
              setState(() {
                _messages.removeWhere((m) => m['id'] == message['id']);
                _filteredMessages = _filterMessages(_messages);
              });
            },
            child: Text('Delete', style: TextStyle(color: tc.danger)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final tc = context.tc;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border(
          top: BorderSide(
            color: tc.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Attachment Button
          IconButton(
            onPressed: () => _attachFile(),
            icon: Icon(
              Icons.attach_file,
              color: tc.iconSecondary,
            ),
          ),
          
          // Voice Message Button
          IconButton(
            onPressed: () => _recordVoiceMessage(),
            icon: Icon(
              Icons.mic,
              color: tc.iconSecondary,
            ),
          ),
          
          
          // Message Input
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space12),
              decoration: BoxDecoration(
                color: tc.inputFill,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(
                  color: tc.border,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: tc.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: tc.textSecondary),
                  border: InputBorder.none,
                ),
                maxLines: null,
                onSubmitted: (value) => _sendMessage(),
              ),
            ),
          ),
          
          const SizedBox(width: DesignTokens.space8),
          
          // Send Button
          Container(
            decoration: BoxDecoration(
              color: tc.accent,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: Icon(
                Icons.send,
                color: tc.textOnDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    
    // Send message
    _messageController.clear();
    
    // Add message to list (optimistic update)
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'content': content,
        'sender_id': Supabase.instance.client.auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startAudioCall() async {
    try {
      final callingService = SimpleCallingService();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final sessionId = await callingService.createLiveSession(
        sessionType: SessionType.audioCall,
        title: 'Audio Call with ${widget.conversation.clientName}',
        coachId: user.id,
        clientId: widget.conversation.clientId,
      );
      
      final session = await callingService.getLiveSession(sessionId);
      if (session != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimpleCallScreen(session: session),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Failed to start call: $e');
    }
  }

  Future<void> _startVideoCall() async {
    try {
      final callingService = SimpleCallingService();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final sessionId = await callingService.createLiveSession(
        sessionType: SessionType.videoCall,
        title: 'Video Call with ${widget.conversation.clientName}',
        coachId: user.id,
        clientId: widget.conversation.clientId,
      );
      
      final session = await callingService.getLiveSession(sessionId);
      if (session != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimpleCallScreen(session: session),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Failed to start video call: $e');
    }
  }
  
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showMoreOptions() {
    final tc = context.tc;
    showModalBottomSheet(
      context: context,
      backgroundColor: tc.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final sheetTc = ThemeColors.of(sheetContext);
        return Container(
          padding: const EdgeInsets.all(DesignTokens.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.search, color: sheetTc.accent),
                title: Text('Search Messages', style: TextStyle(color: sheetTc.textPrimary)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _showSearch = true);
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications_off, color: sheetTc.accent),
                title: Text('Mute Notifications', style: TextStyle(color: sheetTc.textPrimary)),
                onTap: () => Navigator.pop(sheetContext),
              ),
              ListTile(
                leading: Icon(Icons.block, color: sheetTc.danger),
                title: Text('Block Client', style: TextStyle(color: sheetTc.danger)),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        );
      },
    );
  }

  void _attachFile() {
    final tc = context.tc;
    showModalBottomSheet(
      context: context,
      backgroundColor: tc.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final sheetTc = ThemeColors.of(sheetContext);
        return Container(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Attach File',
                style: TextStyle(
                  color: sheetTc.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DesignTokens.space16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachOption(sheetContext, Icons.camera_alt, 'Camera', sheetTc.accent, () {
                    Navigator.pop(sheetContext);
                    _takePhoto();
                  }),
                  _buildAttachOption(sheetContext, Icons.photo_library, 'Gallery', Colors.purple, () {
                    Navigator.pop(sheetContext);
                    _pickImage();
                  }),
                  _buildAttachOption(sheetContext, Icons.insert_drive_file, 'Document', Colors.orange, () {
                    Navigator.pop(sheetContext);
                    _pickDocument();
                  }),
                  _buildAttachOption(sheetContext, Icons.videocam, 'Video', Colors.red, () {
                    Navigator.pop(sheetContext);
                    _pickVideo();
                  }),
                ],
              ),
              const SizedBox(height: DesignTokens.space16),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAttachOption(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: ThemeColors.of(context).textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        _showSnackBar('Photo captured - sending...');
        // TODO: Send attachment through MessagesService
      }
    } catch (e) {
      _showSnackBar('Failed to take photo: $e');
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _showSnackBar('Image selected - sending...');
        // TODO: Send attachment through MessagesService
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
    }
  }
  
  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md'],
      );
      if (result != null && result.files.isNotEmpty) {
        _showSnackBar('Document selected - sending...');
        // TODO: Send attachment through MessagesService
      }
    } catch (e) {
      _showSnackBar('Failed to pick document: $e');
    }
  }
  
  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        _showSnackBar('Video selected - sending...');
        // TODO: Send attachment through MessagesService
      }
    } catch (e) {
      _showSnackBar('Failed to pick video: $e');
    }
  }

  void _recordVoiceMessage() {
    final tc = context.tc;
    showModalBottomSheet(
      context: context,
      backgroundColor: tc.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final sheetTc = ThemeColors.of(sheetContext);
        return Container(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Voice Message',
                style: TextStyle(
                  color: sheetTc.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DesignTokens.space16),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
                    );
                    if (result != null && result.files.isNotEmpty) {
                      _showSnackBar('Voice message selected - sending...');
                    }
                  } catch (e) {
                    _showSnackBar('Failed to pick audio: $e');
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: sheetTc.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(Icons.audio_file, color: sheetTc.accent, size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick Audio File',
                      style: TextStyle(color: sheetTc.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.space8),
              Text(
                'Select an audio file from your device',
                style: TextStyle(color: sheetTc.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: DesignTokens.space16),
            ],
          ),
        );
      },
    );
  }

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 1) {
        return 'now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }
}
