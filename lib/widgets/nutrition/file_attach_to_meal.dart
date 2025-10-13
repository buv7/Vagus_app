import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';

class FileAttachToMeal extends StatefulWidget {
  final List<String> attachments;
  final Function(List<String>) onAttachmentsChanged;
  final bool isReadOnly;
  final String? planId;
  final String? mealId;

  const FileAttachToMeal({
    super.key,
    required this.attachments,
    required this.onAttachmentsChanged,
    this.isReadOnly = false,
    this.planId,
    this.mealId,
  });

  @override
  State<FileAttachToMeal> createState() => _FileAttachToMealState();
}

class _FileAttachToMealState extends State<FileAttachToMeal> {
  bool _isUploading = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _pickAndUploadFile() async {
    if (widget.isReadOnly) return;

    try {
      setState(() => _isUploading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'mp4', 'mov', 'mp3', 'wav'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final newAttachments = <String>[];
        
        for (final file in result.files) {
          if (file.path != null) {
            try {
              // Upload to Supabase Storage
              final filePath = await _uploadToStorage(file);
              if (filePath != null) {
                newAttachments.add(filePath);
              }
            } catch (e) {
              debugPrint('Failed to upload ${file.name}: $e');
              // Continue with other files even if one fails
            }
          }
        }

        if (newAttachments.isNotEmpty) {
          final updatedAttachments = [...widget.attachments, ...newAttachments];
          widget.onAttachmentsChanged(updatedAttachments);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully uploaded ${newAttachments.length} file(s)'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<String?> _uploadToStorage(PlatformFile file) async {
    try {
      final fileBytes = file.bytes;
      if (fileBytes == null) return null;

      // Create storage path: nutrition/{planId}/{mealId}/{timestamp}_{filename}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${file.name}';
      final storagePath = 'nutrition/${widget.planId ?? 'unknown'}/${widget.mealId ?? 'unknown'}/$fileName';

      // Upload to Supabase Storage
      await _supabase.storage
          .from('vagus-media')
          .uploadBinary(storagePath, fileBytes);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('vagus-media')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      debugPrint('Storage upload error: $e');
      rethrow;
    }
  }

  void _removeAttachment(int index) async {
    if (widget.isReadOnly) return;

    final attachmentToRemove = widget.attachments[index];
    
    try {
      // Try to delete from storage if it's a storage URL
      if (attachmentToRemove.contains('storage.supabase')) {
        await _deleteFromStorage(attachmentToRemove);
      }
    } catch (e) {
      debugPrint('Failed to delete from storage: $e');
      // Continue with UI update even if storage deletion fails
    }

    final updatedAttachments = List<String>.from(widget.attachments);
    updatedAttachments.removeAt(index);
    widget.onAttachmentsChanged(updatedAttachments);
  }

  Future<void> _deleteFromStorage(String fileUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the storage path after 'vagus-media'
      final vagusMediaIndex = pathSegments.indexOf('vagus-media');
      if (vagusMediaIndex != -1 && vagusMediaIndex + 1 < pathSegments.length) {
        final storagePath = pathSegments.sublist(vagusMediaIndex + 1).join('/');
        
        await _supabase.storage
            .from('vagus-media')
            .remove([storagePath]);
      }
    } catch (e) {
      debugPrint('Storage deletion error: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.accentGreen,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
        Row(
          children: [
            const Icon(Icons.attach_file, color: DesignTokens.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Attachments',
              style: DesignTokens.titleSmall.copyWith(
                color: DesignTokens.neutralWhite,
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
                    // Show image preview for image files
                    if (_isImageFile(attachment))
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: NetworkImage(attachment),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Icon(
                        _getFileIcon(attachment),
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _getFileName(attachment),
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
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();
    
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
      case 'mp4':
      case 'mov':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileExtension(String fileName) {
    final uri = Uri.tryParse(fileName);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final lastSegment = uri.pathSegments.last;
      final dotIndex = lastSegment.lastIndexOf('.');
      if (dotIndex != -1 && dotIndex < lastSegment.length - 1) {
        return lastSegment.substring(dotIndex + 1);
      }
    }
    return '';
  }

  String _getFileName(String filePath) {
    final uri = Uri.tryParse(filePath);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return filePath;
  }

  bool _isImageFile(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }
}
