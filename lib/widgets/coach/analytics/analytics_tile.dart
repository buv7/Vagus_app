import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import 'package:vagus_app/theme/design_tokens.dart';

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
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.accentBlue.withValues(alpha: 0.3),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Title
            Text(
              title,
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // Value
            Text(
              value,
              style: DesignTokens.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: DesignTokens.neutralWhite,
              ),
            ),
            
            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: DesignTokens.bodySmall.copyWith(
                  color: DesignTokens.textSecondary.withValues(alpha: 0.8),
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
          ),
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
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: DesignTokens.textSecondary,
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
            color: DesignTokens.accentBlue,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: DesignTokens.accentBlue.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}
