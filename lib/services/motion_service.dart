import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for managing motion and accessibility settings
class MotionService {
  static const Duration _standardDuration = Duration(milliseconds: 200);
  static const Duration _fastDuration = Duration(milliseconds: 160);
  static const Duration _slowDuration = Duration(milliseconds: 220);

  /// Get appropriate duration based on reduce-motion setting
  static Duration getDuration({bool isEssential = false}) {
    final mediaQuery = MediaQuery.maybeOf(navigatorKey.currentContext!);
    final reduceMotion = mediaQuery?.accessibleNavigation ?? false;
    
    if (reduceMotion && !isEssential) {
      return Duration.zero;
    }
    
    return _standardDuration;
  }

  /// Get fast duration for quick interactions
  static Duration getFastDuration({bool isEssential = false}) {
    final mediaQuery = MediaQuery.maybeOf(navigatorKey.currentContext!);
    final reduceMotion = mediaQuery?.accessibleNavigation ?? false;
    
    if (reduceMotion && !isEssential) {
      return Duration.zero;
    }
    
    return _fastDuration;
  }

  /// Get slow duration for important animations
  static Duration getSlowDuration({bool isEssential = false}) {
    final mediaQuery = MediaQuery.maybeOf(navigatorKey.currentContext!);
    final reduceMotion = mediaQuery?.accessibleNavigation ?? false;
    
    if (reduceMotion && !isEssential) {
      return Duration.zero;
    }
    
    return _slowDuration;
  }

  /// Check if reduce motion is enabled
  static bool get reduceMotion {
    final mediaQuery = MediaQuery.maybeOf(navigatorKey.currentContext!);
    return mediaQuery?.accessibleNavigation ?? false;
  }

  /// Provide haptic feedback with motion consideration
  static void hapticFeedback() {
    if (!reduceMotion) {
      HapticFeedback.lightImpact();
    }
  }
}

// Global navigator key for accessing context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
