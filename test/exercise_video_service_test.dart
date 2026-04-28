import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/models/workout/exercise_video.dart';
import 'package:vagus_app/services/exercise/exercise_video_service.dart';
import 'package:vagus_app/services/media/media_url_resolver.dart';

void main() {
  group('ExerciseVideo.fromMap', () {
    test('parses all fields correctly', () {
      final map = {
        'id': 'vid-1',
        'exercise_id': 'ex-1',
        'video_url': 'https://cdn.example.com/v.mp4',
        'source': 'own',
        'uploader_user_id': 'user-1',
        'duration_seconds': 90,
        'thumbnail_url': 'https://cdn.example.com/thumb.jpg',
        'language': 'en',
        'is_default': true,
        'client_id': null,
        'title': 'Squat demo',
        'is_active': true,
        'created_at': '2026-04-27T22:00:00.000Z',
        'updated_at': '2026-04-27T22:00:00.000Z',
      };
      final v = ExerciseVideo.fromMap(map);
      expect(v.id, 'vid-1');
      expect(v.source, VideoSource.own);
      expect(v.isDefault, true);
      expect(v.durationSeconds, 90);
      expect(v.title, 'Squat demo');
    });

    test('defaults source to own when field is missing', () {
      final v = ExerciseVideo.fromMap({
        'exercise_id': 'ex-1',
        'video_url': 'https://x.com/v.mp4',
        'uploader_user_id': 'u',
      });
      expect(v.source, VideoSource.own);
      expect(v.isDefault, false);
      expect(v.isActive, true);
    });

    test('parses youtube source', () {
      final v = ExerciseVideo.fromMap({
        'exercise_id': 'ex-1',
        'video_url': 'https://www.youtube.com/watch?v=abc',
        'source': 'youtube',
        'uploader_user_id': 'u',
      });
      expect(v.source, VideoSource.youtube);
    });
  });

  group('ExerciseVideo.toInsertMap', () {
    test('omits null optional fields', () {
      const v = ExerciseVideo(
        exerciseId: 'ex-1',
        videoUrl: 'https://cdn.example.com/v.mp4',
        uploaderUserId: 'u',
      );
      final m = v.toInsertMap();
      expect(m.containsKey('client_id'), false);
      expect(m.containsKey('title'), false);
      expect(m['is_default'], false);
    });

    test('includes client_id when set', () {
      const v = ExerciseVideo(
        exerciseId: 'ex-1',
        videoUrl: 'https://cdn.example.com/v.mp4',
        uploaderUserId: 'u',
        clientId: 'client-99',
      );
      expect(v.toInsertMap()['client_id'], 'client-99');
    });
  });

  group('videoSourceFromString', () {
    for (final entry in {
      'own': VideoSource.own,
      'youtube': VideoSource.youtube,
      'instagram': VideoSource.instagram,
      'tiktok': VideoSource.tiktok,
      'other': VideoSource.other,
      'unknown': VideoSource.own,
    }.entries) {
      test('${entry.key} → ${entry.value}', () {
        expect(videoSourceFromString(entry.key), entry.value);
      });
    }
  });

  group('MediaUrlResolver', () {
    test('passes through YouTube URL unchanged', () {
      const url = 'https://www.youtube.com/watch?v=xyz';
      expect(MediaUrlResolver.resolve(url), url);
    });

    test('passes through Instagram URL unchanged', () {
      const url = 'https://www.instagram.com/reel/abc/';
      expect(MediaUrlResolver.resolve(url), url);
    });

    test('passes through TikTok URL unchanged', () {
      const url = 'https://www.tiktok.com/@user/video/123';
      expect(MediaUrlResolver.resolve(url), url);
    });

    test('returns empty string for empty input', () {
      expect(MediaUrlResolver.resolve(''), '');
    });

    test('thumbnail returns empty string for null', () {
      expect(MediaUrlResolver.thumbnail(null), '');
    });
  });

  group('ExerciseVideoService._detectSource (via linkExternalVideo validation)', () {
    test('file size constant is 200 MB', () {
      expect(kMaxVideoBytes, 200 * 1024 * 1024);
    });

    test('duration constant is 120 seconds', () {
      expect(kMaxVideoDurationSeconds, 120);
    });
  });

  group('ExerciseVideoException', () {
    test('toString includes message', () {
      const e = ExerciseVideoException('Test error');
      expect(e.toString(), contains('Test error'));
    });
  });
}
