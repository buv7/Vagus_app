import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../services/animation/animation_registry.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final double animationSize;
  final Color? color;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.animationSize = 120,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: animationSize,
              height: animationSize,
              child: Lottie.asset(
                AnimPaths.lottieEmpty,
                width: animationSize,
                height: animationSize,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.inbox_outlined,
                  size: animationSize * 0.6,
                  color: color ?? Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color ?? Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color?.withValues(alpha: 0.7) ?? Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
