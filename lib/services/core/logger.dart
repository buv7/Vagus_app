import 'package:flutter/foundation.dart';

/// Centralized logging service for consistent app-wide logging
///
/// Usage:
/// ```dart
/// Logger.info('User logged in', data: {'userId': user.id});
/// Logger.error('API call failed', error: e, stackTrace: st);
/// ```
class Logger {
  Logger._();

  static const String _tag = 'Vagus';
  static bool _isEnabled = kDebugMode;
  static LogLevel _minLevel = LogLevel.debug;

  /// Enable or disable logging
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Set minimum log level
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Log debug message (development only)
  static void debug(
    String message, {
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(LogLevel.debug, message, data: data, tag: tag);
  }

  /// Log info message
  static void info(
    String message, {
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(LogLevel.info, message, data: data, tag: tag);
  }

  /// Log warning message
  static void warning(
    String message, {
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(LogLevel.warning, message, data: data, tag: tag);
  }

  /// Log error message
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
      tag: tag,
    );
  }

  /// Log fatal error (critical errors that should crash in debug)
  static void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(
      LogLevel.fatal,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
      tag: tag,
    );

    // In debug mode, throw to catch issues early
    if (kDebugMode) {
      throw Exception('FATAL: $message ${error != null ? '- $error' : ''}');
    }
  }

  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) {
    if (!_isEnabled || level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final logTag = tag ?? _tag;
    final prefix = _getLevelPrefix(level);

    final buffer = StringBuffer();
    buffer.write('[$timestamp] $prefix [$logTag] $message');

    if (data != null && data.isNotEmpty) {
      buffer.write(' | Data: $data');
    }

    if (error != null) {
      buffer.write('\n  Error: $error');
    }

    if (stackTrace != null) {
      buffer.write('\n  Stack trace:\n${stackTrace.toString().split('\n').take(10).join('\n')}');
    }

    final logMessage = buffer.toString();

    // Use appropriate print method based on level
    switch (level) {
      case LogLevel.debug:
      case LogLevel.info:
        debugPrint(logMessage);
        break;
      case LogLevel.warning:
        debugPrint('⚠️ $logMessage');
        break;
      case LogLevel.error:
        debugPrint('❌ $logMessage');
        break;
      case LogLevel.fatal:
        debugPrint('🔥 $logMessage');
        break;
    }

    // TODO: Send to remote logging service in production (e.g., Sentry, Firebase Crashlytics)
  }

  static String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG]';
      case LogLevel.info:
        return '[INFO]';
      case LogLevel.warning:
        return '[WARN]';
      case LogLevel.error:
        return '[ERROR]';
      case LogLevel.fatal:
        return '[FATAL]';
    }
  }
}

/// Log levels (ordered by severity)
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

