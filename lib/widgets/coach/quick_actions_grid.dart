import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onNewWorkoutPlan;
  final VoidCallback onNewNutritionPlan;
  final VoidCallback onAddCoachNote;
  final VoidCallback onOpenMessages;
  final VoidCallback onAddSupplement;
  final VoidCallback onTemplates;
  final VoidCallback onIntakeForms;
  final VoidCallback onPublishAvailability;
  final VoidCallback onViewAnalytics;
  final VoidCallback onImportProgram;

  const QuickActionsGrid({
    super.key,
    required this.onNewWorkoutPlan,
    required this.onNewNutritionPlan,
    required this.onAddCoachNote,
    required this.onOpenMessages,
    required this.onAddSupplement,
    required this.onTemplates,
    required this.onIntakeForms,
    required this.onPublishAvailability,
    required this.onViewAnalytics,
    required this.onImportProgram,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
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
              const Icon(
                Icons.add_circle_outline,
                color: AppTheme.mintAqua,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.space8),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space20),
          
          // Actions Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: DesignTokens.space16,
            mainAxisSpacing: DesignTokens.space16,
            childAspectRatio: 1.1,
            children: [
              _buildActionCard(
                icon: Icons.fitness_center_outlined,
                title: 'New Workout Plan',
                subtitle: 'Create a custom workout plan',
                onTap: onNewWorkoutPlan,
                color: AppTheme.mintAqua,
              ),
              _buildActionCard(
                icon: Icons.restaurant_outlined,
                title: 'New Nutrition Plan',
                subtitle: 'Build a nutrition plan',
                onTap: onNewNutritionPlan,
                color: AppTheme.softYellow,
              ),
              _buildActionCard(
                icon: Icons.note_add_outlined,
                title: 'Add Coach Note',
                subtitle: 'Quick note for a client',
                onTap: onAddCoachNote,
                color: AppTheme.lightGrey,
              ),
              _buildActionCard(
                icon: Icons.chat_bubble_outline,
                title: 'Open Messages',
                subtitle: 'View client conversations',
                onTap: onOpenMessages,
                color: AppTheme.softYellow,
              ),
              _buildActionCard(
                icon: Icons.add_circle_outline,
                title: 'Add Supplement',
                subtitle: 'Add supplement to client plan',
                onTap: onAddSupplement,
                color: AppTheme.mintAqua,
              ),
              _buildActionCard(
                icon: Icons.settings_outlined,
                title: 'Templates',
                subtitle: 'Manage plan templates',
                onTap: onTemplates,
                color: AppTheme.lightGrey,
              ),
              _buildActionCard(
                icon: Icons.assignment_outlined,
                title: 'Intake Forms',
                subtitle: 'Manage client intake forms',
                onTap: onIntakeForms,
                color: AppTheme.mintAqua,
              ),
              _buildActionCard(
                icon: Icons.calendar_today_outlined,
                title: 'Publish Availability',
                subtitle: 'Set your available time slots',
                onTap: onPublishAvailability,
                color: AppTheme.lightGrey,
              ),
              _buildActionCard(
                icon: Icons.analytics_outlined,
                title: 'View Analytics',
                subtitle: 'Detailed performance metrics',
                onTap: onViewAnalytics,
                color: AppTheme.softYellow,
              ),
              _buildActionCard(
                icon: Icons.upload_outlined,
                title: 'Import Program',
                subtitle: 'Upload or paste program text',
                onTap: onImportProgram,
                color: AppTheme.mintAqua,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space16),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlack,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          border: Border.all(
            color: AppTheme.steelGrey,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: DesignTokens.space12),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
