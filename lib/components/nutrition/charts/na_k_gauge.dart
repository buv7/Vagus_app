import 'dart:math' as math;
import 'package:flutter/material.dart';

class NaKGauge extends StatelessWidget {
  final int sodiumMg;   // day total
  final int potassiumMg; // day total
  final int sodiumLimitMg; // prefs or WHO 2300mg default
  
  const NaKGauge({
    super.key, 
    required this.sodiumMg, 
    required this.potassiumMg, 
    this.sodiumLimitMg = 2300
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (sodiumMg / sodiumLimitMg).clamp(0.0, 2.0);
    return CustomPaint(
      size: const Size(180, 90),
      painter: _GaugePainter(ratio, potassiumMg),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double ratio;
  final int k;
  
  _GaugePainter(this.ratio, this.k);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height);
    final radius = size.width/2 - 8;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = const Color(0x22000000);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1E88E5);
    final warn = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE53935);

    // background semicircle
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius), 
      math.pi, 
      math.pi, 
      false, 
      bg
    );

    // sodium needle (blue until 1.0, red beyond)
    final sweep = math.pi * ratio.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius), 
      math.pi, 
      sweep, 
      false, 
      fg
    );
    
    if (ratio > 1.0) {
      final extra = math.pi * (ratio - 1.0).clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), 
        math.pi + sweep, 
        extra, 
        false, 
        warn
      );
    }

    // potassium label
    final tp = TextPainter(
      text: TextSpan(
        text: 'K: ${k}mg', 
        style: const TextStyle(
          fontSize: 12, 
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.w500,
        )
      ), 
      textDirection: TextDirection.ltr
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width/2, center.dy - radius - 24));
    
    // sodium label
    final sp = TextPainter(
      text: TextSpan(
        text: 'Na: ${(ratio * 100).round()}%', 
        style: TextStyle(
          fontSize: 12, 
          color: ratio > 1.0 ? const Color(0xFFE53935) : const Color(0xFF1E88E5),
          fontWeight: FontWeight.w500,
        )
      ), 
      textDirection: TextDirection.ltr
    )..layout();
    sp.paint(canvas, Offset(center.dx - sp.width/2, center.dy - radius - 8));
  }
  
  @override
  bool shouldRepaint(_GaugePainter old) => old.ratio != ratio || old.k != k;
}
