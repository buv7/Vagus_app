import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/haptics.dart';

/// Stunning animated circular progress rings for macros
/// Features: 3 concentric rings, smooth animations, micro-interactions
class AnimatedCircularProgressRings extends StatefulWidget {
  final double protein;
  final double proteinTarget;
  final double carbs;
  final double carbsTarget;
  final double fat;
  final double fatTarget;
  final double totalCalories;
  final double calorieTarget;
  final VoidCallback? onTap;
  final bool showMicroInteractions;

  const AnimatedCircularProgressRings({
    super.key,
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbsTarget,
    required this.fat,
    required this.fatTarget,
    required this.totalCalories,
    required this.calorieTarget,
    this.onTap,
    this.showMicroInteractions = true,
  });

  @override
  State<AnimatedCircularProgressRings> createState() =>
      _AnimatedCircularProgressRingsState();
}

class _AnimatedCircularProgressRingsState
    extends State<AnimatedCircularProgressRings>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _proteinController;
  late AnimationController _carbsController;
  late AnimationController _fatController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;

  late Animation<double> _proteinAnimation;
  late Animation<double> _carbsAnimation;
  late Animation<double> _fatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  bool _isPressed = false;
  bool _hasShownAchievement = false;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _proteinController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _carbsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fatController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _proteinAnimation = Tween<double>(
      begin: 0.0,
      end: (widget.protein / widget.proteinTarget).clamp(0.0, 1.5),
    ).animate(CurvedAnimation(
      parent: _proteinController,
      curve: Curves.easeOutCubic,
    ));

    _carbsAnimation = Tween<double>(
      begin: 0.0,
      end: (widget.carbs / widget.carbsTarget).clamp(0.0, 1.5),
    ).animate(CurvedAnimation(
      parent: _carbsController,
      curve: Curves.easeOutCubic,
    ));

    _fatAnimation = Tween<double>(
      begin: 0.0,
      end: (widget.fat / widget.fatTarget).clamp(0.0, 1.5),
    ).animate(CurvedAnimation(
      parent: _fatController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _proteinController.forward();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _carbsController.forward();
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _fatController.forward();
    });

    _checkForMicroInteractions();
  }

  void _checkForMicroInteractions() {
    if (!widget.showMicroInteractions) return;

    // Pulse animation on achievement
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _allTargetsMet() && !_hasShownAchievement) {
        _hasShownAchievement = true;
        _pulseController.forward().then((_) {
          _pulseController.reverse();
          Haptics.success();
        });
      }
    });

    // Shake animation on significant overage
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && _hasOverage()) {
        _shakeController.forward().then((_) {
          _shakeController.reset();
          Haptics.warning();
        });
      }
    });
  }

  bool _allTargetsMet() {
    return widget.protein >= widget.proteinTarget * 0.9 &&
           widget.carbs >= widget.carbsTarget * 0.9 &&
           widget.fat >= widget.fatTarget * 0.9;
  }

  bool _hasOverage() {
    return widget.protein > widget.proteinTarget * 1.3 ||
           widget.carbs > widget.carbsTarget * 1.3 ||
           widget.fat > widget.fatTarget * 1.3;
  }

  @override
  void didUpdateWidget(AnimatedCircularProgressRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.protein != widget.protein ||
        oldWidget.carbs != widget.carbs ||
        oldWidget.fat != widget.fat) {
      _setupAnimations();
      _proteinController.forward(from: 0);
      _carbsController.forward(from: 0);
      _fatController.forward(from: 0);
      _hasShownAchievement = false;
      _checkForMicroInteractions();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        Haptics.tap();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _proteinAnimation,
          _carbsAnimation,
          _fatAnimation,
          _pulseAnimation,
          _shakeAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? 0.95 : (_pulseAnimation.value),
            child: Transform.translate(
              offset: Offset(
                math.sin(_shakeAnimation.value * math.pi * 4) * 2,
                0,
              ),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    if (_allTargetsMet())
                      BoxShadow(
                        color: const Color(0xFF00D9A3).withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 0),
                      ),
                  ],
                ),
                child: CustomPaint(
                  painter: _MacroRingsPainter(
                    proteinProgress: _proteinAnimation.value,
                    carbsProgress: _carbsAnimation.value,
                    fatProgress: _fatAnimation.value,
                    showGlow: _allTargetsMet(),
                  ),
                  child: Center(
                    child: _buildCenterContent(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCenterContent() {
    final calorieProgress = widget.totalCalories / widget.calorieTarget;
    final remaining = widget.calorieTarget - widget.totalCalories;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Total calories
        Text(
          widget.totalCalories.toStringAsFixed(0),
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),

        // kcal label
        Text(
          'kcal',
          style: TextStyle(
            color: AppTheme.lightGrey.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        // Target vs actual
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: _getCalorieStatusColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            remaining > 0
              ? '${remaining.toStringAsFixed(0)} left'
              : '${(-remaining).toStringAsFixed(0)} over',
            style: TextStyle(
              color: _getCalorieStatusColor(),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Progress indicator
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.mediumGrey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: calorieProgress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: _getCalorieStatusColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getCalorieStatusColor() {
    final progress = widget.totalCalories / widget.calorieTarget;
    if (progress >= 0.9 && progress <= 1.1) return const Color(0xFF00D9A3);
    if (progress < 0.9) return const Color(0xFF3B82F6);
    return const Color(0xFFEF4444);
  }
}

class _MacroRingsPainter extends CustomPainter {
  final double proteinProgress;
  final double carbsProgress;
  final double fatProgress;
  final bool showGlow;

  _MacroRingsPainter({
    required this.proteinProgress,
    required this.carbsProgress,
    required this.fatProgress,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    // Ring configurations
    final rings = [
      _RingConfig(
        progress: proteinProgress,
        color: const Color(0xFF00D9A3), // Protein green
        radius: baseRadius - 20,
        strokeWidth: 12,
        label: 'Protein',
      ),
      _RingConfig(
        progress: carbsProgress,
        color: const Color(0xFFFF9A3C), // Carbs orange
        radius: baseRadius - 40,
        strokeWidth: 12,
        label: 'Carbs',
      ),
      _RingConfig(
        progress: fatProgress,
        color: const Color(0xFFFFD93C), // Fat yellow
        radius: baseRadius - 60,
        strokeWidth: 12,
        label: 'Fat',
      ),
    ];

    // Draw rings
    for (final ring in rings) {
      _drawRing(canvas, center, ring);
    }
  }

  void _drawRing(Canvas canvas, Offset center, _RingConfig ring) {
    final rect = Rect.fromCircle(center: center, radius: ring.radius);

    // Background ring
    final backgroundPaint = Paint()
      ..color = ring.color.withValues(alpha: 0.1)
      ..strokeWidth = ring.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, ring.radius, backgroundPaint);

    // Progress ring
    final progressPaint = Paint()
      ..strokeWidth = ring.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Create gradient for progress
    if (ring.progress > 1.0) {
      // Over target - gradient from normal to warning
      progressPaint.shader = LinearGradient(
        colors: [ring.color, const Color(0xFFEF4444)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    } else {
      progressPaint.color = ring.color;
    }

    // Add glow effect if target achieved
    if (showGlow && ring.progress >= 0.9) {
      final glowPaint = Paint()
        ..color = ring.color.withValues(alpha: 0.3)
        ..strokeWidth = ring.strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final sweepAngle = math.min(ring.progress * 2 * math.pi, 2 * math.pi);
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, glowPaint);
    }

    // Draw progress arc
    final sweepAngle = math.min(ring.progress * 2 * math.pi, 2 * math.pi);
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);

    // Add sparkle effect for completed rings
    if (ring.progress >= 1.0) {
      _drawSparkles(canvas, center, ring.radius, ring.color);
    }
  }

  void _drawSparkles(Canvas canvas, Offset center, double radius, Color color) {
    final sparklePositions = [
      Offset(center.dx + radius * 0.7, center.dy - radius * 0.7),
      Offset(center.dx - radius * 0.7, center.dy - radius * 0.7),
      Offset(center.dx + radius * 0.9, center.dy),
    ];

    final sparklePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (final pos in sparklePositions) {
      _drawStar(canvas, pos, 4, sparklePaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const angles = [0, 90, 180, 270];

    for (int i = 0; i < angles.length; i++) {
      final angle = angles[i] * math.pi / 180;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MacroRingsPainter oldDelegate) {
    return oldDelegate.proteinProgress != proteinProgress ||
           oldDelegate.carbsProgress != carbsProgress ||
           oldDelegate.fatProgress != fatProgress ||
           oldDelegate.showGlow != showGlow;
  }
}

class _RingConfig {
  final double progress;
  final Color color;
  final double radius;
  final double strokeWidth;
  final String label;

  _RingConfig({
    required this.progress,
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.label,
  });
}