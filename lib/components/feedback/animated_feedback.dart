import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';

enum FeedbackType {
  milestone,
  pending,
  approved,
  connected,
  warning,
  error,
  success,
  info,
}

class AnimatedFeedback extends StatefulWidget {
  final FeedbackType type;
  final String? title;
  final String? message;
  final Duration duration;
  final VoidCallback? onDismiss;

  const AnimatedFeedback({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  static void show(
    BuildContext context,
    FeedbackType type, {
    String? title,
    String? message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimatedFeedback(
        type: type,
        title: title,
        message: message,
        duration: duration,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<AnimatedFeedback> createState() => _AnimatedFeedbackState();
}

class _AnimatedFeedbackState extends State<AnimatedFeedback>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await _fadeController.forward();
    await _scaleController.forward();
    
    if (widget.type == FeedbackType.milestone || widget.type == FeedbackType.success) {
      _particleController.forward();
    }

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _fadeController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onDismiss?.call();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withOpacity(0.6),
            child: Center(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _buildFeedbackCard(),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackCard() {
    return GestureDetector(
      onTap: _dismiss,
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with animation
            _buildAnimatedIcon(),
            const SizedBox(height: 16),
            
            // Title
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlack,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            
            // Message
            if (widget.message != null) ...[
              Text(
                widget.message!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            
            // Dismiss button
            TextButton(
              onPressed: _dismiss,
              child: const Text(
                'Got it',
                style: TextStyle(
                  color: AppTheme.primaryBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    final iconData = _getIconForType();
    final color = _getColorForType();
    
    if (widget.type == FeedbackType.milestone || widget.type == FeedbackType.success) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Particle effects
          AnimatedBuilder(
            animation: _particleAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(80, 80),
                painter: ParticlePainter(_particleAnimation.value),
              );
            },
          ),
          // Main icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: color,
              size: 32,
            ),
          ),
        ],
      );
    } else {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconData,
          color: color,
          size: 32,
        ),
      );
    }
  }

  IconData _getIconForType() {
    switch (widget.type) {
      case FeedbackType.milestone:
        return Icons.emoji_events;
      case FeedbackType.pending:
        return Icons.schedule;
      case FeedbackType.approved:
        return Icons.check_circle;
      case FeedbackType.connected:
        return Icons.link;
      case FeedbackType.warning:
        return Icons.warning;
      case FeedbackType.error:
        return Icons.error;
      case FeedbackType.success:
        return Icons.check_circle;
      case FeedbackType.info:
        return Icons.info;
    }
  }

  Color _getColorForType() {
    switch (widget.type) {
      case FeedbackType.milestone:
        return Colors.amber;
      case FeedbackType.pending:
        return Colors.orange;
      case FeedbackType.approved:
        return Colors.green;
      case FeedbackType.connected:
        return Colors.blue;
      case FeedbackType.warning:
        return Colors.orange;
      case FeedbackType.error:
        return Colors.red;
      case FeedbackType.success:
        return Colors.green;
      case FeedbackType.info:
        return Colors.blue;
    }
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw particles in a circle
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2 / 8) + (animationValue * math.pi * 2);
      final distance = radius * 0.7 * animationValue;
      
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;
      
      final particleSize = 4 * (1 - animationValue);
      if (particleSize > 0) {
        canvas.drawCircle(
          Offset(x, y),
          particleSize,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper class for easy feedback triggers
class FeedbackHelper {
  static void showMilestone(BuildContext context, String message) {
    AnimatedFeedback.show(
      context,
      FeedbackType.milestone,
      title: 'Milestone Achieved!',
      message: message,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    AnimatedFeedback.show(
      context,
      FeedbackType.success,
      title: 'Success!',
      message: message,
    );
  }

  static void showWarning(BuildContext context, String message) {
    AnimatedFeedback.show(
      context,
      FeedbackType.warning,
      title: 'Warning',
      message: message,
    );
  }

  static void showError(BuildContext context, String message) {
    AnimatedFeedback.show(
      context,
      FeedbackType.error,
      title: 'Error',
      message: message,
    );
  }

  static void showPending(BuildContext context, String message) {
    AnimatedFeedback.show(
      context,
      FeedbackType.pending,
      title: 'Pending',
      message: message,
    );
  }

  static void showApproved(BuildContext context, String message) {
    AnimatedFeedback.show(
      context,
      FeedbackType.approved,
      title: 'Approved!',
      message: message,
    );
  }

  static void showConnected(BuildContext context, String message) {
    AnimatedFeedback.show(
      context,
      FeedbackType.connected,
      title: 'Connected!',
      message: message,
    );
  }
}
