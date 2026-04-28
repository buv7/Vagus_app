// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// ─── Source detection ────────────────────────────────────────────────────────

enum VideoSource { mp4, youtube, webview }

VideoSource detectVideoSource(String url) {
  final u = url.toLowerCase();
  if (u.contains('youtu.be') || u.contains('youtube.com')) {
    return VideoSource.youtube;
  }
  if (u.contains('instagram.com') || u.contains('tiktok.com')) {
    return VideoSource.webview;
  }
  return VideoSource.mp4;
}

/// Converts an Instagram or TikTok share URL to its embeddable iframe URL.
/// Returns [url] unchanged for unknown sources.
String toEmbedUrl(String url) {
  // Instagram reel or post → /embed/
  final ig = RegExp(r'instagram\.com/(?:reel|p)/([A-Za-z0-9_-]+)');
  final igM = ig.firstMatch(url);
  if (igM != null) {
    return 'https://www.instagram.com/p/${igM.group(1)}/embed/';
  }
  // TikTok video → embed/v2/{id}
  final tt = RegExp(r'tiktok\.com/@[^/]+/video/(\d+)');
  final ttM = tt.firstMatch(url);
  if (ttM != null) {
    return 'https://www.tiktok.com/embed/v2/${ttM.group(1)}';
  }
  return url;
}

// ─── Constants ───────────────────────────────────────────────────────────────

const List<double> kReelSpeeds = [0.5, 1.0, 1.5, 2.0];
const double _kFloatW = 220;
const double _kFloatH = 128;

// ─── Controller ──────────────────────────────────────────────────────────────

/// Singleton controller — keeps video playing across routes and floating mode.
///
/// Usage:
///   ReelPlayerController.instance.load(url, autoPlay: true);
///   ReelPlayerController.instance.minimize(context); // → floating overlay
///   ReelPlayerController.instance.expand(); // → back to inline
class ReelPlayerController extends ChangeNotifier {
  ReelPlayerController._();
  static final ReelPlayerController instance = ReelPlayerController._();

  String? _url;
  VideoSource? _src;
  double _speed = 1.0;
  bool isLooping = false;
  bool isFloating = false;
  Duration _resumeAt = Duration.zero;

  VideoPlayerController? _vp;
  YoutubePlayerController? _yt;
  OverlayEntry? _overlay;
  Offset _floatPos = const Offset(12, 420);

  // ── Getters ──────────────────────────────────────────────────────────────

  String? get url => _url;
  VideoSource? get src => _src;
  double get speed => _speed;
  Offset get floatPos => _floatPos;
  VideoPlayerController? get vp => _vp;
  YoutubePlayerController? get yt => _yt;

  bool get isLoaded => switch (_src) {
    VideoSource.mp4 => _vp?.value.isInitialized ?? false,
    VideoSource.youtube => _yt != null,
    VideoSource.webview => _url != null,
    null => false,
  };

  bool get isPlaying {
    if (_vp != null) return _vp!.value.isPlaying;
    if (_yt != null) return _yt!.value.isPlaying;
    return false;
  }

  Duration get position => _vp?.value.position ?? Duration.zero;
  Duration get duration => _vp?.value.duration ?? Duration.zero;

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<void> load(String url, {bool autoPlay = false}) async {
    if (_url == url && isLoaded) {
      if (autoPlay) play();
      return;
    }
    _disposeControllers();
    _url = url;
    _src = detectVideoSource(url);
    _resumeAt = Duration.zero;

    switch (_src!) {
      case VideoSource.mp4:
        _vp = VideoPlayerController.networkUrl(Uri.parse(url));
        await _vp!.initialize();
        await _vp!.setLooping(isLooping);
        await _vp!.setPlaybackSpeed(_speed);
        _vp!.addListener(notifyListeners);
        if (autoPlay) await _vp!.play();

      case VideoSource.youtube:
        final id = YoutubePlayer.convertUrlToId(url) ?? url;
        _yt = YoutubePlayerController(
          initialVideoId: id,
          flags: YoutubePlayerFlags(
            autoPlay: autoPlay,
            loop: false, // handled manually in onEnded so we can toggle at runtime
            enableCaption: true,
          ),
        );
        _yt!.addListener(notifyListeners);

      case VideoSource.webview:
        break; // WebView widget is self-contained
    }
    notifyListeners();
  }

  // ── Playback ─────────────────────────────────────────────────────────────

  void play() {
    _vp?.play();
    _yt?.play();
    notifyListeners();
  }

  void pause() {
    _vp?.pause();
    _yt?.pause();
    notifyListeners();
  }

  void togglePlayPause() => isPlaying ? pause() : play();

  void seek(Duration pos) {
    _vp?.seekTo(pos);
    _yt?.seekTo(pos);
  }

  void setSpeed(double s) {
    _speed = s;
    _vp?.setPlaybackSpeed(s);
    _yt?.setPlaybackRate(s);
    notifyListeners();
  }

  void toggleLoop() {
    isLooping = !isLooping;
    _vp?.setLooping(isLooping);
    notifyListeners();
  }

  // ── Floating mode ────────────────────────────────────────────────────────

  /// Minimizes the player to a draggable floating overlay.
  /// [context] must be a widget context inside the app's Navigator tree.
  void minimize(BuildContext context) {
    if (isFloating) return;
    _resumeAt = position;
    isFloating = true;
    notifyListeners();
    final overlay = Overlay.of(context, rootOverlay: true);
    _overlay = OverlayEntry(builder: (_) => _FloatingReel(ctrl: this));
    overlay.insert(_overlay!);
  }

  /// Dismisses the floating overlay and resumes inline.
  void expand() {
    if (!isFloating) return;
    _overlay?.remove();
    _overlay = null;
    isFloating = false;
    if (_src == VideoSource.mp4) seek(_resumeAt);
    notifyListeners();
  }

  /// Closes the floating widget and stops playback.
  void dismiss() {
    _overlay?.remove();
    _overlay = null;
    isFloating = false;
    pause();
    notifyListeners();
  }

  void dragFloat(Offset delta, Size screen) {
    final nx = (_floatPos.dx + delta.dx)
        .clamp(0.0, screen.width - _kFloatW);
    final ny = (_floatPos.dy + delta.dy)
        .clamp(0.0, screen.height - _kFloatH);
    _floatPos = Offset(nx, ny);
    _overlay?.markNeedsBuild();
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  void _disposeControllers() {
    _vp?.removeListener(notifyListeners);
    _vp?.dispose();
    _vp = null;
    _yt?.removeListener(notifyListeners);
    _yt?.dispose();
    _yt = null;
  }

  void reset() {
    dismiss();
    _disposeControllers();
    _url = null;
    _src = null;
    notifyListeners();
  }
}

// ─── ReelPlayer ──────────────────────────────────────────────────────────────

/// Universal in-app video player.
///
/// Detects URL type automatically:
///   • mp4 / m3u8 → video_player (native)
///   • YouTube     → youtube_player_flutter (no external browser)
///   • Instagram / TikTok → flutter_inappwebview (embedded)
///
/// Tap the screen to show/hide controls. Tap the floating button to minimize
/// to a draggable pip overlay that persists while navigating other screens.
class ReelPlayer extends StatefulWidget {
  final String url;
  final bool autoPlay;
  final double aspectRatio;

  const ReelPlayer({
    super.key,
    required this.url,
    this.autoPlay = false,
    this.aspectRatio = 16 / 9,
  });

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  final _ctrl = ReelPlayerController.instance;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.load(widget.url, autoPlay: widget.autoPlay);
    });
  }

  @override
  void didUpdateWidget(ReelPlayer old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _ctrl.load(widget.url, autoPlay: widget.autoPlay);
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_ctrl.isFloating) return _buildPlaceholder();

    if (!_ctrl.isLoaded) {
      return _buildLoading();
    }

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildVideoLayer(),
              if (_showControls) _buildControlsOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoLayer() {
    switch (_ctrl.src!) {
      case VideoSource.mp4:
        final vp = _ctrl.vp!;
        return AspectRatio(
          aspectRatio: vp.value.aspectRatio,
          child: VideoPlayer(vp),
        );

      case VideoSource.youtube:
        return YoutubePlayer(
          controller: _ctrl.yt!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.white,
          onEnded: (_) {
            if (_ctrl.isLooping) {
              _ctrl.yt!.seekTo(Duration.zero);
              _ctrl.yt!.play();
            }
          },
        );

      case VideoSource.webview:
        return _WebViewPlayer(url: _ctrl.url!);
    }
  }

  Widget _buildControlsOverlay(BuildContext context) {
    final isYt = _ctrl.src == VideoSource.youtube;
    final isWeb = _ctrl.src == VideoSource.webview;

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.65),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!isYt && !isWeb) _SeekBar(ctrl: _ctrl),
            _ControlBar(ctrl: _ctrl, showSeekFeedback: !isYt && !isWeb),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        color: Colors.black87,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.picture_in_picture,
              color: Colors.white54,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Playing in floating window',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _ctrl.expand,
              icon: const Icon(Icons.open_in_full, size: 16),
              label: const Text('Expand'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Control bar ─────────────────────────────────────────────────────────────

class _ControlBar extends StatelessWidget {
  final ReelPlayerController ctrl;
  final bool showSeekFeedback;

  const _ControlBar({required this.ctrl, required this.showSeekFeedback});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              ctrl.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: ctrl.togglePlayPause,
          ),
          const Spacer(),
          _SpeedButton(ctrl: ctrl),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.loop,
              color: ctrl.isLooping ? Colors.white : Colors.white54,
            ),
            onPressed: ctrl.toggleLoop,
            tooltip: 'Loop',
          ),
          IconButton(
            icon: const Icon(
              Icons.picture_in_picture_alt,
              color: Colors.white,
            ),
            onPressed: () => ctrl.minimize(context),
            tooltip: 'Float',
          ),
        ],
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final ReelPlayerController ctrl;
  const _SpeedButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${ctrl.speed}x',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: kReelSpeeds
              .map(
                (s) => ListTile(
                  title: Text('${s}x'),
                  selected: ctrl.speed == s,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  onTap: () {
                    ctrl.setSpeed(s);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SeekBar extends StatelessWidget {
  final ReelPlayerController ctrl;
  const _SeekBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final dur = ctrl.duration.inMilliseconds.toDouble();
    final pos = ctrl.position.inMilliseconds.toDouble().clamp(0.0, dur);
    if (dur <= 0) return const SizedBox.shrink();

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        overlayColor: Colors.white24,
      ),
      child: Slider(
        min: 0,
        max: dur,
        value: pos,
        onChanged: (v) => ctrl.seek(Duration(milliseconds: v.toInt())),
      ),
    );
  }
}

// ─── WebView player ──────────────────────────────────────────────────────────

class _WebViewPlayer extends StatefulWidget {
  final String url;
  const _WebViewPlayer({required this.url});

  @override
  State<_WebViewPlayer> createState() => _WebViewPlayerState();
}

class _WebViewPlayerState extends State<_WebViewPlayer> {
  late final String _embedUrl = toEmbedUrl(widget.url);

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_embedUrl)),
      initialSettings: InAppWebViewSettings(
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        useHybridComposition: true,
        javaScriptEnabled: true,
      ),
    );
  }
}

// ─── Floating overlay ────────────────────────────────────────────────────────

class _FloatingReel extends StatefulWidget {
  final ReelPlayerController ctrl;
  const _FloatingReel({required this.ctrl});

  @override
  State<_FloatingReel> createState() => _FloatingReelState();
}

class _FloatingReelState extends State<_FloatingReel> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final screen = MediaQuery.of(context).size;

    return Positioned(
      left: ctrl.floatPos.dx,
      top: ctrl.floatPos.dy,
      child: GestureDetector(
        onPanUpdate: (d) => ctrl.dragFloat(d.delta, screen),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: _kFloatW,
            height: _kFloatH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  _buildMiniPlayer(ctrl),
                  _buildMiniControls(ctrl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(ReelPlayerController ctrl) {
    switch (ctrl.src) {
      case VideoSource.mp4:
        final vp = ctrl.vp;
        if (vp == null || !vp.value.isInitialized) {
          return Container(color: Colors.black);
        }
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: vp.value.size.width,
            height: vp.value.size.height,
            child: VideoPlayer(vp),
          ),
        );

      case VideoSource.youtube:
        final yt = ctrl.yt;
        if (yt == null) return Container(color: Colors.black);
        return YoutubePlayer(
          controller: yt,
          showVideoProgressIndicator: false,
          onEnded: (_) {
            if (ctrl.isLooping) {
              yt.seekTo(Duration.zero);
              yt.play();
            }
          },
        );

      case VideoSource.webview:
        return _WebViewPlayer(url: ctrl.url!);

      case null:
        return Container(color: Colors.black);
    }
  }

  Widget _buildMiniControls(ReelPlayerController ctrl) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent, Colors.black45],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniBtn(Icons.open_in_full, onTap: ctrl.expand),
                _miniBtn(Icons.close, onTap: ctrl.dismiss),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _miniBtn(
                  ctrl.isPlaying ? Icons.pause : Icons.play_arrow,
                  onTap: ctrl.togglePlayPause,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
