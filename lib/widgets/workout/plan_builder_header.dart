import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plan Builder',
                      style: TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space8),
                    const Text(
                      'Create and manage workout and nutrition plans for your clients.',
                      style: TextStyle(
                        color: AppTheme.lightGrey,
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
                    color: AppTheme.primaryBlack,
                    size: 20,
                  ),
                  label: const Text(
                    'New Workout Plan',
                    style: TextStyle(
                      color: AppTheme.primaryBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mintAqua,
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
                    side: const BorderSide(color: AppTheme.steelGrey),
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
    );
  }
}
