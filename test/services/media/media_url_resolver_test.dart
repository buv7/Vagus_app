import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/services/media/media_url_resolver.dart';

void main() {
  group('isAbsoluteMediaUrl', () {
    test('true for http and https', () {
      expect(isAbsoluteMediaUrl('https://example.com/x.jpg'), isTrue);
      expect(isAbsoluteMediaUrl('http://example.com/x.jpg'), isTrue);
    });

    test('false for storage paths', () {
      expect(isAbsoluteMediaUrl('users/123/avatar.jpg'), isFalse);
      expect(isAbsoluteMediaUrl('avatar.jpg'), isFalse);
      expect(isAbsoluteMediaUrl(''), isFalse);
    });
  });

  group('resolveMediaUrl', () {
    test('absolute URL in path is returned unchanged', () {
      const url = 'https://cdn.example.com/u/42/avatar.jpg';
      expect(
        resolveMediaUrl(bucket: 'vagus-media', path: url),
        equals(url),
      );
    });

    test('throws on empty bucket', () {
      expect(
        () => resolveMediaUrl(bucket: '', path: 'avatar.jpg'),
        throwsArgumentError,
      );
    });

    test('throws on empty path', () {
      expect(
        () => resolveMediaUrl(bucket: 'vagus-media', path: ''),
        throwsArgumentError,
      );
    });
  });
}
