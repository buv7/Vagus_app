import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class FadeInAnimation extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 800),
    this.slideOffset = const Offset(0, 20),
  });

  @override
  Widget build(BuildContext context) {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      delay: delay,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              slideOffset.dx * (1 - value),
              slideOffset.dy * (1 - value),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
