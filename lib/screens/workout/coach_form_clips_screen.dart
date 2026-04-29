import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

/// Allows a coach to view a client's saved pose clips and rep counts.
/// Only clips where the client has opted in (save_clip = true) appear here.
class CoachFormClipsScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const CoachFormClipsScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<CoachFormClipsScreen> createState() => _CoachFormClipsScreenState();
}

class _CoachFormClipsScreenState extends State<CoachFormClipsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _clips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClips();
  }

  Future<void> _loadClips() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _supabase
          .from('pose_clips')
          .select()
          .eq('user_id', widget.clientId)
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);
      if (mounted) setState(() => _clips = List<Map<String, dynamic>>.from(rows));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pinClip(String clipId, bool pinned) async {
    final coach = _supabase.auth.currentUser;
    if (coach == null) return;
    await _supabase.from('pose_clips').update({
      'pinned': pinned,
      'pinned_by': pinned ? coach.id : null,
    }).eq('id', clipId);
    await _loadClips();
  }

  Future<String?> _signedUrl(String path) async {
    try {
      final url = await _supabase.storage
          .from('pose-clips')
          .createSignedUrl(path, 300); // 5-min signed URL
      return url;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.clientName} — Form Clips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClips,
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_clips.isEmpty) {
      return const Center(
        child: Text(
          'No saved clips yet.\nClips appear here when the client opts in during a form check session.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadClips,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _clips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _ClipCard(
          clip: _clips[i],
          onPin: (pinned) => _pinClip(_clips[i]['id'] as String, pinned),
          signedUrl: _signedUrl,
        ),
      ),
    );
  }
}

class _ClipCard extends StatelessWidget {
  final Map<String, dynamic> clip;
  final Future<void> Function(bool) onPin;
  final Future<String?> Function(String) signedUrl;

  const _ClipCard({
    required this.clip,
    required this.onPin,
    required this.signedUrl,
  });

  @override
  Widget build(BuildContext context) {
    final exercise = clip['exercise'] as String? ?? '—';
    final repCount = clip['rep_count'] as int? ?? 0;
    final quality = clip['form_quality'] as String? ?? '—';
    final pinned = clip['pinned'] as bool? ?? false;
    final createdAt = DateTime.tryParse(clip['created_at'] as String? ?? '');
    final expiresAt = DateTime.tryParse(clip['expires_at'] as String? ?? '');
    final storagePath = clip['storage_path'] as String? ?? '';

    final qualityColor = switch (quality) {
      'good' => Colors.green,
      'fair' => Colors.orange,
      _ => Colors.red,
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: qualityColor.withOpacity(0.15),
          child: Text(
            quality.substring(0, 1).toUpperCase(),
            style: TextStyle(
                color: qualityColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          _exerciseLabel(exercise),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$repCount reps · form: $quality'),
            if (createdAt != null)
              Text(
                _formatDate(createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            if (!pinned && expiresAt != null)
              Text(
                'Expires ${_formatDate(expiresAt)}',
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            if (pinned)
              const Text('Pinned — won\'t auto-delete',
                  style: TextStyle(fontSize: 11, color: Colors.green)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                pinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: pinned ? Colors.blue : Colors.grey,
              ),
              tooltip: pinned ? 'Unpin' : 'Pin (prevent auto-delete)',
              onPressed: () => onPin(!pinned),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              tooltip: 'Play clip',
              onPressed: storagePath.isEmpty
                  ? null
                  : () async {
                      final url = await signedUrl(storagePath);
                      if (url != null && context.mounted) {
                        _playVideo(context, url);
                      }
                    },
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _exerciseLabel(String e) => switch (e) {
        'squat' => 'Squat',
        'pushUp' => 'Push-up',
        'deadlift' => 'Deadlift',
        _ => e,
      };

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _playVideo(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _VideoPlayerScreen(url: url),
    ));
  }
}

class _VideoPlayerScreen extends StatefulWidget {
  final String url;
  const _VideoPlayerScreen({required this.url});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late VideoPlayerController _ctrl;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialised = true);
          _ctrl.play();
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Form clip'),
      ),
      body: Center(
        child: _initialised
            ? AspectRatio(
                aspectRatio: _ctrl.value.aspectRatio,
                child: VideoPlayer(_ctrl),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
      floatingActionButton: _initialised
          ? FloatingActionButton(
              onPressed: () {
                _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play();
                setState(() {});
              },
              child: Icon(
                  _ctrl.value.isPlaying ? Icons.pause : Icons.play_arrow),
            )
          : null,
    );
  }
}
