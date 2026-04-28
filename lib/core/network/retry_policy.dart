import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Classifies an exception as transient (retriable) or permanent.
typedef TransientPredicate = bool Function(Object error);

bool _defaultTransient(Object e) {
  final s = e.toString().toLowerCase();
  return s.contains('socketexception') ||
      s.contains('connection') ||
      s.contains('timeout') ||
      s.contains('network') ||
      s.contains('handshake') ||
      s.contains('502') ||
      s.contains('503') ||
      s.contains('504');
}

/// Executes [operation] with up to [maxAttempts] tries using exponential
/// back-off with full jitter.  Only retries when [isTransient] returns true.
///
/// On permanent failure (non-transient error or exhausted retries) the
/// exception is reported to Sentry and rethrown — never silently swallowed.
Future<T> withRetry<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration baseDelay = const Duration(milliseconds: 500),
  TransientPredicate? isTransient,
  String? operationName,
}) async {
  final pred = isTransient ?? _defaultTransient;
  final rng = Random();
  Object? lastError;
  StackTrace? lastStack;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await operation();
    } catch (e, st) {
      lastError = e;
      lastStack = st;

      if (!pred(e) || attempt == maxAttempts) {
        // Permanent failure or exhausted retries — report and rethrow.
        await Sentry.captureException(e, stackTrace: st);
        rethrow;
      }

      // Exponential back-off with full jitter: delay ∈ [0, base * 2^(attempt-1)]
      final window = baseDelay * (1 << (attempt - 1));
      final jitter = Duration(
        milliseconds: rng.nextInt(window.inMilliseconds.clamp(1, 30000)),
      );

      if (kDebugMode) {
        debugPrint('[RetryPolicy] $operationName attempt $attempt failed: $e — '
            'retrying in ${jitter.inMilliseconds}ms');
      }

      await Future<void>.delayed(jitter);
    }
  }

  // Unreachable, but the analyzer needs this.
  await Sentry.captureException(lastError!, stackTrace: lastStack);
  throw lastError!;
}
