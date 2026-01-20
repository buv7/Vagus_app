import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import '../../theme/theme_index.dart';
import '../../theme/theme_colors.dart';

/// Preview attachment in message (image/video/file)
class AttachmentPreview extends StatefulWidget {
  final String fileUrl;
  final String fileType; // 'image', 'video', 'file'
  final String? fileName;
  final Function()? onTap;
  final double? width;
  final double? height;

  const AttachmentPreview({
    super.key,
    required this.fileUrl,
    required this.fileType,
    this.fileName,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  State<AttachmentPreview> createState() => _AttachmentPreviewState();
}

class _AttachmentPreviewState extends State<AttachmentPreview> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.fileType == 'video') {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.fileUrl),
      );
      await _videoController!.initialize();
      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      debugPrint('Video initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: widget.onTap ?? () => _showFullScreen(context),
      child: Container(
        width: widget.width ?? 200,
        height: widget.height ?? 150,
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(radiusM),
          border: Border.all(
            color: primaryAccent.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radiusM),
          child: _buildPreviewContent(),
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    switch (widget.fileType) {
      case 'image':
        return Image.network(
          widget.fileUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _buildErrorWidget(),
        );
      
      case 'video':
        if (_isVideoInitialized && _videoController != null) {
          return Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
              ),
                child: Builder(
                  builder: (context) {
                    final tc = ThemeColors.of(context);
                    return Icon(
                      Icons.play_circle_outline,
                      size: 48,
                      color: tc.textPrimary,
                    );
                  },
                ),
              ),
            ],
          );
        }
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(mintAqua),
          ),
        );
      
      case 'file':
      default:
        return _buildFilePreview();
    }
  }

  Widget _buildFilePreview() {
    return Builder(
      builder: (context) {
        final tc = ThemeColors.of(context);
        final extension = widget.fileName?.split('.').last.toUpperCase() ?? 'FILE';
        
        return Container(
          color: tc.surfaceAlt,
          padding: const EdgeInsets.all(spacing3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getFileIcon(extension),
                size: 48,
                color: mintAqua,
              ),
              const SizedBox(height: spacing2),
              Text(
                widget.fileName ?? 'File',
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildErrorWidget() {
    return Builder(
      builder: (context) {
        final tc = ThemeColors.of(context);
        return Container(
          color: tc.surfaceAlt,
          child: Center(
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: tc.textSecondary,
            ),
          ),
        );
      },
    );
  }

  void _showFullScreen(BuildContext context) {
    if (widget.fileType == 'image') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: PhotoView(
              imageProvider: NetworkImage(widget.fileUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
          ),
        ),
      );
    } else if (widget.fileType == 'video' && _videoController != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _VideoFullScreen(
            controller: _videoController!,
          ),
        ),
      );
    }
  }
}

class _VideoFullScreen extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoFullScreen({required this.controller});

  @override
  State<_VideoFullScreen> createState() => _VideoFullScreenState();
}

class _VideoFullScreenState extends State<_VideoFullScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: widget.controller.value.aspectRatio,
          child: VideoPlayer(widget.controller),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            widget.controller.value.isPlaying
                ? widget.controller.pause()
                : widget.controller.play();
          });
        },
        child: Icon(
          widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}


