import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../services/settings/reduce_motion.dart';
import '../../services/animation/animation_registry.dart';

class VagusLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const VagusLoader({
    super.key,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = context.read<ReduceMotion>().enabled;
    
    if (reduce) {
      // Minimal fallback (no animation)
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.blue),
        ),
      );
    }

    return Lottie.asset(
      AnimPaths.lottieLoading,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.blue),
          ),
        );
      },
    );
  }
}
