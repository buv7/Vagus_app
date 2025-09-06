import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../services/settings/reduce_motion.dart';
import '../../services/animation/animation_registry.dart';

class TypingDots extends StatelessWidget {
  final double size;
  final Color? color;

  const TypingDots({
    super.key,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = context.read<ReduceMotion>().enabled;
    
    if (reduce) {
      // Minimal fallback (no animation)
      return Text(
        '...',
        style: TextStyle(
          fontSize: size * 0.8,
          color: color ?? Colors.grey,
        ),
      );
    }

    return Lottie.asset(
      AnimPaths.lottieTyping,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(size, color),
            _buildDot(size, color),
            _buildDot(size, color),
          ],
        );
      },
    );
  }

  Widget _buildDot(double size, Color? color) {
    return Container(
      width: size * 0.2,
      height: size * 0.2,
      margin: EdgeInsets.symmetric(horizontal: size * 0.05),
      decoration: BoxDecoration(
        color: color ?? Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}
