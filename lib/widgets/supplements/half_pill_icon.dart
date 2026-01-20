import 'package:flutter/material.dart';

/// Custom icon widget for supplements - a pill that's half red and half blue
class HalfPillIcon extends StatelessWidget {
  final double size;
  final Color? redColor;
  final Color? blueColor;

  const HalfPillIcon({
    super.key,
    this.size = 24.0,
    this.redColor,
    this.blueColor,
  });

  @override
  Widget build(BuildContext context) {
    final red = redColor ?? Colors.red;
    final blue = blueColor ?? Colors.blue;

    return CustomPaint(
      size: Size(size, size * 0.6), // Pill shape: wider than tall
      painter: _HalfPillPainter(red: red, blue: blue),
    );
  }
}

class _HalfPillPainter extends CustomPainter {
  final Color red;
  final Color blue;

  _HalfPillPainter({
    required this.red,
    required this.blue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Calculate pill dimensions
    final pillHeight = size.height;
    final pillWidth = size.width;
    final radius = pillHeight / 2;
    
    // Create pill path (rounded rectangle)
    final pillPath = Path()
      ..moveTo(radius, 0)
      ..lineTo(pillWidth - radius, 0)
      ..arcToPoint(
        Offset(pillWidth, radius),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..lineTo(pillWidth, pillHeight - radius)
      ..arcToPoint(
        Offset(pillWidth - radius, pillHeight),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..lineTo(radius, pillHeight)
      ..arcToPoint(
        Offset(0, pillHeight - radius),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..lineTo(0, radius)
      ..arcToPoint(
        Offset(radius, 0),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..close();

    // Clip to pill shape
    canvas.clipPath(pillPath);

    // Draw left half (red)
    paint.color = red;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, pillWidth / 2, pillHeight),
      paint,
    );

    // Draw right half (blue)
    paint.color = blue;
    canvas.drawRect(
      Rect.fromLTWH(pillWidth / 2, 0, pillWidth / 2, pillHeight),
      paint,
    );

    // Draw divider line
    final dividerPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(pillWidth / 2, 0),
      Offset(pillWidth / 2, pillHeight),
      dividerPaint,
    );
  }

  @override
  bool shouldRepaint(_HalfPillPainter oldDelegate) {
    return oldDelegate.red != red || oldDelegate.blue != blue;
  }
}
