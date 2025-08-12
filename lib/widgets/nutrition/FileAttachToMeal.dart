import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileAttachToMeal extends StatefulWidget {
  final List<String> attachments;
  final Function(List<String>) onAttachmentsChanged;
  final bool isReadOnly;

  const FileAttachToMeal({
    super.key,
    required this.attachments,
    required this.onAttachmentsChanged,
    this.isReadOnly = false,
  });

  @override
  State<FileAttachToMeal> createState() => _FileAttachToMealState();
}

class _FileAttachToMealState extends State<FileAttachToMeal> {
  bool _isUploading = false;

  Future<void> _pickAndUploadFile() async {
    if (widget.isReadOnly) return;

    try {
      setState(() => _isUploading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final newAttachments = <String>[];
        
        for (final file in result.files) {
          if (file.path != null) {
            // Here you would typically upload to Supabase Storage
            // For now, we'll just add the file name as a placeholder
            // In a real implementation, you'd use the existing storage service
            final fileName = file.name;
            newAttachments.add(fileName);
          }
        }

        if (newAttachments.isNotEmpty) {
          final updatedAttachments = [...widget.attachments, ...newAttachments];
          widget.onAttachmentsChanged(updatedAttachments);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _removeAttachment(int index) {
    if (widget.isReadOnly) return;

    final updatedAttachments = List<String>.from(widget.attachments);
    updatedAttachments.removeAt(index);
    widget.onAttachmentsChanged(updatedAttachments);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              'Attachments',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            if (!widget.isReadOnly)
              TextButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadFile,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add, size: 16),
                label: Text(_isUploading ? 'Uploading...' : 'Add Files'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
          ],
        ),
        
        if (widget.attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.attachments.asMap().entries.map((entry) {
              final index = entry.key;
              final attachment = entry.value;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFileIcon(attachment),
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        attachment,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!widget.isReadOnly) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeAttachment(index),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}
