import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/design_tokens.dart';
import '../../theme/theme_colors.dart';
import '../../services/messages_service.dart';
import '../../services/simple_calling_service.dart';
import '../../models/live_session.dart';
import '../calling/simple_call_screen.dart';

class ModernMessengerScreen extends StatefulWidget {
  const ModernMessengerScreen({super.key});

  @override
  State<ModernMessengerScreen> createState() => _ModernMessengerScreenState();
}

class _ModernMessengerScreenState extends State<ModernMessengerScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagesService _messagesService = MessagesService();
  final SimpleCallingService _callingService = SimpleCallingService();
  bool _isTyping = false;
  bool _showSearch = false;
  bool _showSmartReplies = true;
  bool _showPinnedMessages = false;
  bool _isRecording = false;
  bool _isOnline = true;
  String _searchQuery = '';

  // Real data from Supabase
  List<Message> _messages = [];
  List<Message> _pinnedMessages = [];
  List<Message> _filteredMessages = [];
  bool _isLoading = true;
  String? _error;
  String _role = 'client';
  String? _threadId;
  String? _coachId;
  String? _coachName;
  String? _coachAvatar;
  StreamSubscription? _messagesSubscription;
  Timer? _onlineStatusTimer;

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
    _startOnlineStatusCheck();
  }

  @override
  void dispose() {
    // Restore system UI when leaving messenger screen
    _restoreSystemUI();
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    _onlineStatusTimer?.cancel();
    _callingService.dispose();
    super.dispose();
  }
  
  void _startOnlineStatusCheck() {
    // Check online status every 30 seconds
    _onlineStatusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkOnlineStatus();
    });
  }
  
  Future<void> _checkOnlineStatus() async {
    if (_coachId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('last_seen')
          .eq('id', _coachId!)
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

  @override
  void deactivate() {
    // Safety net: Restore UI even if dispose isn't called properly
    _restoreSystemUI();
    super.deactivate();
  }

  /// Restore system UI to show navigation bar and status bar
  void _restoreSystemUI() {
    try {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values, // Show all system overlays
      );
    } catch (e) {
      debugPrint('❌ Failed to restore system UI: $e');
    }
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
        
        // Load coach info
        await _loadCoachInfo();
        
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
              _filteredMessages = _searchQuery.isEmpty ? messages : _filterMessages(messages);
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
          _filteredMessages = _messages;
          _pinnedMessages = _messages.where((msg) => msg.reactions.containsKey('pinned')).toList();
        });
      }
    }
  }
  
  Future<void> _loadCoachInfo() async {
    if (_coachId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name, avatar_url, last_seen')
          .eq('id', _coachId!)
          .maybeSingle();
      
      if (response != null && mounted) {
        final lastSeen = DateTime.tryParse(response['last_seen']?.toString() ?? '');
        setState(() {
          _coachName = response['full_name'] as String? ?? 'Coach';
          _coachAvatar = response['avatar_url'] as String?;
          _isOnline = lastSeen != null && 
              DateTime.now().difference(lastSeen).inMinutes < 5;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }
  
  List<Message> _filterMessages(List<Message> messages) {
    if (_searchQuery.isEmpty) return messages;
    final query = _searchQuery.toLowerCase();
    return messages.where((msg) => 
      msg.text.toLowerCase().contains(query)
    ).toList();
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
  
  // ===== CALL FUNCTIONALITY =====
  
  Future<void> _startAudioCall() async {
    if (_coachId == null) {
      _showSnackBar('No coach connected');
      return;
    }
    
    try {
      final sessionId = await _callingService.createLiveSession(
        sessionType: SessionType.audioCall,
        title: 'Audio Call with ${_coachName ?? 'Coach'}',
        clientId: Supabase.instance.client.auth.currentUser?.id,
        coachId: _coachId,
      );
      
      final session = await _callingService.getLiveSession(sessionId);
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
    if (_coachId == null) {
      _showSnackBar('No coach connected');
      return;
    }
    
    try {
      final sessionId = await _callingService.createLiveSession(
        sessionType: SessionType.videoCall,
        title: 'Video Call with ${_coachName ?? 'Coach'}',
        clientId: Supabase.instance.client.auth.currentUser?.id,
        coachId: _coachId,
      );
      
      final session = await _callingService.getLiveSession(sessionId);
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
  
  // ===== ATTACHMENT FUNCTIONALITY =====
  
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null && _threadId != null) {
        final file = File(pickedFile.path);
        await _messagesService.sendAttachment(
          threadId: _threadId!,
          file: file,
        );
        _showSnackBar('Image sent');
      }
    } catch (e) {
      _showSnackBar('Failed to send image: $e');
    }
  }
  
  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (pickedFile != null && _threadId != null) {
        final file = File(pickedFile.path);
        await _messagesService.sendAttachment(
          threadId: _threadId!,
          file: file,
        );
        _showSnackBar('Video sent');
      }
    } catch (e) {
      _showSnackBar('Failed to send video: $e');
    }
  }
  
  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md', 'json'],
      );
      
      if (result != null && result.files.isNotEmpty && _threadId != null) {
        final file = File(result.files.first.path!);
        await _messagesService.sendAttachment(
          threadId: _threadId!,
          file: file,
        );
        _showSnackBar('Document sent');
      }
    } catch (e) {
      _showSnackBar('Failed to send document: $e');
    }
  }
  
  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null && _threadId != null) {
        final file = File(pickedFile.path);
        await _messagesService.sendAttachment(
          threadId: _threadId!,
          file: file,
        );
        _showSnackBar('Photo sent');
      }
    } catch (e) {
      _showSnackBar('Failed to send photo: $e');
    }
  }
  
  // ===== VOICE MESSAGE FUNCTIONALITY =====
  
  Future<void> _pickVoiceMessage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
      );
      
      if (result != null && result.files.isNotEmpty && _threadId != null) {
        final file = File(result.files.first.path!);
        await _messagesService.sendVoice(
          threadId: _threadId!,
          audioFile: file,
        );
        _showSnackBar('Voice message sent');
      }
    } catch (e) {
      _showSnackBar('Failed to send voice message: $e');
    }
  }
  
  // ===== MESSAGE ACTIONS =====
  
  Future<void> _deleteMessage(String messageId) async {
    try {
      await _messagesService.deleteMessage(messageId);
      _showSnackBar('Message deleted');
    } catch (e) {
      _showSnackBar('Failed to delete message: $e');
    }
  }
  
  void _copyMessage(String messageId) {
    final message = _messages.firstWhere((m) => m.id == messageId);
    Clipboard.setData(ClipboardData(text: message.text));
    _showSnackBar('Message copied to clipboard');
  }
  
  Future<void> _forwardMessage(String messageId) async {
    // Show dialog to select thread to forward to
    _showSnackBar('Forward feature coming soon');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tc = context.tc;
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? DesignTokens.darkGradient : LinearGradient(
            colors: [theme.scaffoldBackgroundColor, theme.scaffoldBackgroundColor],
          ),
        ),
        child: SafeArea(
          child: _isLoading 
            ? Center(
                child: CircularProgressIndicator(
                  color: tc.accent,
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: tc.danger,
                          size: 48,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        Text(
                          'Error loading messages',
                          style: DesignTokens.titleMedium.copyWith(
                            color: tc.textPrimary,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space8),
                        Text(
                          _error!,
                          style: DesignTokens.bodyMedium.copyWith(
                            color: tc.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        ElevatedButton(
                          onPressed: _loadMessages,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tc.accent,
                            foregroundColor: tc.textOnDark,
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
                itemCount: (_showSearch ? _filteredMessages : _messages).length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  final displayMessages = _showSearch ? _filteredMessages : _messages;
                  if (index == displayMessages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  
                  final message = displayMessages[index];
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
    final tc = context.tc;
    final coachInitials = (_coachName ?? 'Coach').split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border(
          bottom: BorderSide(
            color: tc.border,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button instead of hamburger menu (drawer accessible via swipe)
          IconButton(
            icon: Icon(Icons.arrow_back, color: tc.icon),
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          // Coach Avatar with online indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: tc.accent,
                backgroundImage: _coachAvatar != null ? NetworkImage(_coachAvatar!) : null,
                child: _coachAvatar == null ? Text(
                  coachInitials,
                  style: TextStyle(
                    color: tc.textOnDark,
                    fontWeight: FontWeight.bold,
                  ),
                ) : null,
              ),
              // Online indicator
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
          
          // Coach Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _coachName ?? 'Coach',
                  style: DesignTokens.titleMedium.copyWith(
                    color: tc.textPrimary,
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
                          color: tc.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: DesignTokens.bodySmall.copyWith(
                      color: _isOnline ? tc.success : tc.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          
          // Action Buttons
          Row(
            children: [
              IconButton(
                onPressed: _startAudioCall,
                icon: Icon(Icons.phone, color: tc.accent),
                tooltip: 'Audio call',
              ),
              IconButton(
                onPressed: _startVideoCall,
                icon: Icon(Icons.videocam, color: tc.accent),
                tooltip: 'Video call',
              ),
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
                onPressed: () {
                  setState(() {
                    _showPinnedMessages = !_showPinnedMessages;
                  });
                },
                icon: Icon(
                  Icons.push_pin,
                  color: _showPinnedMessages ? tc.accent : tc.iconSecondary,
                ),
                tooltip: 'Pinned messages',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final tc = context.tc;
    final matchCount = _searchQuery.isNotEmpty ? _filteredMessages.length : 0;
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border(
          bottom: BorderSide(
            color: tc.border,
          ),
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
              prefixIcon: Icon(
                Icons.search,
                color: tc.iconSecondary,
              ),
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
                borderSide: BorderSide(
                  color: tc.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: tc.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: tc.accent,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: tc.inputFill,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filteredMessages = _filterMessages(_messages);
              });
            },
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.space8),
            Text(
              '$matchCount ${matchCount == 1 ? 'message' : 'messages'} found',
              style: DesignTokens.bodySmall.copyWith(
                color: tc.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPinnedMessagesPanel() {
    final tc = context.tc;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border(
          bottom: BorderSide(
            color: tc.border,
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
                  Icon(
                    Icons.push_pin,
                    color: tc.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pinned Messages',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: tc.textPrimary,
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
                icon: Icon(Icons.close, color: tc.iconSecondary, size: 20),
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
    final tc = context.tc;
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space8),
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: tc.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tc.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.push_pin,
            color: tc.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.text,
              style: DesignTokens.bodySmall.copyWith(
                color: tc.textSecondary,
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
    final tc = context.tc;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border(
          top: BorderSide(
            color: tc.border,
          ),
        ),
      ),
      child: Row(
        children: [
          // Attachment Button
          IconButton(
            onPressed: _showAttachmentMenu,
            icon: Icon(Icons.attach_file, color: tc.accent),
            tooltip: 'Attach file',
          ),
          
          // Voice Message Button
          IconButton(
            onPressed: _showVoiceOptions,
            icon: Icon(Icons.mic, color: _isRecording ? tc.danger : tc.accent),
            tooltip: 'Voice message',
          ),
          
          // Message Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: tc.inputFill,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: tc.border,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: tc.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: tc.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space16,
                    vertical: DesignTokens.space12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                onChanged: (value) {
                  // Set typing indicator
                  if (_threadId != null && value.isNotEmpty) {
                    _messagesService.setTyping(_threadId!, true);
                  }
                },
              ),
            ),
          ),
          
          // Send Button
          IconButton(
            onPressed: _sendMessage,
            icon: Icon(Icons.send, color: tc.accent),
            tooltip: 'Send message',
          ),
        ],
      ),
    );
  }
  
  void _showVoiceOptions() {
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
                style: DesignTokens.titleMedium.copyWith(
                  color: sheetTc.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DesignTokens.space16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildVoiceOption(
                    sheetContext,
                    Icons.audio_file,
                    'Pick Audio',
                    sheetTc.accent,
                    () {
                      Navigator.pop(sheetContext);
                      _pickVoiceMessage();
                    },
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
                child: Text(
                  'Select an audio file from your device to send as a voice message',
                  style: DesignTokens.bodySmall.copyWith(
                    color: sheetTc.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: DesignTokens.space16),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildVoiceOption(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
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
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: DesignTokens.bodySmall.copyWith(
              color: ThemeColors.of(context).textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    final tc = context.tc;
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: tc.accent,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final tc = context.tc;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: tc.accent,
            child: Text(
              'JD',
              style: TextStyle(
                color: tc.textOnDark,
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
              color: tc.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tc.border),
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
    final tc = context.tc;
    final user = Supabase.instance.client.auth.currentUser;
    final isUser = message.senderId == user?.id;
    final isPinned = message.reactions.containsKey('pinned');
    final isRead = message.seenAt != null;
    final coachInitials = (_coachName ?? 'Coach').split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: tc.accent,
              backgroundImage: _coachAvatar != null ? NetworkImage(_coachAvatar!) : null,
              child: _coachAvatar == null ? Text(
                coachInitials,
                style: TextStyle(
                  color: tc.textOnDark,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ) : null,
            ),
            const SizedBox(width: DesignTokens.space8),
          ],
          
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
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
                      color: isUser ? tc.accent : tc.surface,
                      borderRadius: BorderRadius.circular(18).copyWith(
                        bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                      ),
                      border: isPinned
                          ? Border.all(color: tc.warning, width: 2)
                          : Border.all(color: tc.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.text.isNotEmpty)
                          Text(
                            message.text,
                            style: DesignTokens.bodyMedium.copyWith(
                              color: isUser ? tc.textOnDark : tc.textPrimary,
                            ),
                          ),
                        if (message.attachments.isNotEmpty) ...[
                          if (message.text.isNotEmpty) const SizedBox(height: DesignTokens.space8),
                          _buildAttachmentPreview(message.attachments.first, isUser),
                        ],
                      ],
                    ),
                  ),
                  
                  // Reactions
                  if (message.reactions.isNotEmpty && !message.reactions.containsKey('pinned'))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: GestureDetector(
                        onTap: () => _showReactionPicker(message.id),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...message.reactions.entries.where((e) => e.key != 'pinned').map<Widget>((entry) => Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tc.surfaceAlt,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: tc.border),
                              ),
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 12),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                  
                  // Timestamp and Read Receipts
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: DesignTokens.bodySmall.copyWith(
                            color: tc.textSecondary,
                          ),
                        ),
                        if (isPinned) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.push_pin,
                            color: tc.warning,
                            size: 12,
                          ),
                        ],
                        // Read receipts (WhatsApp style double check)
                        if (isUser) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isRead ? Icons.done_all : Icons.done,
                            color: isRead ? tc.accent : tc.textSecondary,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: DesignTokens.space8),
            CircleAvatar(
              radius: 16,
              backgroundColor: tc.surfaceAlt,
              child: Icon(
                Icons.person,
                color: tc.textPrimary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildAttachmentPreview(Map<String, dynamic> attachment, bool isUser) {
    final tc = context.tc;
    final mime = attachment['mime']?.toString() ?? '';
    final name = attachment['name']?.toString() ?? 'File';
    final url = attachment['url']?.toString();
    
    IconData icon;
    Color color;
    
    if (mime.startsWith('image/')) {
      icon = Icons.image;
      color = Colors.purple;
    } else if (mime.startsWith('video/')) {
      icon = Icons.videocam;
      color = Colors.red;
    } else if (mime.startsWith('audio/')) {
      icon = Icons.audiotrack;
      color = Colors.orange;
    } else if (mime == 'application/pdf') {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space8),
      decoration: BoxDecoration(
        color: isUser ? tc.textOnDark.withValues(alpha: 0.2) : tc.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: DesignTokens.space8),
          Flexible(
            child: Text(
              name,
              style: DesignTokens.bodySmall.copyWith(
                color: isUser ? tc.textOnDark : tc.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showMessageOptions(Message message) {
    final tc = context.tc;
    final user = Supabase.instance.client.auth.currentUser;
    final isUser = message.senderId == user?.id;
    
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
                        _addReaction(message.id, emoji);
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
                  _copyMessage(message.id);
                },
              ),
              
              // Pin/Unpin
              ListTile(
                leading: Icon(
                  message.reactions.containsKey('pinned') ? Icons.push_pin_outlined : Icons.push_pin,
                  color: sheetTc.icon,
                ),
                title: Text(
                  message.reactions.containsKey('pinned') ? 'Unpin' : 'Pin',
                  style: TextStyle(color: sheetTc.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _togglePin(message.id);
                },
              ),
              
              // Forward
              ListTile(
                leading: Icon(Icons.forward, color: sheetTc.icon),
                title: Text('Forward', style: TextStyle(color: sheetTc.textPrimary)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _forwardMessage(message.id);
                },
              ),
              
              // Delete (only for own messages)
              if (isUser)
                ListTile(
                  leading: Icon(Icons.delete, color: sheetTc.danger),
                  title: Text('Delete', style: TextStyle(color: sheetTc.danger)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDeleteMessage(message.id);
                  },
                ),
              
              const SizedBox(height: DesignTokens.space8),
            ],
          ),
        );
      },
    );
  }
  
  void _showReactionPicker(String messageId) {
    final tc = context.tc;
    showModalBottomSheet(
      context: context,
      backgroundColor: tc.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Reaction',
                style: DesignTokens.titleMedium.copyWith(
                  color: ThemeColors.of(sheetContext).textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DesignTokens.space16),
              Wrap(
                spacing: DesignTokens.space12,
                runSpacing: DesignTokens.space12,
                children: ['👍', '❤️', '😂', '😮', '😢', '🔥', '👏', '🎉', '💯', '🙏'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _addReaction(messageId, emoji);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeColors.of(sheetContext).surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: DesignTokens.space16),
            ],
          ),
        );
      },
    );
  }
  
  void _confirmDeleteMessage(String messageId) {
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
              _deleteMessage(messageId);
            },
            child: Text('Delete', style: TextStyle(color: tc.danger)),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartRepliesPanel() {
    final tc = context.tc;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border(
          top: BorderSide(
            color: tc.border,
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
                  color: tc.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSmartReplies = false;
                  });
                },
                icon: Icon(Icons.close, color: tc.iconSecondary, size: 20),
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
                  color: tc.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: tc.border,
                  ),
                ),
                child: Text(
                  reply,
                  style: DesignTokens.bodySmall.copyWith(
                    color: tc.textPrimary,
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
                style: DesignTokens.titleMedium.copyWith(
                  color: sheetTc.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DesignTokens.space16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    sheetContext, 
                    Icons.camera_alt, 
                    'Camera',
                    sheetTc.accent,
                    () {
                      Navigator.pop(sheetContext);
                      _takePhoto();
                    },
                  ),
                  _buildAttachmentOption(
                    sheetContext, 
                    Icons.photo_library, 
                    'Gallery',
                    Colors.purple,
                    () {
                      Navigator.pop(sheetContext);
                      _pickImage();
                    },
                  ),
                  _buildAttachmentOption(
                    sheetContext, 
                    Icons.insert_drive_file, 
                    'Document',
                    Colors.orange,
                    () {
                      Navigator.pop(sheetContext);
                      _pickDocument();
                    },
                  ),
                  _buildAttachmentOption(
                    sheetContext, 
                    Icons.videocam, 
                    'Video',
                    Colors.red,
                    () {
                      Navigator.pop(sheetContext);
                      _pickVideo();
                    },
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
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
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: DesignTokens.bodySmall.copyWith(
              color: ThemeColors.of(context).textSecondary,
            ),
          ),
        ],
      ),
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
