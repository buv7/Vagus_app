import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../services/settings/reduce_motion.dart';
import '../../services/animation/animation_registry.dart';

class VagusSuccess extends StatelessWidget {
  final double size;
  final Color? color;

  const VagusSuccess({
    super.key,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = context.read<ReduceMotion>().enabled;
    
    if (reduce) {
      // Minimal fallback (no animation)
      return Icon(
        Icons.check_circle,
        size: size,
        color: color ?? Colors.green,
      );
    }

    return Lottie.asset(
      AnimPaths.lottieSuccess,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.check_circle,
          size: size,
          color: color ?? Colors.green,
        );
      },
    );
  }
}
