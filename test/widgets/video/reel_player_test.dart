import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/widgets/video/reel_player.dart';

void main() {
  group('detectVideoSource', () {
    test('mp4 URL → mp4', () {
      expect(
        detectVideoSource('https://example.com/workout.mp4'),
        VideoSource.mp4,
      );
    });

    test('m3u8 stream URL → mp4', () {
      expect(
        detectVideoSource('https://cdn.example.com/stream/index.m3u8'),
        VideoSource.mp4,
      );
    });

    test('direct video URL with no extension → mp4', () {
      expect(
        detectVideoSource('https://storage.example.com/video/abc123'),
        VideoSource.mp4,
      );
    });

    test('youtube.com/watch URL → youtube', () {
      expect(
        detectVideoSource('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        VideoSource.youtube,
      );
    });

    test('youtu.be short URL → youtube', () {
      expect(
        detectVideoSource('https://youtu.be/dQw4w9WgXcQ'),
        VideoSource.youtube,
      );
    });

    test('youtube.com/shorts URL → youtube', () {
      expect(
        detectVideoSource('https://www.youtube.com/shorts/abc123'),
        VideoSource.youtube,
      );
    });

    test('instagram.com reel URL → webview', () {
      expect(
        detectVideoSource('https://www.instagram.com/reel/CXyz123456/'),
        VideoSource.webview,
      );
    });

    test('instagram.com post URL → webview', () {
      expect(
        detectVideoSource('https://www.instagram.com/p/CXyz123456/'),
        VideoSource.webview,
      );
    });

    test('tiktok.com video URL → webview', () {
      expect(
        detectVideoSource(
          'https://www.tiktok.com/@username/video/7123456789012345678',
        ),
        VideoSource.webview,
      );
    });
  });

  group('toEmbedUrl', () {
    test('Instagram reel URL → /embed/', () {
      final result = toEmbedUrl(
        'https://www.instagram.com/reel/CXyz123456/',
      );
      expect(result, 'https://www.instagram.com/p/CXyz123456/embed/');
    });

    test('Instagram post URL → /embed/', () {
      final result = toEmbedUrl(
        'https://www.instagram.com/p/CXyz123456/',
      );
      expect(result, 'https://www.instagram.com/p/CXyz123456/embed/');
    });

    test('TikTok video URL → embed/v2/{id}', () {
      final result = toEmbedUrl(
        'https://www.tiktok.com/@someuser/video/7123456789012345678',
      );
      expect(
        result,
        'https://www.tiktok.com/embed/v2/7123456789012345678',
      );
    });

    test('unknown URL passes through unchanged', () {
      const url = 'https://example.com/some-video.mp4';
      expect(toEmbedUrl(url), url);
    });

    test('mp4 URL passes through unchanged', () {
      const url = 'https://cdn.example.com/workouts/squat-demo.mp4';
      expect(toEmbedUrl(url), url);
    });
  });

  group('ReelPlayerController', () {
    late ReelPlayerController ctrl;

    setUp(() {
      ctrl = ReelPlayerController.instance;
      ctrl.reset();
    });

    test('initial speed is 1.0', () {
      expect(ctrl.speed, 1.0);
    });

    test('initial loop is false', () {
      expect(ctrl.isLooping, isFalse);
    });

    test('initial floating state is false', () {
      expect(ctrl.isFloating, isFalse);
    });

    test('setSpeed updates speed', () {
      ctrl.setSpeed(1.5);
      expect(ctrl.speed, 1.5);
    });

    test('setSpeed clamps to supported values', () {
      ctrl.setSpeed(0.5);
      expect(ctrl.speed, 0.5);
      ctrl.setSpeed(2.0);
      expect(ctrl.speed, 2.0);
    });

    test('toggleLoop flips isLooping', () {
      expect(ctrl.isLooping, isFalse);
      ctrl.toggleLoop();
      expect(ctrl.isLooping, isTrue);
      ctrl.toggleLoop();
      expect(ctrl.isLooping, isFalse);
    });

    test('isLoaded is false before load', () {
      expect(ctrl.isLoaded, isFalse);
    });

    test('position and duration are zero before load', () {
      expect(ctrl.position, Duration.zero);
      expect(ctrl.duration, Duration.zero);
    });

    test('kReelSpeeds contains expected values', () {
      expect(kReelSpeeds, containsAll([0.5, 1.0, 1.5, 2.0]));
    });
  });
}
