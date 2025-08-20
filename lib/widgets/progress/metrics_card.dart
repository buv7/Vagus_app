import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../services/progress/progress_service.dart';
import '../../screens/progress/ProgressEntryForm.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _waistController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isAddingMetric = false;
  
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

  Future<void> _addMetric() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAddingMetric = true);

    try {
      await _progressService.addMetric(
        userId: widget.userId,
        date: DateTime.now(),
        weightKg: double.tryParse(_weightController.text),
        bodyFatPercent: double.tryParse(_bodyFatController.text),
        waistCm: double.tryParse(_waistController.text),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Metric added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to add metric: $e')),
        );
      }
    } finally {
      setState(() => _isAddingMetric = false);
    }
  }

  // Calculate SMA (Simple Moving Average)
  List<FlSpot> _calculateSMA(List<FlSpot> data, int period) {
    if (data.length < period) return [];
    
    List<FlSpot> sma = [];
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
    
    Map<String, double> deltas = {};
    
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'fast loss',
            style: TextStyle(
              color: Colors.orange[800],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (percentChange > 1.5) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'refeed?',
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 10,
              fontWeight: FontWeight.bold,
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
        child: const Text(
          'Add at least 2 weight entries to see the chart',
          style: TextStyle(color: Colors.grey),
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
        child: const Text(
          'Add at least 2 weight entries to see the chart',
          style: TextStyle(color: Colors.grey),
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
        child: const Text(
          'Add at least 2 weight entries to see the chart',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10),
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
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: weightData,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
            if (_showSMA7 && sma7Data.isNotEmpty)
              LineChartBarData(
                spots: sma7Data,
                isCurved: true,
                color: Colors.orange,
                barWidth: 2,
                dotData: FlDotData(show: false),
              ),
            if (_showSMA30 && sma30Data.isNotEmpty)
              LineChartBarData(
                spots: sma30Data,
                isCurved: true,
                color: Colors.green,
                barWidth: 2,
                dotData: FlDotData(show: false),
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
                    title: Text(DateFormat('MMM dd, yyyy').format(date)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weight: ${weight.toStringAsFixed(1)} kg'),
                        if (weightDelta != null)
                          Text('Δ: ${weightDelta >= 0 ? '+' : ''}${weightDelta.toStringAsFixed(1)} kg'),
                        if (sma7Value != null)
                          Text('SMA7: ${sma7Value.toStringAsFixed(1)} kg'),
                        if (sma30Value != null)
                          Text('SMA30: ${sma30Value.toStringAsFixed(1)} kg'),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No metrics recorded yet.\nTap "Add Metric" to get started!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
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
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (metric['weight_kg'] != null)
                  Text('Weight: ${metric['weight_kg']} kg'),
                if (metric['body_fat_percent'] != null)
                  Text('Body Fat: ${metric['body_fat_percent']}%'),
                if (metric['waist_cm'] != null)
                  Text('Waist: ${metric['waist_cm']} cm'),
                if (metric['notes'] != null && metric['notes'].toString().isNotEmpty)
                  Text('Notes: ${metric['notes']}'),
                if (hasNutritionData) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restaurant_menu, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Minerals: ${metric['sodium_mg'] ?? 0}mg Na, ${metric['potassium_mg'] ?? 0}mg K',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
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
        title: const Text('Delete Metric'),
        content: const Text('Are you sure you want to delete this metric entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Progress Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddEntryForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
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
                    selectedColor: Colors.orange[100],
                    checkmarkColor: Colors.orange[800],
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('SMA30'),
                    selected: _showSMA30,
                    onSelected: (selected) {
                      setState(() => _showSMA30 = selected);
                    },
                    selectedColor: Colors.green[100],
                    checkmarkColor: Colors.green[800],
                  ),
                  const Spacer(),
                  if (_buildWeightFlag(widget.metrics) != null)
                    _buildWeightFlag(widget.metrics)!,
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            _buildWeightChart(),
            const SizedBox(height: 16),
            const Text(
              'Recent Entries',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildMetricsList(),
          ],
        ),
      ),
    );
  }
}
