import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/coach/weekly_review_service.dart';

class ComplianceDonut extends StatelessWidget {
  final ComplianceData compliance;
  const ComplianceDonut({super.key, required this.compliance});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color c() {
      switch (compliance.flag) {
        case 'green': return Colors.greenAccent.shade400;
        case 'yellow': return Colors.amberAccent.shade400;
        default: return Colors.redAccent.shade400;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Compliance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.6,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 48,
                sectionsSpace: 2,
                sections: [
                  PieChartSectionData(
                    value: compliance.percent.clamp(0, 100),
                    showTitle: false,
                    color: c(),
                    radius: 56,
                  ),
                  PieChartSectionData(
                    value: 100 - compliance.percent.clamp(0, 100),
                    showTitle: false,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
                    radius: 56,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${compliance.percent.toStringAsFixed(1)}% • ${compliance.flag.toUpperCase()}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
