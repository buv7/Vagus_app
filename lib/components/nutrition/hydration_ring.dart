import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../theme/design_tokens.dart';

/// Hydration ring widget for dashboard display
class HydrationRing extends StatelessWidget {
  final int ml;
  final int targetMl;
  final VoidCallback? onAdd250;
  final VoidCallback? onAdd500;
  
  const HydrationRing({
    super.key,
    required this.ml,
    required this.targetMl,
    this.onAdd250,
    this.onAdd500,
  });

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final ratio = targetMl <= 0 ? 0.0 : (ml / targetMl).clamp(0.0, 1.0);
    final progress = (ratio * 100).round();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Progress ring
            CustomPaint(
              painter: _RingPainter(
                ratio: ratio,
                color: DesignTokens.accentBlue,
                gradientColors: [DesignTokens.accentBlue, DesignTokens.accentGreen],
              ),
              size: const Size(80, 80),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$progress%',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.accentGreen,
                      ),
                    ),
                    Text(
                      '${(ml / 1000.0).toStringAsFixed(1)}L',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info and buttons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleHelper.t('hydration', language),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$ml / $targetMl ml',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(
                            LocaleHelper.t('add_water_250', language),
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: onAdd250,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(
                            LocaleHelper.t('add_water_500', language),
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: onAdd500,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the hydration progress ring
class _RingPainter extends CustomPainter {
  final double ratio;
  final Color color;
  final List<Color>? gradientColors;

  _RingPainter({
    required this.ratio,
    required this.color,
    this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    
    // Background ring
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    // Progress ring with gradient support
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Apply gradient if available, otherwise use solid color
    if (gradientColors != null && gradientColors!.length >= 2) {
      progressPaint.shader = SweepGradient(
        colors: gradientColors!,
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + (2 * math.pi * ratio),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    } else {
      progressPaint.color = color;
    }

    // Draw background circle
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    if (ratio > 0) {
      final sweepAngle = 2 * math.pi * ratio;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.ratio != ratio ||
           oldDelegate.color != color ||
           oldDelegate.gradientColors != gradientColors;
  }
}
