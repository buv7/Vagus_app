import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/files/inline_file_picker.dart';
import '../../widgets/files/file_previewer.dart';

class AttachmentMeta {
  final String fileName;
  final String storagePath;
  final String url;
  final int sizeBytes;

  AttachmentMeta({
    required this.fileName,
    required this.storagePath,
    required this.url,
    required this.sizeBytes,
  });
}

class AttachToCheckin extends StatefulWidget {
  final String checkinId;
  final String clientId;
  final Function(List<AttachmentMeta>) onChanged;

  const AttachToCheckin({
    super.key,
    required this.checkinId,
    required this.clientId,
    required this.onChanged,
  });

  @override
  State<AttachToCheckin> createState() => _AttachToCheckinState();
}

class _AttachToCheckinState extends State<AttachToCheckin> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<AttachmentMeta> _attachments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAttachments());
  }

  Future<void> _loadAttachments() async {
    try {
      setState(() => _loading = true);

      // List files from storage with prefix
      final storagePrefix = 'checkins/${widget.clientId}/${widget.checkinId}/';
      
      final storageFiles = await _supabase.storage
          .from('vagus-media')
          .list(path: storagePrefix.substring(0, storagePrefix.length - 1));

      final attachments = <AttachmentMeta>[];
      
      for (final file in storageFiles) {
        if (file.name != '.emptyFolderPlaceholder') {
          final fileName = file.name;
          final storagePath = '$storagePrefix$fileName';
          final url = _supabase.storage.from('vagus-media').getPublicUrl(storagePath);
          final sizeBytes = file.metadata?['size'] ?? 0;
          
          attachments.add(AttachmentMeta(
            fileName: fileName,
            storagePath: storagePath,
            url: url,
            sizeBytes: sizeBytes,
          ));
        }
      }

      setState(() {
        _attachments = attachments;
        _loading = false;
        _error = null;
      });
      
      widget.onChanged(_attachments);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onFileSelected(Map<String, dynamic> fileData) async {
    try {
      // The file is already uploaded by InlineFilePicker to user_files/
      // We need to move it to our checkin-specific location
      final originalPath = fileData['file_path'] as String;
      final fileName = fileData['file_name'] as String;
      final newPath = 'checkins/${widget.clientId}/${widget.checkinId}/$fileName';
      
      // Download from original location
      final fileBytes = await _supabase.storage
          .from('vagus-media')
          .download(originalPath);
      
      // Upload to new location
      await _supabase.storage
          .from('vagus-media')
          .uploadBinary(newPath, fileBytes);
      
      // Delete original file
      await _supabase.storage
          .from('vagus-media')
          .remove([originalPath]);
      
      // Reload attachments
      unawaited(_loadAttachments());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ File attached successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to attach file: $e')),
        );
      }
    }
  }

  Future<void> _removeAttachment(AttachmentMeta attachment) async {
    try {
      await _supabase.storage
          .from('vagus-media')
          .remove([attachment.storagePath]);
      
      unawaited(_loadAttachments());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ File removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to remove file: $e')),
        );
      }
    }
  }

  void _openFile(AttachmentMeta attachment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(attachment.fileName),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove Attachment'),
                      content: Text('Remove ${attachment.fileName}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );
                  
                  if (!context.mounted) return;
                  if (confirmed == true) {
                    Navigator.pop(context); // Close file viewer
                    unawaited(_removeAttachment(attachment));
                  }
                },
              ),
            ],
          ),
          body: FilePreviewer(
            fileUrl: attachment.url,
            fileName: attachment.fileName,
            fileType: _getFileType(attachment.fileName),
            category: _getFileCategory(attachment.fileName),
          ),
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Widget _buildAttachmentChip(AttachmentMeta attachment) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      child: InkWell(
        onTap: () => _openFile(attachment),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getFileIcon(attachment.fileName),
                size: 16,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  attachment.fileName,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _formatFileSize(attachment.sizeBytes),
                style: TextStyle(
                  color: Colors.blue[500],
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _removeAttachment(attachment),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Icons.audio_file;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.attach_file;
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'pdf';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'image';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'm4a':
        return 'audio';
      case 'doc':
      case 'docx':
        return 'document';
      default:
        return 'file';
    }
  }

  String _getFileCategory(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
      case 'doc':
      case 'docx':
        return 'documents';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'images';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'videos';
      case 'mp3':
      case 'wav':
      case 'm4a':
        return 'audio';
      default:
        return 'files';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Attachments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // File picker
        InlineFilePicker(
          onFileSelected: _onFileSelected,
          showPreview: false,
          hint: 'Attach file to check-in',
          allowMultiple: false,
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $error')),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Attachments list
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Text(
            'Error loading attachments: $_error',
            style: const TextStyle(color: Colors.red),
          )
        else if (_attachments.isEmpty)
          const Text(
            'No attachments yet',
            style: TextStyle(color: Colors.grey),
          )
        else
          Wrap(
            children: _attachments.map(_buildAttachmentChip).toList(),
          ),
      ],
    );
  }
}
