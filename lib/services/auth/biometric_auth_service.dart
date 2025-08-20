import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricAuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Storage keys
  static const String _bioEnabledKey = 'bio_enabled';
  static const String _bioUserEmailKey = 'bio_user_email';

  /// Check if biometric authentication is available on this device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      return canCheckBiometrics && isDeviceSupported;
    } on PlatformException catch (e) {
      print('Biometric availability check failed: $e');
      return false;
    }
  }

  /// Get the list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Failed to get available biometrics: $e');
      return [];
    }
  }

  /// Check if biometric login is enabled for the current user
  Future<bool> getBiometricEnabled() async {
    try {
      final String? enabled = await _secureStorage.read(key: _bioEnabledKey);
      return enabled == 'true';
    } catch (e) {
      print('Failed to read biometric enabled status: $e');
      return false;
    }
  }

  /// Set biometric login enabled/disabled and store user email
  Future<void> setBiometricEnabled(bool enabled, {String? userEmail}) async {
    try {
      await _secureStorage.write(
        key: _bioEnabledKey,
        value: enabled.toString(),
      );
      
      if (enabled && userEmail != null) {
        await _secureStorage.write(
          key: _bioUserEmailKey,
          value: userEmail,
        );
      }
    } catch (e) {
      print('Failed to set biometric enabled status: $e');
      rethrow;
    }
  }

  /// Get the stored user email for biometric login
  Future<String?> getStoredUserEmail() async {
    try {
      return await _secureStorage.read(key: _bioUserEmailKey);
    } catch (e) {
      print('Failed to read stored user email: $e');
      return null;
    }
  }

  /// Authenticate user with biometrics
  Future<bool> authenticateWithBiometrics({String reason = 'Please authenticate to log in'}) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('Biometric authentication not available');
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric authentication failed: $e');
      return false;
    }
  }

  /// Clear all stored biometric data
  Future<void> clearBiometricData() async {
    try {
      await _secureStorage.delete(key: _bioEnabledKey);
      await _secureStorage.delete(key: _bioUserEmailKey);
    } catch (e) {
      print('Failed to clear biometric data: $e');
    }
  }

  /// Get a user-friendly description of available biometrics
  Future<String> getBiometricDescription() async {
    try {
      final List<BiometricType> availableBiometrics = await getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        return 'No biometric authentication available';
      }
      
      final List<String> descriptions = availableBiometrics.map((type) {
        switch (type) {
          case BiometricType.face:
            return 'Face ID';
          case BiometricType.fingerprint:
            return 'Fingerprint';
          case BiometricType.iris:
            return 'Iris';
          default:
            return 'Biometric';
        }
      }).toList();
      
      return descriptions.join(' or ');
    } catch (e) {
      return 'Biometric authentication';
    }
  }
}
