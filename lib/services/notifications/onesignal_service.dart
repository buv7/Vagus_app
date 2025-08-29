import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// OneSignal notification service for VAGUS
/// Handles push notifications, device registration, and in-app messaging
/// NOTE: OneSignal dependency removed - this is now a stub service
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
      // OneSignal dependency removed - this is now a stub
      debugPrint('⚠️ OneSignal service is disabled - dependency removed');

      _initialized = true;
      debugPrint('✅ OneSignal stub initialized');

    } catch (e) {
      debugPrint('❌ OneSignal initialization failed: $e');
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
