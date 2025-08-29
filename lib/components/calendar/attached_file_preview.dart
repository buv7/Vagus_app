import 'package:flutter/material.dart';
import '../../widgets/files/file_previewer.dart';

class AttachedFilePreview extends StatelessWidget {
  final List<Map<String, dynamic>> attachments;
  final VoidCallback? onTap;

  const AttachedFilePreview({
    super.key,
    required this.attachments,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: attachments.map((attachment) {
            final fileName = attachment['name'] ?? 'Unknown file';
            final fileType = attachment['type'] ?? 'unknown';
            final fileSize = attachment['size'];
            
            return GestureDetector(
              onTap: onTap ?? () {
                // Launch existing file viewer
                                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => FilePreviewer(
                       fileUrl: attachment['url'] ?? '',
                       fileName: fileName,
                       fileType: fileType,
                       category: _getFileCategory(fileType),
                     ),
                   ),
                 );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFileIcon(fileType),
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        fileName,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (fileSize != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        _formatFileSize(fileSize),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.attach_file;
    }
  }

  String _formatFileSize(dynamic size) {
    if (size is int) {
      if (size < 1024) return '${size}B';
      if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '';
  }

  String _getFileCategory(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return 'images';
      case 'video':
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return 'videos';
      case 'audio':
      case 'mp3':
      case 'wav':
      case 'aac':
        return 'audio';
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
      case 'txt':
        return 'documents';
      default:
        return 'documents';
    }
  }
}
