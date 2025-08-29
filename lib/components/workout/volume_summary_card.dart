import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../services/workout/workout_metrics_service.dart';
import '../../theme/design_tokens.dart';

class VolumeSummaryCard extends StatefulWidget {
  final Map<String, dynamic> plan;
  final int weekIndex;
  final bool collapsedInitially;

  const VolumeSummaryCard({
    super.key,
    required this.plan,
    required this.weekIndex,
    this.collapsedInitially = false,
  });

  @override
  State<VolumeSummaryCard> createState() => _VolumeSummaryCardState();
}

class _VolumeSummaryCardState extends State<VolumeSummaryCard> {
  bool _collapsed = false;
  String? _lastKey;
  Map<String, dynamic> _cached = const {};

  @override
  void initState() {
    super.initState();
    _collapsed = widget.collapsedInitially;
    _recomputeIfNeeded();
  }

  @override
  void didUpdateWidget(covariant VolumeSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recomputeIfNeeded();
  }

  void _recomputeIfNeeded() {
    final key = '${WorkoutMetricsService.stablePlanHash(widget.plan)}::${widget.weekIndex}';
    if (key != _lastKey) {
      _cached = WorkoutMetricsService.weekVolumeSummary(widget.plan, weekIndex: widget.weekIndex);
      _lastKey = key;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cached.isEmpty) return const SizedBox.shrink();

    // Sort by volume desc for display
    final entries = _cached.entries
        .map((e) => MapEntry(e.key, Map<String, num>.from(e.value as Map)))
        .sorted((a, b) => ((b.value['volume'] ?? 0)).compareTo((a.value['volume'] ?? 0)))
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '📈 Weekly Volume Summary', 
                  style: DesignTokens.titleMedium.copyWith(fontWeight: FontWeight.w600)
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(_collapsed ? Icons.expand_more : Icons.expand_less),
                  tooltip: _collapsed ? 'Expand' : 'Collapse',
                  onPressed: () => setState(() => _collapsed = !_collapsed),
                ),
              ],
            ),
            if (!_collapsed) ...[
              const SizedBox(height: DesignTokens.space8),
              _buildTable(entries),
              const SizedBox(height: DesignTokens.space8),
              _buildMiniChart(entries),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List<MapEntry<String, Map<String, num>>> entries) {
    final headerStyle = DesignTokens.labelMedium.copyWith(
      color: DesignTokens.ink700, 
      fontWeight: FontWeight.w600
    );
    final rowStyle = DesignTokens.bodySmall;
    return Column(
      children: [
        Row(children: [
          Expanded(child: Text('Muscle', style: headerStyle)),
          SizedBox(width: 72, child: Text('Sets', style: headerStyle, textAlign: TextAlign.right)),
          SizedBox(width: 72, child: Text('Reps', style: headerStyle, textAlign: TextAlign.right)),
          SizedBox(width: 100, child: Text('Volume', style: headerStyle, textAlign: TextAlign.right)),
        ]),
        const Divider(),
        ...entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Expanded(child: Text(e.key, style: rowStyle)),
                SizedBox(
                  width: 72, 
                  child: Text(
                    '${(e.value['sets'] ?? 0).toInt()}', 
                    style: DesignTokens.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.blue600,
                    ),
                    textAlign: TextAlign.right
                  )
                ),
                SizedBox(
                  width: 72, 
                  child: Text(
                    '${(e.value['reps'] ?? 0).toInt()}', 
                    style: DesignTokens.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.purple500,
                    ),
                    textAlign: TextAlign.right
                  )
                ),
                SizedBox(
                  width: 100, 
                  child: Text(
                    ((e.value['volume'] ?? 0).toDouble()).toStringAsFixed(1), 
                    style: DesignTokens.displaySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.ink900,
                    ),
                    textAlign: TextAlign.right
                  )
                ),
              ]),
            )),
      ],
    );
  }

  Widget _buildMiniChart(List<MapEntry<String, Map<String, num>>> entries) {
    // Show top 5 by volume
    final top = entries.take(5).toList();
    final maxVolume = top.map((e) => (e.value['volume'] ?? 0).toDouble()).fold<double>(0, (p, v) => v > p ? v : p);
    if (maxVolume <= 0) return const SizedBox.shrink();

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= top.length) return const SizedBox.shrink();
                  final label = top[idx].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label.length > 6 ? label.substring(0, 6) : label,
                      style: DesignTokens.labelSmall.copyWith(
                        color: DesignTokens.ink500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(top.length, (i) {
            final volume = (top[i].value['volume'] ?? 0).toDouble();
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: volume, 
                color: DesignTokens.blue600, 
                width: 16
              ),
            ]);
          }),
        ),
      ),
    );
  }
}


