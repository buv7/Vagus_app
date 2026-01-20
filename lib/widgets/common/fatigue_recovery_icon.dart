import 'package:flutter/material.dart';
import '../../theme/theme_colors.dart';
import '../../theme/design_tokens.dart';

/// Theme-aware Fatigue Budget / Recovery icon widget
/// Displays a rising line graph/chart icon
/// Automatically adapts colors to light and dark themes
class FatigueRecoveryIcon extends StatelessWidget {
  final double size;
  final Color? color;

  FatigueRecoveryIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    
    // Use accent blue color (consistent with the design)
    final iconColor = color ?? DesignTokens.accentBlue;
    
    return CustomPaint(
      size: Size(size, size),
      painter: _FatigueRecoveryIconPainter(
        color: iconColor,
      ),
    );
  }
}

class _FatigueRecoveryIconPainter extends CustomPainter {
  final Color color;

  _FatigueRecoveryIconPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0; // Base scale for 24px icon
    
    // Define chart area with padding
    final padding = 2.0 * scale;
    final chartLeft = padding;
    final chartRight = size.width - padding;
    final chartBottom = size.height - padding;
    final chartTop = padding;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;
    
    // Draw rising line graph
    // Points: start low, rise gradually, then spike up at the end
    final linePath = Path();
    
    // Starting point (left, near bottom)
    final startX = chartLeft;
    final startY = chartBottom - chartHeight * 0.3;
    linePath.moveTo(startX, startY);
    
    // Middle point (slight rise)
    final midX = chartLeft + chartWidth * 0.5;
    final midY = chartBottom - chartHeight * 0.5;
    linePath.lineTo(midX, midY);
    
    // End point (spike up)
    final endX = chartRight;
    final endY = chartTop + chartHeight * 0.2;
    linePath.lineTo(endX, endY);
    
    // Draw the line with accent blue color
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    canvas.drawPath(linePath, linePaint);
    
    // Draw small circles at data points for emphasis
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Start point
    canvas.drawCircle(Offset(startX, startY), 1.5 * scale, pointPaint);
    
    // Middle point
    canvas.drawCircle(Offset(midX, midY), 1.5 * scale, pointPaint);
    
    // End point (slightly larger for emphasis on the spike)
    canvas.drawCircle(Offset(endX, endY), 2.0 * scale, pointPaint);
  }

  @override
  bool shouldRepaint(_FatigueRecoveryIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
