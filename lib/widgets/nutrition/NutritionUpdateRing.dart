import 'package:flutter/material.dart';

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
          color: Colors.orange.shade400,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.shade200,
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.notifications_active,
            color: Colors.white,
            size: size * 0.6,
          ),
        ),
      ),
    );
  }
}
