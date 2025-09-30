import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../theme/design_tokens.dart';

class AttachmentPicker extends StatefulWidget {
  final Function(File file) onFileSelected;
  final Function(File audioFile) onVoiceRecorded;

  const AttachmentPicker({
    super.key,
    required this.onFileSelected,
    required this.onVoiceRecorded,
  });

  @override
  State<AttachmentPicker> createState() => _AttachmentPickerState();
}

class _AttachmentPickerState extends State<AttachmentPicker> {

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
          const Text(
            'Add Attachment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOption(
                context,
                icon: Icons.image,
                label: 'Photo',
                onTap: () => _pickImage(context),
              ),
              _buildOption(
                context,
                icon: Icons.video_library,
                label: 'Video',
                onTap: () => _pickVideo(context),
              ),
              _buildOption(
                context,
                icon: Icons.mic,
                label: 'Voice',
                onTap: () => _recordVoice(context),
              ),
              _buildOption(
                context,
                icon: Icons.attach_file,
                label: 'File',
                onTap: () => _pickFile(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue[700], size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        widget.onFileSelected(file);
        if (!mounted || !context.mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        widget.onFileSelected(file);
        if (!mounted || !context.mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick video: $e')),
      );
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'txt', 'md', 'json', 'xml',
          'jpg', 'jpeg', 'png', 'gif', 'webp',
          'mp3', 'wav', 'm4a', 'aac',
          'mp4', 'avi', 'mov', 'mkv',
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        widget.onFileSelected(file);
        if (!mounted || !context.mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  Future<void> _recordVoice(BuildContext context) async {
    // For now, we'll simulate voice recording by picking an audio file
    // In a real implementation, you'd use a voice recording package
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        widget.onVoiceRecorded(file);
        if (!mounted || !context.mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record voice: $e')),
      );
    }
  }
}
