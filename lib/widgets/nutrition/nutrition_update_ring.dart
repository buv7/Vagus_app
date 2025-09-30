import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class NutritionUpdateRing extends StatelessWidget {
  final bool hasUnseenUpdate;
  final VoidCallback? onTap;
  final double size;

  const NutritionUpdateRing({
    super.key,
    required this.hasUnseenUpdate,
    this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasUnseenUpdate) {
      return SizedBox(width: size, height: size);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: DesignTokens.cardBackground,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.accentGreen.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.shade400.withValues(alpha: 0.8),
              ),
              child: Center(
                child: Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: size * 0.6,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
