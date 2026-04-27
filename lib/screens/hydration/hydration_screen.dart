import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/hydration/hydration_engine.dart';
import '../../services/hydration/hydration_nudge_scheduler.dart';
import '../../services/nutrition/hydration_service.dart';
import '../../models/nutrition/hydration_log.dart';
import '../../theme/design_tokens.dart';

/// Smart hydration screen.
///
/// Client view: daily progress, quick-log FAB, weekly/monthly trend chart.
/// Coach view (pass [clientId]): client's hydration consistency dashboard.
class HydrationScreen extends StatefulWidget {
  final String? clientId;

  const HydrationScreen({super.key, this.clientId});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _service = HydrationService();
  final _engine = HydrationEngine.instance;
  final _scheduler = HydrationNudgeScheduler.instance;

  late final TabController _tabController;

  bool _loading = true;
  String? _error;

  // Today's state
  HydrationLog? _todayLog;
  HydrationTarget? _target;
  int _targetMl = 2450; // engine default, overwritten on load

  // Trend state
  List<HydrationLog> _trendLogs = [];
  bool _showMonthly = false;

  // Coach consistency
  double _consistencyPercent = 0;
  int _daysOnTarget = 0;
  int _totalDays = 0;

  bool get _isCoachView => widget.clientId != null;
  String get _userId =>
      widget.clientId ?? _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _isCoachView ? 1 : 2,
      vsync: this,
    );
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      // Fetch profile for weight/prefs
      final profile = await _supabase
          .from('profiles')
          .select('weight_kg, wake_time, bedtime')
          .eq('id', _userId)
          .maybeSingle();

      final weightKg =
          (profile?['weight_kg'] as num?)?.toDouble() ?? 70.0;

      // Calculate target using engine
      _target = _engine.calculateTarget(bodyweightKg: weightKg);
      _targetMl = _target!.totalMl;

      // Load today's intake
      _todayLog = await _service.getDaily(_userId, DateTime.now());

      // Load trend
      await _loadTrend();

      // Schedule nudges (self only)
      if (!_isCoachView) {
        _scheduleNudges(profile, user.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTrend() async {
    final days = _showMonthly ? 30 : 7;
    _trendLogs = await _service.getWeeklySummary(_userId, days: days);

    if (_trendLogs.isNotEmpty) {
      _daysOnTarget =
          _trendLogs.where((l) => l.ml >= (_targetMl * 0.8)).length;
      _totalDays = _trendLogs.length;
      _consistencyPercent =
          (_daysOnTarget / _totalDays * 100).clamp(0.0, 100.0);
    }
  }

  void _scheduleNudges(Map<String, dynamic>? profile, String userId) {
    final now = DateTime.now();

    // Parse wake/bedtime from profile strings (HH:mm), default 07:00 / 23:00
    DateTime parseTime(String? raw, int defaultHour) {
      if (raw == null) return DateTime(now.year, now.month, now.day, defaultHour);
      final parts = raw.split(':');
      if (parts.length < 2) {
        return DateTime(now.year, now.month, now.day, defaultHour);
      }
      final h = int.tryParse(parts[0]) ?? defaultHour;
      final m = int.tryParse(parts[1]) ?? 0;
      return DateTime(now.year, now.month, now.day, h, m);
    }

    final wakeTime = parseTime(profile?['wake_time'] as String?, 7);
    final bedtime = parseTime(profile?['bedtime'] as String?, 23);

    final nudges = _engine.distributeNudges(
      targetMl: _targetMl,
      wakeTime: wakeTime,
      bedtime: bedtime,
    );

    _scheduler.reschedule(userId: userId, nudges: nudges);
  }

  Future<void> _logWater(int ml) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final updated =
          await _service.incrementWater(user.id, DateTime.now(), ml);
      await _scheduler.recordLog(user.id);

      if (mounted) {
        setState(() => _todayLog = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+${ml}ml logged'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showCustomAmountDialog() async {
    int? value;
    await showDialog<int>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Custom amount'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Amount in ml',
              suffixText: 'ml',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                value = int.tryParse(controller.text.trim());
                Navigator.pop(ctx, value);
              },
              child: const Text('Log'),
            ),
          ],
        );
      },
    );
    if (value != null && value! > 0 && value! <= 2000) {
      await _logWater(value!);
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hydration')),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCoachView ? 'Client Hydration' : 'Hydration'),
        bottom: _isCoachView
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Today'),
                  Tab(text: 'Trend'),
                ],
              ),
      ),
      floatingActionButton:
          _isCoachView ? null : _buildQuickLogFab(),
      body: _isCoachView
          ? _buildCoachDashboard()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildTrendTab(),
              ],
            ),
    );
  }

  // ---- Quick-log FAB ----

  Widget _buildQuickLogFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final amount in [200, 250, 500])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton.extended(
              heroTag: 'hydra_$amount',
              onPressed: () => _logWater(amount),
              label: Text('${amount}ml'),
              icon: const Icon(Icons.water_drop_outlined),
              backgroundColor: DesignTokens.accentBlue,
              foregroundColor: Colors.white,
            ),
          ),
        FloatingActionButton.extended(
          heroTag: 'hydra_custom',
          onPressed: _showCustomAmountDialog,
          label: const Text('Custom'),
          icon: const Icon(Icons.add),
          backgroundColor: DesignTokens.primaryBlue,
          foregroundColor: Colors.white,
        ),
      ],
    );
  }

  // ---- Today tab ----

  Widget _buildTodayTab() {
    final logged = _todayLog?.ml ?? 0;
    final progress = _engine.progressFraction(_targetMl, logged);
    final remaining = _engine.remainingMl(_targetMl, logged);

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressRing(progress, logged),
            const SizedBox(height: 24),
            _buildInfoRow(
              'Target',
              _target?.formattedLiters ?? '${(_targetMl / 1000.0).toStringAsFixed(1)} L',
              Icons.flag_outlined,
            ),
            _buildInfoRow(
              'Remaining',
              '${(remaining / 1000.0).toStringAsFixed(1)} L',
              Icons.water_outlined,
            ),
            if (_target != null && _target!.workoutBonusMl > 0)
              _buildInfoRow(
                'Workout bonus',
                '+${_target!.workoutBonusMl}ml',
                Icons.fitness_center_outlined,
              ),
            if (_target != null && _target!.climateBonusMl > 0)
              _buildInfoRow(
                'Climate bonus',
                '+${_target!.climateBonusMl}ml',
                Icons.thermostat_outlined,
              ),
            if (_target != null && _target!.railApplied)
              _buildRailWarning(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRing(double progress, int loggedMl) {
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, value, __) => CircularProgressIndicator(
                value: value,
                strokeWidth: 14,
                backgroundColor: Colors.grey.withAlpha(51),
                valueColor: AlwaysStoppedAnimation<Color>(
                  value >= 1.0 ? Colors.green : DesignTokens.accentBlue,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(loggedMl / 1000.0).toStringAsFixed(1)}L',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: DesignTokens.accentBlue),
          const SizedBox(width: 12),
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  )),
          const Spacer(),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRailWarning() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined,
              color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Target capped by safety rail. Contact your coach to adjust.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.amber.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Trend tab ----

  Widget _buildTrendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showMonthly ? 'Last 30 days' : 'Last 7 days',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('7d')),
                  ButtonSegment(value: true, label: Text('30d')),
                ],
                selected: {_showMonthly},
                onSelectionChanged: (s) {
                  setState(() => _showMonthly = s.first);
                  _loadTrend().then((_) => setState(() {}));
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildBarChart(),
          const SizedBox(height: 24),
          _buildConsistencyCard(),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    if (_trendLogs.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data yet')),
      );
    }

    final maxY =
        math.max(_targetMl.toDouble(), _trendLogs.map((l) => l.ml.toDouble()).reduce(math.max)) * 1.1;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, _) => Text(
                  '${(value / 1000.0).toStringAsFixed(1)}L',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _trendLogs.length) {
                    return const SizedBox.shrink();
                  }
                  final d = _trendLogs[idx].date;
                  return Text(
                    '${d.month}/${d.day}',
                    style: const TextStyle(fontSize: 9),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: _targetMl.toDouble() * 0.8,
                color: Colors.green.withAlpha(153),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ],
          ),
          barGroups: _trendLogs.asMap().entries.map((e) {
            final onTarget = e.value.ml >= (_targetMl * 0.8);
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.ml.toDouble(),
                  color: onTarget ? Colors.green : DesignTokens.accentBlue,
                  width: _showMonthly ? 6 : 16,
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

  Widget _buildConsistencyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consistency',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_daysOnTarget / $_totalDays days ≥ 80% target',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${_consistencyPercent.round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _consistencyPercent >= 80
                            ? Colors.green
                            : DesignTokens.accentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _consistencyPercent / 100,
              backgroundColor: Colors.grey.withAlpha(51),
              valueColor: AlwaysStoppedAnimation<Color>(
                _consistencyPercent >= 80 ? Colors.green : DesignTokens.accentBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Coach dashboard ----

  Widget _buildCoachDashboard() {
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hydration Consistency',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Last 30 days',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildConsistencyCard(),
            const SizedBox(height: 24),
            _buildBarChart(),
          ],
        ),
      ),
    );
  }
}
