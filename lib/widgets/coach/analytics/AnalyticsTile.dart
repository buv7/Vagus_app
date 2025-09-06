import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsTile extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final List<double>? spark;
  final VoidCallback? onTap;

  const AnalyticsTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.spark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // Value
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            
            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            // Sparkline
            if (spark != null && spark!.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: _buildSparkline(context, spark!, isDark),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSparkline(BuildContext context, List<double> data, bool isDark) {
    if (data.isEmpty) return const SizedBox.shrink();

    // Normalize data to 0-1 range for consistent display
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    
    if (range == 0) {
      // Flat line if all values are the same
      return Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
      );
    }

    final normalizedData = data.map((value) => (value - min) / range).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: normalizedData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value);
            }).toList(),
            isCurved: true,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}
