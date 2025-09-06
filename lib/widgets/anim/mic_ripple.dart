import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:provider/provider.dart';
import '../../services/settings/reduce_motion.dart';
import '../../services/animation/animation_registry.dart';

class MicRipple extends StatelessWidget {
  final double size;
  final Color? color;

  const MicRipple({
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
        Icons.mic,
        size: size * 0.9,
        color: color ?? Colors.red,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: RiveAnimation.asset(
        AnimPaths.riveMicRipple,
        fit: BoxFit.contain,
      ),
    );
  }
}
