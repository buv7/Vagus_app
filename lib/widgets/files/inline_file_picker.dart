import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Inline File Picker Widget
/// Reusable widget with file icon + filename preview
/// Returns a File or Supabase URL
class InlineFilePicker extends StatefulWidget {
  final Function(Map<String, dynamic> fileData)? onFileSelected;
  final Function(String? error)? onError;
  final bool showPreview;
  final String? label;
  final String? hint;
  final List<String> allowedTypes;
  final bool allowMultiple;
  final bool showUploadProgress;
  final double? width;
  final double? height;

  const InlineFilePicker({
    super.key,
    this.onFileSelected,
    this.onError,
    this.showPreview = true,
    this.label,
    this.hint,
    this.allowedTypes = const ['image', 'video', 'audio', 'pdf'],
    this.allowMultiple = false,
    this.showUploadProgress = true,
    this.width,
    this.height,
  });

  @override
  State<InlineFilePicker> createState() => _InlineFilePickerState();
}

class _InlineFilePickerState extends State<InlineFilePicker> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _uploading = false;
  double _uploadProgress = 0.0;
  Map<String, dynamic>? _selectedFile;
  String? _uploadError;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // File picker button
          InkWell(
            onTap: _uploading ? null : _showPickerOptions,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: _uploading ? Colors.grey.shade100 : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    _uploading ? Icons.upload : Icons.attach_file,
                    color: _uploading ? Colors.grey : Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _uploading ? 'Uploading...' : (widget.hint ?? 'Select a file'),
                          style: TextStyle(
                            color: _uploading ? Colors.grey : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_uploading && widget.showUploadProgress) ...[
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_uploadProgress * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_uploading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),

          // Error message
          if (_uploadError != null) ...[
            const SizedBox(height: 8),
            Text(
              _uploadError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],

          // File preview
          if (widget.showPreview && _selectedFile != null) ...[
            const SizedBox(height: 12),
            _buildFilePreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    final fileName = _selectedFile!['file_name'] ?? 'Unknown file';
    final fileSize = _selectedFile!['file_size'] ?? 0;
    final fileUrl = _selectedFile!['file_url'];
    final category = _selectedFile!['category'] ?? 'other';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // File icon
          CircleAvatar(
            backgroundColor: _getFileColor(category).withValues(alpha: 0.1),
            child: Icon(
              _getFileIcon(category),
              color: _getFileColor(category),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatFileSize(fileSize),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: fileUrl != null ? () => _previewFile(fileUrl) : null,
                tooltip: 'Preview file',
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _clearSelection,
                tooltip: 'Remove file',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select File',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('File Picker'),
              onTap: () {
                Navigator.pop(context);
                _pickFromFilePicker();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        await _uploadFile(File(image.path));
      }
    } catch (e) {
      _handleError('Failed to pick from camera: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        if (widget.allowMultiple) {
          for (final image in images) {
            await _uploadFile(File(image.path));
          }
        } else {
          await _uploadFile(File(images.first.path));
        }
      }
    } catch (e) {
      _handleError('Failed to pick from gallery: $e');
    }
  }

  Future<void> _pickFromFilePicker() async {
    try {
      FileType fileType = FileType.any;
      
      // Determine file type based on allowed types
      if (widget.allowedTypes.contains('image') && 
          widget.allowedTypes.length == 1) {
        fileType = FileType.image;
      } else if (widget.allowedTypes.contains('video') && 
                 widget.allowedTypes.length == 1) {
        fileType = FileType.video;
      } else if (widget.allowedTypes.contains('audio') && 
                 widget.allowedTypes.length == 1) {
        fileType = FileType.audio;
      } else if (widget.allowedTypes.contains('pdf') && 
                 widget.allowedTypes.length == 1) {
        fileType = FileType.custom;
      }

      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowMultiple: widget.allowMultiple,
        allowedExtensions: widget.allowedTypes.contains('pdf') ? ['pdf'] : null,
      );

      if (result != null) {
        if (widget.allowMultiple) {
          for (final file in result.files) {
            if (file.path != null) {
              await _uploadFile(File(file.path!));
            }
          }
        } else {
          final file = result.files.first;
          if (file.path != null) {
            await _uploadFile(File(file.path!));
          }
        }
      }
    } catch (e) {
      _handleError('Failed to pick file: $e');
    }
  }

  Future<void> _uploadFile(File file) async {
    try {
      setState(() {
        _uploading = true;
        _uploadProgress = 0.0;
        _uploadError = null;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final fileName = file.path.split('/').last;
      final fileSize = file.lengthSync();
      final fileExt = fileName.split('.').last.toLowerCase();
      
      // Determine category based on file extension
      String category = 'other';
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExt)) {
        category = 'images';
      } else if (['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(fileExt)) {
        category = 'documents';
      } else if (['mp4', 'avi', 'mov', 'wmv'].contains(fileExt)) {
        category = 'videos';
      } else if (['mp3', 'wav', 'm4a', 'aac'].contains(fileExt)) {
        category = 'audio';
      }

      // Upload to Supabase Storage
      final filePath = 'user_files/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await Supabase.instance.client.storage.from('vagus-media').upload(filePath, file);
      final publicUrl = Supabase.instance.client.storage.from('vagus-media').getPublicUrl(filePath);

      // Create file data
      final fileData = {
        'user_id': user.id,
        'file_name': fileName,
        'file_path': filePath,
        'file_url': publicUrl,
        'file_size': fileSize,
        'file_type': fileExt,
        'category': category,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Save to database
      final response = await Supabase.instance.client
          .from('user_files')
          .insert(fileData)
          .select()
          .single();

      setState(() {
        _selectedFile = response;
        _uploading = false;
        _uploadProgress = 1.0;
      });

      // Notify parent
      widget.onFileSelected?.call(response);

    } catch (e) {
      _handleError('Upload failed: $e');
    }
  }

  void _handleError(String error) {
    setState(() {
      _uploading = false;
      _uploadError = error;
    });
    widget.onError?.call(error);
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
      _uploadError = null;
    });
    widget.onFileSelected?.call({});
  }

  void _previewFile(String fileUrl) {
    // TODO: Navigate to file previewer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening file: $fileUrl')),
    );
  }

  IconData _getFileIcon(String category) {
    switch (category) {
      case 'images':
        return Icons.image;
      case 'videos':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      case 'documents':
        return Icons.description;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String category) {
    switch (category) {
      case 'images':
        return Colors.green;
      case 'videos':
        return Colors.red;
      case 'audio':
        return Colors.orange;
      case 'documents':
        return Colors.blue;
      case 'pdf':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
