import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 2 * pi).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                const Color(0xFF0096FF).withValues(alpha: 0.1),
                const Color(0xFF00FFC8).withValues(alpha: 0.1),
                const Color(0xFF0064C8).withValues(alpha: 0.05),
                const Color(0xFF000000),
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
              center: Alignment(
                cos(value) * 0.8,
                sin(value) * 0.8,
              ),
              radius: 1.5,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00C8FF).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
                center: Alignment(
                  cos(value + pi) * 0.6,
                  sin(value + pi) * 0.6,
                ),
                radius: 1.2,
              ),
            ),
          ),
        );
      },
    );
  }
}
