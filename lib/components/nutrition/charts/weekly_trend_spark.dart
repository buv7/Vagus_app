import 'package:flutter/material.dart';

class WeeklyTrendSpark extends StatelessWidget {
  final List<double> points; // 7 values
  final Color? color;
  final double height;
  
  const WeeklyTrendSpark({
    super.key, 
    required this.points,
    this.color,
    this.height = 40,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height), 
      painter: _Spark(
        points, 
        color ?? Theme.of(context).colorScheme.primary
      )
    );
  }
}

class _Spark extends CustomPainter {
  final List<double> pts; 
  final Color color;
  
  _Spark(this.pts, this.color);
  
  @override
  void paint(Canvas c, Size s) {
    if (pts.isEmpty || pts.length < 2) return;
    
    final maxv = pts.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);
    final minv = pts.reduce((a, b) => a < b ? a : b);
    final range = maxv - minv;
    final stepX = s.width / (pts.length - 1);
    
    final p = Path();
    for (var i = 0; i < pts.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (pts[i] - minv) / range : 0.5;
      final y = s.height - (normalizedValue * s.height);
      
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    c.drawPath(p, paint);
    
    // Add small dots at each point
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    
    for (var i = 0; i < pts.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (pts[i] - minv) / range : 0.5;
      final y = s.height - (normalizedValue * s.height);
      c.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }
  
  @override
  bool shouldRepaint(_Spark old) => old.pts != pts || old.color != color;
}
