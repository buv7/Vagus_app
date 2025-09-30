import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/coach/weekly_review_service.dart';

enum TrendType { line, bar }

class TrendChart extends StatelessWidget {
  final String title;
  final List<DailyPoint> points;
  final TrendType type;

  const TrendChart({
    super.key,
    required this.title,
    required this.points,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final xs = points;
    final maxY = (xs.map((e) => e.value).fold<double>(0, (p, c) => c > p ? c : p) * 1.2).clamp(1, double.infinity).toDouble();

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
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: type == TrendType.line
                ? LineChart(LineChartData(
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (x, _) {
                        final i = x.toInt();
                        if (i < 0 || i >= xs.length) return const SizedBox.shrink();
                        final d = xs[i].day;
                        return Text(['M','T','W','T','F','S','S'][d.weekday - 1], style: const TextStyle(fontSize: 11));
                      })),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    minX: 0,
                    maxX: (xs.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        barWidth: 3,
                        spots: List.generate(xs.length, (i) => FlSpot(i.toDouble(), xs[i].value)),
                        dotData: const FlDotData(show: true),
                      )
                    ],
                  ))
                : BarChart(BarChartData(
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (x, _) {
                        final i = x.toInt();
                        if (i < 0 || i >= xs.length) return const SizedBox.shrink();
                        final d = xs[i].day;
                        return Text(['M','T','W','T','F','S','S'][d.weekday - 1], style: const TextStyle(fontSize: 11));
                      })),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    minY: 0,
                    maxY: maxY,
                    barGroups: List.generate(xs.length, (i) {
                      return BarChartGroupData(x: i, barRods: [BarChartRodData(toY: xs[i].value, width: 14)]);
                    }),
                  )),
          ),
        ],
      ),
    );
  }
}
