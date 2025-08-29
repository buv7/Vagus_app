import 'package:flutter/material.dart';
import '../../models/google/google_models.dart';
import '../../services/google/google_apps_service.dart';

/// Widget to display a Google Drive file attachment
class DriveAttachmentChip extends StatelessWidget {
  final GoogleFileLink file;
  final VoidCallback? onRemove;

  const DriveAttachmentChip({
    super.key,
    required this.file,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      child: InkWell(
        onTap: () => _openFile(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 200),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFileIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getFileTypeName(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    IconData iconData;
    Color iconColor;

    if (file.mime.contains('document')) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (file.mime.contains('spreadsheet')) {
      iconData = Icons.table_chart;
      iconColor = Colors.green;
    } else if (file.mime.contains('presentation')) {
      iconData = Icons.slideshow;
      iconColor = Colors.orange;
    } else if (file.mime.contains('image')) {
      iconData = Icons.image;
      iconColor = Colors.purple;
    } else if (file.mime.contains('video')) {
      iconData = Icons.video_file;
      iconColor = Colors.red;
    } else if (file.mime.contains('audio')) {
      iconData = Icons.audio_file;
      iconColor = Colors.pink;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        iconData,
        size: 18,
        color: iconColor,
      ),
    );
  }

  String _getFileTypeName() {
    if (file.mime.contains('document')) return 'Google Doc';
    if (file.mime.contains('spreadsheet')) return 'Google Sheet';
    if (file.mime.contains('presentation')) return 'Google Slides';
    if (file.mime.contains('image')) return 'Image';
    if (file.mime.contains('video')) return 'Video';
    if (file.mime.contains('audio')) return 'Audio';
    if (file.mime.contains('pdf')) return 'PDF';
    return 'File';
  }

  Future<void> _openFile(BuildContext context) async {
    final googleService = GoogleAppsService();
    final success = await googleService.openUrl(file.webUrl);
    
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open file. Please check the URL.'),
        ),
      );
    }
  }
}

/// Widget to display a list of Google Drive attachments
class DriveAttachmentsList extends StatelessWidget {
  final List<GoogleFileLink> files;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  const DriveAttachmentsList({
    super.key,
    required this.files,
    this.onRemove,
    this.showRemoveButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Wrap(
      children: files.map((file) => DriveAttachmentChip(
        file: file,
        onRemove: showRemoveButton ? onRemove : null,
      )).toList(),
    );
  }
}
