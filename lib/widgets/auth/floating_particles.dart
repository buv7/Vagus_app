import 'dart:math';
import 'package:flutter/material.dart';

class FloatingParticles extends StatefulWidget {
  final int particleCount;

  const FloatingParticles({
    super.key,
    this.particleCount = 50,
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];
  final List<double> _startX = [];
  final List<double> _horizontalDrift = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeParticles();
  }

  void _initializeParticles() {
    for (int i = 0; i < widget.particleCount; i++) {
      // Random duration between 15-25 seconds
      final duration = 15 + _random.nextInt(11);

      final controller = AnimationController(
        duration: Duration(seconds: duration),
        vsync: this,
      );

      // Stagger start times randomly
      Future.delayed(Duration(milliseconds: _random.nextInt(5000)), () {
        if (mounted) {
          controller.repeat();
        }
      });

      final animation = Tween<double>(begin: 1.2, end: -0.2).animate(
        CurvedAnimation(parent: controller, curve: Curves.linear),
      );

      _controllers.add(controller);
      _animations.add(animation);
      _startX.add(_random.nextDouble());
      _horizontalDrift.add(_random.nextDouble() * 0.1 - 0.05);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.particleCount, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            final yPosition = _animations[index].value;
            final xDrift = sin(_animations[index].value * 2 * pi * 3) *
                _horizontalDrift[index];

            return Positioned(
              left: MediaQuery.of(context).size.width *
                  (_startX[index] + xDrift),
              top: MediaQuery.of(context).size.height * yPosition,
              child: Container(
                width: 2,
                height: 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00C8FF).withValues(alpha: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C8FF).withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
