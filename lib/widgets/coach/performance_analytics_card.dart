import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class PerformanceAnalyticsCard extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final Function(int) onTimeRangeChange;

  const PerformanceAnalyticsCard({
    super.key,
    required this.analytics,
    required this.onTimeRangeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
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
              Expanded(
                child: const Text(
                  'Performance Analytics',
                  style: TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space6,
                  vertical: DesignTokens.space2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.softYellow,
                  borderRadius: BorderRadius.circular(DesignTokens.radius4),
                ),
                child: const Text(
                  'Pro Insights',
                  style: TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space8,
                  vertical: DesignTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.steelGrey,
                  borderRadius: BorderRadius.circular(DesignTokens.radius4),
                ),
                child: const Text(
                  'Last 7 days',
                  style: TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Metrics Grid - 2 boxes per row for more space
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, // Changed from 3 to 2
            crossAxisSpacing: DesignTokens.space8,
            mainAxisSpacing: DesignTokens.space8,
            childAspectRatio: 2.2, // 2 COLUMNS - LARGER ICONS & VALUES!
            children: [
              _buildSimpleMetricCard(
                icon: Icons.people_outline,
                value: '${analytics['activeClients']}',
                change: '+${analytics['activeClientsChange']}%',
                isPositive: true,
              ),
              _buildSimpleMetricCard(
                icon: Icons.calendar_today_outlined,
                value: '${analytics['sessionsCompleted']}',
                change: '+${analytics['sessionsChange']}%',
                isPositive: true,
              ),
              _buildSimpleMetricCard(
                icon: Icons.chat_bubble_outline,
                value: analytics['avgResponseTime'],
                change: '${analytics['responseTimeChange']}h',
                isPositive: false,
              ),
              _buildSimpleMetricCard(
                icon: Icons.star_outline,
                value: '${analytics['clientSatisfaction']}',
                change: '+${analytics['satisfactionChange']}',
                isPositive: true,
              ),
              _buildSimpleMetricCard(
                icon: Icons.attach_money_outlined,
                value: '\$${analytics['revenue']}',
                change: '+${analytics['revenueChange']}%',
                isPositive: true,
              ),
              _buildSimpleMetricCard(
                icon: Icons.trending_up_outlined,
                value: '${analytics['planCompliance']}%',
                change: '+${analytics['complianceChange']}%',
                isPositive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMetricCard({
    required IconData icon,
    required String value,
    required String change,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space8),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(
          color: AppTheme.steelGrey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon on the left
          Icon(
            icon,
            color: AppTheme.mintAqua,
            size: 28,
          ),
          
          // Value in the center
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Change indicator on the right
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 18,
              ),
              const SizedBox(width: DesignTokens.space2),
              Text(
                change,
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}