import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/workout/exercise_library_models.dart';
import '../../models/workout/exercise_video.dart';
import '../../services/exercise/exercise_video_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/reel/reel_player_widget.dart';

enum _InputMode { upload, link }

class ExerciseVideoUploader extends StatefulWidget {
  final ExerciseLibraryItem exercise;
  final String? clientId;
  final VoidCallback? onVideoAdded;

  const ExerciseVideoUploader({
    super.key,
    required this.exercise,
    this.clientId,
    this.onVideoAdded,
  });

  @override
  State<ExerciseVideoUploader> createState() => _ExerciseVideoUploaderState();
}

class _ExerciseVideoUploaderState extends State<ExerciseVideoUploader>
    with TickerProviderStateMixin {
  final _linkController = TextEditingController();
  final _titleController = TextEditingController();
  final _service = ExerciseVideoService();

  late final TabController _tabController;

  _InputMode _mode = _InputMode.upload;
  File? _pickedFile;
  String? _pickedFileName;
  int? _pickedFileSizeBytes;

  List<ExerciseVideo> _existing = [];
  bool _loadingExisting = true;
  bool _saving = false;
  String? _error;
  ExerciseVideo? _previewVideo;
  bool _makeDefault = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _mode = _tabController.index == 0 ? _InputMode.upload : _InputMode.link;
        _error = null;
      });
    });
    _loadExisting();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _linkController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final videos = await _service.videosForExercise(
        exerciseId: widget.exercise.id!,
        clientId: widget.clientId,
      );
      if (mounted) {
        setState(() {
          _existing = videos;
          _loadingExisting = false;
        });
      }
    } catch (_) {
      if (mounted) { setState(() => _loadingExisting = false); }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.path == null) return;

    final sizeBytes = f.size;
    if (sizeBytes > kMaxVideoBytes) {
      _setError('File is too large (${(sizeBytes / 1024 / 1024).toStringAsFixed(0)} MB). Max 200 MB.');
      return;
    }
    setState(() {
      _pickedFile = File(f.path!);
      _pickedFileName = f.name;
      _pickedFileSizeBytes = sizeBytes;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (widget.exercise.id == null) {
      _setError('Exercise has no ID. EX-FORGE dep may not be applied yet.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      ExerciseVideo video;
      if (_mode == _InputMode.upload) {
        if (_pickedFile == null) {
          _setError('Please pick a video file first.');
          return;
        }
        video = await _service.uploadVideo(
          exerciseId: widget.exercise.id!,
          videoFile: _pickedFile!,
          clientId: widget.clientId,
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          makeDefault: _makeDefault,
        );
      } else {
        final url = _linkController.text.trim();
        if (url.isEmpty) {
          _setError('Please enter a URL.');
          return;
        }
        video = await _service.linkExternalVideo(
          exerciseId: widget.exercise.id!,
          url: url,
          clientId: widget.clientId,
          makeDefault: _makeDefault,
        );
      }
      if (mounted) {
        setState(() {
          _existing.insert(0, video);
          _previewVideo = video;
          _pickedFile = null;
          _pickedFileName = null;
          _pickedFileSizeBytes = null;
          _linkController.clear();
          _titleController.clear();
          _saving = false;
        });
        widget.onVideoAdded?.call();
        _showSuccessSnack();
      }
    } on ExerciseVideoException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteVideo(ExerciseVideo v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDeleteDialog(title: v.title ?? v.videoUrl),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteVideo(v.id!);
      if (mounted) {
        setState(() {
          _existing.removeWhere((e) => e.id == v.id);
          if (_previewVideo?.id == v.id) _previewVideo = null;
        });
      }
    } catch (e) {
      _setError('Could not delete: $e');
    }
  }

  Future<void> _setDefault(ExerciseVideo v) async {
    try {
      await _service.setDefaultVideo(
        videoId: v.id!,
        exerciseId: v.exerciseId,
        clientId: widget.clientId,
      );
      await _loadExisting();
    } catch (e) {
      _setError('Could not set default: $e');
    }
  }

  void _setError(String msg) {
    if (mounted) {
      setState(() {
        _error = msg;
        _saving = false;
      });
    }
  }

  void _showSuccessSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video added'),
        backgroundColor: DesignTokens.accentGreen,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.primaryDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.primaryDark,
        foregroundColor: DesignTokens.neutralWhite,
        title: Text(
          'Videos — ${widget.exercise.name}',
          style: DesignTokens.titleMedium.copyWith(color: DesignTokens.neutralWhite),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: DesignTokens.accentGreen,
          unselectedLabelColor: DesignTokens.textSecondary,
          indicatorColor: DesignTokens.accentGreen,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file, size: 18), text: 'Upload'),
            Tab(icon: Icon(Icons.link, size: 18), text: 'Link'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUploadTab(),
                _buildLinkTab(),
              ],
            ),
          ),
          if (_previewVideo != null) _buildPreviewSection(_previewVideo!),
          _buildExistingSection(),
        ],
      ),
    );
  }

  // ── Upload tab ─────────────────────────────────────────────────────────────

  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.clientId != null)
            const _InfoBanner(
              'Assigning to client. Video will override the default for this client only.',
            ),
          const SizedBox(height: DesignTokens.space16),
          _buildFilePicker(),
          const SizedBox(height: DesignTokens.space16),
          _buildTitleField(),
          const SizedBox(height: DesignTokens.space12),
          _buildDefaultToggle(),
          if (_error != null) ...[
            const SizedBox(height: DesignTokens.space12),
            _ErrorBanner(_error!),
          ],
          const SizedBox(height: DesignTokens.space20),
          _buildSaveButton('Upload Video'),
        ],
      ),
    );
  }

  Widget _buildFilePicker() {
    return GestureDetector(
      onTap: _saving ? null : _pickFile,
      child: Container(
        height: 130,
        width: double.infinity,
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          border: Border.all(
            color: _pickedFile != null
                ? DesignTokens.accentGreen
                : DesignTokens.glassBorder,
            width: _pickedFile != null ? 1.5 : 1,
          ),
        ),
        child: _pickedFile != null
            ? _PickedFileTile(
                name: _pickedFileName!,
                sizeBytes: _pickedFileSizeBytes!,
                onRemove: () => setState(() {
                  _pickedFile = null;
                  _pickedFileName = null;
                  _pickedFileSizeBytes = null;
                }),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined,
                      size: 36, color: DesignTokens.textSecondary),
                  SizedBox(height: 8),
                  Text('Tap to select video',
                      style: TextStyle(
                          color: DesignTokens.textSecondary, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('mp4, mov, webm • max 200 MB',
                      style: TextStyle(
                          color: DesignTokens.textSecondary, fontSize: 11)),
                ],
              ),
      ),
    );
  }

  // ── Link tab ───────────────────────────────────────────────────────────────

  Widget _buildLinkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoBanner(
            'Paste a YouTube, Instagram Reel, or TikTok URL. Videos play inside the app — no browser redirect.',
          ),
          const SizedBox(height: DesignTokens.space16),
          Text('Video URL',
              style: DesignTokens.labelMedium
                  .copyWith(color: DesignTokens.neutralWhite)),
          const SizedBox(height: DesignTokens.space8),
          TextField(
            controller: _linkController,
            style: const TextStyle(color: DesignTokens.neutralWhite),
            decoration: _inputDecoration('https://www.youtube.com/watch?v=…'),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: DesignTokens.space16),
          _buildTitleField(hint: 'Optional — auto-filled for YouTube'),
          const SizedBox(height: DesignTokens.space12),
          _buildDefaultToggle(),
          if (_error != null) ...[
            const SizedBox(height: DesignTokens.space12),
            _ErrorBanner(_error!),
          ],
          const SizedBox(height: DesignTokens.space20),
          _buildSaveButton('Add Link'),
        ],
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _buildTitleField({String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Title (optional)',
            style: DesignTokens.labelMedium
                .copyWith(color: DesignTokens.neutralWhite)),
        const SizedBox(height: DesignTokens.space8),
        TextField(
          controller: _titleController,
          style: const TextStyle(color: DesignTokens.neutralWhite),
          decoration: _inputDecoration(hint ?? 'E.g. Barbell squat — full depth'),
        ),
      ],
    );
  }

  Widget _buildDefaultToggle() {
    return Row(
      children: [
        Switch(
          value: _makeDefault,
          onChanged: (v) => setState(() => _makeDefault = v),
          activeColor: DesignTokens.accentGreen,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.clientId != null
                ? 'Set as default video for this client'
                : 'Set as default video for all clients',
            style: DesignTokens.bodySmall
                .copyWith(color: DesignTokens.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.accentGreen,
          foregroundColor: DesignTokens.primaryDark,
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.space14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
        ),
        child: _saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: DesignTokens.primaryDark),
              )
            : Text(label,
                style: DesignTokens.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.primaryDark)),
      ),
    );
  }

  // ── Preview section ────────────────────────────────────────────────────────

  Widget _buildPreviewSection(ExerciseVideo v) {
    return Container(
      color: DesignTokens.cardBackground,
      padding: const EdgeInsets.all(DesignTokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preview',
              style: DesignTokens.labelMedium
                  .copyWith(color: DesignTokens.textSecondary)),
          const SizedBox(height: 8),
          ReelPlayerWidget(
            videoUrl: v.videoUrl,
            source: v.source,
            thumbnailUrl: v.thumbnailUrl,
          ),
        ],
      ),
    );
  }

  // ── Existing videos section ────────────────────────────────────────────────

  Widget _buildExistingSection() {
    if (_loadingExisting) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
            child: CircularProgressIndicator(color: DesignTokens.accentGreen)),
      );
    }
    if (_existing.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      color: DesignTokens.primaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Existing videos (${_existing.length})',
              style: DesignTokens.labelMedium
                  .copyWith(color: DesignTokens.textSecondary),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _existing.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: DesignTokens.space8),
              itemBuilder: (_, i) => _VideoListTile(
                video: _existing[i],
                onPreview: () => setState(() => _previewVideo = _existing[i]),
                onSetDefault: () => _setDefault(_existing[i]),
                onDelete: () => _deleteVideo(_existing[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
      filled: true,
      fillColor: DesignTokens.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        borderSide: const BorderSide(color: DesignTokens.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        borderSide: const BorderSide(color: DesignTokens.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        borderSide:
            const BorderSide(color: DesignTokens.accentGreen, width: 1.5),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: DesignTokens.accentBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(color: DesignTokens.accentBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 16, color: DesignTokens.accentBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: DesignTokens.bodySmall
                    .copyWith(color: DesignTokens.accentBlue)),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;
  const _ErrorBanner(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: DesignTokens.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(color: DesignTokens.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: DesignTokens.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: DesignTokens.bodySmall
                    .copyWith(color: DesignTokens.danger)),
          ),
        ],
      ),
    );
  }
}

class _PickedFileTile extends StatelessWidget {
  final String name;
  final int sizeBytes;
  final VoidCallback onRemove;

  const _PickedFileTile({
    required this.name,
    required this.sizeBytes,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final sizeMb = (sizeBytes / 1024 / 1024).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.movie, color: DesignTokens.accentGreen, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name,
                    style: DesignTokens.labelMedium
                        .copyWith(color: DesignTokens.neutralWhite),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('$sizeMb MB',
                    style: DesignTokens.labelSmall
                        .copyWith(color: DesignTokens.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: DesignTokens.textSecondary),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _VideoListTile extends StatelessWidget {
  final ExerciseVideo video;
  final VoidCallback onPreview;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _VideoListTile({
    required this.video,
    required this.onPreview,
    required this.onSetDefault,
    required this.onDelete,
  });

  IconData get _sourceIcon {
    switch (video.source) {
      case VideoSource.youtube:
        return Icons.smart_display;
      case VideoSource.instagram:
        return Icons.camera_alt;
      case VideoSource.tiktok:
        return Icons.music_note;
      default:
        return Icons.movie;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space12, vertical: DesignTokens.space8),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(
          color: video.isDefault
              ? DesignTokens.accentGreen
              : DesignTokens.glassBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(_sourceIcon, size: 20, color: DesignTokens.accentGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title ??
                      _truncateUrl(video.videoUrl),
                  style: DesignTokens.bodySmall
                      .copyWith(color: DesignTokens.neutralWhite),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (video.isDefault)
                  Text('Default',
                      style: DesignTokens.labelSmall
                          .copyWith(color: DesignTokens.accentGreen)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow,
                size: 20, color: DesignTokens.accentBlue),
            tooltip: 'Preview',
            onPressed: onPreview,
          ),
          if (!video.isDefault)
            IconButton(
              icon: const Icon(Icons.star_border,
                  size: 20, color: DesignTokens.accentOrange),
              tooltip: 'Set as default',
              onPressed: onSetDefault,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: DesignTokens.danger),
            tooltip: 'Remove',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _truncateUrl(String url) {
    if (url.length <= 40) return url;
    return '${url.substring(0, 37)}…';
  }
}

class _ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  const _ConfirmDeleteDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignTokens.cardBackground,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16)),
      title: Text('Remove video?',
          style: DesignTokens.titleMedium
              .copyWith(color: DesignTokens.neutralWhite)),
      content: Text(
        '"$title" will be removed from this exercise.',
        style: DesignTokens.bodySmall.copyWith(color: DesignTokens.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: DesignTokens.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.danger),
          child: const Text('Remove'),
        ),
      ],
    );
  }
}

