import 'package:flutter/foundation.dart';

/// PostHog analytics stub for call events.
///
/// TODO(POSTHOG): Add posthog_flutter to pubspec.yaml and replace
/// the debugPrint lines with real PostHog.capture() calls once the
/// PostHog SDK is wired up in main.dart.
class CallAnalyticsService {
  static void logCallStarted({
    required String sessionId,
    required String sessionType,
    required bool isVideo,
    required bool isCaller,
  }) {
    debugPrint(
      '[CallAnalytics] call_started '
      'session=$sessionId type=$sessionType video=$isVideo caller=$isCaller',
    );
    // PostHog.capture('call_started', properties: {...});
  }

  static void logCallEnded({
    required String sessionId,
    required int durationSeconds,
    required Map<String, dynamic> qualityStats,
  }) {
    debugPrint(
      '[CallAnalytics] call_ended '
      'session=$sessionId duration=${durationSeconds}s stats=$qualityStats',
    );
    // PostHog.capture('call_ended', properties: {...});
  }

  static void logCallQuality({
    required String sessionId,
    required String connectionState,
    required bool usedTurn,
  }) {
    debugPrint(
      '[CallAnalytics] call_quality '
      'session=$sessionId state=$connectionState turn=$usedTurn',
    );
    // PostHog.capture('call_quality', properties: {...});
  }
}
