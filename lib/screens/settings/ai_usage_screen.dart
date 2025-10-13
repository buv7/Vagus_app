import 'package:flutter/material.dart';
import '../../services/navigation/app_navigator.dart';
import '../../theme/design_tokens.dart';

class AiUsageScreen extends StatelessWidget {
  const AiUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Usage & Quotas'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'AI Usage & Quotas',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    _QuotaItem(
                      featureLabel: 'Notes AI',
                      icon: Icons.note,
                      current: 45,
                      total: 100,
                    ),
                    SizedBox(height: 12),
                    _QuotaItem(
                      featureLabel: 'Nutrition AI',
                      icon: Icons.restaurant,
                      current: 23,
                      total: 50,
                    ),
                    SizedBox(height: 12),
                    _QuotaItem(
                      featureLabel: 'Workout AI',
                      icon: Icons.fitness_center,
                      current: 67,
                      total: 75,
                      showLimitWarning: true,
                    ),
                    SizedBox(height: 12),
                    _QuotaItem(
                      featureLabel: 'Messaging AI',
                      icon: Icons.chat,
                      current: 12,
                      total: 200,
                    ),
                    SizedBox(height: 12),
                    _QuotaItem(
                      featureLabel: 'Transcription',
                      icon: Icons.mic,
                      current: 8,
                      total: 25,
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => AppNavigator.billingUpgrade(context),
                  icon: const Icon(Icons.star),
                  label: const Text('Upgrade to Pro'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaItem extends StatelessWidget {
  final String featureLabel;
  final IconData icon;
  final int current;
  final int total;
  final bool showLimitWarning;

  const _QuotaItem({
    required this.featureLabel,
    required this.icon,
    required this.current,
    required this.total,
    this.showLimitWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = total == 0 ? 0 : current / total;
    final bool isWarning = percentage >= 0.8;
    final bool isDanger = percentage >= 0.95;

    Color progressColor;
    if (isDanger) {
      progressColor = Colors.red;
    } else if (isWarning || showLimitWarning) {
      progressColor = Colors.orange;
    } else {
      progressColor = DesignTokens.accentGreen;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                featureLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              '$current/$total',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 4,
            backgroundColor: DesignTokens.darkBackground,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        if (isWarning || showLimitWarning) ...[
          const SizedBox(height: 6),
          Text(
            isDanger ? '⚠️ Almost at limit!' : '⚠️ Getting close to limit',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}


