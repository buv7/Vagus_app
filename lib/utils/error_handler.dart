import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global error handler utility for consistent error handling across the app
class ErrorHandler {
  /// Handle an error and show appropriate message to the user
  static void handle(BuildContext context, dynamic error, {String? customMessage}) {
    if (!context.mounted) return;

    String message;

    if (customMessage != null) {
      message = customMessage;
    } else if (error is PostgrestException) {
      message = _handlePostgrestException(error);
    } else if (error is AuthException) {
      message = _handleAuthException(error);
    } else if (error is StorageException) {
      message = _handleStorageException(error);
    } else {
      message = 'An unexpected error occurred: ${error.toString()}';
    }

    showSnackBar(context, message, isError: true);
  }

  /// Show a success message
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    showSnackBar(context, message, isError: false);
  }

  /// Show a warning message
  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;
    showSnackBar(context, message, isWarning: true);
  }

  /// Show info message
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    showSnackBar(context, message, isInfo: true);
  }

  /// Display a SnackBar with the given message
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isWarning = false,
    bool isInfo = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;

    Color backgroundColor;
    IconData icon;

    if (isError) {
      backgroundColor = Colors.red.shade600;
      icon = Icons.error_outline;
    } else if (isWarning) {
      backgroundColor = Colors.orange.shade600;
      icon = Icons.warning_outlined;
    } else if (isInfo) {
      backgroundColor = Colors.blue.shade600;
      icon = Icons.info_outline;
    } else {
      backgroundColor = Colors.green.shade600;
      icon = Icons.check_circle_outline;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
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
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show an error dialog with more details
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    String? details,
  }) async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (details != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Text(
                  details,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Private helper methods

  static String _handlePostgrestException(PostgrestException error) {
    switch (error.code) {
      case '23505':
        return 'This record already exists.';
      case '23503':
        return 'Cannot complete operation due to related data.';
      case '42501':
        return 'You do not have permission to perform this action.';
      case 'PGRST116':
        return 'No data found for the requested resource.';
      default:
        if (error.message.contains('JWT expired')) {
          return 'Your session has expired. Please log in again.';
        }
        if (error.message.contains('permission denied')) {
          return 'You do not have permission to perform this action.';
        }
        return 'Database error: ${error.message}';
    }
  }

  static String _handleAuthException(AuthException error) {
    switch (error.message.toLowerCase()) {
      case 'invalid login credentials':
        return 'Invalid email or password. Please try again.';
      case 'user already registered':
        return 'An account with this email already exists.';
      case 'email not confirmed':
        return 'Please verify your email before logging in.';
      case 'password should be at least 6 characters':
        return 'Password must be at least 6 characters long.';
      default:
        if (error.message.contains('rate limit')) {
          return 'Too many attempts. Please try again later.';
        }
        if (error.message.contains('network')) {
          return 'Network error. Please check your connection.';
        }
        return 'Authentication error: ${error.message}';
    }
  }

  static String _handleStorageException(StorageException error) {
    if (error.message.contains('not found')) {
      return 'The requested file was not found.';
    }
    if (error.message.contains('unauthorized')) {
      return 'You do not have permission to access this file.';
    }
    if (error.message.contains('size')) {
      return 'File size exceeds the maximum allowed.';
    }
    return 'Storage error: ${error.message}';
  }

  /// Handle loading state errors
  static Widget buildErrorWidget({
    required String error,
    required VoidCallback onRetry,
    String? customMessage,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              customMessage ?? 'Something went wrong',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle loading state
  static Widget buildLoadingWidget({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message),
          ],
        ],
      ),
    );
  }

  /// Handle empty state
  static Widget buildEmptyWidget({
    required String message,
    IconData icon = Icons.inbox,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
