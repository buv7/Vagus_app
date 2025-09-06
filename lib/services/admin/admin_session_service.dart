import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/admin/session_models.dart';

class AdminSessionService {
  AdminSessionService._();
  static final AdminSessionService instance = AdminSessionService._();

  // --- DATA LOAD (replace with Supabase calls later) ---
  Future<UserDiagnostics> loadDiagnostics(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    // stubbed example
    return UserDiagnostics(
      userId: userId,
      email: 'user+$userId@example.com',
      role: 'client',
      plan: 'pro',
      timezone: 'America/Los_Angeles',
      locale: 'en_US',
      devices: [
        DeviceSnapshot(
          deviceId: 'dev-$userId-1',
          platform: DevicePlatform.android,
          osVersion: '14',
          appVersion: '0.9.0',
          buildNumber: '90',
          model: 'Pixel 7',
          lastSeen: DateTime.now().subtract(const Duration(minutes: 11)),
        ),
      ],
      flags: const UserRuntimeFlags(),
    );
  }

  // --- QUICK TOOLS (stubs) ---
  Future<bool> pingDevice(String userId, String deviceId) async {
    debugPrint('ping $userId@$deviceId');
    return true;
  }

  Future<bool> forceRefreshConfig(String userId) async {
    debugPrint('forceRefresh $userId');
    return true;
  }

  Future<bool> flushCache(String userId) async {
    debugPrint('flushCache $userId');
    return true;
  }

  Future<bool> resetStreaks(String userId) async {
    debugPrint('resetStreaks $userId');
    return true;
  }

  Future<bool> reindexSearch(String userId) async {
    debugPrint('reindexSearch $userId');
    return true;
  }

  Future<bool> sendPasswordReset(String userId) async {
    debugPrint('sendPasswordReset $userId');
    return true;
  }

  Future<bool> invalidateSessions(String userId) async {
    debugPrint('invalidateSessions $userId');
    return true;
  }

  // --- LOGGING (stubs) ---
  Future<bool> setVerboseLogging(String userId, bool on) async {
    debugPrint('verbose=$on for $userId');
    return true;
  }

  Future<String> pullRecentLogs(String userId) async {
    return 'LOGS for $userId\n[00:00] App started\n[00:01] Fetch profile OK';
  }

  // --- FLAGS ---
  Future<UserRuntimeFlags> setFlag(String userId, UserRuntimeFlags flags) async {
    debugPrint('flags update for $userId');
    return flags;
  }
}
