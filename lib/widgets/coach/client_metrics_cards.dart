import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/design_tokens.dart';
import '../../theme/theme_colors.dart';

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
              context: context,
              icon: Icons.people_outline,
              label: 'Total Clients',
              value: totalClients.toString(),
              color: DesignTokens.accentGreen,
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: _buildMetricCard(
              context: context,
              icon: Icons.people_outline,
              label: 'Active Clients',
              value: activeClients.toString(),
              color: DesignTokens.accentGreen,
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: _buildMetricCard(
              context: context,
              icon: Icons.calendar_today_outlined,
              label: 'Sessions Today',
              value: sessionsToday.toString(),
              color: DesignTokens.accentGreen,
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: _buildMetricCard(
              context: context,
              icon: Icons.assignment_outlined,
              label: 'Avg Compliance',
              value: '$avgCompliance%',
              color: DesignTokens.accentGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final tc = ThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tc.border,
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
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space16),
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
                  style: DesignTokens.titleLarge.copyWith(
                    color: tc.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  label,
                  style: DesignTokens.labelSmall.copyWith(
                    color: tc.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
