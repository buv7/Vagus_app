import 'dart:math' as math;
import 'package:flutter/material.dart';

class WeekProgressRing extends StatelessWidget {
  final int completedSets;
  final int totalSets;
  final double size;

  const WeekProgressRing({
    super.key,
    required this.completedSets,
    required this.totalSets,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    final double pct = totalSets <= 0 ? 0.0 : (completedSets.clamp(0, totalSets) / totalSets);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              progress: pct,
              trackColor: Colors.grey.shade300,
              progressColor: Theme.of(context).colorScheme.primary,
              strokeWidth: 6,
            ),
          ),
          Text('${(pct * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Track
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi, false, track);
    // Progress
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      prog,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}


