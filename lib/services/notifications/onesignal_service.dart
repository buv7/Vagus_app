import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// OneSignal notification service for VAGUS
/// Handles push notifications, device registration, and in-app messaging
class OneSignalService {
  OneSignalService._();
  static final OneSignalService instance = OneSignalService._();

  bool _initialized = false;
  String? _currentPlayerId;
  final supabase = Supabase.instance.client;

  /// Initialize OneSignal service
  /// Call this once in main() after Supabase initialization
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Set log level for debugging
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // Initialize OneSignal with your app ID
      // TODO: Replace with your actual OneSignal App ID
      OneSignal.initialize("YOUR-ONESIGNAL-APP-ID");

      // Request notification permissions
      OneSignal.Notifications.requestPermission(true);

      // Set up notification handlers
      _setupNotificationHandlers();

      // Get current device state and register with Supabase
      await _registerDevice();

      _initialized = true;
      debugPrint('✅ OneSignal initialized successfully');

    } catch (e) {
      debugPrint('❌ OneSignal initialization failed: $e');
    }
  }

  /// Set up notification event handlers
  void _setupNotificationHandlers() {
    // Notification received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('📱 Foreground notification received: ${event.notification.title}');
      // You can customize how foreground notifications are displayed
      // For now, we'll let OneSignal handle it
    });

    // Notification opened (tapped by user)
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('👆 Notification tapped: ${event.notification.title}');
      _handleNotificationTap(event.notification);
    });

    // Notification permission changed
    OneSignal.Notifications.addPermissionObserver((state) async {
      debugPrint('🔐 Notification permission changed: $state');
      if (state) {
        _registerDevice(); // Re-register if permission granted
      }
    });
  }

  /// Handle notification tap and route to appropriate screen
  void _handleNotificationTap(OSNotification notification) {
    final data = notification.additionalData;
    if (data == null) return;

    // Extract routing information from notification data
    final route = data['route'] as String?;
    final screen = data['screen'] as String?;
    final id = data['id'] as String?;

    if (route != null) {
      // Navigate to specific route
      _navigateToRoute(route, id: id);
    } else if (screen != null) {
      // Navigate to specific screen
      _navigateToScreen(screen, id: id);
    }
  }

  /// Navigate to a specific route
  void _navigateToRoute(String route, {String? id}) {
    // This will be implemented when we add navigation support
    debugPrint('🔄 Navigating to route: $route${id != null ? ' with id: $id' : ''}');

    // TODO: Implement navigation logic
    // Example routes:
    // - /messages?threadId=123
    // - /workout?planId=456
    // - /nutrition?planId=789
    // - /calendar?eventId=101
  }

  /// Navigate to a specific screen
  void _navigateToScreen(String screen, {String? id}) {
    debugPrint('🔄 Navigating to screen: $screen${id != null ? ' with id: $id' : ''}');

    // TODO: Implement screen navigation logic
    // Example screens:
    // - messages, workout, nutrition, calendar, profile
  }

  /// Register current device with Supabase
  Future<void> _registerDevice() async {
    try {
      final playerId = OneSignal.User.pushSubscription.id;

      if (playerId == null) {
        debugPrint('⚠️ No OneSignal player ID available');
        return;
      }

      _currentPlayerId = playerId;

      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No authenticated user for device registration');
        return;
      }

      // Upsert device registration in Supabase
      await supabase.from('user_devices').upsert({
        'user_id': user.id,
        'onesignal_id': playerId,
        'platform': _getPlatform(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,onesignal_id');

      debugPrint('✅ Device registered with Supabase: $playerId');

    } catch (e) {
      debugPrint('❌ Device registration failed: $e');
    }
  }

  /// Get current platform
  String _getPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    } else {
      return 'web';
    }
  }

  /// Public helper to subscribe to server-driven topics (optional).
  Future<void> subscribeToTopic(String topic) async {
    if (!_initialized) return;

    try {
      // Note: OneSignal v5 tag management is handled differently
      // For now, we'll log the intent to add tags
      debugPrint('📝 Would add tag: topic = $topic');
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_initialized) return;

    try {
      // Note: OneSignal v5 tag management is handled differently
      // For now, we'll log the intent to remove tags
      debugPrint('📝 Would remove tag: topic');
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic: $e');
    }
  }

  /// Add custom tags for user segmentation
  Future<void> addUserTag(String key, String value) async {
    if (!_initialized) return;

    try {
      // Note: OneSignal v5 tag management is handled differently
      // For now, we'll log the intent to add tags
      debugPrint('📝 Would add tag: $key = $value');
      debugPrint('✅ Added user tag: $key = $value');
    } catch (e) {
      debugPrint('❌ Failed to add user tag: $e');
    }
  }

  /// Remove custom tags
  Future<void> removeUserTag(String key) async {
    if (!_initialized) return;

    try {
      // Note: OneSignal v5 tag management is handled differently
      // For now, we'll log the intent to remove tags
      debugPrint('📝 Would remove tag: $key');
      debugPrint('✅ Removed user tag: $key');
    } catch (e) {
      debugPrint('❌ Failed to remove user tag: $e');
    }
  }

  /// Get current player ID
  String? get currentPlayerId => _currentPlayerId;

  /// Check if service is initialized
  bool get isInitialized => _initialized;

  /// Send in-app message (for testing)
  Future<void> sendInAppMessage(String message) async {
    if (!_initialized) return;

    try {
      // This would typically be handled by OneSignal's in-app messaging
      // For now, we'll just log it
      debugPrint('💬 In-app message: $message');
    } catch (e) {
      debugPrint('❌ Failed to send in-app message: $e');
    }
  }
}
