import 'package:flutter/material.dart';

class AttachmentTile extends StatelessWidget {
  final Map<String, dynamic> attachment;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const AttachmentTile({
    super.key,
    required this.attachment,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final path = attachment['path']?.toString() ?? '';
    final mime = attachment['mime']?.toString() ?? '';
    final size = attachment['size']?.toString() ?? '';

    
    final fileName = path.split('/').last;
    final fileExt = fileName.split('.').last.toLowerCase();
    
    IconData iconData;
    Color iconColor;
    
    // Determine icon based on file type
    if (mime.startsWith('image/') || ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExt)) {
      iconData = Icons.image;
      iconColor = Colors.green;
    } else if (mime.startsWith('video/') || ['mp4', 'avi', 'mov', 'mkv'].contains(fileExt)) {
      iconData = Icons.video_file;
      iconColor = Colors.red;
    } else if (mime.startsWith('audio/') || ['mp3', 'wav', 'm4a', 'aac'].contains(fileExt)) {
      iconData = Icons.audio_file;
      iconColor = Colors.orange;
    } else if (mime == 'application/pdf' || fileExt == 'pdf') {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (mime.startsWith('text/') || ['txt', 'md', 'json', 'xml'].contains(fileExt)) {
      iconData = Icons.text_snippet;
      iconColor = Colors.blue;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.1),
        child: Icon(iconData, color: iconColor),
      ),
      title: Text(
        fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        size.isNotEmpty ? _formatFileSize(int.tryParse(size) ?? 0) : 'Unknown size',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Delete attachment',
            )
          : null,
      onTap: onTap,
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
