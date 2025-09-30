import 'package:flutter/material.dart';
import '../../services/coach/weekly_ai_insights_service.dart';

class WeeklyAIInsightsCard extends StatelessWidget {
  final WeeklyAIInsights insights;
  final VoidCallback? onRegenerate;

  const WeeklyAIInsightsCard({
    super.key,
    required this.insights,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget section(String title, List<String> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...items.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(t)),
                ],
              ),
            )),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('AI Weekly Insights', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              if (onRegenerate != null)
                IconButton(
                  tooltip: 'Regenerate',
                  icon: const Icon(Icons.refresh_outlined),
                  onPressed: onRegenerate,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (insights.usedAI)
            Text('Generated with AI${insights.aiModel != null ? ' — ${insights.aiModel}' : ''}',
                style: TextStyle(fontSize: 12, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6))),
          if (!insights.usedAI)
            Text('Heuristic summary (AI unavailable).',
                style: TextStyle(fontSize: 12, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6))),
          const SizedBox(height: 12),
          section('Key Wins', insights.wins),
          section('Risk Flags', insights.risks),
          section('Suggestions', insights.suggestions),
          if (insights.rationale.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Rationale', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(insights.rationale),
          ],
        ],
      ),
    );
  }
}
