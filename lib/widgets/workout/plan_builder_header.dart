import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class PlanBuilderHeader extends StatelessWidget {
  final VoidCallback onNewWorkoutPlan;
  final VoidCallback onNewNutritionPlan;

  const PlanBuilderHeader({
    super.key,
    required this.onNewWorkoutPlan,
    required this.onNewNutritionPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space20),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan Builder',
                      style: TextStyle(
                        color: DesignTokens.neutralWhite,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: DesignTokens.space8),
                    Text(
                      'Create and manage workout and nutrition plans for your clients.',
                      style: TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNewWorkoutPlan,
                  icon: const Icon(
                    Icons.fitness_center,
                    color: AppTheme.primaryDark,
                    size: 20,
                  ),
                  label: const Text(
                    'New Workout Plan',
                    style: TextStyle(
                      color: AppTheme.primaryDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNewNutritionPlan,
                  icon: const Icon(
                    Icons.restaurant,
                    color: AppTheme.neutralWhite,
                    size: 20,
                  ),
                  label: const Text(
                    'New Nutrition Plan',
                    style: TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.mediumGrey),
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
            ),
          ),
        ),
      ),
    );
  }
}
