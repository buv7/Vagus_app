import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:vagus_app/services/coach/coach_analytics_service.dart';
import 'package:vagus_app/theme/design_tokens.dart';
import 'analytics_tile.dart';

class AnalyticsHeader extends StatelessWidget {
  final CoachAnalyticsSummary data;
  final int days;
  final void Function(int days) onRangeChange;

  const AnalyticsHeader({
    super.key,
    required this.data,
    required this.days,
    required this.onRangeChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time range selector
        Row(
          children: [
            Text(
              'Analytics',
              style: DesignTokens.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: DesignTokens.neutralWhite,
              ),
            ),
            const Spacer(),
            _buildRangeSelector(context, isDark),
          ],
        ),
        const SizedBox(height: 16),
        
        // Analytics tiles grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final crossAxisCount = isWide ? 3 : 2;
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 1.8 : 1.5,
              children: [
                // Active Clients
                AnalyticsTile(
                  title: 'Active Clients',
                  value: data.activeClients.toString(),
                  subtitle: 'in last $days days',
                ),
                
                // Average Compliance
                AnalyticsTile(
                  title: 'Avg Compliance',
                  value: '${data.avgCompliance.toStringAsFixed(0)}%',
                  subtitle: 'workout completion',
                  spark: data.sparkCompliance,
                ),
                
                // Average Steps
                AnalyticsTile(
                  title: 'Avg Steps',
                  value: data.avgSteps.toStringAsFixed(0),
                  subtitle: 'daily average',
                  spark: data.sparkSteps,
                ),
                
                // Energy Balance
                AnalyticsTile(
                  title: 'Energy Balance',
                  value: '${data.netEnergyBalance >= 0 ? '+' : ''}${data.netEnergyBalance.toStringAsFixed(0)} kcal',
                  subtitle: 'net daily average',
                  spark: data.sparkEnergy,
                ),
                
                // Check-ins This Week
                AnalyticsTile(
                  title: 'Check-ins (7d)',
                  value: data.checkinsThisWeek.toString(),
                  subtitle: 'this week',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRangeSelector(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentPink.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRangeButton(context, 7, '7d', isDark),
                _buildRangeButton(context, 30, '30d', isDark),
                _buildRangeButton(context, 90, '90d', isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeButton(BuildContext context, int value, String label, bool isDark) {
    final isSelected = days == value;
    
    return GestureDetector(
      onTap: () => onRangeChange(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.accentPink.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: DesignTokens.labelSmall.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? DesignTokens.neutralWhite
                : DesignTokens.textSecondary,
          ),
        ),
      ),
    );
  }
}
