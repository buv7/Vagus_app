import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/workout/analytics_models.dart';
import '../../utils/locale_helper.dart';

/// Muscle group balance visualization
///
/// Shows distribution across muscle groups using:
/// - Pie chart for percentage breakdown
/// - Radar chart for balance analysis (optional)
/// - Color-coded segments with touch interaction
class MuscleGroupBalanceChart extends StatefulWidget {
  final DistributionReport distribution;
  final ChartType chartType;

  const MuscleGroupBalanceChart({
    Key? key,
    required this.distribution,
    this.chartType = ChartType.pie,
  }) : super(key: key);

  @override
  State<MuscleGroupBalanceChart> createState() => _MuscleGroupBalanceChartState();
}

enum ChartType { pie, radar }

class _MuscleGroupBalanceChartState extends State<MuscleGroupBalanceChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chart
        SizedBox(
          height: 250,
          child: widget.chartType == ChartType.pie
              ? _buildPieChart()
              : _buildRadarChart(),
        ),
        const SizedBox(height: 16),

        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildPieChart() {
    final entries = widget.distribution.percentageByMuscleGroup.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (event, pieTouchResponse) {
            setState(() {
              if (pieTouchResponse?.touchedSection != null) {
                _touchedIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
              } else {
                _touchedIndex = null;
              }
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        sections: List.generate(entries.length, (index) {
          final isTouched = index == _touchedIndex;
          final radius = isTouched ? 65.0 : 55.0;
          final fontSize = isTouched ? 16.0 : 12.0;

          final muscleGroup = entries[index].key;
          final percentage = entries[index].value;
          final color = _getMuscleGroupColor(muscleGroup);

          return PieChartSectionData(
            color: color,
            value: percentage,
            title: '${percentage.toStringAsFixed(0)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
            badgeWidget: isTouched
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      muscleGroup.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  )
                : null,
            badgePositionPercentageOffset: 1.3,
          );
        }),
      ),
    );
  }

  Widget _buildRadarChart() {
    final entries = widget.distribution.percentageByMuscleGroup.entries.toList();

    // Normalize to 0-100 scale for radar chart
    final maxPercentage = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        tickCount: 4,
        ticksTextStyle: Theme.of(context).textTheme.bodySmall!,
        tickBorderData: BorderSide(color: Colors.grey[300]!),
        gridBorderData: BorderSide(color: Colors.grey[300]!, width: 1),
        radarBorderData: BorderSide(color: Colors.grey[400]!, width: 2),
        titlePositionPercentageOffset: 0.2,
        getTitle: (index, angle) {
          if (index >= entries.length) return RadarChartTitle(text: '');
          return RadarChartTitle(
            text: entries[index].key.substring(0, 3).toUpperCase(),
            angle: angle,
          );
        },
        dataSets: [
          RadarDataSet(
            fillColor: Colors.blue.withOpacity(0.3),
            borderColor: Colors.blue,
            entryRadius: 3,
            dataEntries: entries.map((entry) {
              return RadarEntry(value: (entry.value / maxPercentage) * 100);
            }).toList(),
          ),
          // Ideal balanced distribution line
          RadarDataSet(
            fillColor: Colors.transparent,
            borderColor: Colors.green.withOpacity(0.5),
            entryRadius: 0,
            borderWidth: 2,
            dataEntries: List.generate(
              entries.length,
              (_) => RadarEntry(value: (100 / entries.length) / maxPercentage * 100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final entries = widget.distribution.percentageByMuscleGroup.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: entries.map((entry) {
        final muscleGroup = entry.key;
        final percentage = entry.value;
        final color = _getMuscleGroupColor(muscleGroup);
        final isOverdeveloped = widget.distribution.overdevelopedGroups.contains(muscleGroup);
        final isUnderdeveloped = widget.distribution.underdevelopedGroups.contains(muscleGroup);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOverdeveloped
                  ? Colors.red
                  : isUnderdeveloped
                      ? Colors.orange
                      : color,
              width: isOverdeveloped || isUnderdeveloped ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${muscleGroup.toUpperCase()} (${percentage.toStringAsFixed(1)}%)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (isOverdeveloped || isUnderdeveloped) ...[
                const SizedBox(width: 4),
                Icon(
                  isOverdeveloped ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: isOverdeveloped ? Colors.red : Colors.orange,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getMuscleGroupColor(String muscleGroup) {
    final colors = {
      'chest': Colors.blue,
      'back': Colors.green,
      'shoulders': Colors.orange,
      'arms': Colors.purple,
      'legs': Colors.red,
      'core': Colors.teal,
      'quads': Colors.indigo,
      'hamstrings': Colors.pink,
      'glutes': Colors.deepOrange,
      'calves': Colors.cyan,
      'biceps': Colors.deepPurple,
      'triceps': Colors.amber,
    };
    return colors[muscleGroup.toLowerCase()] ?? Colors.grey;
  }
}
