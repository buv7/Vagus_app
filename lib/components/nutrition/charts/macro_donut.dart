import 'dart:math' as math;
import 'package:flutter/material.dart';

class MacroDonut extends StatelessWidget {
  final double proteinG, carbsG, fatG;
  final double size;
  final String? centerLabel; // e.g., "kcal"
  
  const MacroDonut({
    super.key, 
    required this.proteinG, 
    required this.carbsG, 
    required this.fatG, 
    this.size = 120, 
    this.centerLabel
  });

  @override
  Widget build(BuildContext context) {
    final p = proteinG.clamp(0, double.infinity);
    final c = carbsG.clamp(0, double.infinity);
    final f = fatG.clamp(0, double.infinity);
    final total = (p + c + f) == 0 ? 1.0 : (p + c + f);
    final segs = [
      (p / total, Theme.of(context).colorScheme.primary), // protein
      (c / total, Theme.of(context).colorScheme.tertiary), // carbs
      (f / total, Theme.of(context).colorScheme.secondary), // fat
    ];
    
    return SizedBox(
      width: size, 
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(segs),
        child: Center(
          child: Text(
            centerLabel ?? '', 
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<(double, Color)> segs;
  
  _DonutPainter(this.segs);
  
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.14;
    final rect = Rect.fromLTWH(
      stroke/2, 
      stroke/2, 
      size.width - stroke, 
      size.height - stroke
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    
    double start = -math.pi/2;
    for (final (r, color) in segs) {
      final sweep = 2 * math.pi * r;
      paint.color = color.withOpacity(0.9);
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
    
    // inner hole
    final hole = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(
      size.center(Offset.zero), 
      (size.shortestSide/2) - stroke, 
      hole
    );
  }
  
  @override
  bool shouldRepaint(_DonutPainter old) => old.segs != segs;
}
