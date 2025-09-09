import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  static SessionService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static const String _deviceIdKey = 'device_id';

  /// Get or create a stable device ID
  Future<String> _getDeviceId() async {
    String? deviceId = await _secureStorage.read(key: _deviceIdKey);
    
    if (deviceId == null) {
      // Generate a new device ID
      deviceId = const Uuid().v4();
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    }
    
    return deviceId;
  }

  /// Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
    final Map<String, String> deviceData = {};
    
    try {
      // Get app version
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      deviceData['app_version'] = '${packageInfo.version} (${packageInfo.buildNumber})';
      
      // Get platform
      deviceData['platform'] = Platform.operatingSystem;
      
      // Get OS version
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        deviceData['model'] = '${androidInfo.brand} ${androidInfo.model}';
        deviceData['os_version'] = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        deviceData['model'] = '${iosInfo.name} ${iosInfo.model}';
        deviceData['os_version'] = 'iOS ${iosInfo.systemVersion}';
      } else {
        deviceData['model'] = 'Unknown Device';
        deviceData['os_version'] = 'Unknown OS';
      }
      
      // OneSignal ID (currently disabled)
      deviceData['onesignal_id'] = '';
    } catch (e) {
      debugPrint('Failed to get device info: $e');
      deviceData['platform'] = Platform.operatingSystem;
      deviceData['model'] = 'Unknown Device';
      deviceData['app_version'] = 'Unknown';
      deviceData['os_version'] = 'Unknown OS';
      deviceData['onesignal_id'] = '';
    }
    
    return deviceData;
  }

  /// Get app version string
  Future<String> _getAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version} (${packageInfo.buildNumber})';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Create or update the current device record
  Future<void> upsertCurrentDevice() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final deviceId = await _getDeviceId();
      final deviceInfo = await _getDeviceInfo();

      // Note: Current schema doesn't have is_current field, so we skip this step

      // Upsert current device - handle missing columns gracefully
      try {
        await _supabase
            .from('user_devices')
            .upsert({
              'user_id': user.id,
              'device_id': deviceId,
              'device_type': deviceInfo['platform'],
              'os_version': deviceInfo['os_version'],
              'app_version': deviceInfo['app_version'],
              'onesignal_player_id': deviceInfo['onesignal_id'],
            }, onConflict: 'device_id');
      } catch (e) {
        // If device_type column doesn't exist, try without it
        if (e.toString().contains('device_type')) {
          await _supabase
              .from('user_devices')
              .upsert({
                'user_id': user.id,
                'device_id': deviceId,
                'os_version': deviceInfo['os_version'],
                'app_version': deviceInfo['app_version'],
                'onesignal_player_id': deviceInfo['onesignal_id'],
              }, onConflict: 'device_id');
        } else {
          rethrow;
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Device upserted: ${deviceInfo['model']}');
      }
    } catch (e) {
      debugPrint('Failed to upsert current device: $e');
    }
  }

  /// Update heartbeat for current device (using updated_at field)
  Future<void> heartbeat() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final deviceId = await _getDeviceId();

      // Update the device record to trigger updated_at timestamp
      // Handle missing updated_at field gracefully
      try {
        await _supabase
            .from('user_devices')
            .update({
              'app_version': await _getAppVersion(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id)
            .eq('device_id', deviceId);
      } catch (e) {
        // If updated_at field doesn't exist, try without it
        if (e.toString().contains('updated_at')) {
          await _supabase
              .from('user_devices')
              .update({
                'app_version': await _getAppVersion(),
              })
              .eq('user_id', user.id)
              .eq('device_id', deviceId);
        } else {
          rethrow;
        }
      }

      if (kDebugMode) {
        debugPrint('💓 Heartbeat updated');
      }
    } catch (e) {
      debugPrint('Failed to update heartbeat: $e');
    }
  }

  /// Get list of user's devices
  Future<List<Map<String, dynamic>>> listDevices() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('user_devices')
          .select()
          .eq('user_id', user.id)
          .order('last_seen', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Failed to list devices: $e');
      return [];
    }
  }

  /// Mark a device for revocation
  Future<void> markRevoke(String deviceId, bool revoke) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('user_devices')
          .update({'revoke': revoke})
          .eq('user_id', user.id)
          .eq('device_id', deviceId);

      if (kDebugMode) {
        debugPrint('${revoke ? '🚫' : '✅'} Device revocation ${revoke ? 'set' : 'cleared'} for $deviceId');
      }
    } catch (e) {
      debugPrint('Failed to mark device revocation: $e');
    }
  }

  /// Check if current device should be revoked
  Future<void> checkRevocation() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final deviceId = await _getDeviceId();

      final response = await _supabase
          .from('user_devices')
          .select('revoke')
          .eq('user_id', user.id)
          .eq('device_id', deviceId)
          .maybeSingle();

      // If no device record found, it's a new device - that's fine
      if (response == null) {
        if (kDebugMode) {
          debugPrint('🔧 Device not found in revocation check - new device, continuing');
        }
        return;
      }

      if (response['revoke'] == true) {
        if (kDebugMode) {
          debugPrint('🚫 Device revoked, signing out');
        }
        
        // Clear device ID and sign out
        await _secureStorage.delete(key: _deviceIdKey);
        await _supabase.auth.signOut();
      }
    } catch (e) {
      debugPrint('Failed to check revocation: $e');
      // Don't rethrow - this shouldn't block login
    }
  }

  /// Get current device ID
  Future<String?> getCurrentDeviceId() async {
    return await _getDeviceId();
  }

  /// Clear all session data (for logout)
  Future<void> clearSessionData() async {
    try {
      await _secureStorage.delete(key: _deviceIdKey);
    } catch (e) {
      debugPrint('Failed to clear session data: $e');
    }
  }
}
