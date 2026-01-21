import 'package:flutter/material.dart';
import 'inline_file_picker.dart';
import 'file_previewer.dart';
import '../../theme/design_tokens.dart';

/// Attach to Note Button Widget
/// Allows attaching files to notes
class AttachToNoteButton extends StatefulWidget {
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

  const AttachToNoteButton({
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
  });

  @override
  State<AttachToNoteButton> createState() => _AttachToNoteButtonState();
}

class _AttachToNoteButtonState extends State<AttachToNoteButton> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : DesignTokens.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Attach button with glassmorphism style
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(DesignTokens.radius16),
              border: Border.all(
                color: isDark 
                    ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                    : DesignTokens.borderColor(context),
              ),
              boxShadow: isDark ? [
                BoxShadow(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ] : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showAttachmentOptions,
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                              : DesignTokens.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radius8),
                        ),
                        child: Icon(
                          Icons.attach_file,
                          color: DesignTokens.accentBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.hint ?? 'Attach files to note',
                              style: TextStyle(
                                color: isDark ? Colors.white : DesignTokens.textColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_attachedFiles.isNotEmpty)
                              Text(
                                '${_attachedFiles.length} file${_attachedFiles.length == 1 ? '' : 's'} attached',
                                style: TextStyle(
                                  color: isDark 
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : DesignTokens.textColorSecondary(context),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.add,
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.6)
                            : DesignTokens.textColorSecondary(context),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildAttachmentsPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attached Files:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey.shade700,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fileName = file['file_name'] ?? 'Unknown file';
    final fileSize = file['file_size'] ?? 0;
    final category = file['category'] ?? 'other';
    final fileUrl = file['file_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark 
            ? DesignTokens.accentBlue.withValues(alpha: 0.1)
            : Colors.grey.shade50,
        border: Border.all(
          color: isDark 
              ? DesignTokens.accentBlue.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark 
                  ? _getFileColor(category).withValues(alpha: 0.2)
                  : _getFileColor(category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
              border: Border.all(
                color: isDark 
                    ? _getFileColor(category).withValues(alpha: 0.3)
                    : _getFileColor(category).withValues(alpha: 0.2),
              ),
            ),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: isDark ? Colors.white : DesignTokens.textColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatFileSize(fileSize),
                  style: TextStyle(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.grey.shade600,
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
                  icon: Icon(
                    Icons.visibility, 
                    size: 20,
                    color: isDark ? Colors.white.withValues(alpha: 0.8) : null,
                  ),
                  onPressed: () => _previewFile(file),
                  tooltip: 'Preview file',
                ),
              IconButton(
                icon: Icon(
                  Icons.close, 
                  size: 20,
                  color: isDark ? Colors.white.withValues(alpha: 0.8) : null,
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: isDark 
                ? DesignTokens.accentBlue.withValues(alpha: 0.4)
                : DesignTokens.borderColor(context),
            width: isDark ? 2 : 1,
          ),
          boxShadow: isDark ? [
            BoxShadow(
              color: DesignTokens.accentBlue.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, -8),
            ),
          ] : null,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Attach Files',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : DesignTokens.textColor(context),
                ),
              ),
              const SizedBox(height: 16),
              _buildBottomSheetTile(
                context: ctx,
                isDark: isDark,
                icon: Icons.attach_file,
                iconColor: DesignTokens.accentBlue,
                title: 'Add New Files',
                subtitle: 'Upload files from device',
                onTap: () {
                  Navigator.pop(ctx);
                  _showFilePicker();
                },
              ),
              if (_attachedFiles.isNotEmpty)
                _buildBottomSheetTile(
                  context: ctx,
                  isDark: isDark,
                  icon: Icons.folder_open,
                  iconColor: DesignTokens.accentPurple,
                  title: 'Select from Uploaded',
                  subtitle: 'Choose from your uploaded files',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showFileSelector();
                  },
                ),
              _buildBottomSheetTile(
                context: ctx,
                isDark: isDark,
                icon: Icons.clear_all,
                iconColor: DesignTokens.accentOrange,
                title: 'Clear All Attachments',
                subtitle: 'Remove all attached files',
                onTap: () {
                  Navigator.pop(ctx);
                  _clearAllAttachments();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBottomSheetTile({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: iconColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : DesignTokens.textColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.6)
              : DesignTokens.textColorSecondary(context),
          fontSize: 12,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
    );
  }

  void _showFilePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: isDark ? DesignTokens.darkBackground : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
          side: BorderSide(
            color: isDark 
                ? DesignTokens.accentBlue.withValues(alpha: 0.4)
                : DesignTokens.borderColor(context),
            width: isDark ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload Files',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : DesignTokens.textColor(context),
                ),
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
                  Container(
                    decoration: BoxDecoration(
                      color: DesignTokens.accentBlue,
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(dialogContext),
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
