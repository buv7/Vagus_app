import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final supabase = Supabase.instance.client;
  bool _loading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final response = await supabase.from('profiles').select();
    setState(() {
      _users = response;
      _loading = false;
    });
  }

  int get total => _users.length;

  int countByRole(String role) =>
      _users.where((u) => u['role'] == role).length;

  int get disabled => _users.where((u) => u['is_disabled'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📊 Analytics")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                "Total Users: $total",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildBarChart(),
              const SizedBox(height: 32),
              _buildPieChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final roles = ['client', 'coach', 'admin'];
    final data = roles.map((r) => countByRole(r).toDouble()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("👥 Users by Role", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (data.reduce((a, b) => a > b ? a : b) + 2),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= roles.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(roles[value.toInt()]),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(roles.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data[index],
                      width: 24,
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    final active = total - disabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("🚦 Active vs Disabled", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: active.toDouble(),
                  title: "Active\n$active",
                  radius: 60,
                  titleStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: disabled.toDouble(),
                  title: "Disabled\n$disabled",
                  radius: 60,
                  titleStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
