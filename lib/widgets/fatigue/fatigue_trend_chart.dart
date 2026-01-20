// lib/widgets/fatigue/fatigue_trend_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/design_tokens.dart';

/// Line chart showing fatigue trend over time
class FatigueTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> snapshots; // List of {date, fatigue_score}
  final int days; // 7, 14, or 28

  const FatigueTrendChart({
    super.key,
    required this.snapshots,
    this.days = 7,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                color: DesignTokens.textSecondary,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'No data available',
                style: TextStyle(
                  color: DesignTokens.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Prepare data points
    final spots = <FlSpot>[];
    final dates = <String>[];
    
    for (int i = 0; i < snapshots.length; i++) {
      final snapshot = snapshots[i];
      final score = snapshot['fatigue_score'] as int? ?? 0;
      final date = snapshot['snapshot_date'] as String? ?? '';
      
      spots.add(FlSpot(i.toDouble(), score.toDouble()));
      dates.add(date);
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: DesignTokens.glassBorder,
                strokeWidth: 1,
                dashArray: [4, 4],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: days <= 7 ? 1 : (days <= 14 ? 2 : 4),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dates.length) return const Text('');
                  final date = dates[index];
                  // Format: "Jan 22" or just day number
                  final parts = date.split('-');
                  if (parts.length >= 3) {
                    return Text(
                      '${parts[2]}/${parts[1]}',
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 10,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: DesignTokens.glassBorder),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: DesignTokens.accentGreen,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: DesignTokens.accentGreen,
                    strokeWidth: 2,
                    strokeColor: DesignTokens.primaryDark,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: DesignTokens.accentGreen.withValues(alpha: 0.1),
              ),
            ),
          ],
          minY: 0,
          maxY: 100,
        ),
      ),
    );
  }
}
