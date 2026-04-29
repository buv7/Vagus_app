import 'package:flutter/foundation.dart';

/// Incoming-call push notification contract — stub until SIGNAL merges.
///
/// SIGNAL agent status: PENDING. Once SIGNAL ships its Edge Function and
/// OneSignal integration, replace this stub with a call to the
/// `notify-incoming-call` Supabase Edge Function which will:
///   1. Look up the callee's OneSignal player_id from the profiles table.
///   2. Send a high-priority push with data: {session_id, caller_name, call_type}.
///   3. The push's notification service extension opens SimpleCallScreen(isIncoming: true).
///
/// Degradation mode: without SIGNAL, both parties must have the app in the
/// foreground and navigate to the same session. The callee can join from the
/// Call Management screen's Active tab.
class IncomingCallStub {
  /// Notify [calleeId] of an incoming call for [sessionId].
  /// No-op until SIGNAL is READY-FOR-REVIEW.
  static Future<void> notifyCallee({
    required String sessionId,
    required String calleeId,
    required String callerName,
    required String callType,
  }) async {
    // TODO(SIGNAL): invoke notify-incoming-call Edge Function
    debugPrint(
      '[IncomingCallStub] Would push: callee=$calleeId '
      'session=$sessionId caller="$callerName" type=$callType',
    );
  }
}
