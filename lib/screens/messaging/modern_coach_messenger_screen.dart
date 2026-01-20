import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_colors.dart';
import '../../widgets/messaging/messaging_header.dart';
import '../../widgets/messaging/message_list_view.dart';
import '../../widgets/messaging/smart_replies_panel.dart';
import '../../widgets/messaging/message_input_bar.dart';
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
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    // Restore system UI when leaving messenger screen
    _restoreSystemUI();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    final colors = ThemeColors.of(context);
    // Show more options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignTokens.space20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radius16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person_outline, color: colors.icon),
              title: Text('View Client Profile', style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                // Navigate to client profile
              },
            ),
            ListTile(
              leading: Icon(Icons.push_pin_outlined, color: colors.icon),
              title: Text('Pinned Messages', style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                // Navigate to pinned messages
              },
            ),
            ListTile(
              leading: Icon(Icons.download_outlined, color: colors.icon),
              title: Text('Export Conversation', style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                // Export conversation
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_outlined, color: AppTheme.accentGreen),
              title: Text('Import Program', style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showImportProgramSheet();
              },
            ),
            ListTile(
              leading: Icon(Icons.archive_outlined, color: colors.icon),
              title: Text('Archive Chat', style: TextStyle(color: colors.textPrimary)),
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
              Builder(
                builder: (context) {
                  final colors = ThemeColors.of(context);
                  return Container(
                    padding: const EdgeInsets.all(DesignTokens.space16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      ),
                      child: TextField(
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search in conversation...',
                          hintStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colors.icon,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radius12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colors.inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space16,
                            vertical: DesignTokens.space12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
