import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Test helper for OneSignal notifications
/// Use this to test push notification functionality
/// NOTE: OneSignal dependency removed - this is now a stub helper
class NotificationTestHelper {
  NotificationTestHelper._();
  static final NotificationTestHelper instance = NotificationTestHelper._();

  final supabase = Supabase.instance.client;

  /// Send a test notification to the current user
  Future<bool> sendTestNotification({
    String title = '🧪 Test Notification',
    String message = 'This is a test notification from VAGUS',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user for test notification');
        return false;
      }

      // Get the user's OneSignal ID from Supabase
      final response = await supabase
          .from('user_devices')
          .select('onesignal_id')
          .eq('user_id', user.id)
          .single();

      if (response['onesignal_id'] == null) {
        debugPrint('❌ No OneSignal ID found for user (OneSignal disabled)');
        return false;
      }



      // Send notification via Supabase Edge Function
      final result = await supabase.functions.invoke(
        'send-notification',
        body: {
          'type': 'user',
          'userId': user.id,
          'title': title,
          'message': message,
          'additionalData': additionalData ?? {
            'test': true,
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );

      if (result.status == 200) {
        debugPrint('✅ Test notification sent successfully');
        return true;
      } else {
        debugPrint('❌ Failed to send test notification: ${result.status}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
      return false;
    }
  }

  /// Check if OneSignal is properly initialized
  bool get isOneSignalReady {
    // OneSignal dependency removed - stub implementation
    return false;
  }

  /// Get current OneSignal subscription ID
  String? get currentSubscriptionId {
    // OneSignal dependency removed - stub implementation
    return null;
  }

  /// Check notification permission status
  Future<bool> getPermissionStatus() async {
    // OneSignal dependency removed - stub implementation
    return false;
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    // OneSignal dependency removed - stub implementation
    debugPrint('⚠️ OneSignal permissions disabled');
    return false;
  }

  /// Test local notification display
  Future<void> showLocalTestNotification() async {
    try {
      // This would show a local notification for testing
      // In OneSignal v5, you can use the in-app messaging or local notifications
      debugPrint('📱 Local test notification would be displayed here');
      
      // You can also test by sending a notification to yourself
      await sendTestNotification(
        title: '🔔 Local Test',
        message: 'This notification was triggered locally',
        additionalData: {'local_test': true},
      );
    } catch (e) {
      debugPrint('❌ Error showing local test notification: $e');
    }
  }

  /// Get device information for debugging
  Map<String, dynamic> getDeviceInfo() {
    return {
      'oneSignalReady': isOneSignalReady,
      'subscriptionId': currentSubscriptionId,
      'platform': _getPlatform(),
    };
  }

  String _getPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    } else {
      return 'web';
    }
  }
}
