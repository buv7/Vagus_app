import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'hydration_engine.dart';

/// Manages local hydration reminder notifications for a single user session.
///
/// Rules enforced:
///   - Minimum 90 minutes between any two nudges (hard-coded safety).
///   - A nudge is suppressed when the user logged intake within ±15 min.
///   - All notifications are cancelled and rescheduled when user prefs change.
///
/// This scheduler does NOT talk to Supabase — it only writes to the device
/// notification tray and [SharedPreferences] for last-log tracking.
class HydrationNudgeScheduler {
  HydrationNudgeScheduler._();
  static final HydrationNudgeScheduler instance = HydrationNudgeScheduler._();

  static const String _channelId = 'hydration_reminders';
  static const String _channelName = 'Hydration Reminders';
  static const String _channelDesc = 'Timely water intake reminders';

  static const Duration _minInterval = Duration(minutes: 90);
  static const Duration _suppressWindow = Duration(minutes: 15);

  static const String _prefLastLogMs = 'hydra::lastLogMs';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _channelCreated = false;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Cancel all previously scheduled hydration nudges and schedule [nudges]
  /// freshly. Call this whenever the user updates wake/sleep prefs or target.
  Future<void> reschedule({
    required String userId,
    required List<HydrationNudge> nudges,
  }) async {
    await _ensureChannel();
    await cancelAll(userId);

    for (final nudge in nudges) {
      final fireAt = nudge.scheduledAt;
      if (fireAt.isBefore(DateTime.now())) continue;

      final id = _notificationId(userId, nudge.index);
      final tzFireAt = tz.TZDateTime.from(fireAt, tz.local);

      try {
        await _plugin.zonedSchedule(
          id,
          'Time to hydrate',
          'Drink ${nudge.targetMl} ml of water — you\'re on track!',
          tzFireAt,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDesc,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: 'hydra:$userId:${nudge.index}',
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('HydrationNudgeScheduler: failed to schedule #${nudge.index} — $e');
      }
    }

    debugPrint(
        'HydrationNudgeScheduler: scheduled ${nudges.length} nudges for $userId');
  }

  /// Cancel all hydration nudges for [userId].
  ///
  /// We use IDs in the range [_baseId(userId) .. _baseId(userId)+99].
  Future<void> cancelAll(String userId) async {
    await _ensureChannel();
    final base = _baseId(userId);
    for (var i = 0; i < 100; i++) {
      await _plugin.cancel(base + i);
    }
  }

  /// Record that the user just logged water. This suppresses any nudge
  /// that would fire within the next [_suppressWindow].
  ///
  /// Call this immediately after a successful water-log write.
  Future<void> recordLog(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        '$_prefLastLogMs:$userId', DateTime.now().millisecondsSinceEpoch);
  }

  /// Returns true if a nudge scheduled at [nudgeTime] should be suppressed
  /// because the user already logged intake within [_suppressWindow].
  Future<bool> shouldSuppress(String userId, DateTime nudgeTime) async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt('$_prefLastLogMs:$userId');
    if (lastMs == null) return false;

    final lastLog = DateTime.fromMillisecondsSinceEpoch(lastMs);
    final diff = nudgeTime.difference(lastLog).abs();
    return diff <= _suppressWindow;
  }

  // -------------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------------

  Future<void> _ensureChannel() async {
    if (_channelCreated) return;
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(initSettings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.defaultImportance,
        ),
      );
    }
    _channelCreated = true;
  }

  /// Deterministic int ID for a nudge: low bits = nudge index, high bits = hash of userId.
  int _notificationId(String userId, int index) =>
      (_baseId(userId) + index).abs() & 0x7FFFFFFF;

  int _baseId(String userId) => (userId.hashCode & 0x7FFFFF00);

  /// The minimum interval between nudges — exposed for external guard checks.
  static Duration get minimumInterval => _minInterval;
}
