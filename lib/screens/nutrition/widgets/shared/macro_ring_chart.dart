import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';

/// Reusable circular progress chart for macronutrients
/// Used throughout the nutrition system for consistent visualization
class MacroRingChart extends StatefulWidget {
  final double current;
  final double target;
  final String label;
  final String unit;
  final Color color;
  final double size;
  final bool showLabels;
  final bool animated;
  final VoidCallback? onTap;

  const MacroRingChart({
    super.key,
    required this.current,
    required this.target,
    required this.label,
    required this.unit,
    required this.color,
    this.size = 120,
    this.showLabels = true,
    this.animated = true,
    this.onTap,
  });

  @override
  State<MacroRingChart> createState() => _MacroRingChartState();
}

class _MacroRingChartState extends State<MacroRingChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: (widget.current / widget.target).clamp(0.0, 1.5), // Allow >100%
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animated) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MacroRingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current || oldWidget.target != widget.target) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: (widget.current / widget.target).clamp(0.0, 1.5),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withOpacity(0.8),
          borderRadius: BorderRadius.circular(widget.size / 2),
          border: Border.all(
            color: AppTheme.mediumGrey.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            final progress = _progressAnimation.value;
            final percentage = (progress * 100).round();
            final isOverTarget = progress > 1.0;

            return CustomPaint(
              painter: _MacroRingPainter(
                progress: progress,
                color: widget.color,
                strokeWidth: widget.size * 0.08,
                isOverTarget: isOverTarget,
              ),
              child: Center(
                child: widget.showLabels
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            color: AppTheme.neutralWhite,
                            fontSize: widget.size * 0.12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: AppTheme.lightGrey,
                            fontSize: widget.size * 0.08,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${widget.current.toStringAsFixed(0)}/${widget.target.toStringAsFixed(0)}${widget.unit}',
                          style: TextStyle(
                            color: AppTheme.lightGrey,
                            fontSize: widget.size * 0.06,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MacroRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool isOverTarget;

  _MacroRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.isOverTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    // Background ring
    final backgroundPaint = Paint()
      ..color = AppTheme.mediumGrey.withOpacity(0.2)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring
    final progressPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isOverTarget) {
      // Gradient from normal color to warning color when over target
      final gradientColors = [
        color,
        Colors.orange,
        Colors.red,
      ];
      final sweepAngle = math.min(progress * 2 * math.pi, 2 * math.pi);

      progressPaint.shader = SweepGradient(
        colors: gradientColors,
        stops: const [0.0, 0.8, 1.0],
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepAngle,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    } else {
      progressPaint.color = color;
    }

    // Draw progress arc
    final sweepAngle = math.min(progress * 2 * math.pi, 2 * math.pi);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );

    // Add glow effect for over-target
    if (isOverTarget) {
      final glowPaint = Paint()
        ..color = Colors.red.withOpacity(0.3)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.isOverTarget != isOverTarget;
  }
}

/// Multi-macro ring chart for showing protein, carbs, fat together
class MultiMacroRingChart extends StatelessWidget {
  final double protein;
  final double proteinTarget;
  final double carbs;
  final double carbsTarget;
  final double fat;
  final double fatTarget;
  final double size;
  final bool showLabels;

  const MultiMacroRingChart({
    super.key,
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbsTarget,
    required this.fat,
    required this.fatTarget,
    this.size = 200,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring - Protein
          CustomPaint(
            size: Size(size, size),
            painter: _MultiMacroRingPainter(
              progress: (protein / proteinTarget).clamp(0.0, 1.5),
              color: AppTheme.accentOrange,
              strokeWidth: size * 0.06,
              ringRadius: size * 0.4,
            ),
          ),

          // Middle ring - Carbs
          CustomPaint(
            size: Size(size * 0.8, size * 0.8),
            painter: _MultiMacroRingPainter(
              progress: (carbs / carbsTarget).clamp(0.0, 1.5),
              color: Colors.blue,
              strokeWidth: size * 0.06,
              ringRadius: size * 0.32,
            ),
          ),

          // Inner ring - Fat
          CustomPaint(
            size: Size(size * 0.6, size * 0.6),
            painter: _MultiMacroRingPainter(
              progress: (fat / fatTarget).clamp(0.0, 1.5),
              color: Colors.yellow.shade700,
              strokeWidth: size * 0.06,
              ringRadius: size * 0.24,
            ),
          ),

          // Center content
          if (showLabels)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Daily\nProgress',
                  style: TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: size * 0.08,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                _buildMacroLabel('P', protein, proteinTarget, AppTheme.accentOrange),
                _buildMacroLabel('C', carbs, carbsTarget, Colors.blue),
                _buildMacroLabel('F', fat, fatTarget, Colors.yellow.shade700),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMacroLabel(String label, double current, double target, Color color) {
    final percentage = ((current / target) * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $percentage%',
            style: TextStyle(
              color: AppTheme.lightGrey,
              fontSize: size * 0.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiMacroRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final double ringRadius;

  _MultiMacroRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.ringRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background ring
    final backgroundPaint = Paint()
      ..color = AppTheme.mediumGrey.withOpacity(0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, ringRadius, backgroundPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.min(progress * 2 * math.pi, 2 * math.pi);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringRadius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MultiMacroRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}