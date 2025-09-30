import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/workout/workout_service.dart';

/// Progress chart widget for visualizing workout performance over time
class ProgressChartWidget extends StatefulWidget {
  final String clientId;
  final String? exerciseName;
  final ChartType chartType;

  const ProgressChartWidget({
    Key? key,
    required this.clientId,
    this.exerciseName,
    this.chartType = ChartType.volume,
  }) : super(key: key);

  @override
  State<ProgressChartWidget> createState() => _ProgressChartWidgetState();
}

class _ProgressChartWidgetState extends State<ProgressChartWidget> {
  final WorkoutService _workoutService = WorkoutService();
  List<ExerciseHistoryEntry> _historyEntries = [];
  bool _isLoading = true;
  ChartType _selectedChartType = ChartType.volume;

  @override
  void initState() {
    super.initState();
    _selectedChartType = widget.chartType;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      if (widget.exerciseName != null) {
        final history = await _workoutService.fetchExerciseHistory(
          widget.clientId,
          widget.exerciseName!,
        );
        setState(() {
          _historyEntries = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historyEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No history data available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Chart type selector
        _buildChartTypeSelector(theme),
        const SizedBox(height: 16),

        // Chart
        Expanded(
          child: _buildChart(theme),
        ),

        // Stats summary
        _buildStatsSummary(theme),
      ],
    );
  }

  Widget _buildChartTypeSelector(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ChartType.values.map((type) {
          final isSelected = _selectedChartType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_getChartTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedChartType = type);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    switch (_selectedChartType) {
      case ChartType.volume:
        return _buildVolumeChart(theme);
      case ChartType.weight:
        return _buildWeightChart(theme);
      case ChartType.oneRM:
        return _build1RMChart(theme);
      case ChartType.reps:
        return _buildRepsChart(theme);
    }
  }

  Widget _buildVolumeChart(ThemeData theme) {
    final spots = _historyEntries.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final history = entry.value;
      final volume = history.volume ?? 0;
      return FlSpot(index, volume);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.surfaceVariant,
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: theme.colorScheme.surfaceVariant,
                strokeWidth: 1,
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
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= _historyEntries.length) {
                    return const SizedBox();
                  }
                  final entry = _historyEntries[value.toInt()];
                  final date = entry.completedAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: null,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: theme.textTheme.bodySmall,
                  );
                },
                reservedSize: 42,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: theme.colorScheme.outline,
              width: 1,
            ),
          ),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: _getMaxValue(spots.map((s) => s.y).toList()) * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: theme.colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart(ThemeData theme) {
    final spots = _historyEntries.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final history = entry.value;
      final weight = history.weightUsed;
      return FlSpot(index, weight);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
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
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= _historyEntries.length) {
                    return const SizedBox();
                  }
                  final entry = _historyEntries[value.toInt()];
                  final date = entry.completedAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}kg',
                    style: theme.textTheme.bodySmall,
                  );
                },
                reservedSize: 50,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.colorScheme.outline),
          ),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: _getMaxValue(spots.map((s) => s.y).toList()) * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build1RMChart(ThemeData theme) {
    final spots = _historyEntries.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final history = entry.value;
      final oneRM = history.estimated1RM ?? 0;
      return FlSpot(index, oneRM);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
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
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= _historyEntries.length) {
                    return const SizedBox();
                  }
                  final entry = _historyEntries[value.toInt()];
                  final date = entry.completedAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}kg',
                    style: theme.textTheme.bodySmall,
                  );
                },
                reservedSize: 50,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.colorScheme.outline),
          ),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: _getMaxValue(spots.map((s) => s.y).toList()) * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orange.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepsChart(ThemeData theme) {
    final spots = _historyEntries.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final history = entry.value;
      final reps = double.tryParse(history.completedReps) ?? 0;
      return FlSpot(index, reps);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxValue(spots.map((s) => s.y).toList()) * 1.2,
          barTouchData: BarTouchData(enabled: true),
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
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= _historyEntries.length) {
                    return const SizedBox();
                  }
                  final entry = _historyEntries[value.toInt()];
                  final date = entry.completedAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: theme.textTheme.bodySmall,
                  );
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.colorScheme.outline),
          ),
          barGroups: spots.map((spot) {
            return BarChartGroupData(
              x: spot.x.toInt(),
              barRods: [
                BarChartRodData(
                  toY: spot.y,
                  color: theme.colorScheme.secondary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(ThemeData theme) {
    final analysis = _workoutService.analyzeProgressTrend(_historyEntries);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Trend',
                _getTrendDisplay(analysis.trend),
                _getTrendIcon(analysis.trend),
                _getTrendColor(analysis.trend),
                theme,
              ),
              _buildStatItem(
                'Sessions',
                '${_historyEntries.length}',
                Icons.fitness_center,
                theme.colorScheme.primary,
                theme,
              ),
              _buildStatItem(
                'Best',
                _getBestPerformance(),
                Icons.emoji_events,
                Colors.amber,
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _getChartTypeLabel(ChartType type) {
    switch (type) {
      case ChartType.volume:
        return 'Volume';
      case ChartType.weight:
        return 'Weight';
      case ChartType.oneRM:
        return '1RM';
      case ChartType.reps:
        return 'Reps';
    }
  }

  double _getMaxValue(List<double> values) {
    if (values.isEmpty) return 100;
    return values.reduce((a, b) => a > b ? a : b);
  }

  String _getTrendDisplay(dynamic trend) {
    final trendStr = trend.toString().split('.').last;
    switch (trendStr) {
      case 'improving':
        return 'Improving';
      case 'maintaining':
        return 'Stable';
      case 'declining':
        return 'Declining';
      default:
        return 'Unknown';
    }
  }

  IconData _getTrendIcon(dynamic trend) {
    final trendStr = trend.toString().split('.').last;
    switch (trendStr) {
      case 'improving':
        return Icons.trending_up;
      case 'maintaining':
        return Icons.trending_flat;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.help_outline;
    }
  }

  Color _getTrendColor(dynamic trend) {
    final trendStr = trend.toString().split('.').last;
    switch (trendStr) {
      case 'improving':
        return Colors.green;
      case 'maintaining':
        return Colors.blue;
      case 'declining':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getBestPerformance() {
    if (_historyEntries.isEmpty) return '-';

    switch (_selectedChartType) {
      case ChartType.volume:
        final max = _historyEntries
            .map((e) => e.volume ?? 0)
            .reduce((a, b) => a > b ? a : b);
        return '${max.toInt()}kg';
      case ChartType.weight:
        final max = _historyEntries
            .map((e) => e.weightUsed)
            .reduce((a, b) => a > b ? a : b);
        return '${max.toInt()}kg';
      case ChartType.oneRM:
        final max = _historyEntries
            .map((e) => e.estimated1RM ?? 0)
            .reduce((a, b) => a > b ? a : b);
        return '${max.toInt()}kg';
      case ChartType.reps:
        final max = _historyEntries
            .map((e) => int.tryParse(e.completedReps) ?? 0)
            .reduce((a, b) => a > b ? a : b);
        return max.toString();
    }
  }
}

/// Chart type enum
enum ChartType {
  volume,
  weight,
  oneRM,
  reps,
}