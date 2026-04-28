import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/core/network/retry_policy.dart';

void main() {
  group('withRetry', () {
    test('returns value on first success', () async {
      final result = await withRetry(() async => 42, operationName: 'test');
      expect(result, 42);
    });

    test('retries on transient error and succeeds', () async {
      var attempts = 0;
      final result = await withRetry(
        () async {
          attempts++;
          if (attempts < 3) throw Exception('SocketException: timeout');
          return 'ok';
        },
        maxAttempts: 3,
        baseDelay: Duration.zero,
        operationName: 'flaky-call',
      );
      expect(result, 'ok');
      expect(attempts, 3);
    });

    test('does not retry permanent errors', () async {
      var attempts = 0;
      await expectLater(
        withRetry(
          () async {
            attempts++;
            throw Exception('invalid_grant');
          },
          maxAttempts: 3,
          baseDelay: Duration.zero,
          isTransient: (_) => false,
          operationName: 'auth-call',
        ),
        throwsException,
      );
      expect(attempts, 1);
    });

    test('rethrows after exhausting retries', () async {
      var attempts = 0;
      await expectLater(
        withRetry(
          () async {
            attempts++;
            throw Exception('SocketException: connection refused');
          },
          maxAttempts: 3,
          baseDelay: Duration.zero,
          operationName: 'always-fails',
        ),
        throwsException,
      );
      expect(attempts, 3);
    });
  });
}
