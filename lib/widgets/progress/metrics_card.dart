import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/progress/progress_service.dart';

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

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _waistController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddMetricDialog() {
    _weightController.clear();
    _bodyFatController.clear();
    _waistController.clear();
    _notesController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Progress Metric'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bodyFatController,
                  decoration: const InputDecoration(
                    labelText: 'Body Fat (%)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _waistController,
                  decoration: const InputDecoration(
                    labelText: 'Waist (cm)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isAddingMetric ? null : _addMetric,
            child: _isAddingMetric
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add'),
          ),
        ],
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

    final weightData = widget.metrics
        .where((m) => m['weight_kg'] != null)
        .map((m) => FlSpot(
              DateTime.parse(m['date']).millisecondsSinceEpoch.toDouble(),
              (m['weight_kg'] as num).toDouble(),
            ))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

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
          ],
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
                  onPressed: _showAddMetricDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Metric'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
