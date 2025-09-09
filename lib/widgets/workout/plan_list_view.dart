import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class PlanListView extends StatelessWidget {
  final List<Map<String, dynamic>> plans;
  final Function(Map<String, dynamic>) onEditPlan;
  final Function(Map<String, dynamic>) onAssignPlan;

  const PlanListView({
    super.key,
    required this.plans,
    required this.onEditPlan,
    required this.onAssignPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
      child: plans.isEmpty
          ? const Center(
              child: Text(
                'No plans found',
                style: TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 16,
                ),
              ),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: DesignTokens.space16,
                mainAxisSpacing: DesignTokens.space16,
                childAspectRatio: 0.6, // Fixed overflow
              ),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return _buildPlanCard(plan);
              },
            ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final type = plan['type'] as String;
    final difficulty = plan['difficulty'] as String;
    final rating = plan['rating'] as double;
    final difficultyColor = _getDifficultyColor(difficulty);
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                type == 'workout' ? Icons.fitness_center : Icons.restaurant,
                color: AppTheme.mintAqua,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space8,
                  vertical: DesignTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: difficultyColor,
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Text(
                  difficulty,
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: AppTheme.softYellow,
                    size: 16,
                  ),
                  const SizedBox(width: DesignTokens.space4),
                  Text(
                    rating.toString(),
                    style: const TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space8),
          
          // Title
          Text(
            plan['title'],
            style: const TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: DesignTokens.space6),
          
          // Description
          Text(
            plan['description'],
            style: const TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 12,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const Spacer(),
          
          // Stats
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppTheme.lightGrey,
                size: 14,
              ),
              const SizedBox(width: DesignTokens.space4),
              Text(
                plan['duration'],
                style: const TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              Icon(
                Icons.people_outline,
                color: AppTheme.lightGrey,
                size: 14,
              ),
              const SizedBox(width: DesignTokens.space4),
              Text(
                '${plan['clientsAssigned']} clients',
                style: const TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space8),
          
          // Tags
          Wrap(
            spacing: DesignTokens.space4,
            runSpacing: DesignTokens.space4,
            children: (plan['tags'] as List<String>).take(3).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space6,
                  vertical: DesignTokens.space2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.steelGrey,
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: DesignTokens.space12),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onEditPlan(plan),
                  child: const Text(
                    'Edit Plan',
                    style: TextStyle(
                      color: AppTheme.primaryBlack,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mintAqua,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onAssignPlan(plan),
                  child: const Text(
                    'Assign',
                    style: TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.steelGrey),
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space8,
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return AppTheme.softYellow;
      case 'advanced':
        return Colors.red;
      default:
        return AppTheme.steelGrey;
    }
  }
}
