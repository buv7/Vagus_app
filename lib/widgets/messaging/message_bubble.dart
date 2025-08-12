import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/messages_service.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;
  final String currentUserId;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String)? onReaction;
  final VoidCallback? onAttachmentTap;
  final VoidCallback? onCopy;
  final VoidCallback? onForward;
  final VoidCallback? onStar;
  final bool isStarred;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    required this.currentUserId,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onReaction,
    this.onAttachmentTap,
    this.onCopy,
    this.onForward,
    this.onStar,
    this.isStarred = false,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show deleted messages
    if (message.deletedAt != null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: isOwnMessage ? () => _showMessageOptions(context) : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOwnMessage ? Colors.blue[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reply to message (if any)
                    if (message.replyTo != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Replying to a message...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    
                    // Message text
                    if (message.text.isNotEmpty)
                      Text(
                        message.text,
                        style: const TextStyle(fontSize: 16),
                      ),
                    
                    // Attachments
                    if (message.attachments.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...message.attachments.map((attachment) => 
                        _buildAttachmentPreview(attachment),
                      ),
                    ],
                    
                    // Reactions
                    if (message.reactions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: message.reactions.entries.map((entry) {
                          final hasReacted = entry.key == currentUserId;
                          return GestureDetector(
                            onTap: () => onReaction?.call(entry.value),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: hasReacted ? Colors.blue[200] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    
                    // Message metadata
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (message.editedAt != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(edited)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (isOwnMessage) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.seenAt != null ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.seenAt != null ? Colors.blue : Colors.grey[600],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isOwnMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[300],
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview(Map<String, dynamic> attachment) {
    final mime = attachment['mime']?.toString() ?? '';
    final url = attachment['url']?.toString();
    final name = attachment['name']?.toString() ?? '';
    final size = attachment['size']?.toString() ?? '';

    if (mime.startsWith('image/')) {
      return GestureDetector(
        onTap: onAttachmentTap,
        child: Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildSafeImage(url),
          ),
        ),
      );
    } else if (mime.startsWith('video/')) {
      return GestureDetector(
        onTap: onAttachmentTap,
        child: Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.play_circle_outline, size: 48, color: Colors.white),
              Positioned(
                bottom: 8,
                left: 8,
                child: Text(
                  'Video',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (mime.startsWith('audio/')) {
      return GestureDetector(
        onTap: onAttachmentTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow, color: Colors.orange),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Message',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.orange[800],
                    ),
                  ),
                  if (size.isNotEmpty)
                    Text(
                      _formatFileSize(int.tryParse(size) ?? 0),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Generic file attachment
      return GestureDetector(
        onTap: onAttachmentTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getFileIcon(mime),
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (size.isNotEmpty)
                    Text(
                      _formatFileSize(int.tryParse(size) ?? 0),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSafeImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  IconData _getFileIcon(String mime) {
    if (mime == 'application/pdf') return Icons.picture_as_pdf;
    if (mime.startsWith('text/')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick reactions
            if (message.text.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickReaction(context, '❤️'),
                    _buildQuickReaction(context, '👍'),
                    _buildQuickReaction(context, '🔥'),
                    _buildQuickReaction(context, '😂'),
                  ],
                ),
              ),
              const Divider(),
            ],
            
            // Message actions
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                onReply?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                onCopy?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                onForward?.call();
              },
            ),
            ListTile(
              leading: Icon(
                isStarred ? Icons.star : Icons.star_border,
                color: isStarred ? Colors.amber : null,
              ),
              title: Text(isStarred ? 'Unstar' : 'Star'),
              onTap: () {
                Navigator.pop(context);
                onStar?.call();
              },
            ),
            
            // Own message actions
            if (isOwnMessage) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReaction(BuildContext context, String emoji) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onReaction?.call(emoji);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
