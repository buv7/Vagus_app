import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/admin/live_session_models.dart';

class AdminLiveSessionService {
  AdminLiveSessionService._();
  static final AdminLiveSessionService instance = AdminLiveSessionService._();

  // Simulated presence & network streams
  Stream<PresenceSnapshot> presence(String userId) {
    return Stream<PresenceSnapshot>.periodic(const Duration(seconds: 3), (i) {
      final status = [PresenceStatus.online, PresenceStatus.idle, PresenceStatus.offline][i % 3];
      return PresenceSnapshot(status: status, lastSeen: DateTime.now(), note: 'route:/home');
    });
  }

  Stream<NetworkSnapshot> network(String userId) {
    final rnd = Random();
    return Stream<NetworkSnapshot>.periodic(const Duration(seconds: 2), (_) {
      return NetworkSnapshot(
        pingMs: 20 + rnd.nextInt(60),
        jitterMs: 1 + rnd.nextInt(15),
        downKbps: 3000 + rnd.nextInt(12000),
        upKbps: 600 + rnd.nextInt(3000),
        at: DateTime.now(),
      );
    });
  }

  // Incident tools (stubs)
  Future<PushTestResult> pushTest(String userId, {String title = 'Test', String body = 'Ping'}) async {
    debugPrint('pushTest -> $userId: $title | $body');
    return PushTestResult(
      sent: true,
      messageId: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      info: 'queued',
    );
  }

  Future<bool> sendDeepLink(String userId, String uri) async {
    debugPrint('sendDeepLink -> $userId: $uri');
    return true;
  }

  Future<bool> broadcastBanner(String userId, String message, {int seconds = 60}) async {
    debugPrint('banner -> $userId for $seconds s: $message');
    return true;
  }

  Future<bool> refreshRemoteConfig(String userId) async {
    debugPrint('refreshRemoteConfig -> $userId');
    return true;
  }
}
