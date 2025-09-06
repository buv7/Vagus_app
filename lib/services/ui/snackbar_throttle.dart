import 'package:flutter/material.dart';

class SnackbarThrottle {
  static DateTime? _lastShown;
  static String? _lastMessage;

  /// Show a throttled snackbar that suppresses duplicates within the time window
  static void showSnack(
    BuildContext context, 
    String message, {
    Duration minGap = const Duration(seconds: 2),
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final now = DateTime.now();
    
    // Check if we should suppress this message
    if (_lastShown != null && 
        now.difference(_lastShown!).inMilliseconds < minGap.inMilliseconds &&
        _lastMessage == message) {
      return; // Suppress duplicate message
    }

    _lastShown = now;
    _lastMessage = message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }
}
