// REEL_HANDOFF: This widget is the EX-MEDIA stub for the in-app video player.
// When REEL ships, REEL agent should extend or replace the _ReelVideoPlayerState
// with its full player implementation (controls, progress bar, fullscreen, etc.).
// Interface contract:
//   - ReelPlayerWidget(videoUrl, source) → plays video in-app, never opens browser.
//   - YouTube/Instagram/TikTok → embedded WebView (flutter_inappwebview).
//   - own/other → video_player controller.
//   - thumbnailUrl shown while loading.

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:video_player/video_player.dart';

import '../../models/workout/exercise_video.dart';
import '../../services/media/media_url_resolver.dart';
import '../../theme/design_tokens.dart';

class ReelPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final VideoSource source;
  final String? thumbnailUrl;
  final double? aspectRatio;

  const ReelPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.source,
    this.thumbnailUrl,
    this.aspectRatio,
  });

  @override
  State<ReelPlayerWidget> createState() => _ReelPlayerWidgetState();
}

class _ReelPlayerWidgetState extends State<ReelPlayerWidget> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showWebView = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  bool get _isEmbedded =>
      widget.source == VideoSource.youtube ||
      widget.source == VideoSource.instagram ||
      widget.source == VideoSource.tiktok;

  void _init() {
    if (_isEmbedded) return; // WebView initializes on tap.
    final resolved = MediaUrlResolver.resolve(widget.videoUrl);
    _videoController = VideoPlayerController.networkUrl(Uri.parse(resolved))
      ..initialize().then((_) {
        if (mounted) setState(() => _isInitialized = true);
      }).catchError((_) {
        if (mounted) setState(() => _hasError = true);
      });
  }

  String _embedUrl() {
    final url = widget.videoUrl;
    switch (widget.source) {
      case VideoSource.youtube:
        // Convert watch URLs to embed URLs
        final videoId = _extractYoutubeId(url);
        if (videoId != null) {
          return 'https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1';
        }
        return url;
      case VideoSource.instagram:
        // Instagram embed: append /embed to the reel/post URL
        final raw = url.split('?').first;
        final base = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
        return '$base/embed/';
      case VideoSource.tiktok:
        // TikTok does not offer a standard embed; use the share URL in a WebView
        return url;
      default:
        return url;
    }
  }

  String? _extractYoutubeId(String url) {
    final regexps = [
      RegExp(r'v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'embed/([a-zA-Z0-9_-]{11})'),
    ];
    for (final re in regexps) {
      final match = re.firstMatch(url);
      if (match != null) return match.group(1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.aspectRatio ?? 16 / 9;
    return AspectRatio(
      aspectRatio: ratio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_hasError) return _errorPlaceholder();

    if (_isEmbedded) {
      if (!_showWebView) return _thumbnailWithPlayButton(onTap: () => setState(() => _showWebView = true));
      return _buildWebView();
    }

    if (!_isInitialized) {
      return _thumbnailWithPlayButton(onTap: null);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
        });
      },
      child: Stack(
        children: [
          VideoPlayer(_videoController!),
          if (!_videoController!.value.isPlaying)
            const Center(
              child: Icon(Icons.play_circle_fill,
                  size: 56, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_embedUrl())),
      initialSettings: InAppWebViewSettings(
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        javaScriptEnabled: true,
        transparentBackground: true,
      ),
    );
  }

  Widget _thumbnailWithPlayButton({VoidCallback? onTap}) {
    final thumb = widget.thumbnailUrl != null
        ? MediaUrlResolver.thumbnail(widget.thumbnailUrl)
        : '';
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumb.isNotEmpty)
            Image.network(thumb, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _blankBackground())
          else
            _blankBackground(),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.play_arrow, size: 40, color: Colors.white),
            ),
          ),
          if (onTap == null)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _blankBackground() => Container(color: DesignTokens.primaryDark);

  Widget _errorPlaceholder() {
    return Container(
      color: DesignTokens.primaryDark,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: DesignTokens.textSecondary, size: 32),
            SizedBox(height: 8),
            Text('Could not load video',
                style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
