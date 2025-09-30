import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A beautiful animated ring chart displaying macro progress.
///
/// Shows protein, carbs, and fat as three concentric rings with smooth animations.
/// Used in nutrition dashboard and plan viewer screens.
///
/// Example:
/// ```dart
/// MacroRingChart(
///   protein: 120,
///   proteinTarget: 150,
///   carbs: 200,
///   carbsTarget: 250,
///   fat: 60,
///   fatTarget: 70,
///   size: 200,
///   onTap: () => showMacroDetails(),
/// )
/// ```
class MacroRingChart extends StatefulWidget {
  /// Current protein intake in grams
  final double protein;

  /// Target protein goal in grams
  final double proteinTarget;

  /// Current carbs intake in grams
  final double carbs;

  /// Target carbs goal in grams
  final double carbsTarget;

  /// Current fat intake in grams
  final double fat;

  /// Target fat goal in grams
  final double fatTarget;

  /// Diameter of the chart in logical pixels
  final double size;

  /// Whether to animate the rings on first render
  final bool animated;

  /// Duration of the animation
  final Duration animationDuration;

  /// Callback when chart is tapped
  final VoidCallback? onTap;

  const MacroRingChart({
    super.key,
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbsTarget,
    required this.fat,
    required this.fatTarget,
    this.size = 200.0,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 1000),
    this.onTap,
  });

  @override
  State<MacroRingChart> createState() => _MacroRingChartState();
}

class _MacroRingChartState extends State<MacroRingChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.animated) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MacroRingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-animate if values change significantly
    if (_hasSignificantChange(oldWidget)) {
      _controller.forward(from: 0.0);
    }
  }

  bool _hasSignificantChange(MacroRingChart oldWidget) {
    const threshold = 5.0; // 5g difference
    return (widget.protein - oldWidget.protein).abs() > threshold ||
        (widget.carbs - oldWidget.carbs).abs() > threshold ||
        (widget.fat - oldWidget.fat).abs() > threshold;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: MacroRingPainter(
              proteinProgress: _calculateProgress(
                widget.protein,
                widget.proteinTarget,
                _animation.value,
              ),
              carbsProgress: _calculateProgress(
                widget.carbs,
                widget.carbsTarget,
                _animation.value,
              ),
              fatProgress: _calculateProgress(
                widget.fat,
                widget.fatTarget,
                _animation.value,
              ),
              proteinColor: const Color(0xFF00D9A3),
              carbsColor: const Color(0xFFFF9A3C),
              fatColor: const Color(0xFFFFD93C),
            ),
          );
        },
      ),
    );
  }

  double _calculateProgress(double current, double target, double animValue) {
    if (target <= 0) return 0.0;
    final progress = (current / target).clamp(0.0, 1.0);
    return progress * animValue;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Custom painter for the macro ring chart.
///
/// Draws three concentric rings with progress indicators for protein, carbs, and fat.
class MacroRingPainter extends CustomPainter {
  final double proteinProgress;
  final double carbsProgress;
  final double fatProgress;
  final Color proteinColor;
  final Color carbsColor;
  final Color fatColor;

  MacroRingPainter({
    required this.proteinProgress,
    required this.carbsProgress,
    required this.fatProgress,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.12;

    // Background circles (gray)
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, size.width * 0.40, bgPaint);
    canvas.drawCircle(center, size.width * 0.30, bgPaint);
    canvas.drawCircle(center, size.width * 0.20, bgPaint);

    // Protein ring (outer)
    _drawRing(
      canvas,
      center,
      size.width * 0.40,
      strokeWidth,
      proteinColor,
      proteinProgress,
    );

    // Carbs ring (middle)
    _drawRing(
      canvas,
      center,
      size.width * 0.30,
      strokeWidth,
      carbsColor,
      carbsProgress,
    );

    // Fat ring (inner)
    _drawRing(
      canvas,
      center,
      size.width * 0.20,
      strokeWidth,
      fatColor,
      fatProgress,
    );
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double strokeWidth,
    Color color,
    double progress,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2; // Start at top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    // Add glow effect for progress > 90%
    if (progress > 0.9) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
    }
  }

  @override
  bool shouldRepaint(MacroRingPainter oldDelegate) {
    return oldDelegate.proteinProgress != proteinProgress ||
        oldDelegate.carbsProgress != carbsProgress ||
        oldDelegate.fatProgress != fatProgress;
  }
}