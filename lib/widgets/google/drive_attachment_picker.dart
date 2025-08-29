import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/google/google_models.dart';
import '../../services/google/google_apps_service.dart';

/// Widget for picking and attaching Google Drive files
class DriveAttachmentPicker extends StatefulWidget {
  final DriveAttachmentTarget target;
  final Function(GoogleFileLink) onAttachmentSelected;

  const DriveAttachmentPicker({
    super.key,
    required this.target,
    required this.onAttachmentSelected,
  });

  @override
  State<DriveAttachmentPicker> createState() => _DriveAttachmentPickerState();
}

class _DriveAttachmentPickerState extends State<DriveAttachmentPicker> {
  final GoogleAppsService _googleService = GoogleAppsService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }





  Future<void> _attachFile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Create GoogleFileLink from form data
      final link = GoogleFileLink(
        id: '', // Will be set by database
        ownerId: '', // Will be set by service
        googleId: _extractGoogleId(_urlController.text),
        mime: _detectMimeType(_urlController.text),
        name: _nameController.text.trim(),
        webUrl: _urlController.text.trim(),
        createdAt: DateTime.now(),
      );

      final success = await _googleService.attachDriveLink(
        target: widget.target,
        link: link,
      );

      if (success && mounted) {
        widget.onAttachmentSelected(link);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File attached successfully!')),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to attach file')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _extractGoogleId(String url) {
    // Extract Google Drive file ID from URL
    // Example: https://drive.google.com/file/d/1ABC123/view -> 1ABC123
    final regex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    return match?.group(1) ?? 'unknown';
  }

  String _detectMimeType(String url) {
    // Simple MIME type detection based on URL
    if (url.contains('docs.google.com/document')) return 'application/vnd.google-apps.document';
    if (url.contains('docs.google.com/spreadsheets')) return 'application/vnd.google-apps.spreadsheet';
    if (url.contains('docs.google.com/presentation')) return 'application/vnd.google-apps.presentation';
    if (url.contains('drive.google.com/file')) return 'application/octet-stream';
    return 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Attach from Google Drive'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'File Name',
                hintText: 'Enter a name for this file',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a file name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Google Drive URL',
                hintText: 'Paste the Google Drive file URL',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a Google Drive URL';
                }
                if (!value.contains('drive.google.com') && !value.contains('docs.google.com')) {
                  return 'Please enter a valid Google Drive URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Paste the sharing URL from Google Drive or Google Docs',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => unawaited(_attachFile()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Attach'),
        ),
      ],
    );
  }
}

/// Extension method to show Drive attachment picker
extension DriveAttachmentPickerExtension on BuildContext {
  Future<void> showDriveAttachmentPicker({
    required DriveAttachmentTarget target,
    required Function(GoogleFileLink) onAttachmentSelected,
  }) async {
    final googleService = GoogleAppsService();
    final isConnected = await googleService.isConnected();
    
    if (!isConnected) {
      // Show connection required dialog
      await showDialog(
        context: this,
        builder: (context) => AlertDialog(
          title: const Text('Google Account Required'),
          content: const Text(
            'You need to connect your Google account to attach files from Drive. '
            'Go to Settings > Google Integration to connect your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to Google Integrations screen
                unawaited(Navigator.pushNamed(context, '/settings/google-integrations'));
              },
              child: const Text('Connect Account'),
            ),
          ],
        ),
      );
      return;
    }

    // Show attachment picker
    await showDialog(
      context: this,
      builder: (context) => DriveAttachmentPicker(
        target: target,
        onAttachmentSelected: onAttachmentSelected,
      ),
    );
  }
}
