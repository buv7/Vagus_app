import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/navigation/vagus_side_menu.dart';
import '../../services/messages_service.dart';

class ModernMessengerScreen extends StatefulWidget {
  const ModernMessengerScreen({super.key});

  @override
  State<ModernMessengerScreen> createState() => _ModernMessengerScreenState();
}

class _ModernMessengerScreenState extends State<ModernMessengerScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagesService _messagesService = MessagesService();
  bool _isTyping = false;
  bool _showSearch = false;
  bool _showSmartReplies = true;
  bool _showPinnedMessages = false;

  // Real data from Supabase
  List<Message> _messages = [];
  List<Message> _pinnedMessages = [];
  bool _isLoading = true;
  String? _error;
  String _role = 'client';
  String? _threadId;
  String? _coachId;
  StreamSubscription? _messagesSubscription;

  // Mock data as fallback
  final List<Map<String, dynamic>> _mockMessages = [
    {
      'id': '1',
      'content': 'Great job on today\'s workout! Your form on the squats was perfect. Keep up the excellent work!',
      'sender': 'coach',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'type': 'text',
      'isRead': true,
      'reactions': ['💪', '🔥'],
    },
    {
      'id': '2',
      'content': 'Thank you! I felt really strong today. Should I increase the weight next session?',
      'sender': 'user',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 50)),
      'type': 'text',
      'isRead': true,
    },
    {
      'id': '3',
      'content': 'Yes, let\'s bump up the weight by 5lbs. Your progression has been fantastic this month.',
      'sender': 'coach',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'type': 'text',
      'isRead': true,
      'isPinned': true,
    },
    {
      'id': '4',
      'content': 'Perfect! Also, I took some progress photos today. The difference is amazing!',
      'sender': 'user',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
      'type': 'text',
      'isRead': true,
      'attachments': [
        {'type': 'image', 'url': '/progress-photo.jpg'}
      ],
    },
  ];

  final List<String> _smartReplies = [
    'Thanks for the feedback!',
    'I\'ll work on that',
    'Great session today',
    'Need help with form',
    'Feeling strong today',
  ];


  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get user role
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      _role = (profile['role'] ?? 'client').toString();

      // For clients, find their coach and ensure thread exists
      if (_role == 'client') {
        _coachId = await _getCoachId(user.id);
        if (_coachId == null) {
          setState(() {
            _isLoading = false;
            _error = 'No coach connected. Please connect with a coach first.';
          });
          return;
        }
        
        _threadId = await _messagesService.ensureThread(
          coachId: _coachId!,
          clientId: user.id,
        );
      }

      if (_threadId != null) {
        // Set up real-time subscription for messages in this thread
        _messagesSubscription = _messagesService.subscribeMessages(_threadId!).listen((messages) {
          if (mounted) {
            setState(() {
              _messages = messages;
              _pinnedMessages = messages.where((msg) => msg.reactions.containsKey('pinned')).toList();
            });
          }
        });
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          // Use mock data as fallback
          _messages = _mockMessages.map((mock) => Message(
            id: mock['id'] ?? 'mock_${DateTime.now().millisecondsSinceEpoch}',
            threadId: 'mock_thread',
            senderId: mock['sender'] == 'user' ? 'user_id' : 'coach_id',
            text: mock['content'] ?? '',
            attachments: [],
            reactions: Map<String, String>.from(mock['reactions'] ?? {}),
            createdAt: mock['timestamp'] ?? DateTime.now(),
          )).toList();
          _pinnedMessages = _messages.where((msg) => msg.reactions.containsKey('pinned')).toList();
        });
      }
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _threadId == null) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      // Send message using MessagesService
      await _messagesService.sendText(
        threadId: _threadId!,
        text: content,
      );

      setState(() {
        _showSmartReplies = false;
      });

      _scrollToBottom();
      
      // Simulate coach typing
      _simulateCoachTyping();
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _simulateCoachTyping() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isTyping = true;
        });
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _showSmartReplies = true;
        });
      }
    });
  }

  void _scrollToBottom() {
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

  void _addReaction(String messageId, String reaction) {
    _messagesService.addReaction(messageId, reaction);
  }

  void _togglePin(String messageId) {
    final message = _messages.firstWhere((msg) => msg.id == messageId);
    final isPinned = message.reactions.containsKey('pinned');
    if (isPinned) {
      _messagesService.removeReaction(messageId);
    } else {
      _messagesService.addReaction(messageId, 'pinned');
    }
  }

  void _selectSmartReply(String reply) {
    _messageController.text = reply;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.primaryDark,
      drawerEdgeDragWidth: 24,
      drawer: const VagusSideMenu(isClient: true),
      body: Container(
        decoration: const BoxDecoration(
          gradient: DesignTokens.darkGradient,
        ),
        child: SafeArea(
          child: _isLoading 
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentGreen,
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        Text(
                          'Error loading messages',
                          style: DesignTokens.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space8),
                        Text(
                          _error!,
                          style: DesignTokens.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        ElevatedButton(
                          onPressed: _loadMessages,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            foregroundColor: AppTheme.primaryDark,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Header with hamburger menu
                      _buildHeader(),
                      
                      // Search Bar
                      if (_showSearch) _buildSearchBar(),
                      
                      // Pinned Messages Panel
            if (_showPinnedMessages) _buildPinnedMessagesPanel(),
            
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(DesignTokens.space16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
            
            // Smart Replies
            if (_showSmartReplies) _buildSmartRepliesPanel(),
            
            // Message Composer
            _buildMessageComposer(),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Hamburger menu
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          
          // Coach Avatar
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.accentGreen,
            child: Text(
              'JD',
              style: TextStyle(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          
          // Coach Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coach Jordan',
                  style: DesignTokens.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isTyping)
                  Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTypingDot(0),
                            _buildTypingDot(1),
                            _buildTypingDot(2),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'typing...',
                        style: DesignTokens.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Action Buttons
          Row(
            children: [
              IconButton(
                onPressed: () {
                  // Schedule call functionality
                },
                icon: const Icon(Icons.phone, color: AppTheme.accentGreen),
              ),
              IconButton(
                onPressed: () {
                  // Video call functionality
                },
                icon: const Icon(Icons.videocam, color: AppTheme.accentGreen),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                  });
                },
                icon: Icon(
                  Icons.search,
                  color: _showSearch ? AppTheme.accentGreen : Colors.white70,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showPinnedMessages = !_showPinnedMessages;
                  });
                },
                icon: Icon(
                  Icons.push_pin,
                  color: _showPinnedMessages ? AppTheme.accentGreen : Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search messages...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppTheme.accentGreen,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppTheme.primaryDark.withValues(alpha: 0.3),
        ),
        onChanged: (value) {
          setState(() {
          });
        },
      ),
    );
  }

  Widget _buildPinnedMessagesPanel() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.push_pin,
                    color: AppTheme.accentOrange,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pinned Messages',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showPinnedMessages = false;
                  });
                },
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space8),
          ..._pinnedMessages.map((message) => _buildPinnedMessageCard(message)),
        ],
      ),
    );
  }

  Widget _buildPinnedMessageCard(Message message) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space8),
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.push_pin,
            color: AppTheme.accentOrange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.text,
              style: DesignTokens.bodySmall.copyWith(
                color: Colors.white70,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Attachment Button
          IconButton(
            onPressed: () {
              _showAttachmentMenu();
            },
            icon: const Icon(Icons.attach_file, color: AppTheme.accentGreen),
          ),
          
          // Voice Message Button
          IconButton(
            onPressed: () {
              // Voice message functionality
            },
            icon: const Icon(Icons.mic, color: AppTheme.accentGreen),
          ),
          
          // Message Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space16,
                    vertical: DesignTokens.space12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          
          // Send Button
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send, color: AppTheme.accentGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: AppTheme.accentGreen,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.accentGreen,
            child: Text(
              'JD',
              style: TextStyle(
                color: AppTheme.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space16,
              vertical: DesignTokens.space12,
            ),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final user = Supabase.instance.client.auth.currentUser;
    final isUser = message.senderId == user?.id;
    final isPinned = message.reactions.containsKey('pinned');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentGreen,
              child: Text(
                'JD',
                style: TextStyle(
                  color: AppTheme.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.space8),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space16,
                    vertical: DesignTokens.space12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.accentGreen : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    border: isPinned
                        ? Border.all(color: AppTheme.accentOrange, width: 2)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: DesignTokens.bodyMedium.copyWith(
                          color: isUser ? AppTheme.primaryDark : Colors.white,
                        ),
                      ),
                      if (message.attachments.isNotEmpty) ...[
                        const SizedBox(height: DesignTokens.space8),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image,
                            color: AppTheme.accentGreen,
                            size: 32,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Reactions
                if (message.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...message.reactions.values.map<Widget>((reaction) => Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryDark.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reaction,
                            style: const TextStyle(fontSize: 12),
                          ),
                        )),
                      ],
                    ),
                  ),
                
                // Timestamp and Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: DesignTokens.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    if (isPinned) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.push_pin,
                        color: AppTheme.accentOrange,
                        size: 12,
                      ),
                    ],
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 16,
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'react':
                            _addReaction(message.id, '👍');
                            break;
                          case 'pin':
                            _togglePin(message.id);
                            break;
                          case 'copy':
                            // Copy message functionality
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'react',
                          child: Text('Add Reaction'),
                        ),
                        const PopupMenuItem(
                          value: 'pin',
                          child: Text('Pin Message'),
                        ),
                        const PopupMenuItem(
                          value: 'copy',
                          child: Text('Copy'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: DesignTokens.space8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryDark,
              child: Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmartRepliesPanel() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Replies',
                style: DesignTokens.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSmartReplies = false;
                  });
                },
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space8),
          Wrap(
            spacing: DesignTokens.space8,
            runSpacing: DesignTokens.space8,
            children: _smartReplies.map((reply) => InkWell(
              onTap: () => _selectSmartReply(reply),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space12,
                  vertical: DesignTokens.space8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  reply,
                  style: DesignTokens.bodySmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Attach File',
              style: DesignTokens.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(Icons.camera_alt, 'Camera'),
                _buildAttachmentOption(Icons.photo_library, 'Gallery'),
                _buildAttachmentOption(Icons.insert_drive_file, 'Document'),
                _buildAttachmentOption(Icons.videocam, 'Video'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.primaryDark.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(
            icon,
            color: AppTheme.accentGreen,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: DesignTokens.bodySmall.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

}
