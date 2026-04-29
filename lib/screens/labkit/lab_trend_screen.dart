import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/labkit/biomarker_result.dart';
import '../../services/labkit/lab_work_service.dart';
import '../../theme/design_tokens.dart';

/// Trend chart for a single biomarker across all of the user's lab uploads.
///
/// Shows the value over time with a horizontal band for the reference range
/// and color-coded markers (blue = low, green = normal, orange = high).
///
/// No diagnosis language — axis labels and tooltips show only numeric values.
class LabTrendScreen extends StatefulWidget {
  const LabTrendScreen({
    super.key,
    required this.biomarkerName,
  });

  final String biomarkerName;

  @override
  State<LabTrendScreen> createState() => _LabTrendScreenState();
}

class _LabTrendScreenState extends State<LabTrendScreen> {
  final _service = LabWorkService();
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  List<_TrendPoint> _points = [];
  String? _unit;
  String? _referenceRange;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final labs = await _service.listMyLabs();
      final points = <_TrendPoint>[];

      for (final labMeta in labs) {
        try {
          final detail = await _service.getLabDetail(labMeta.id);
          for (final b in detail.biomarkers) {
            if (b.name.toLowerCase() == widget.biomarkerName.toLowerCase() &&
                b.value != null) {
              points.add(_TrendPoint(
                date: detail.labDate,
                value: b.value!,
                flag: b.flag,
                unit: b.unit,
                referenceRange: b.referenceRange,
              ));
              _unit ??= b.unit;
              _referenceRange ??= b.referenceRange;
            }
          }
        } catch (_) {
          // skip labs that fail to load
        }
      }

      points.sort((a, b) => a.date.compareTo(b.date));

      if (mounted) {
        setState(() {
          _points = points;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load trend data. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.primaryDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.primaryDark,
        title: Text(
          widget.biomarkerName,
          style: const TextStyle(color: DesignTokens.textPrimary),
        ),
        iconTheme:
            const IconThemeData(color: DesignTokens.textPrimary),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(
              color: DesignTokens.accentGreen));
    }
    if (_error != null) {
      return Center(
          child: Text(_error!,
              style: const TextStyle(
                  color: DesignTokens.textSecondary)));
    }
    if (_points.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.show_chart,
                color: DesignTokens.textTertiary, size: 56),
            const SizedBox(height: 12),
            Text(
              'No data for ${widget.biomarkerName} yet.',
              style: const TextStyle(color: DesignTokens.textSecondary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload more lab results to see your trend.',
              style: TextStyle(
                  color: DesignTokens.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLatestCard(),
          const SizedBox(height: 24),
          _buildChart(),
          if (_referenceRange != null) ...[
            const SizedBox(height: 12),
            _buildRangeNote(),
          ],
          const SizedBox(height: 24),
          _buildDataTable(),
        ],
      ),
    );
  }

  Widget _buildLatestCard() {
    final latest = _points.last;
    final flagColor = _flagColor(latest.flag);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Latest',
                  style: TextStyle(
                      color: DesignTokens.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    latest.value.toStringAsFixed(2),
                    style: TextStyle(
                      color: flagColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _unit ?? '',
                    style: const TextStyle(
                        color: DesignTokens.textSecondary),
                  ),
                ],
              ),
              Text(
                DateFormat('MMM d, yyyy').format(latest.date),
                style: const TextStyle(
                    color: DesignTokens.textTertiary, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          _buildTrendArrow(),
        ],
      ),
    );
  }

  Widget _buildTrendArrow() {
    if (_points.length < 2) return const SizedBox.shrink();
    final delta = _points.last.value - _points[_points.length - 2].value;
    final icon = delta > 0
        ? Icons.trending_up
        : delta < 0
            ? Icons.trending_down
            : Icons.trending_flat;
    final color = delta.abs() < 0.001
        ? DesignTokens.textSecondary
        : delta > 0
            ? DesignTokens.accentOrange
            : DesignTokens.accentBlue;
    return Icon(icon, color: color, size: 32);
  }

  Widget _buildChart() {
    final values = _points.map((p) => p.value).toList();
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);

    double chartMin = minVal;
    double chartMax = maxVal;

    // Expand range if reference range is available
    final bounds = _parseBounds(_referenceRange);
    if (bounds != null) {
      chartMin = math.min(chartMin, bounds.$1);
      chartMax = math.max(chartMax, bounds.$2);
    }

    final padding = (chartMax - chartMin) * 0.2;
    chartMin = math.max(0, chartMin - padding);
    chartMax = chartMax + padding;

    final spots = _points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: DesignTokens.textTertiary.withAlpha(40),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (v, meta) => Text(
                  v.toStringAsFixed(1),
                  style: const TextStyle(
                      color: DesignTokens.textTertiary, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: math.max(1, (_points.length / 4).floorToDouble()),
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= _points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('M/d').format(_points[idx].date),
                      style: const TextStyle(
                          color: DesignTokens.textTertiary, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          minY: chartMin,
          maxY: chartMax,
          extraLinesData: bounds != null
              ? ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: bounds.$1,
                    color: DesignTokens.accentGreen.withAlpha(60),
                    strokeWidth: 1,
                    dashArray: [6, 4],
                  ),
                  HorizontalLine(
                    y: bounds.$2,
                    color: DesignTokens.accentGreen.withAlpha(60),
                    strokeWidth: 1,
                    dashArray: [6, 4],
                  ),
                ])
              : null,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: _points.length > 3,
              color: DesignTokens.accentGreen,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, idx) {
                  final color = _flagColor(_points[idx].flag);
                  return FlDotCirclePainter(
                    radius: 5,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: DesignTokens.primaryDark,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: DesignTokens.accentGreen.withAlpha(20),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => DesignTokens.secondaryDark,
              getTooltipItems: (spots) => spots.map((s) {
                final pt = _points[s.spotIndex];
                return LineTooltipItem(
                  '${pt.value.toStringAsFixed(2)} ${_unit ?? ''}\n'
                  '${DateFormat('MMM d, yyyy').format(pt.date)}',
                  const TextStyle(
                      color: DesignTokens.textPrimary, fontSize: 12),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeNote() {
    return Row(
      children: [
        Container(
          width: 24,
          height: 2,
          color: DesignTokens.accentGreen.withAlpha(120),
        ),
        const SizedBox(width: 8),
        Text(
          'Typical range: $_referenceRange ${_unit ?? ''}',
          style: const TextStyle(
              color: DesignTokens.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All readings',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...(_points.reversed.map(
          (p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(p.date),
                  style: const TextStyle(
                      color: DesignTokens.textSecondary, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${p.value.toStringAsFixed(2)} ${p.unit}',
                  style: TextStyle(
                    color: _flagColor(p.flag),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Color _flagColor(BiomarkerFlag flag) => switch (flag) {
        BiomarkerFlag.low => DesignTokens.accentBlue,
        BiomarkerFlag.normal => DesignTokens.accentGreen,
        BiomarkerFlag.high => DesignTokens.accentOrange,
        BiomarkerFlag.unknown => DesignTokens.textSecondary,
      };

  (double, double)? _parseBounds(String? range) {
    if (range == null) return null;
    final m = RegExp(r'^([\d.]+)\s*[-–]\s*([\d.]+)$').firstMatch(range.trim());
    if (m == null) return null;
    final lo = double.tryParse(m.group(1)!);
    final hi = double.tryParse(m.group(2)!);
    if (lo == null || hi == null || hi <= lo) return null;
    return (lo, hi);
  }
}

class _TrendPoint {
  const _TrendPoint({
    required this.date,
    required this.value,
    required this.flag,
    required this.unit,
    this.referenceRange,
  });

  final DateTime date;
  final double value;
  final BiomarkerFlag flag;
  final String unit;
  final String? referenceRange;
}
