import 'package:flutter/material.dart';
import '../../theme/theme_colors.dart';
import '../../theme/design_tokens.dart';

/// Theme-aware save icon widget
/// Displays a checkmark on a circular blue background
/// Automatically adapts checkmark color to light and dark themes
class SaveIcon extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? checkmarkColor;

  SaveIcon({
    super.key,
    this.size = 24.0,
    this.backgroundColor,
    this.checkmarkColor,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    
    // Blue background (consistent across themes)
    final bgColor = backgroundColor ?? DesignTokens.accentBlue;
    // Checkmark color: white for dark mode, black for light mode
    final checkColor = checkmarkColor ?? (tc.isDark ? DesignTokens.neutralWhite : Colors.black);

    return CustomPaint(
      size: Size(size, size),
      painter: _SaveIconPainter(
        backgroundColor: bgColor,
        checkmarkColor: checkColor,
      ),
    );
  }
}

class _SaveIconPainter extends CustomPainter {
  final Color backgroundColor;
  final Color checkmarkColor;

  _SaveIconPainter({
    required this.backgroundColor,
    required this.checkmarkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.94; // Slight padding
    
    // Draw blue circle background
    final circlePaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);
    
    // Draw checkmark
    final checkmarkPaint = Paint()
      ..color = checkmarkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    // Checkmark path: left point, middle point, right point
    final checkPath = Path();
    final leftX = center.dx - radius * 0.35;
    final leftY = center.dy;
    final middleX = center.dx - radius * 0.1;
    final middleY = center.dy + radius * 0.25;
    final rightX = center.dx + radius * 0.35;
    final rightY = center.dy - radius * 0.25;
    
    checkPath.moveTo(leftX, leftY);
    checkPath.lineTo(middleX, middleY);
    checkPath.lineTo(rightX, rightY);
    
    canvas.drawPath(checkPath, checkmarkPaint);
  }

  @override
  bool shouldRepaint(_SaveIconPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.checkmarkColor != checkmarkColor;
  }
}
