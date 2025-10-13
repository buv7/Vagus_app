import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 32,
                spreadRadius: -8,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: const Color(0xFF00C8FF).withValues(alpha: 0.05),
                blurRadius: 64,
                spreadRadius: -16,
                offset: const Offset(0, 32),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(48),
          child: child,
        ),
      ),
    );
  }
}
