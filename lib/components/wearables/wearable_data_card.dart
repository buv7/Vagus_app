import 'package:flutter/material.dart';
import '../../services/wearables/wearable_service.dart';
import '../../theme/design_tokens.dart';

/// Coach dashboard widget: shows a client's recent wearable aggregates.
/// Data is read via wearable_read_daily RPC which emits an audit row.
class WearableDataCard extends StatefulWidget {
  final String clientId;
  final String? consentId;

  const WearableDataCard({
    super.key,
    required this.clientId,
    this.consentId,
  });

  @override
  State<WearableDataCard> createState() => _WearableDataCardState();
}

class _WearableDataCardState extends State<WearableDataCard> {
  final _service = WearableService.instance;
  List<WearableDailySummary> _summaries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _service.getClientSummaries(
      clientId: widget.clientId,
      days: 7,
      consentId: widget.consentId,
    );
    if (mounted) setState(() { _summaries = rows; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onRefresh: _load),
            const SizedBox(height: DesignTokens.space12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(DesignTokens.space16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_summaries.isEmpty)
              _EmptyState()
            else ...[
              _TodayRow(_summaries.first),
              if (_summaries.length > 1) ...[
                const SizedBox(height: DesignTokens.space16),
                _WeekSparklines(_summaries),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.monitor_heart_outlined,
            color: DesignTokens.accentBlue, size: 20),
        const SizedBox(width: DesignTokens.space8),
        Text('Wearable Data',
            style: DesignTokens.titleSmall
                .copyWith(fontWeight: FontWeight.w600)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh, size: 18),
          onPressed: onRefresh,
          tooltip: 'Refresh',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class _TodayRow extends StatelessWidget {
  final WearableDailySummary summary;
  const _TodayRow(this.summary);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _Metric(
          icon: Icons.directions_walk,
          label: 'Steps',
          value: summary.steps != null
              ? _formatNum(summary.steps!)
              : '—',
          color: DesignTokens.success,
        ),
        _Metric(
          icon: Icons.bedtime_outlined,
          label: 'Sleep',
          value: summary.sleepMinutes != null
              ? '${(summary.sleepMinutes! / 60).toStringAsFixed(1)}h'
              : '—',
          color: DesignTokens.accentBlue,
        ),
        _Metric(
          icon: Icons.favorite_border,
          label: 'RHR',
          value: summary.restingHr != null
              ? '${summary.restingHr} bpm'
              : '—',
          color: DesignTokens.warn,
        ),
        _Metric(
          icon: Icons.local_fire_department_outlined,
          label: 'Active',
          value: summary.activeKcal != null
              ? '${summary.activeKcal} kcal'
              : '—',
          color: DesignTokens.accentOrange,
        ),
      ],
    );
  }

  static String _formatNum(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: DesignTokens.space4),
        Text(value,
            style: DesignTokens.labelMedium
                .copyWith(fontWeight: FontWeight.w700, color: DesignTokens.ink900)),
        Text(label,
            style: DesignTokens.labelSmall
                .copyWith(color: DesignTokens.ink500)),
      ],
    );
  }
}

class _WeekSparklines extends StatelessWidget {
  final List<WearableDailySummary> summaries;
  const _WeekSparklines(this.summaries);

  @override
  Widget build(BuildContext context) {
    final maxSteps = summaries
        .map((s) => s.steps ?? 0)
        .fold<int>(1, (a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last 7 days — steps',
            style: DesignTokens.labelSmall.copyWith(color: DesignTokens.ink500)),
        const SizedBox(height: DesignTokens.space8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: summaries.reversed.map((s) {
            final frac = maxSteps > 0 ? (s.steps ?? 0) / maxSteps : 0.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  children: [
                    Container(
                      height: 40 * frac.clamp(0.04, 1.0),
                      decoration: BoxDecoration(
                        color: DesignTokens.success.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dayLabel(s.day),
                      style: DesignTokens.labelSmall
                          .copyWith(color: DesignTokens.ink400, fontSize: 9),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static String _dayLabel(DateTime d) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[d.weekday - 1];
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.space16),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.watch_off_outlined, size: 36, color: DesignTokens.ink300),
            SizedBox(height: DesignTokens.space8),
            Text(
              'No wearable data yet',
              style: TextStyle(color: DesignTokens.ink500),
            ),
            SizedBox(height: DesignTokens.space4),
            Text(
              'Client needs to connect a health source',
              style: TextStyle(color: DesignTokens.ink400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
