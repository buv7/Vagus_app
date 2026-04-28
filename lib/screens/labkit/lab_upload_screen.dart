import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/labkit/lab_work_service.dart';
import '../../theme/design_tokens.dart';
import 'lab_detail_screen.dart';

/// Lab upload screen.
///
/// Disclaimer is shown on every visit (spec requirement).
/// PII strip and audit happen inside LabWorkService — never here.
class LabUploadScreen extends StatefulWidget {
  const LabUploadScreen({super.key});

  @override
  State<LabUploadScreen> createState() => _LabUploadScreenState();
}

class _LabUploadScreenState extends State<LabUploadScreen> {
  final _service = LabWorkService();
  final _supabase = Supabase.instance.client;

  _UploadState _state = _UploadState.idle;
  String _statusMessage = '';
  String? _errorMessage;

  DateTime _labDate = DateTime.now();
  String _sex = 'male';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.primaryDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.primaryDark,
        title: const Text(
          'Upload Lab Work',
          style: TextStyle(color: DesignTokens.textPrimary),
        ),
        iconTheme:
            const IconThemeData(color: DesignTokens.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DisclaimerCard(),
              const SizedBox(height: 24),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildSexSelector(),
              const SizedBox(height: 24),
              if (_state == _UploadState.idle) ...[
                _buildUploadButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Upload PDF',
                  onTap: _pickPdf,
                ),
                const SizedBox(height: 12),
                _buildUploadButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Take / Choose Photo',
                  onTap: _pickPhoto,
                ),
              ],
              if (_state == _UploadState.processing)
                _buildProgress(),
              if (_state == _UploadState.done)
                _buildSuccess(),
              if (_errorMessage != null)
                _buildError(_errorMessage!),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.accentBlue.withAlpha(80)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: DesignTokens.accentGreen, size: 20),
            const SizedBox(width: 12),
            Text(
              'Lab Date: ${DateFormat('MMM d, yyyy').format(_labDate)}',
              style: const TextStyle(color: DesignTokens.textPrimary),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                color: DesignTokens.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSexSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.accentBlue.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Text(
            'Reference ranges for:',
            style: TextStyle(color: DesignTokens.textSecondary),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sex,
              dropdownColor: DesignTokens.secondaryDark,
              style:
                  const TextStyle(color: DesignTokens.textPrimary),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (v) => setState(() => _sex = v ?? 'male'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.accentBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        const CircularProgressIndicator(color: DesignTokens.accentGreen),
        const SizedBox(height: 16),
        Text(
          _statusMessage,
          style: const TextStyle(color: DesignTokens.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const Icon(Icons.check_circle_outline,
            color: DesignTokens.accentGreen, size: 56),
        const SizedBox(height: 12),
        Text(
          _statusMessage,
          style: const TextStyle(
              color: DesignTokens.textPrimary, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => setState(() {
            _state = _UploadState.idle;
            _statusMessage = '';
            _errorMessage = null;
          }),
          child: const Text('Upload Another'),
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.accentPink.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.accentPink.withAlpha(100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: DesignTokens.accentPink, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: DesignTokens.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close,
                color: DesignTokens.textSecondary, size: 20),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _labDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: DesignTokens.accentGreen,
            surface: DesignTokens.secondaryDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _labDate = picked);
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.first.path;
    if (path == null) return;

    await _runUpload(() async {
      _setStatus('Extracting text from PDF…');
      return _service.uploadPdf(
        File(path),
        _labDate,
        knownNames: _currentUserName(),
        sex: _sex,
      );
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    await _runUpload(() async {
      _setStatus('Running OCR on photo…');
      return _service.uploadPhoto(
        bytes,
        _labDate,
        knownNames: _currentUserName(),
        sex: _sex,
      );
    });
  }

  Future<void> _runUpload(Future<UploadResult> Function() fn) async {
    setState(() {
      _state = _UploadState.processing;
      _errorMessage = null;
    });
    try {
      _setStatus('Processing…');
      final result = await fn();
      if (!result.ok) {
        setState(() {
          _state = _UploadState.idle;
          _errorMessage = result.error;
        });
        return;
      }
      setState(() {
        _state = _UploadState.done;
        _statusMessage =
            '${result.biomarkerCount} biomarkers extracted successfully.'
            '${result.needsReviewCount > 0 ? '\n${result.needsReviewCount} need manual review.' : ''}';
      });
      // Navigate to detail after brief pause
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && result.labWorkId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                LabDetailScreen(labWorkId: result.labWorkId!),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _state = _UploadState.idle;
        _errorMessage = 'Unexpected error. Please try again.';
      });
    }
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _statusMessage = msg);
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: DesignTokens.secondaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt,
                  color: DesignTokens.accentGreen),
              title: const Text('Camera',
                  style: TextStyle(color: DesignTokens.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library,
                  color: DesignTokens.accentGreen),
              title: const Text('Photo Library',
                  style: TextStyle(color: DesignTokens.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _currentUserName() {
    final user = _supabase.auth.currentUser;
    final meta = user?.userMetadata;
    final name = meta?['full_name'] as String? ?? '';
    return name.isNotEmpty ? [name] : [];
  }
}

// ---------------------------------------------------------------------------
// Disclaimer card — shown on every visit (spec requirement)
// ---------------------------------------------------------------------------

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.accentBlue.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.accentBlue.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: DesignTokens.accentGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Important notice',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'This feature is for personal health tracking only. '
            'Values shown are not medical diagnoses. '
            'Always discuss your lab results with your healthcare provider '
            'before making any health decisions.',
            style: TextStyle(
              color: DesignTokens.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

enum _UploadState { idle, processing, done }
