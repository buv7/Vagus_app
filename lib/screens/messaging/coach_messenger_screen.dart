import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/messages_service.dart';
import '../../services/ai/messaging_ai.dart';
import '../../widgets/messaging/message_bubble.dart';
import '../../widgets/messaging/attachment_picker.dart';
import '../../widgets/messaging/voice_recorder.dart';
import '../../components/messaging/message_search_bar.dart';
import '../../components/messaging/pin_panel.dart';
import '../../components/messaging/thread_view.dart';
import 'dart:io';

class CoachMessengerScreen extends StatefulWidget {
  final Map<String, dynamic> client;

  const CoachMessengerScreen({
    super.key,
    required this.client,
  });

  @override
  State<CoachMessengerScreen> createState() => _CoachMessengerScreenState();
}

class _CoachMessengerScreenState extends State<CoachMessengerScreen> {
  final MessagesService _messagesService = MessagesService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String? _threadId;
  List<Message> _messages = [];
  List<Map<String, dynamic>> _typingUsers = [];
  String? _replyToMessageId;
  String _searchQuery = '';
  bool _loading = true;
  bool _sending = false;
  bool _showSearchBar = false;
  DateTime? _lastReadAt;
  
  // AI features
  static const bool kEnableSmartReplies = true;
  List<String> _smartReplies = [];
  bool _loadingSmartReplies = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Ensure thread exists
      _threadId = await _messagesService.ensureThread(
        coachId: user.id,
        clientId: widget.client['id'],
      );

      // Subscribe to messages
      _messagesService.subscribeMessages(_threadId!).listen((messages) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
        _markMessagesAsSeen();
      });

      // Subscribe to read receipts
      _messagesService.onReadReceipts(_threadId!).listen((receipts) {
        // Update last read time for the other user
        if (receipts.isNotEmpty) {
          final otherUserId = widget.client['id'];
          _updateLastReadAt(otherUserId);
        }
      });

      // Subscribe to typing indicators
      _messagesService.subscribeTyping(_threadId!).listen((typingUsers) {
        setState(() {
          _typingUsers = typingUsers;
        });
      });

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize chat: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _threadId == null || _sending) return;

    setState(() => _sending = true);

    try {
      await _messagesService.sendText(
        threadId: _threadId!,
        text: text,
        replyTo: _replyToMessageId,
      );

      _messageController.clear();
      _replyToMessageId = null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _sendAttachment(File file) async {
    if (_threadId == null) return;

    try {
      await _messagesService.sendAttachment(
        threadId: _threadId!,
        file: file,
        replyTo: _replyToMessageId,
      );
      _replyToMessageId = null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send attachment: $e')),
        );
      }
    }
  }

  Future<void> _sendVoiceMessage(File audioFile) async {
    if (_threadId == null) return;

    try {
      await _messagesService.sendVoice(
        threadId: _threadId!,
        audioFile: audioFile,
        replyTo: _replyToMessageId,
      );
      _replyToMessageId = null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _markMessagesAsSeen() {
    if (_threadId == null) return;
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Mark conversation as read up to the latest message
    if (_messages.isNotEmpty) {
      final latestMessage = _messages.last;
      _messagesService.markConversationRead(
        threadId: _threadId!,
        upTo: latestMessage.createdAt,
      );
    }

    // Also mark individual messages as seen (legacy support)
    for (final message in _messages) {
      if (message.senderId != user.id && message.seenAt == null) {
        _messagesService.markSeen(
          threadId: _threadId!,
          messageId: message.id,
        );
      }
    }
  }

  Future<void> _updateLastReadAt(String otherUserId) async {
    try {
      final lastRead = await _messagesService.lastReadAtByOther(_threadId!, otherUserId);
      setState(() {
        _lastReadAt = lastRead;
      });
    } catch (e) {
      // Ignore errors for read receipts
    }
  }

  void _onTypingChanged(bool isTyping) {
    if (_threadId != null) {
      _messagesService.setTyping(_threadId!, isTyping);
    }
  }

  List<Message> get _filteredMessages {
    if (_searchQuery.isEmpty) return _messages;
    
    return _messages.where((message) {
      final searchLower = _searchQuery.toLowerCase();
      return message.text.toLowerCase().contains(searchLower) ||
          message.attachments.any((attachment) =>
              attachment['name']?.toString().toLowerCase().contains(searchLower) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final clientName = widget.client['name'] ?? 'Client';
    final clientAvatar = widget.client['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: clientAvatar != null ? NetworkImage(clientAvatar) : null,
              child: clientAvatar == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clientName),
                if (_typingUsers.isNotEmpty)
                  const Text(
                    'typing...',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
          ),
          IconButton(
            icon: const Icon(Icons.push_pin),
            onPressed: _openPinPanel,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar (if active)
          if (_showSearchBar)
            MessageSearchBar(
              onQuery: (query) => setState(() => _searchQuery = query),
              onClear: () => setState(() => _searchQuery = ''),
            ),

          // Reply indicator
          if (_replyToMessageId != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16),
                  const SizedBox(width: 8),
                  const Text('Replying to a message'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () => setState(() => _replyToMessageId = null),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: _filteredMessages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _filteredMessages.length,
                    itemBuilder: (context, index) {
                      final message = _filteredMessages[index];
                      final user = Supabase.instance.client.auth.currentUser;
                      final isOwnMessage = user?.id == message.senderId;

                      return MessageBubble(
                        message: message,
                        isOwnMessage: isOwnMessage,
                        currentUserId: user?.id ?? '',
                        onReply: () => _openThread(message),
                        onEdit: () => _editMessage(message),
                        onDelete: () => _deleteMessage(message),
                        onReaction: (emoji) => _addReaction(message, emoji),
                        onAttachmentTap: () => _viewAttachment(message),
                        onPin: () => _pinMessage(message),
                        onUnpin: () => _unpinMessage(message),
                        lastReadAt: _lastReadAt,
                        onOpenThread: () => _openThread(message),
                      );
                    },
                  ),
          ),

          // Smart Replies (if enabled and there are recent incoming messages)
          if (kEnableSmartReplies && _shouldShowSmartReplies())
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loadingSmartReplies)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Generating suggestions...', style: TextStyle(fontSize: 12)),
                      ],
                    )
                  else if (_smartReplies.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick replies:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _smartReplies.map((reply) => 
                            ActionChip(
                              label: Text(reply),
                              onPressed: () => _useSmartReply(reply),
                              backgroundColor: Colors.blue.shade50,
                              labelStyle: const TextStyle(fontSize: 12),
                            ),
                          ).toList(),
                        ),
                      ],
                    ),
                ],
              ),
            ),

          // Message composer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () => _showAttachmentPicker(),
                ),
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () => _showVoiceRecorder(),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: null,
                    onChanged: (text) => _onTypingChanged(text.isNotEmpty),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _sending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _pinMessage(Message message) async {
    try {
      await _messagesService.pinMessage(message.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message pinned')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pin message: $e')),
        );
      }
    }
  }

  Future<void> _unpinMessage(Message message) async {
    try {
      await _messagesService.unpinMessage(message.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message unpinned')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unpin message: $e')),
        );
      }
    }
  }

  void _openThread(Message message) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ThreadView(
          conversationId: _threadId!,
          parentMessage: message.toMap(),
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openPinPanel() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: PinPanel(
          conversationId: _threadId!,
          onOpenMessage: (messageId) {
            // Scroll to message
            final messageIndex = _messages.indexWhere((m) => m.id == messageId);
            if (messageIndex != -1) {
              _scrollController.animateTo(
                messageIndex * 100.0, // Approximate height
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentPicker(
        onFileSelected: _sendAttachment,
        onVoiceRecorded: _sendVoiceMessage,
      ),
    );
  }

  void _showVoiceRecorder() {
    showModalBottomSheet(
      context: context,
      builder: (context) => VoiceRecorder(
        onVoiceRecorded: _sendVoiceMessage,
      ),
    );
  }

  void _editMessage(Message message) {
    _messageController.text = message.text;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  Future<void> _deleteMessage(Message message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _messagesService.deleteMessage(message.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete message: $e')),
          );
        }
      }
    }
  }

  Future<void> _addReaction(Message message, String emoji) async {
    try {
      await _messagesService.addReaction(message.id, emoji);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reaction: $e')),
        );
      }
    }
  }

  void _viewAttachment(Message message) {
    if (message.attachments.isEmpty) return;

    final attachment = message.attachments.first;
    final url = attachment['url']?.toString();
    final mime = attachment['mime']?.toString() ?? '';

    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment not available')),
      );
      return;
    }

    // For now, just show a dialog with the URL
    // In a real implementation, you'd open the file in a viewer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(attachment['name']?.toString() ?? 'Attachment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: $mime'),
            Text('Size: ${_formatFileSize(attachment['size'] ?? 0)}'),
            const SizedBox(height: 16),
            const Text('URL:'),
            SelectableText(url),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Smart Replies Logic
  bool _shouldShowSmartReplies() {
    if (_messageController.text.isNotEmpty) return false; // Don't show if user is typing
    
    // Check if there's a recent incoming message (last 5 minutes)
    final now = DateTime.now();
    final recentMessages = _messages.where((msg) {
      final user = Supabase.instance.client.auth.currentUser;
      final isIncoming = user?.id != msg.senderId;
      final isRecent = now.difference(msg.createdAt).inMinutes < 5;
      return isIncoming && isRecent;
    }).toList();
    
    return recentMessages.isNotEmpty;
  }

  Future<void> _loadSmartReplies() async {
    if (!kEnableSmartReplies || _loadingSmartReplies) return;
    
    final recentMessage = _messages.lastWhere(
      (msg) {
        final user = Supabase.instance.client.auth.currentUser;
        return user?.id != msg.senderId;
      },
      orElse: () => _messages.first,
    );
    
    if (recentMessage.text.isEmpty) return;
    
    setState(() => _loadingSmartReplies = true);
    
    try {
      // Get thread context (last 10 messages)
      final contextMessages = _messages.take(10).map((m) => m.text).join('\n');
      
      final replies = await MessagingAI.smartReplies(
        lastMessage: recentMessage.text,
        threadContext: contextMessages,
      );
      
      setState(() {
        _smartReplies = replies;
        _loadingSmartReplies = false;
      });
    } catch (e) {
      setState(() => _loadingSmartReplies = false);
      // Silent failure - smart replies are optional
    }
  }

  void _useSmartReply(String reply) {
    _messageController.text = reply;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
    setState(() => _smartReplies = []); // Clear suggestions after use
  }

  @override
  void didUpdateWidget(CoachMessengerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Load smart replies when messages change
    if (kEnableSmartReplies && _shouldShowSmartReplies() && _smartReplies.isEmpty) {
      _loadSmartReplies();
    }
  }
}
