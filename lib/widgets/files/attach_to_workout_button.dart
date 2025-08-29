import 'package:flutter/material.dart';
import 'inline_file_picker.dart';
import 'file_previewer.dart';

/// Attach to Workout Button Widget
/// Allows attaching files to workout plans
class AttachToWorkoutButton extends StatefulWidget {
  final Function(List<Map<String, dynamic>> files)? onFilesAttached;
  final Function(String? error)? onError;
  final List<Map<String, dynamic>>? existingAttachments;
  final bool allowMultiple;
  final String? label;
  final String? hint;
  final List<String> allowedTypes;
  final bool showPreview;
  final double? width;
  final double? height;
  final String? workoutType; // 'exercise', 'workout', 'plan'

  const AttachToWorkoutButton({
    super.key,
    this.onFilesAttached,
    this.onError,
    this.existingAttachments,
    this.allowMultiple = true,
    this.label,
    this.hint,
    this.allowedTypes = const ['image', 'video', 'audio', 'pdf'],
    this.showPreview = true,
    this.width,
    this.height,
    this.workoutType,
  });

  @override
  State<AttachToWorkoutButton> createState() => _AttachToWorkoutButtonState();
}

class _AttachToWorkoutButtonState extends State<AttachToWorkoutButton> {
  List<Map<String, dynamic>> _attachedFiles = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingAttachments != null) {
      _attachedFiles = List.from(widget.existingAttachments!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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

        // Attach button
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: InkWell(
            onTap: _showAttachmentOptions,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.hint ?? _getDefaultHint(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_attachedFiles.isNotEmpty)
                          Text(
                            '${_attachedFiles.length} file${_attachedFiles.length == 1 ? '' : 's'} attached',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.add,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Attached files preview
        if (widget.showPreview && _attachedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildAttachmentsPreview(),
        ],
      ],
    );
  }

  String _getDefaultHint() {
    switch (widget.workoutType) {
      case 'exercise':
        return 'Attach exercise files (form videos, images)';
      case 'workout':
        return 'Attach workout files (routines, instructions)';
      case 'plan':
        return 'Attach workout plan files (schedules, programs)';
      default:
        return 'Attach files to workout';
    }
  }

  Widget _buildAttachmentsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attached Files:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ...(_attachedFiles.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          return _buildAttachmentTile(file, index);
        })),
      ],
    );
  }

  Widget _buildAttachmentTile(Map<String, dynamic> file, int index) {
    final fileName = file['file_name'] ?? 'Unknown file';
    final fileSize = file['file_size'] ?? 0;
    final category = file['category'] ?? 'other';
    final fileUrl = file['file_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              if (fileUrl != null)
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: () => _previewFile(file),
                  tooltip: 'Preview file',
                ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => _removeAttachment(index),
                tooltip: 'Remove attachment',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Attach ${_getWorkoutTypeText()} Files',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Add New Files'),
              subtitle: const Text('Upload files from device'),
              onTap: () {
                Navigator.pop(context);
                _showFilePicker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Exercise Video'),
              subtitle: const Text('Record form demonstration'),
              onTap: () {
                Navigator.pop(context);
                _recordVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Exercise Photo'),
              subtitle: const Text('Capture form or progress'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_attachedFiles.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('Select from Uploaded'),
                subtitle: const Text('Choose from your uploaded files'),
                onTap: () {
                  Navigator.pop(context);
                  _showFileSelector();
                },
              ),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear All Attachments'),
              subtitle: const Text('Remove all attached files'),
              onTap: () {
                Navigator.pop(context);
                _clearAllAttachments();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getWorkoutTypeText() {
    switch (widget.workoutType) {
      case 'exercise':
        return 'Exercise';
      case 'workout':
        return 'Workout';
      case 'plan':
        return 'Plan';
      default:
        return 'Workout';
    }
  }

  void _showFilePicker() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload ${_getWorkoutTypeText()} Files',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              InlineFilePicker(
                onFileSelected: (fileData) {
                  if (fileData.isNotEmpty) {
                    _addAttachment(fileData);
                  }
                },
                onError: (error) {
                  widget.onError?.call(error);
                },
                allowMultiple: widget.allowMultiple,
                allowedTypes: widget.allowedTypes,
                showPreview: false,
                hint: 'Select files to upload',
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _recordVideo() {
    // TODO: Implement video recording functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video recording coming soon...')),
    );
  }

  void _takePhoto() {
    // TODO: Implement photo capture functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo capture coming soon...')),
    );
  }

  void _showFileSelector() {
    // TODO: Implement file selector from user's uploaded files
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File selector coming soon...')),
    );
  }

  void _addAttachment(Map<String, dynamic> fileData) {
    setState(() {
      _attachedFiles.add(fileData);
    });
    widget.onFilesAttached?.call(_attachedFiles);
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
    widget.onFilesAttached?.call(_attachedFiles);
  }

  void _clearAllAttachments() {
    setState(() {
      _attachedFiles.clear();
    });
    widget.onFilesAttached?.call(_attachedFiles);
  }

  void _previewFile(Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 600,
          height: 700,
          child: FilePreviewer(
            fileUrl: file['file_url'] ?? '',
            fileName: file['file_name'] ?? 'Unknown file',
            fileType: file['file_type'] ?? 'unknown',
            category: file['category'] ?? 'other',
            fileData: file,
            showFullScreen: true,
          ),
        ),
      ),
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
