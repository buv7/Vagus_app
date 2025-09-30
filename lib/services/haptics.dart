import 'package:flutter/services.dart';

class Haptics {
  /// Light haptic feedback for general taps
  static void tap() {
    try {
      HapticFeedback.lightImpact();
    } catch (e) {
      // Silently ignore if haptics not supported
    }
  }

  /// Medium haptic feedback for success actions
  static void success() {
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      // Silently ignore if haptics not supported
    }
  }

  /// Heavy haptic feedback for warnings/errors
  static void warning() {
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      // Silently ignore if haptics not supported
    }
  }

  /// Selection haptic feedback
  static void selection() {
    try {
      HapticFeedback.selectionClick();
    } catch (e) {
      // Silently ignore if haptics not supported
    }
  }

  /// Generic impact haptic feedback (medium)
  static void impact() {
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      // Silently ignore if haptics not supported
    }
  }

  /// Error haptic feedback (heavy impact)
  static void error() {
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      // Silently ignore if haptics not supported
    }
  }
}
