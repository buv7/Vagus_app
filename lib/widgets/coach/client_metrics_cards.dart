import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class ClientMetricsCards extends StatelessWidget {
  final int totalClients;
  final int activeClients;
  final int sessionsToday;
  final int avgCompliance;

  const ClientMetricsCards({
    super.key,
    required this.totalClients,
    required this.activeClients,
    required this.sessionsToday,
    required this.avgCompliance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              icon: Icons.people_outline,
              label: 'Total Clients',
              value: totalClients.toString(),
              color: AppTheme.mintAqua,
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: _buildMetricCard(
              icon: Icons.people_outline,
              label: 'Active Clients',
              value: activeClients.toString(),
              color: AppTheme.mintAqua,
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: _buildMetricCard(
              icon: Icons.calendar_today_outlined,
              label: 'Sessions Today',
              value: sessionsToday.toString(),
              color: AppTheme.mintAqua,
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: _buildMetricCard(
              icon: Icons.assignment_outlined,
              label: 'Avg Compliance',
              value: '$avgCompliance%',
              color: AppTheme.mintAqua,
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
