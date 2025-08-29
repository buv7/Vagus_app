import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/messages_service.dart';

class PinPanel extends StatefulWidget {
  final String conversationId;
  final Function(String) onOpenMessage;

  const PinPanel({
    super.key,
    required this.conversationId,
    required this.onOpenMessage,
  });

  @override
  State<PinPanel> createState() => _PinPanelState();
}

class _PinPanelState extends State<PinPanel> {
  final MessagesService _messagesService = MessagesService();
  List<Map<String, dynamic>> _pinnedMessages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPinnedMessages();
  }

  Future<void> _loadPinnedMessages() async {
    try {
      final pinned = await _messagesService.fetchPinned(widget.conversationId);
      setState(() {
        _pinnedMessages = pinned;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _unpinMessage(String messageId) async {
    try {
      await _messagesService.unpinMessage(messageId);
      await _loadPinnedMessages(); // Refresh the list
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

  String _getMessagePreview(Map<String, dynamic> message) {
    final text = message['text']?.toString() ?? '';
    if (text.isEmpty) {
      final attachments = message['attachments'] as List<dynamic>? ?? [];
      if (attachments.isNotEmpty) {
        return '📎 Attachment';
      }
      return 'Empty message';
    }
    return text.length > 50 ? '${text.substring(0, 50)}...' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.push_pin, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Pinned Messages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _pinnedMessages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.push_pin_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No pinned messages',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _pinnedMessages.length,
                        itemBuilder: (context, index) {
                          final pin = _pinnedMessages[index];
                          final message = pin['message'] as Map<String, dynamic>? ?? {};
                          final messageId = message['id'] as String? ?? '';
                          final text = _getMessagePreview(message);
                          final createdAt = DateTime.tryParse(message['created_at'] ?? '') ?? DateTime.now();
                          final pinnedAt = DateTime.tryParse(pin['pinned_at'] ?? '') ?? DateTime.now();

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.push_pin, color: Colors.blue, size: 20),
                              title: Text(
                                text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sent: ${DateFormat('MMM d, HH:mm').format(createdAt)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Pinned: ${DateFormat('MMM d, HH:mm').format(pinnedAt)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'open':
                                      widget.onOpenMessage(messageId);
                                      Navigator.of(context).pop();
                                      break;
                                    case 'unpin':
                                      _unpinMessage(messageId);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'open',
                                    child: Row(
                                      children: [
                                        Icon(Icons.open_in_new, size: 16),
                                        SizedBox(width: 8),
                                        Text('Open Message'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'unpin',
                                    child: Row(
                                      children: [
                                        Icon(Icons.push_pin_outlined, size: 16),
                                        SizedBox(width: 8),
                                        Text('Unpin'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                widget.onOpenMessage(messageId);
                                Navigator.of(context).pop();
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
