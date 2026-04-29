import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../firebase_options.dart';

// Must be top-level — Firebase requirement for background isolation.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Notification categories — used as `category` in FCM data payload and in
/// per-category preference keys stored in `notification_preferences`.
enum NotificationCategory {
  workouts('workouts'),
  nutritionReminders('nutrition_reminders'),
  coachMessages('coach_messages'),
  marketplace('marketplace'),
  periods('periods'),
  streaks('streaks'),
  labResults('lab_results');

  final String value;
  const NotificationCategory(this.value);

  static NotificationCategory? fromString(String? s) {
    if (s == null) return null;
    for (final c in values) {
      if (c.value == s) return c;
    }
    return null;
  }
}

/// Payload emitted on the [FcmService.inAppNotifications] stream when a
/// foreground FCM message arrives. The banner widget listens to this.
class FcmInAppNotification {
  final String title;
  final String body;
  final String? route;
  final NotificationCategory? category;

  const FcmInAppNotification({
    required this.title,
    required this.body,
    this.route,
    this.category,
  });
}

/// Singleton FCM service. Wraps `firebase_messaging` and owns:
///   - Firebase initialisation
///   - Permission request (first signed-in launch only)
///   - Token registration in `user_devices`
///   - Foreground in-app notification stream
///   - Background/tap navigation
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  static const _permissionAskedKey = 'fcm_permission_asked';
  static const _deviceIdKey = 'device_id'; // mirrors SessionService constant

  FirebaseMessaging? _messaging;
  bool _initialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  final _secureStorage = const FlutterSecureStorage();

  final _inAppController = StreamController<FcmInAppNotification>.broadcast();

  /// Stream of foreground notifications to display as in-app banners.
  Stream<FcmInAppNotification> get inAppNotifications => _inAppController.stream;

  // ─────────────────────────────────────────────
  // Initialisation
  // ─────────────────────────────────────────────

  /// Call once from main() before runApp(). Safe to call if Firebase is
  /// already initialized by another path.
  Future<void> init() async {
    if (_initialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _messaging = FirebaseMessaging.instance;

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Suppress system tray on foreground — we show our own in-app banner.
      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );

      _listenForeground();
      _listenTaps();

      _initialized = true;
      debugPrint('[FCM] Initialized');
    } catch (e) {
      debugPrint('[FCM] Init error: $e');
    }
  }

  /// Wire up the app's global navigator key so tap-to-navigate works.
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // ─────────────────────────────────────────────
  // Sign-in hook — call from AuthGate
  // ─────────────────────────────────────────────

  /// Call immediately after a user signs in. Requests permission (once) and
  /// registers/refreshes the FCM token in Supabase.
  Future<void> onSignedIn() async {
    if (_messaging == null) return;
    try {
      await _requestPermissionIfNeeded();
      await _registerToken();
      _messaging!.onTokenRefresh.listen(_persistToken);
    } catch (e) {
      debugPrint('[FCM] onSignedIn error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Permission
  // ─────────────────────────────────────────────

  Future<void> _requestPermissionIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_permissionAskedKey) == true) return;

    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    await prefs.setBool(_permissionAskedKey, true);
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
  }

  // ─────────────────────────────────────────────
  // Token management
  // ─────────────────────────────────────────────

  Future<void> _registerToken() async {
    final token = await _messaging!.getToken();
    if (token != null) await _persistToken(token);
  }

  Future<void> _persistToken(String token) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final deviceId = await _secureStorage.read(key: _deviceIdKey);
      if (deviceId == null) return;

      await supabase.from('user_devices').upsert(
        {
          'user_id': user.id,
          'device_id': deviceId,
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'device_id',
      );
      debugPrint('[FCM] Token persisted for device $deviceId');
    } catch (e) {
      debugPrint('[FCM] Token persist failed: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Foreground messages → in-app banner
  // ─────────────────────────────────────────────

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _inAppController.add(FcmInAppNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
        route: message.data['route'] as String?,
        category: NotificationCategory.fromString(
          message.data['category'] as String?,
        ),
      ));
    });
  }

  // ─────────────────────────────────────────────
  // Tap handling → deep-link navigation
  // ─────────────────────────────────────────────

  void _listenTaps() {
    // Terminated → opened via notification.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleTap(message);
    });

    // Background → foregrounded via notification.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
  }

  void _handleTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route == null || _navigatorKey == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey!.currentState?.pushNamed(route);
    });
  }

  // ─────────────────────────────────────────────
  // Test helper — send a test push via send-push Edge Function
  // ─────────────────────────────────────────────

  Future<bool> sendTestPush() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final response = await supabase.functions.invoke(
        'send-push',
        body: {
          'user_id': user.id,
          'template_key': 'test_push',
          'params': {},
        },
      );
      return response.status == 200;
    } catch (e) {
      debugPrint('[FCM] Test push failed: $e');
      return false;
    }
  }

  void dispose() {
    _inAppController.close();
  }
}
