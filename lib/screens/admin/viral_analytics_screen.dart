import 'package:flutter/material.dart';
import '../../services/config/feature_flags.dart';
import '../../services/growth/viral_analytics_service.dart';

class ViralAnalyticsScreen extends StatefulWidget {
  const ViralAnalyticsScreen({super.key});

  @override
  State<ViralAnalyticsScreen> createState() => _ViralAnalyticsScreenState();
}

class _ViralAnalyticsScreenState extends State<ViralAnalyticsScreen> {
  List<Map<String, dynamic>> _trends = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    setState(() => _loading = true);
    try {
      final trends = await ViralAnalyticsService.I.getTrends(days: 14);
      setState(() {
        _trends = trends;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Viral Analytics')),
      body: FutureBuilder<bool>(
        future: FeatureFlags.instance.isEnabled(FeatureFlags.viralAnalytics),
        builder: (context, flagSnapshot) {
          if (!(flagSnapshot.data ?? false)) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Feature disabled'),
              ),
            );
          }

          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_trends.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No analytics data available'),
              ),
            );
          }

          // Group by date
          final grouped = <String, List<Map<String, dynamic>>>{};
          for (final trend in _trends) {
            final date = trend['date'] as String;
            grouped.putIfAbsent(date, () => []).add(trend);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '14-Day Trends',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...grouped.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...entry.value.map((metric) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(metric['metric_name'] as String),
                                Text(
                                  (metric['metric_value'] as num).toStringAsFixed(4),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
