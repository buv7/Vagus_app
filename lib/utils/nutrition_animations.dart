import 'package:flutter/material.dart';

/// Animation utilities and transitions for Nutrition Platform 2.0.
///
/// Provides consistent animations, durations, curves, and page transitions
/// across all nutrition features.
///
/// Usage:
/// ```dart
/// AnimatedContainer(
///   duration: NutritionAnimations.normal,
///   curve: NutritionAnimations.easeOut,
///   color: isActive ? Colors.green : Colors.grey,
/// )
/// ```
class NutritionAnimations {
  // Prevent instantiation
  NutritionAnimations._();

  // ============================================================
  // ANIMATION DURATIONS
  // ============================================================

  /// Very fast animation (100ms) - Micro-interactions
  static const Duration veryFast = Duration(milliseconds: 100);

  /// Fast animation (200ms) - Quick feedback
  static const Duration fast = Duration(milliseconds: 200);

  /// Normal animation (300ms) - Standard transitions
  static const Duration normal = Duration(milliseconds: 300);

  /// Slow animation (500ms) - Emphasized transitions
  static const Duration slow = Duration(milliseconds: 500);

  /// Very slow animation (800ms) - Major state changes
  static const Duration verySlow = Duration(milliseconds: 800);

  /// Macro ring animation (1000ms) - Special charts
  static const Duration macroRing = Duration(milliseconds: 1000);

  // ============================================================
  // ANIMATION CURVES
  // ============================================================

  /// Ease in curve - Accelerating
  static const Curve easeIn = Curves.easeIn;

  /// Ease out curve - Decelerating (recommended default)
  static const Curve easeOut = Curves.easeOut;

  /// Ease in-out curve - Smooth acceleration and deceleration
  static const Curve easeInOut = Curves.easeInOutCubic;

  /// Spring curve - Bouncy effect
  static const Curve spring = Curves.elasticOut;

  /// Fast out slow in - Material Design standard
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  /// Decelerate - Smooth ending
  static const Curve decelerate = Curves.decelerate;

  // ============================================================
  // PAGE TRANSITIONS
  // ============================================================

  /// Slide up page transition (from bottom)
  ///
  /// Example:
  /// ```dart
  /// Navigator.push(
  ///   context,
  ///   NutritionAnimations.slideUp(MyScreen()),
  /// );
  /// ```
  static Route<T> slideUp<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: easeOut)),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: normal,
    );
  }

  /// Slide from right page transition
  static Route<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: easeOut)),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: normal,
    );
  }

  /// Fade page transition
  static Route<T> fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: fast,
    );
  }

  /// Scale page transition (from center)
  static Route<T> scale<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: easeOut),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: normal,
    );
  }

  /// Modal bottom sheet transition
  static Route<T> modalBottomSheet<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: fastOutSlowIn)),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: slow,
      opaque: false,
      barrierColor: Colors.black54,
    );
  }

  // ============================================================
  // ANIMATED WIDGETS
  // ============================================================

  /// Animated opacity fade in/out
  ///
  /// Example:
  /// ```dart
  /// NutritionAnimations.fadeIn(
  ///   visible: isVisible,
  ///   child: MyWidget(),
  /// )
  /// ```
  static Widget fadeIn({
    required bool visible,
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: duration ?? normal,
      curve: curve ?? easeOut,
      child: child,
    );
  }

  /// Animated scale
  static Widget animatedScale({
    required bool expanded,
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return AnimatedScale(
      scale: expanded ? 1.0 : 0.0,
      duration: duration ?? normal,
      curve: curve ?? easeOut,
      child: child,
    );
  }

  /// Animated slide
  static Widget animatedSlide({
    required bool visible,
    required Widget child,
    Offset? begin,
    Duration? duration,
    Curve? curve,
  }) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : (begin ?? const Offset(0.0, 0.2)),
      duration: duration ?? normal,
      curve: curve ?? easeOut,
      child: child,
    );
  }

  // ============================================================
  // SHIMMER LOADING ANIMATION
  // ============================================================

  /// Creates a shimmer loading effect for skeleton screens
  ///
  /// Example:
  /// ```dart
  /// NutritionAnimations.shimmer(
  ///   child: Container(width: 200, height: 20, color: Colors.white),
  /// )
  /// ```
  static Widget shimmer({required Widget child}) {
    return _ShimmerWidget(child: child);
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Delays execution by the specified duration
  ///
  /// Example:
  /// ```dart
  /// await NutritionAnimations.delay(NutritionAnimations.fast);
  /// ```
  static Future<void> delay(Duration duration) {
    return Future.delayed(duration);
  }

  /// Stagger animation delays for list items
  ///
  /// Example:
  /// ```dart
  /// ListView.builder(
  ///   itemBuilder: (context, index) {
  ///     final delay = NutritionAnimations.staggerDelay(index);
  ///     return NutritionAnimations.fadeIn(
  ///       visible: true,
  ///       duration: delay,
  ///       child: MyListItem(),
  ///     );
  ///   },
  /// )
  /// ```
  static Duration staggerDelay(int index, {Duration base = veryFast}) {
    return Duration(milliseconds: base.inMilliseconds + (index * 50));
  }
}

/// Internal shimmer widget for loading states
class _ShimmerWidget extends StatefulWidget {
  final Widget child;

  const _ShimmerWidget({required this.child});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Colors.white10,
                Colors.white30,
                Colors.white10,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}