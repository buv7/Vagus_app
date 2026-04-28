import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/workout/exercise_video.dart';
import '../media/media_url_resolver.dart';

// Max file size: 200 MB. Max duration: 120 s.
const int kMaxVideoBytes = 200 * 1024 * 1024;
const int kMaxVideoDurationSeconds = 120;

class ExerciseVideoService {
  final SupabaseClient _supabase;

  ExerciseVideoService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<List<ExerciseVideo>> videosForExercise({
    required String exerciseId,
    String? clientId,
  }) async {
    // All filters must be applied before .order() to stay on PostgrestFilterBuilder.
    final List<dynamic> rows;
    if (clientId != null) {
      rows = await _supabase
          .from('exercise_videos')
          .select()
          .eq('exercise_id', exerciseId)
          .eq('is_active', true)
          .or('client_id.is.null,client_id.eq.$clientId')
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
    } else {
      rows = await _supabase
          .from('exercise_videos')
          .select()
          .eq('exercise_id', exerciseId)
          .eq('is_active', true)
          .filter('client_id', 'is', null)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
    }
    return rows
        .map((r) => ExerciseVideo.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<ExerciseVideo?> defaultVideoForExercise({
    required String exerciseId,
    String? clientId,
  }) async {
    final videos = await videosForExercise(
      exerciseId: exerciseId,
      clientId: clientId,
    );
    if (videos.isEmpty) return null;
    final clientDefault = clientId != null
        ? videos.where((v) => v.clientId == clientId && v.isDefault).firstOrNull
        : null;
    return clientDefault ??
        videos.where((v) => v.isDefault).firstOrNull ??
        videos.first;
  }

  // ── Upload own video ───────────────────────────────────────────────────────

  Future<ExerciseVideo> uploadVideo({
    required String exerciseId,
    required File videoFile,
    String? clientId,
    String? title,
    String language = 'en',
    bool makeDefault = false,
  }) async {
    final size = await videoFile.length();
    if (size > kMaxVideoBytes) {
      throw ExerciseVideoException(
        'File exceeds 200 MB limit (${(size / 1024 / 1024).toStringAsFixed(1)} MB)',
      );
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const ExerciseVideoException('Not authenticated');

    final ext = videoFile.path.split('.').last.toLowerCase();
    const allowedExts = {'mp4', 'mov', 'webm', 'm4v'};
    if (!allowedExts.contains(ext)) {
      throw ExerciseVideoException(
        'Unsupported file type .$ext. Use mp4, mov, webm, or m4v.',
      );
    }

    final storagePath =
        'exercise-videos/$exerciseId/$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _supabase.storage.from('exercise-media').upload(storagePath, videoFile);
    final publicUrl =
        _supabase.storage.from('exercise-media').getPublicUrl(storagePath);

    if (makeDefault) {
      await _clearExistingDefaults(
          exerciseId: exerciseId, clientId: clientId, coachId: userId);
    }

    final video = ExerciseVideo(
      exerciseId: exerciseId,
      videoUrl: publicUrl,
      source: VideoSource.own,
      uploaderUserId: userId,
      language: language,
      isDefault: makeDefault,
      clientId: clientId,
      title: title,
    );

    final row = await _supabase
        .from('exercise_videos')
        .insert(video.toInsertMap())
        .select()
        .single();
    return ExerciseVideo.fromMap(row);
  }

  // ── Link external URL (YouTube / Instagram / TikTok) ─────────────────────

  Future<ExerciseVideo> linkExternalVideo({
    required String exerciseId,
    required String url,
    String? clientId,
    String language = 'en',
    bool makeDefault = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const ExerciseVideoException('Not authenticated');

    final source = _detectSource(url);
    if (source == null) {
      throw const ExerciseVideoException(
        'URL is not a supported platform (YouTube, Instagram, TikTok) or direct video file.',
      );
    }

    final meta = await _fetchExternalMeta(url, source);

    if (makeDefault) {
      await _clearExistingDefaults(
          exerciseId: exerciseId, clientId: clientId, coachId: userId);
    }

    final video = ExerciseVideo(
      exerciseId: exerciseId,
      videoUrl: url,
      source: source,
      uploaderUserId: userId,
      thumbnailUrl: meta.thumbnailUrl,
      language: language,
      isDefault: makeDefault,
      clientId: clientId,
      title: meta.title,
    );

    final row = await _supabase
        .from('exercise_videos')
        .insert(video.toInsertMap())
        .select()
        .single();
    return ExerciseVideo.fromMap(row);
  }

  // ── Set default video for a client ────────────────────────────────────────

  Future<void> setDefaultVideo({
    required String videoId,
    required String exerciseId,
    String? clientId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const ExerciseVideoException('Not authenticated');
    await _clearExistingDefaults(
        exerciseId: exerciseId, clientId: clientId, coachId: userId);
    await _supabase
        .from('exercise_videos')
        .update({'is_default': true})
        .eq('id', videoId)
        .eq('uploader_user_id', userId);
  }

  // ── Image overrides ────────────────────────────────────────────────────────

  Future<String?> resolvedImageUrl({
    required String exerciseId,
    required String coachId,
    String? clientId,
    String? fallbackUrl,
  }) async {
    final orFilter = clientId != null
        ? 'client_id.is.null,client_id.eq.$clientId'
        : 'client_id.is.null';
    final rows = await _supabase
        .from('exercise_image_overrides')
        .select('image_url')
        .eq('exercise_id', exerciseId)
        .eq('coach_id', coachId)
        .or(orFilter)
        .order('client_id', ascending: false)
        .limit(1);

    if (rows.isNotEmpty) {
      return MediaUrlResolver.resolve(rows.first['image_url'] as String);
    }
    return fallbackUrl != null ? MediaUrlResolver.resolve(fallbackUrl) : null;
  }

  Future<void> upsertImageOverride({
    required String exerciseId,
    required String imageUrl,
    String? clientId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const ExerciseVideoException('Not authenticated');
    await _supabase.from('exercise_image_overrides').upsert({
      'exercise_id': exerciseId,
      'coach_id': userId,
      if (clientId != null) 'client_id': clientId,
      'image_url': imageUrl,
    }, onConflict: 'exercise_id,coach_id,client_id');
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteVideo(String videoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const ExerciseVideoException('Not authenticated');
    await _supabase
        .from('exercise_videos')
        .update({'is_active': false})
        .eq('id', videoId)
        .eq('uploader_user_id', userId);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _clearExistingDefaults({
    required String exerciseId,
    required String? clientId,
    required String coachId,
  }) async {
    if (clientId != null) {
      await _supabase
          .from('exercise_videos')
          .update({'is_default': false})
          .eq('exercise_id', exerciseId)
          .eq('uploader_user_id', coachId)
          .eq('is_default', true)
          .eq('client_id', clientId);
    } else {
      await _supabase
          .from('exercise_videos')
          .update({'is_default': false})
          .eq('exercise_id', exerciseId)
          .eq('uploader_user_id', coachId)
          .eq('is_default', true)
          .filter('client_id', 'is', null);
    }
  }

  VideoSource? _detectSource(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return VideoSource.youtube;
    }
    if (url.contains('instagram.com')) return VideoSource.instagram;
    if (url.contains('tiktok.com')) return VideoSource.tiktok;
    if (url.endsWith('.mp4') || url.endsWith('.mov') || url.endsWith('.webm')) {
      return VideoSource.own;
    }
    return null;
  }

  Future<_ExternalMeta> _fetchExternalMeta(
      String url, VideoSource source) async {
    try {
      if (source == VideoSource.youtube) {
        return await _youtubeOembed(url);
      }
      return const _ExternalMeta();
    } catch (_) {
      return const _ExternalMeta();
    }
  }

  Future<_ExternalMeta> _youtubeOembed(String url) async {
    final oembedUrl = Uri.parse(
      'https://www.youtube.com/oembed?url=${Uri.encodeComponent(url)}&format=json',
    );
    final response =
        await http.get(oembedUrl).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return const _ExternalMeta();

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _ExternalMeta(
      title: data['title'] as String?,
      thumbnailUrl: data['thumbnail_url'] as String?,
    );
  }
}

class _ExternalMeta {
  final String? title;
  final String? thumbnailUrl;

  const _ExternalMeta({this.title, this.thumbnailUrl});
}

class ExerciseVideoException implements Exception {
  final String message;
  const ExerciseVideoException(this.message);
  @override
  String toString() => 'ExerciseVideoException: $message';
}
