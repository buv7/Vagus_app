import 'dart:async';
import 'package:flutter/material.dart';

/// Safe setState wrapper that checks mounted state
extension SafeSetState on State {
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(fn);
    }
  }
}

/// Safe context operations
extension SafeContext on BuildContext {
  /// Navigate only if context is still mounted
  Future<T?> safePush<T>(Route<T> route) async {
    if (!mounted) return null;
    return Navigator.push(this, route);
  }

  /// Pop only if context is still mounted
  void safePop<T>([T? result]) {
    if (!mounted) return;
    Navigator.pop(this, result);
  }

  /// Show snackbar only if context is still mounted
  void safeShowSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// Helper to safely run async operations
Future<T?> safeAsync<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } catch (e) {
    debugPrint('⚠️ Async operation failed: $e');
    return null;
  }
}
