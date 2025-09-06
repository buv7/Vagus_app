import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/messages_service.dart';
import '../../services/notifications/notification_helper.dart';
import '../../widgets/messaging/message_bubble.dart';
import '../../widgets/messaging/attachment_picker.dart';
import '../../widgets/messaging/voice_recorder.dart';
import '../../components/messaging/thread_view.dart';

class AdminSupportChatScreen extends StatefulWidget {
  final String? clientId; // Optional when admin initiates chat with a client
  const AdminSupportChatScreen({super.key, this.clientId});

  @override
  State<AdminSupportChatScreen> createState() => _AdminSupportChatScreenState();
}

class _AdminSupportChatScreenState extends State<AdminSupportChatScreen> {
  final MessagesService _messagesService = MessagesService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _threadId;
  String? _adminId;
  Map<String, dynamic>? _adminProfile;
  List<Message> _messages = [];
  String? _replyToMessageId;
  bool _loading = true;
  bool _sending = false;

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
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final bool isAdmin = await _currentUserIsAdmin();
      if (isAdmin && widget.clientId != null) {
        // Admin chatting with a specific client
        _adminId = user.id;
        _adminProfile = await _getProfile(_adminId!);

        _threadId = await _findExistingThread(_adminId!, widget.clientId!);
        _threadId ??= await _messagesService.ensureThread(
          coachId: _adminId!,
          clientId: widget.clientId!,
        );
      } else {
        // Client-initiated support chat; pick any admin
        _adminId = await _getAnyAdminId();
        if (_adminId == null) {
          setState(() => _loading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No admin available for support.')),
            );
          }
          return;
        }

        _adminProfile = await _getProfile(_adminId!);
        _threadId = await _findExistingThread(_adminId!, user.id);
        _threadId ??= await _messagesService.ensureThread(
          coachId: _adminId!,
          clientId: user.id,
        );

        // Send notification to all admins about the support request
        final clientProfile = await _getProfile(user.id);
        if (clientProfile != null) {
          try {
            await NotificationHelper.instance.notifyAdminsOfSupportRequest(
              clientName: clientProfile['name'] ?? 'Unknown User',
              clientEmail: clientProfile['email'] ?? 'No email',
              clientId: user.id,
              threadId: _threadId,
            );

            // Also notify the specific admin who was assigned
            await NotificationHelper.instance.notifyAdminOfAssignedChat(
              adminId: _adminId!,
              clientName: clientProfile['name'] ?? 'Unknown User',
              clientEmail: clientProfile['email'] ?? 'No email',
              clientId: user.id,
              threadId: _threadId,
            );
          } catch (e) {
            // If notifications fail, just log it and continue
            debugPrint('Failed to send notifications: $e');
            
            // Show local feedback instead
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('💬 Support chat opened with ${clientProfile['name'] ?? 'user'}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
      }

      _messagesService.subscribeMessages(_threadId!).listen((messages) {
        setState(() => _messages = messages);
        _scrollToBottom();
      });

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open support chat: $e')),
        );
      }
    }
  }

  Future<String?> _findExistingThread(String adminId, String clientId) async {
    try {
      final row = await Supabase.instance.client
          .from('message_threads')
          .select('id')
          .eq('coach_id', adminId)
          .eq('client_id', clientId)
          .maybeSingle();
      return row?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _currentUserIsAdmin() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return false;
      final row = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      return (row?['role']?.toString().toLowerCase() ?? '') == 'admin';
    } catch (_) {
      return false;
    }
  }

  Future<String?> _getAnyAdminId() async {
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('role', 'admin')
          .limit(1)
          .maybeSingle();
      return row?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getProfile(String userId) async {
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return profile;
    } catch (e) {
      return null;
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _threadId == null || _sending) return;
    setState(() => _sending = true);
    try {
      await _messagesService.sendText(threadId: _threadId!, text: text, replyTo: _replyToMessageId);
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
      await _messagesService.sendAttachment(threadId: _threadId!, file: file, replyTo: _replyToMessageId);
      _replyToMessageId = null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send attachment: $e')),
        );
      }
    }
  }

  Future<void> _sendVoice(File audioFile) async {
    if (_threadId == null) return;
    try {
      await _messagesService.sendVoice(threadId: _threadId!, audioFile: audioFile, replyTo: _replyToMessageId);
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final adminName = _adminProfile?['name'] ?? 'Admin';
    final adminAvatar = _adminProfile?['avatar_url'];
    final hasAvatar = (adminAvatar is String) && adminAvatar.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: hasAvatar ? NetworkImage(adminAvatar as String) : null,
              child: !hasAvatar ? const Icon(Icons.support_agent) : null,
            ),
            const SizedBox(width: 12),
            Text('Support • $adminName'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text('No messages yet. Ask us anything!'),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final user = Supabase.instance.client.auth.currentUser;
                      final isOwn = user?.id == message.senderId;
                      return MessageBubble(
                        message: message,
                        isOwnMessage: isOwn,
                        currentUserId: user?.id ?? '',
                        onReply: () => _openThread(message),
                        onEdit: null,
                        onDelete: null,
                        onReaction: (_) {},
                        onAttachmentTap: () {},
                        onPin: null,
                        onUnpin: null,
                        lastReadAt: null,
                        onOpenThread: () => _openThread(message),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _showAttachmentPicker,
                ),
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: _showVoiceRecorder,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _sending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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

  void _openThread(Message message) {
    if (_threadId == null) return;
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

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentPicker(
        onFileSelected: _sendAttachment,
        onVoiceRecorded: _sendVoice,
      ),
    );
  }

  void _showVoiceRecorder() {
    showModalBottomSheet(
      context: context,
      builder: (context) => VoiceRecorder(
        onVoiceRecorded: _sendVoice,
      ),
    );
  }
}


