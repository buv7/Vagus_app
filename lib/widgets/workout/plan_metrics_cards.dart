import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class PlanMetricsCards extends StatelessWidget {
  final int totalPlans;
  final int activeClients;
  final double avgRating;
  final int thisMonth;

  const PlanMetricsCards({
    super.key,
    required this.totalPlans,
    required this.activeClients,
    required this.avgRating,
    required this.thisMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              icon: Icons.fitness_center,
              label: 'Total Plans',
              value: totalPlans.toString(),
              color: AppTheme.mintAqua,
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: _buildMetricCard(
              icon: Icons.people_outline,
              label: 'Active Clients',
              value: activeClients.toString(),
              color: AppTheme.lightGrey,
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: _buildMetricCard(
              icon: Icons.star_outline,
              label: 'Avg Rating',
              value: avgRating.toString(),
              color: AppTheme.mintAqua,
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: _buildMetricCard(
              icon: Icons.schedule,
              label: 'This Month',
              value: thisMonth.toString(),
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
