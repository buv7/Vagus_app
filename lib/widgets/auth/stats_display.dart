import 'package:flutter/material.dart';

class StatsDisplay extends StatelessWidget {
  const StatsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatItem(
            value: 86,
            suffix: '%',
            label: 'PERFORMANCE GAIN',
          ),
        ),
        SizedBox(width: 32),
        Expanded(
          child: _StatItem(
            value: 120,
            suffix: '+',
            label: 'NEURAL PATHWAYS',
          ),
        ),
        SizedBox(width: 32),
        Expanded(
          child: _StatItem(
            value: 24,
            suffix: '/7',
            label: 'ADAPTIVE AI',
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final int value;
  final String suffix;
  final String label;

  const _StatItem({
    required this.value,
    required this.suffix,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 2),
          curve: Curves.easeOut,
          tween: Tween(begin: 0, end: value.toDouble()),
          builder: (context, animatedValue, child) {
            return RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: animatedValue.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00C8FF),
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: suffix,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF00C8FF).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.4),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
