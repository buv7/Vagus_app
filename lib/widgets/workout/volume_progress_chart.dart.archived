import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/workout/analytics_models.dart';
import '../../utils/locale_helper.dart';
import '../../utils/design_tokens.dart';

/// Volume progress line chart
///
/// Displays volume trends over time with:
/// - Line chart showing weekly/monthly volume
/// - Touch tooltips with detailed data
/// - Average line indicator
/// - Trend analysis
class VolumeProgressChart extends StatefulWidget {
  final VolumeTrendData trendData;
  final Color? lineColor;
  final bool showAverageLine;
  final bool showGrid;

  const VolumeProgressChart({
    Key? key,
    required this.trendData,
    this.lineColor,
    this.showAverageLine = true,
    this.showGrid = true,
  }) : super(key: key);

  @override
  State<VolumeProgressChart> createState() => _VolumeProgressChartState();
}

class _VolumeProgressChartState extends State<VolumeProgressChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final lineColor = widget.lineColor ?? DesignTokens.primaryColor;
    final dataPoints = widget.trendData.dataPoints;

    if (dataPoints.isEmpty) {
      return Center(
        child: Text(LocaleHelper.t(context, 'no_data_available')),
      );
    }

    // Find min and max for Y axis
    final volumes = dataPoints.map((p) => p.volume).toList();
    final maxVolume = volumes.reduce((a, b) => a > b ? a : b);
    final minVolume = volumes.reduce((a, b) => a < b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with metrics
        _buildHeader(),
        const SizedBox(height: 16),

        // Chart
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: widget.showGrid,
                drawVerticalLine: false,
                horizontalInterval: (maxVolume - minVolume) / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[300],
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${(value / 1000).toStringAsFixed(1)}k',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: dataPoints.length > 10 ? 2 : 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < 0 || value.toInt() >= dataPoints.length) {
                        return const SizedBox();
                      }
                      return Text(
                        dataPoints[value.toInt()].label,
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!),
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              minY: minVolume * 0.9,
              maxY: maxVolume * 1.1,
              lineBarsData: [
                // Main volume line
                LineChartBarData(
                  spots: List.generate(
                    dataPoints.length,
                    (index) => FlSpot(
                      index.toDouble(),
                      dataPoints[index].volume,
                    ),
                  ),
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: _touchedIndex == index ? 6 : 4,
                        color: lineColor,
                        strokeWidth: _touchedIndex == index ? 2 : 0,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        lineColor.withOpacity(0.3),
                        lineColor.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Average line
                if (widget.showAverageLine)
                  LineChartBarData(
                    spots: List.generate(
                      dataPoints.length,
                      (index) => FlSpot(
                        index.toDouble(),
                        widget.trendData.averageVolume,
                      ),
                    ),
                    isCurved: false,
                    color: Colors.orange,
                    barWidth: 2,
                    dashArray: [8, 4],
                    dotData: const FlDotData(show: false),
                  ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
                    setState(() {
                      _touchedIndex = response.lineBarSpots![0].spotIndex;
                    });
                  } else {
                    setState(() {
                      _touchedIndex = null;
                    });
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => Colors.black87,
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      if (spot.barIndex == 0) {
                        final dataPoint = dataPoints[spot.spotIndex];
                        return LineTooltipItem(
                          '${dataPoint.label}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: '${(dataPoint.volume / 1000).toStringAsFixed(1)}k kg\n',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '${dataPoint.sets} ${LocaleHelper.t(context, 'sets')}',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildHeader() {
    final trend = widget.trendData.trend;
    final trendColor = trend == 'increasing'
        ? Colors.green
        : trend == 'decreasing'
            ? Colors.red
            : Colors.blue;
    final trendIcon = trend == 'increasing'
        ? Icons.trending_up
        : trend == 'decreasing'
            ? Icons.trending_down
            : Icons.trending_flat;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleHelper.t(context, 'volume_trend'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.trendData.timeframe == 'weekly'
                  ? LocaleHelper.t(context, 'weekly_view')
                  : LocaleHelper.t(context, 'monthly_view'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: trendColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: trendColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(trendIcon, color: trendColor, size: 16),
              const SizedBox(width: 4),
              Text(
                trend.toUpperCase(),
                style: TextStyle(
                  color: trendColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          LocaleHelper.t(context, 'volume'),
          widget.lineColor ?? DesignTokens.primaryColor,
          isSolid: true,
        ),
        if (widget.showAverageLine) ...[
          const SizedBox(width: 24),
          _buildLegendItem(
            LocaleHelper.t(context, 'average'),
            Colors.orange,
            isDashed: true,
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isSolid = false, bool isDashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: isSolid ? color : null,
            border: isDashed ? Border.all(color: color, width: 2) : null,
          ),
          child: isDashed
              ? CustomPaint(
                  painter: DashedLinePainter(color: color),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
