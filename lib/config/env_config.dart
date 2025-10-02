import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loader for VAGUS app
/// Loads credentials from .env file (never commit .env to git!)
class EnvConfig {
  // Private constructor to prevent instantiation
  EnvConfig._();

  // ==================== Supabase Configuration ====================

  /// Supabase project URL
  /// Get from: Supabase Dashboard → Settings → API
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? '';

  /// Supabase anonymous key (public)
  /// Get from: Supabase Dashboard → Settings → API → anon/public key
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // ==================== OneSignal Configuration ====================

  /// OneSignal App ID for push notifications
  /// Get from: OneSignal Dashboard → Settings → Keys & IDs
  static String get oneSignalAppId =>
      dotenv.env['ONESIGNAL_APP_ID'] ?? '';

  // ==================== Environment Configuration ====================

  /// Current environment (development, staging, production)
  static String get environment =>
      dotenv.env['ENVIRONMENT'] ?? 'development';

  /// Check if running in production
  static bool get isProduction => environment == 'production';

  /// Check if running in development
  static bool get isDevelopment => environment == 'development';

  /// Check if running in staging
  static bool get isStaging => environment == 'staging';

  // ==================== Database Configuration ====================

  /// Direct database connection URL (for backend/MCP tools only)
  /// This is NOT used by the Flutter app - only for server-side operations
  /// Uses PostgreSQL session pooler for reliable connections
  static String get databaseUrl =>
      dotenv.env['DATABASE_URL'] ?? '';

  // ==================== Optional Configuration ====================

  /// Custom API base URL (if using separate backend)
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? '';

  /// Debug mode flag
  static bool get debugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  /// Sentry DSN for error tracking
  static String get sentryDsn =>
      dotenv.env['SENTRY_DSN'] ?? '';

  // ==================== Initialization ====================

  /// Initialize environment configuration
  /// Call this once at app startup before using any config values
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');

      if (kDebugMode) {
        print('✅ Environment variables loaded successfully');
        print('   Environment: $environment');
        print('   Supabase URL: ${supabaseUrl.isNotEmpty ? "✓ Set" : "✗ Missing"}');
        print('   Supabase Key: ${supabaseAnonKey.isNotEmpty ? "✓ Set" : "✗ Missing"}');
        print('   Database URL: ${databaseUrl.isNotEmpty ? "✓ Set (for backend tools)" : "✗ Not set"}');
        print('   OneSignal ID: ${oneSignalAppId.isNotEmpty ? "✓ Set" : "✗ Missing"}');
      }

      // Validate required variables
      _validateRequired();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️  Failed to load .env file: $e');
        print('   Make sure .env file exists and is properly configured');
        print('   Copy .env.example to .env and fill in your credentials');
      }

      // In production, this should throw an error
      if (isProduction) {
        throw Exception('Environment variables not configured. Cannot start app.');
      }
    }
  }

  /// Validate that all required environment variables are set
  static void _validateRequired() {
    final missing = <String>[];

    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');

    if (missing.isNotEmpty) {
      final message = 'Missing required environment variables: ${missing.join(", ")}';

      if (kDebugMode) {
        print('⚠️  $message');
        print('   App may not function correctly without these values');
      }

      if (isProduction) {
        throw Exception(message);
      }
    }
  }

  /// Check if all configuration is valid
  static bool get isConfigValid {
    return supabaseUrl.isNotEmpty &&
           supabaseAnonKey.isNotEmpty;
  }

  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'environment': environment,
      'supabaseUrl': supabaseUrl.isNotEmpty ? 'configured' : 'missing',
      'supabaseAnonKey': supabaseAnonKey.isNotEmpty ? 'configured' : 'missing',
      'databaseUrl': databaseUrl.isNotEmpty ? 'configured' : 'missing',
      'oneSignalAppId': oneSignalAppId.isNotEmpty ? 'configured' : 'missing',
      'isProduction': isProduction,
      'isDevelopment': isDevelopment,
      'isStaging': isStaging,
      'configValid': isConfigValid,
    };
  }
}
