import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/messaging/messaging_header.dart';
import '../../widgets/messaging/message_list_view.dart';
import '../../widgets/messaging/smart_replies_panel.dart';
import '../../widgets/messaging/message_input_bar.dart';
import '../../services/coach/coach_messaging_service.dart';
import '../coach/program_ingest_upload_sheet.dart';

class ModernCoachMessengerScreen extends StatefulWidget {
  final Map<String, dynamic> client;

  const ModernCoachMessengerScreen({
    super.key,
    required this.client,
  });

  @override
  State<ModernCoachMessengerScreen> createState() => _ModernCoachMessengerScreenState();
}

class _ModernCoachMessengerScreenState extends State<ModernCoachMessengerScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
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

  void _loadMessages() {
    // Mock data for now - replace with actual message loading
    setState(() {
      _messages = [
        {
          'id': '1',
          'senderId': widget.client['id'],
          'senderName': widget.client['name'],
          'content': 'Hi Coach! I just finished today\'s workout. It was challenging but I feel great!',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'isFromClient': true,
        },
        {
          'id': '2',
          'senderId': 'coach',
          'senderName': 'Coach',
          'content': 'That\'s fantastic, Mike! How did the bench press feel? Were you able to hit the target reps?',
          'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          'isFromClient': false,
        },
        {
          'id': '3',
          'senderId': widget.client['id'],
          'senderName': widget.client['name'],
          'content': 'Yes! I managed to get all 3 sets of 8 reps at 185 lbs. Felt much stronger than last week.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
          'isFromClient': true,
        },
      ];
    });
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderId': 'coach',
        'senderName': 'Coach',
        'content': content,
        'timestamp': DateTime.now(),
        'isFromClient': false,
      });
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _sendSmartReply(String reply) {
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderId': 'coach',
        'senderName': 'Coach',
        'content': reply,
        'timestamp': DateTime.now(),
        'isFromClient': false,
      });
    });

    _scrollToBottom();
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

  void _onSearch() {
    setState(() {
      _showSearch = !_showSearch;
    });
  }

  void _onCall() {
    // Handle call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Call functionality coming soon!')),
    );
  }

  void _onVideoCall() {
    // Handle video call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video call functionality coming soon!')),
    );
  }

  void _onMoreOptions() {
    // Show more options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignTokens.space20),
        decoration: const BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radius16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppTheme.neutralWhite),
              title: const Text('View Client Profile', style: TextStyle(color: AppTheme.neutralWhite)),
              onTap: () {
                Navigator.pop(context);
                // Navigate to client profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin_outlined, color: AppTheme.neutralWhite),
              title: const Text('Pinned Messages', style: TextStyle(color: AppTheme.neutralWhite)),
              onTap: () {
                Navigator.pop(context);
                // Navigate to pinned messages
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined, color: AppTheme.neutralWhite),
              title: const Text('Export Conversation', style: TextStyle(color: AppTheme.neutralWhite)),
              onTap: () {
                Navigator.pop(context);
                // Export conversation
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_outlined, color: AppTheme.mintAqua),
              title: const Text('Import Program', style: TextStyle(color: AppTheme.neutralWhite)),
              onTap: () {
                Navigator.pop(context);
                _showImportProgramSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined, color: AppTheme.neutralWhite),
              title: const Text('Archive Chat', style: TextStyle(color: AppTheme.neutralWhite)),
              onTap: () {
                Navigator.pop(context);
                // Archive chat
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportProgramSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgramIngestUploadSheet(
        preselectedClientId: widget.client['id'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            MessagingHeader(
              client: widget.client,
              onBack: () => Navigator.pop(context),
              onSearch: _onSearch,
              onCall: _onCall,
              onVideoCall: _onVideoCall,
              onMoreOptions: _onMoreOptions,
            ),
            
            // Search Bar (if shown)
            if (_showSearch)
              Container(
                padding: const EdgeInsets.all(DesignTokens.space16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  ),
                  child: TextField(
                    style: const TextStyle(color: AppTheme.neutralWhite),
                    decoration: InputDecoration(
                      hintText: 'Search in conversation...',
                      hintStyle: const TextStyle(color: AppTheme.lightGrey),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.lightGrey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.cardBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space16,
                        vertical: DesignTokens.space12,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Messages
            Expanded(
              child: MessageListView(
                messages: _messages,
                scrollController: _scrollController,
              ),
            ),
            
            // Smart Replies
            SmartRepliesPanel(
              onReplySelected: _sendSmartReply,
            ),
            
            // Message Input
            MessageInputBar(
              controller: _messageController,
              onSend: _sendMessage,
              onAttachment: () {
                // Handle attachment
              },
              onVoice: () {
                // Handle voice message
              },
              onCalendar: () {
                // Handle calendar
              },
            ),
          ],
        ),
      ),
    );
  }
}
