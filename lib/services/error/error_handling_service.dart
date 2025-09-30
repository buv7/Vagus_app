import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/haptics.dart';

/// Centralized error handling service with user-friendly messaging and recovery
/// Features: Error categorization, user messaging, retry logic, error reporting
class ErrorHandlingService {
  static final _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  final Map<String, DateTime> _errorCooldowns = {};
  final List<AppError> _recentErrors = [];

  static const Duration _cooldownDuration = Duration(seconds: 30);
  static const int _maxRecentErrors = 50;

  /// Handle an error with appropriate user feedback
  Future<void> handleError(
    dynamic error, {
    String? context,
    String? userMessage,
    bool showSnackbar = true,
    bool logError = true,
    VoidCallback? onRetry,
    BuildContext? buildContext,
  }) async {
    final appError = _categorizeError(error, context: context);

    if (logError) {
      _logError(appError);
    }

    _addToRecentErrors(appError);

    if (showSnackbar && buildContext != null && buildContext.mounted) {
      await _showErrorSnackbar(
        buildContext,
        userMessage ?? appError.userMessage,
        appError.severity,
        onRetry: onRetry,
      );
    }
  }

  /// Handle network errors specifically
  Future<void> handleNetworkError(
    dynamic error, {
    required BuildContext context,
    VoidCallback? onRetry,
  }) async {
    final appError = _categorizeError(error, context: 'network');

    if (appError.category == ErrorCategory.network) {
      await _showNetworkErrorDialog(context, appError, onRetry: onRetry);
    } else {
      await handleError(error, buildContext: context, onRetry: onRetry);
    }
  }

  /// Handle database errors with specific messaging
  Future<void> handleDatabaseError(
    dynamic error, {
    required BuildContext context,
    String? operation,
    VoidCallback? onRetry,
  }) async {
    final appError = _categorizeError(error, context: operation ?? 'database');

    String message = appError.userMessage;

    if (error is PostgrestException) {
      switch (error.code) {
        case 'PGRST116':
          message = 'No data found. This might be expected.';
          break;
        case '23505':
          message = 'This item already exists.';
          break;
        case '23503':
          message = 'Unable to save due to missing required data.';
          break;
        default:
          message = 'Database error: ${appError.userMessage}';
      }
    }

    await _showErrorSnackbar(
      context,
      message,
      appError.severity,
      onRetry: onRetry,
    );
  }

  /// Show a retry dialog for critical errors
  Future<bool> showRetryDialog(
    BuildContext context,
    String message, {
    String? title,
    String? retryLabel,
    String? cancelLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text(
          title ?? 'Something went wrong',
          style: const TextStyle(color: AppTheme.neutralWhite),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelLabel ?? 'Cancel',
              style: const TextStyle(color: AppTheme.lightGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
            ),
            child: Text(
              retryLabel ?? 'Retry',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Get user-friendly error message for specific error types
  String getUserMessage(dynamic error) {
    return _categorizeError(error).userMessage;
  }

  /// Check if error should be shown to user (not in cooldown)
  bool shouldShowError(String errorKey) {
    final lastShown = _errorCooldowns[errorKey];
    if (lastShown == null) return true;

    return DateTime.now().difference(lastShown) > _cooldownDuration;
  }

  /// Get recent errors for debugging
  List<AppError> getRecentErrors() {
    return List.unmodifiable(_recentErrors);
  }

  /// Clear error history
  void clearErrorHistory() {
    _recentErrors.clear();
    _errorCooldowns.clear();
  }

  // Private methods
  AppError _categorizeError(dynamic error, {String? context}) {
    if (error is PostgrestException) {
      return _handlePostgrestException(error, context);
    } else if (error is SocketException) {
      return AppError(
        category: ErrorCategory.network,
        severity: ErrorSeverity.warning,
        userMessage: 'No internet connection. Check your network and try again.',
        technicalMessage: 'SocketException: ${error.message}',
        context: context,
        timestamp: DateTime.now(),
      );
    } else if (error is TimeoutException) {
      return AppError(
        category: ErrorCategory.network,
        severity: ErrorSeverity.warning,
        userMessage: 'Request timed out. Please try again.',
        technicalMessage: 'TimeoutException: ${error.message}',
        context: context,
        timestamp: DateTime.now(),
      );
    } else if (error is FormatException) {
      return AppError(
        category: ErrorCategory.data,
        severity: ErrorSeverity.error,
        userMessage: 'Invalid data format. Please try again.',
        technicalMessage: 'FormatException: ${error.message}',
        context: context,
        timestamp: DateTime.now(),
      );
    } else {
      return AppError(
        category: ErrorCategory.unknown,
        severity: ErrorSeverity.error,
        userMessage: 'An unexpected error occurred. Please try again.',
        technicalMessage: error.toString(),
        context: context,
        timestamp: DateTime.now(),
      );
    }
  }

  AppError _handlePostgrestException(PostgrestException error, String? context) {
    String userMessage;
    ErrorSeverity severity;

    switch (error.code) {
      case 'PGRST116':
        userMessage = 'No data found';
        severity = ErrorSeverity.info;
        break;
      case '23505':
        userMessage = 'This item already exists';
        severity = ErrorSeverity.warning;
        break;
      case '23503':
        userMessage = 'Unable to save due to missing required information';
        severity = ErrorSeverity.error;
        break;
      case '42P01':
        userMessage = 'Data structure error. Please update the app.';
        severity = ErrorSeverity.critical;
        break;
      default:
        userMessage = 'Database error occurred';
        severity = ErrorSeverity.error;
    }

    return AppError(
      category: ErrorCategory.database,
      severity: severity,
      userMessage: userMessage,
      technicalMessage: 'PostgrestException ${error.code}: ${error.message}',
      context: context,
      timestamp: DateTime.now(),
    );
  }

  void _logError(AppError error) {
    final logLevel = _getLogLevel(error.severity);
    final message = '[${error.category.name.toUpperCase()}] ${error.technicalMessage}';

    if (kDebugMode) {
      debugPrint('$logLevel: $message');
      if (error.context != null) {
        debugPrint('Context: ${error.context}');
      }
    }

    // TODO: Send to crash reporting service (Sentry, Firebase Crashlytics, etc.)
  }

  String _getLogLevel(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return 'INFO';
      case ErrorSeverity.warning:
        return 'WARN';
      case ErrorSeverity.error:
        return 'ERROR';
      case ErrorSeverity.critical:
        return 'CRITICAL';
    }
  }

  void _addToRecentErrors(AppError error) {
    _recentErrors.insert(0, error);

    if (_recentErrors.length > _maxRecentErrors) {
      _recentErrors.removeLast();
    }
  }

  Future<void> _showErrorSnackbar(
    BuildContext context,
    String message,
    ErrorSeverity severity, {
    VoidCallback? onRetry,
  }) async {
    final errorKey = message.hashCode.toString();

    if (!shouldShowError(errorKey)) {
      return;
    }

    _errorCooldowns[errorKey] = DateTime.now();

    Color backgroundColor;
    IconData icon;

    switch (severity) {
      case ErrorSeverity.info:
        backgroundColor = AppTheme.lightBlue;
        icon = Icons.info_outline;
        break;
      case ErrorSeverity.warning:
        backgroundColor = AppTheme.lightOrange;
        icon = Icons.warning_amber;
        break;
      case ErrorSeverity.error:
        backgroundColor = Colors.red;
        icon = Icons.error_outline;
        break;
      case ErrorSeverity.critical:
        backgroundColor = Colors.red.shade800;
        icon = Icons.dangerous;
        break;
    }

    Haptics.warning();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(
          seconds: severity == ErrorSeverity.critical ? 10 : 4,
        ),
        action: onRetry != null
          ? SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
      ),
    );
  }

  Future<void> _showNetworkErrorDialog(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'Connection Problem',
              style: TextStyle(color: AppTheme.neutralWhite),
            ),
          ],
        ),
        content: Text(
          error.userMessage,
          style: const TextStyle(color: AppTheme.lightGrey),
        ),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Application error model
class AppError {
  final ErrorCategory category;
  final ErrorSeverity severity;
  final String userMessage;
  final String technicalMessage;
  final String? context;
  final DateTime timestamp;

  AppError({
    required this.category,
    required this.severity,
    required this.userMessage,
    required this.technicalMessage,
    this.context,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category.name,
      'severity': severity.name,
      'user_message': userMessage,
      'technical_message': technicalMessage,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Error categories
enum ErrorCategory {
  network,
  database,
  authentication,
  authorization,
  validation,
  data,
  ui,
  unknown,
}

/// Error severity levels
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// Error handling extensions
extension ErrorHandlingContext on BuildContext {
  /// Quick error handling for this context
  Future<void> handleError(
    dynamic error, {
    String? message,
    VoidCallback? onRetry,
  }) async {
    await ErrorHandlingService().handleError(
      error,
      userMessage: message,
      buildContext: this,
      onRetry: onRetry,
    );
  }

  /// Show retry dialog
  Future<bool> showRetryDialog(String message) async {
    return await ErrorHandlingService().showRetryDialog(this, message);
  }
}