import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../services/progress/progress_service.dart';
import '../../screens/progress/progress_entry_form.dart';
import '../../theme/design_tokens.dart';
import '../../components/common/section_header_bar.dart';
import '../../services/share/share_card_service.dart';
import '../../screens/share/share_picker.dart';


class MetricsCard extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> metrics;
  final VoidCallback onRefresh;

  const MetricsCard({
    super.key,
    required this.userId,
    required this.metrics,
    required this.onRefresh,
  });

  @override
  State<MetricsCard> createState() => _MetricsCardState();
}

class _MetricsCardState extends State<MetricsCard> {
  final ProgressService _progressService = ProgressService();

  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _waistController = TextEditingController();
  final _notesController = TextEditingController();

  
  // Chart overlay toggles
  bool _showSMA7 = false;
  bool _showSMA30 = false;

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _waistController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddEntryForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgressEntryForm(
          userId: widget.userId,
          onSaved: widget.onRefresh,
        ),
      ),
    );
  }



  // Calculate SMA (Simple Moving Average)
  List<FlSpot> _calculateSMA(List<FlSpot> data, int period) {
    if (data.length < period) return [];
    
    final List<FlSpot> sma = [];
    for (int i = period - 1; i < data.length; i++) {
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += data[j].y;
      }
      sma.add(FlSpot(data[i].x, sum / period));
    }
    return sma;
  }

  // Calculate daily deltas
  Map<String, double> _calculateDeltas(List<Map<String, dynamic>> metrics) {
    if (metrics.length < 2) return {};
    
    final sortedMetrics = List<Map<String, dynamic>>.from(metrics)
      ..sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
    
    final latest = sortedMetrics.last;
    final previous = sortedMetrics[sortedMetrics.length - 2];
    
    final Map<String, double> deltas = {};
    
    if (latest['weight_kg'] != null && previous['weight_kg'] != null) {
      deltas['weight'] = ((latest['weight_kg'] as num) - (previous['weight_kg'] as num)).toDouble();
    }
    if (latest['body_fat_percent'] != null && previous['body_fat_percent'] != null) {
      deltas['body_fat'] = ((latest['body_fat_percent'] as num) - (previous['body_fat_percent'] as num)).toDouble();
    }
    if (latest['waist_cm'] != null && previous['waist_cm'] != null) {
      deltas['waist'] = ((latest['waist_cm'] as num) - (previous['waist_cm'] as num)).toDouble();
    }
    
    return deltas;
  }

  // Check for fast loss/gain flags
  Widget? _buildWeightFlag(List<Map<String, dynamic>> metrics) {
    if (metrics.length < 7) return null;
    
    final sortedMetrics = List<Map<String, dynamic>>.from(metrics)
      ..sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
    
    final latest = sortedMetrics.last;
    final weekAgo = sortedMetrics[sortedMetrics.length - 7];
    
    if (latest['weight_kg'] != null && weekAgo['weight_kg'] != null) {
      final currentWeight = latest['weight_kg'] as num;
      final weekAgoWeight = weekAgo['weight_kg'] as num;
      final percentChange = ((currentWeight - weekAgoWeight) / weekAgoWeight) * 100;
      
      if (percentChange < -1.5) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space8, vertical: DesignTokens.space4),
          decoration: BoxDecoration(
            color: DesignTokens.warnBg,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
          child: Text(
            'fast loss',
            style: DesignTokens.labelSmall.copyWith(
              color: DesignTokens.warn,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      } else if (percentChange > 1.5) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space8, vertical: DesignTokens.space4),
          decoration: BoxDecoration(
            color: DesignTokens.infoBg,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
          child: Text(
            'refeed?',
            style: DesignTokens.labelSmall.copyWith(
              color: DesignTokens.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
    }
    return null;
  }

  Widget _buildWeightChart() {
    if (widget.metrics.length < 2) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'Add at least 2 weight entries to see the chart',
          style: DesignTokens.bodyMedium.copyWith(
            color: DesignTokens.ink500,
          ),
        ),
      );
    }

    final weightData = <FlSpot>[
      ...widget.metrics
          .where((m) => m['weight_kg'] != null)
          .map((m) => FlSpot(
                DateTime.parse(m['date']).millisecondsSinceEpoch.toDouble(),
                (m['weight_kg'] as num).toDouble(),
              ))
    ]..sort((a, b) => a.x.compareTo(b.x));

    if (weightData.length < 2) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'Add at least 2 weight entries to see the chart',
          style: DesignTokens.bodyMedium.copyWith(
            color: DesignTokens.ink500,
          ),
        ),
      );
    }

    // Calculate SMAs
    final sma7Data = _showSMA7 ? _calculateSMA(weightData, 7) : <FlSpot>[];
    final sma30Data = _showSMA30 ? _calculateSMA(weightData, 30) : <FlSpot>[];

    if (weightData.length < 2) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'Add at least 2 weight entries to see the chart',
          style: DesignTokens.bodyMedium.copyWith(
            color: DesignTokens.ink500,
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: DesignTokens.labelSmall.copyWith(
                      color: DesignTokens.ink500,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Text(
                    DateFormat('MM/dd').format(date),
                    style: DesignTokens.labelSmall.copyWith(
                      color: DesignTokens.ink500,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: weightData,
              isCurved: true,
              color: DesignTokens.blue600,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
            if (_showSMA7 && sma7Data.isNotEmpty)
              LineChartBarData(
                spots: sma7Data,
                isCurved: true,
                color: DesignTokens.warn,
                barWidth: 2,
                dotData: const FlDotData(show: false),
              ),
            if (_showSMA30 && sma30Data.isNotEmpty)
              LineChartBarData(
                spots: sma30Data,
                isCurved: true,
                color: DesignTokens.success,
                barWidth: 2,
                dotData: const FlDotData(show: false),
              ),
          ],
          lineTouchData: LineTouchData(
            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
              if (event is! FlTapUpEvent || touchResponse == null) return;
              
              final spot = touchResponse.lineBarSpots?.firstOrNull;
              if (spot != null) {
                final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                final weight = spot.y;
                
                // Find corresponding SMA values
                final sma7Value = sma7Data.firstWhereOrNull((s) => s.x == spot.x)?.y;
                final sma30Value = sma30Data.firstWhereOrNull((s) => s.x == spot.x)?.y;
                
                // Find delta
                final deltas = _calculateDeltas(widget.metrics);
                final weightDelta = deltas['weight'];
                
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      DateFormat('MMM dd, yyyy').format(date),
                      style: DesignTokens.titleMedium,
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Value (bigger, heavier)
                        Text(
                          'Weight: ${weight.toStringAsFixed(1)} kg',
                          style: DesignTokens.displaySmall.copyWith(
                            color: DesignTokens.blue600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (weightDelta != null) ...[
                          const SizedBox(height: DesignTokens.space8),
                          Text(
                            'Δ: ${weightDelta >= 0 ? '+' : ''}${weightDelta.toStringAsFixed(1)} kg',
                            style: DesignTokens.bodyMedium.copyWith(
                              color: weightDelta >= 0 ? DesignTokens.success : DesignTokens.danger,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (sma7Value != null) ...[
                          const SizedBox(height: DesignTokens.space8),
                          Text(
                            'SMA7: ${sma7Value.toStringAsFixed(1)} kg',
                            style: DesignTokens.bodyMedium.copyWith(
                              color: DesignTokens.warn,
                            ),
                          ),
                        ],
                        if (sma30Value != null) ...[
                          const SizedBox(height: DesignTokens.space8),
                          Text(
                            'SMA30: ${sma30Value.toStringAsFixed(1)} kg',
                            style: DesignTokens.bodyMedium.copyWith(
                              color: DesignTokens.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsList() {
    if (widget.metrics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space32),
          child: Text(
            'No metrics recorded yet.\nTap "Add Metric" to get started!',
            textAlign: TextAlign.center,
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.ink500,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.metrics.length,
      itemBuilder: (context, index) {
        final metric = widget.metrics[index];
        final date = DateTime.parse(metric['date']);
        final hasNutritionData = metric['sodium_mg'] != null || metric['potassium_mg'] != null;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: DesignTokens.space4),
          child: ListTile(
            title: Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: DesignTokens.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (metric['weight_kg'] != null) ...[
                  Row(
                    children: [
                      // Label (smaller, softer)
                      Text(
                        'Weight: ',
                        style: DesignTokens.labelMedium.copyWith(
                          color: DesignTokens.ink500.withValues(alpha: 0.7),
                        ),
                      ),
                      // Value (bigger, heavier)
                      Text(
                        '${metric['weight_kg']} kg',
                        style: DesignTokens.titleSmall.copyWith(
                          color: DesignTokens.blue600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (metric['body_fat_percent'] != null) ...[
                  const SizedBox(height: DesignTokens.space4),
                  Row(
                    children: [
                      Text(
                        'Body Fat: ',
                        style: DesignTokens.labelMedium.copyWith(
                          color: DesignTokens.ink500.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '${metric['body_fat_percent']}%',
                        style: DesignTokens.titleSmall.copyWith(
                          color: DesignTokens.purple500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (metric['waist_cm'] != null) ...[
                  const SizedBox(height: DesignTokens.space4),
                  Row(
                    children: [
                      Text(
                        'Waist: ',
                        style: DesignTokens.labelMedium.copyWith(
                          color: DesignTokens.ink500.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '${metric['waist_cm']} cm',
                        style: DesignTokens.titleSmall.copyWith(
                          color: DesignTokens.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (metric['notes'] != null && metric['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.space4),
                  Text(
                    'Notes: ${metric['notes']}',
                    style: DesignTokens.bodySmall.copyWith(
                      color: DesignTokens.ink500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (hasNutritionData) ...[
                  const SizedBox(height: DesignTokens.space4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space8,
                      vertical: DesignTokens.space4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.successBg,
                      borderRadius: BorderRadius.circular(DesignTokens.radius4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          size: 12,
                          color: DesignTokens.success,
                        ),
                        const SizedBox(width: DesignTokens.space4),
                        Text(
                          'Minerals: ${metric['sodium_mg'] ?? 0}mg Na, ${metric['potassium_mg'] ?? 0}mg K',
                          style: DesignTokens.labelSmall.copyWith(
                            color: DesignTokens.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete,
                color: DesignTokens.danger,
              ),
              onPressed: () => _deleteMetric(metric['id']),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteMetric(String metricId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Metric',
          style: DesignTokens.titleMedium,
        ),
        content: const Text(
          'Are you sure you want to delete this metric entry?',
          style: DesignTokens.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _progressService.deleteMetric(metricId);
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Metric deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to delete metric: $e')),
        );
      }
    }
  }

  void _showShareOptions() {
    final deltas = _calculateDeltas(widget.metrics);
    final latest = widget.metrics.isNotEmpty ? widget.metrics.last : null;
    
    if (latest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No progress data to share'),
          backgroundColor: DesignTokens.warn,
        ),
      );
      return;
    }

    final shareData = ShareDataModel(
      title: 'Progress Update',
      subtitle: 'Tracking my fitness journey',
      metrics: {
        if (latest['weight_kg'] != null) 'Weight': '${latest['weight_kg']} kg',
        if (latest['body_fat_percent'] != null) 'Body Fat': '${latest['body_fat_percent']}%',
        if (latest['waist_cm'] != null) 'Waist': '${latest['waist_cm']} cm',
        if (deltas['weight'] != null) 'Weight Change': '${deltas['weight']!.toStringAsFixed(1)} kg',
        if (deltas['body_fat'] != null) 'Body Fat Change': '${deltas['body_fat']!.toStringAsFixed(1)}%',
      },
      date: DateTime.parse(latest['date']),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharePicker(data: shareData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _showShareOptions,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            SectionHeaderBar(
              title: 'Progress Metrics',
              leadingIcon: const Icon(
                Icons.trending_up,
                color: DesignTokens.blue600,
              ),
              actionLabel: 'Add Entry',
              onAction: () => _showAddEntryForm(),
              actionIcon: Icons.add,
            ),
            const SizedBox(height: DesignTokens.space16),
            
            // Chart overlay toggles
            if (widget.metrics.length >= 2) ...[
              Row(
                children: [
                  FilterChip(
                    label: const Text('SMA7'),
                    selected: _showSMA7,
                    onSelected: (selected) {
                      setState(() => _showSMA7 = selected);
                    },
                    selectedColor: DesignTokens.warnBg,
                    checkmarkColor: DesignTokens.warn,
                  ),
                  const SizedBox(width: DesignTokens.space8),
                  FilterChip(
                    label: const Text('SMA30'),
                    selected: _showSMA30,
                    onSelected: (selected) {
                      setState(() => _showSMA30 = selected);
                    },
                    selectedColor: DesignTokens.successBg,
                    checkmarkColor: DesignTokens.success,
                  ),
                  const Spacer(),
                  if (_buildWeightFlag(widget.metrics) != null)
                    _buildWeightFlag(widget.metrics)!,
                ],
              ),
              const SizedBox(height: DesignTokens.space16),
            ],
            
            _buildWeightChart(),
            const SizedBox(height: DesignTokens.space16),
            Text(
              'Recent Entries',
              style: DesignTokens.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            _buildMetricsList(),
            ],
          ),
        ),
      ),
    );
  }
}
