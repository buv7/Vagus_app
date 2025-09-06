import 'package:flutter/material.dart';
import '../../services/coach/weekly_review_service.dart';

class WeeklySummaryCard extends StatelessWidget {
  final WeeklySummary summary;
  const WeeklySummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget tile(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.7))),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              tile('Compliance', '${summary.compliancePercent.toStringAsFixed(1)}%'),
              const SizedBox(width: 8),
              tile('Sessions', '${summary.sessionsDone} done • ${summary.sessionsSkipped} skipped'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              tile('Tonnage', '${summary.totalTonnage.toStringAsFixed(0)} kg'),
              const SizedBox(width: 8),
              tile('Cardio', '${summary.cardioMinutes} mins'),
            ],
          ),
        ],
      ),
    );
  }
}
