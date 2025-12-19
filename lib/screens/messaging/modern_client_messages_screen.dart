import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../services/coach/coach_messaging_service.dart';

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
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
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
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Row(
        children: [
          // Title with icon
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: AppTheme.accentGreen,
                size: 24,
              ),
              const SizedBox(width: DesignTokens.space8),
              const Text(
                'Client Messages', // Fixed Service Integration
                style: TextStyle(
                  color: AppTheme.neutralWhite,
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
                    color: DesignTokens.danger,
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  ),
                  child: Text(
                    '$_totalUnreadCount',
                    style: const TextStyle(
                      color: AppTheme.neutralWhite,
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
            icon: const Icon(
              Icons.search,
              color: AppTheme.lightGrey,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    if (_searchQuery.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: AppTheme.mediumGrey,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppTheme.neutralWhite),
        decoration: const InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: TextStyle(color: AppTheme.lightGrey),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.lightGrey,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: AppTheme.lightGrey,
            size: 64,
          ),
          SizedBox(height: DesignTokens.space16),
          Text(
            'No client conversations yet',
            style: TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: DesignTokens.space8),
          Text(
            'Clients will appear here when they connect',
            style: TextStyle(
              color: AppTheme.lightGrey,
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
    final clientName = conversation.clientName;
    final lastMessage = conversation.lastMessage ?? '';
    final timestamp = conversation.lastMessageAt;
    final unreadCount = conversation.unreadCount;
    final isOnline = conversation.isOnline;
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: AppTheme.mediumGrey,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DesignTokens.space16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.accentGreen,
              child: Text(
                clientName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryDark,
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
                    color: DesignTokens.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryDark,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          clientName,
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          lastMessage,
          style: const TextStyle(
            color: AppTheme.lightGrey,
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
              icon: const Icon(
                Icons.phone,
                color: AppTheme.lightGrey,
                size: 20,
              ),
            ),
            IconButton(
              onPressed: () => _makeVideoCall(conversation),
              icon: const Icon(
                Icons.videocam,
                color: AppTheme.lightGrey,
                size: 20,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: AppTheme.lightGrey,
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
                  style: const TextStyle(
                    color: AppTheme.lightGrey,
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
                      color: DesignTokens.danger,
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
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

  void _makeCall(Conversation conversation) {
    // Implement call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${conversation.clientName}...'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _makeVideoCall(Conversation conversation) {
    // Implement video call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Video calling ${conversation.clientName}...'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
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
    // Implement mark as read functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked as read'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _pinConversation(Conversation conversation) {
    // Implement pin conversation functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation pinned'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _archiveConversation(Conversation conversation) {
    // Implement archive conversation functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation archived'),
        backgroundColor: AppTheme.accentGreen,
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
  final ScrollController _scrollController = ScrollController();
  final CoachMessagingService _messagingService = CoachMessagingService();
  
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                      ),
                    )
                  : _buildMessagesList(),
            ),
            
            // Message Input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.mediumGrey,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: AppTheme.neutralWhite,
            ),
          ),
          
          // Client Info
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.accentGreen,
            child: Text(
              widget.conversation.clientName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(width: DesignTokens.space12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.clientName,
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: DesignTokens.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space4),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Buttons
          IconButton(
            onPressed: () => setState(() => _showSearch = !_showSearch),
            icon: const Icon(
              Icons.search,
              color: AppTheme.lightGrey,
            ),
          ),
          IconButton(
            onPressed: () => _makeCall(),
            icon: const Icon(
              Icons.phone,
              color: AppTheme.lightGrey,
            ),
          ),
          IconButton(
            onPressed: () => _makeVideoCall(),
            icon: const Icon(
              Icons.videocam,
              color: AppTheme.lightGrey,
            ),
          ),
          IconButton(
            onPressed: () => _showMoreOptions(),
            icon: const Icon(
              Icons.more_vert,
              color: AppTheme.lightGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(DesignTokens.space16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isFromCoach = message['sender_id'] == Supabase.instance.client.auth.currentUser?.id;
    final content = message['content'] ?? '';
    final timestamp = message['created_at'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      child: Row(
        mainAxisAlignment: isFromCoach ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromCoach) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentGreen,
            child: Text(
              widget.conversation.clientName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryDark,
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
                color: isFromCoach ? AppTheme.accentGreen : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: isFromCoach ? null : Border.all(
                  color: AppTheme.mediumGrey,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      color: isFromCoach ? AppTheme.primaryDark : AppTheme.neutralWhite,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  Text(
                    _formatMessageTime(timestamp),
                    style: TextStyle(
                      color: isFromCoach 
                          ? AppTheme.primaryDark.withValues(alpha: 0.7)
                          : AppTheme.lightGrey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isFromCoach) ...[
            const SizedBox(width: DesignTokens.space8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.mediumGrey,
              child: Icon(
                Icons.person,
                color: AppTheme.neutralWhite,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(
            color: AppTheme.mediumGrey,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Attachment Button
          IconButton(
            onPressed: () => _attachFile(),
            icon: const Icon(
              Icons.attach_file,
              color: AppTheme.lightGrey,
            ),
          ),
          
          // Voice Message Button
          IconButton(
            onPressed: () => _recordVoiceMessage(),
            icon: const Icon(
              Icons.mic,
              color: AppTheme.lightGrey,
            ),
          ),
          
          
          // Message Input
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space12),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(
                  color: AppTheme.mediumGrey,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppTheme.neutralWhite),
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: AppTheme.lightGrey),
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
            decoration: const BoxDecoration(
              color: AppTheme.accentGreen,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.send,
                color: AppTheme.primaryDark,
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

  void _makeCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${widget.conversation.clientName}...'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _makeVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Video calling ${widget.conversation.clientName}...'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignTokens.space20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search, color: AppTheme.accentGreen),
              title: const Text('Search Messages', style: TextStyle(color: AppTheme.neutralWhite)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _showSearch = true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off, color: AppTheme.accentGreen),
              title: const Text('Mute Notifications', style: TextStyle(color: AppTheme.neutralWhite)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block, color: DesignTokens.danger),
              title: const Text('Block Client', style: TextStyle(color: DesignTokens.danger)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _attachFile() {
    // Implement file attachment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File attachment feature coming soon'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _recordVoiceMessage() {
    // Implement voice message recording
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice message feature coming soon'),
        backgroundColor: AppTheme.accentGreen,
      ),
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
