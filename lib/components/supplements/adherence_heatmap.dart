import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/supplements/supplement_models.dart';
import '../../services/supplements/supplement_service.dart';
import '../../theme/design_tokens.dart';

class AdherenceHeatmap extends StatefulWidget {
  final String supplementId;
  final String supplementName;
  final VoidCallback? onDayTap;

  const AdherenceHeatmap({
    super.key,
    required this.supplementId,
    required this.supplementName,
    this.onDayTap,
  });

  @override
  State<AdherenceHeatmap> createState() => _AdherenceHeatmapState();
}

class _AdherenceHeatmapState extends State<AdherenceHeatmap> {
  List<SupplementLog> _logs = [];
  bool _loading = true;
  String _error = '';
  
  // 30-day data
  final Map<DateTime, List<SupplementLog>> _dailyLogs = {};
  final Map<DateTime, AdherenceStatus> _dailyStatus = {};

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
          final logs = await SupplementService.instance.getLogsForUser(
      supplementId: widget.supplementId,
    );
      
      setState(() {
        _logs = logs;
        _loading = false;
      });
      
      _processDailyData();
    } catch (e) {
      setState(() {
        _error = 'Failed to load logs: $e';
        _loading = false;
      });
    }
  }

  void _processDailyData() {
    final now = DateTime.now();
    _dailyLogs.clear();
    _dailyStatus.clear();
    
    // Initialize last 30 days
    for (int i = 29; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      _dailyLogs[date] = [];
      _dailyStatus[date] = AdherenceStatus.empty;
    }
    
    // Process logs
    for (final log in _logs) {
      final logDate = DateTime(log.takenAt.year, log.takenAt.month, log.takenAt.day);
      if (_dailyLogs.containsKey(logDate)) {
        _dailyLogs[logDate]!.add(log);
        _dailyStatus[logDate] = _determineStatus(log);
      }
    }
  }

  AdherenceStatus _determineStatus(SupplementLog log) {
    switch (log.status) {
      case 'taken':
        return AdherenceStatus.taken;
      case 'skipped':
        return AdherenceStatus.skipped;
      case 'snoozed':
        return AdherenceStatus.snoozed;
      default:
        return AdherenceStatus.empty;
    }
  }

  double get _adherencePercentage {
    if (_dailyStatus.isEmpty) return 0.0;
    
    final takenDays = _dailyStatus.values
        .where((status) => status == AdherenceStatus.taken)
        .length;
    
    return (takenDays / _dailyStatus.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: DesignTokens.danger, size: 32),
            const SizedBox(height: DesignTokens.space8),
            Text(
              _error,
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.danger,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with adherence percentage
        _buildHeader(),
        const SizedBox(height: DesignTokens.space16),
        
        // Heatmap grid
        _buildHeatmapGrid(),
        const SizedBox(height: DesignTokens.space16),
        
        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '30-Day Adherence',
          style: DesignTokens.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space12,
            vertical: DesignTokens.space6,
          ),
          decoration: BoxDecoration(
            color: _getAdherenceColor(_adherencePercentage),
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
          ),
          child: Text(
            '${_adherencePercentage.round()}%',
            style: DesignTokens.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapGrid() {
    final now = DateTime.now();
    final weeks = <List<DateTime>>[];
    
    // Group days into weeks
    final List<DateTime> currentWeek = [];
    for (int i = 29; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      currentWeek.add(date);
      
      if (currentWeek.length == 7) {
        weeks.add(List.from(currentWeek));
        currentWeek.clear();
      }
    }
    
    // Add remaining days if any
    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return Column(
      children: weeks.map((week) => _buildWeekRow(week)).toList(),
    );
  }

  Widget _buildWeekRow(List<DateTime> week) {
    return Row(
      children: week.map((date) => _buildDayCell(date)).toList(),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final status = _dailyStatus[date] ?? AdherenceStatus.empty;
    final isToday = _isSameDay(date, DateTime.now());
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onDayTap(date, status),
        child: Container(
          margin: const EdgeInsets.all(1),
          height: 32,
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            borderRadius: BorderRadius.circular(DesignTokens.radius4),
            border: isToday 
                ? Border.all(color: DesignTokens.blue600, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              date.day.toString(),
              style: DesignTokens.bodySmall.copyWith(
                color: _getStatusTextColor(status),
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(AdherenceStatus.taken, 'Taken'),
        _buildLegendItem(AdherenceStatus.skipped, 'Skipped'),
        _buildLegendItem(AdherenceStatus.snoozed, 'Snoozed'),
        _buildLegendItem(AdherenceStatus.empty, 'Empty'),
      ],
    );
  }

  Widget _buildLegendItem(AdherenceStatus status, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            borderRadius: BorderRadius.circular(DesignTokens.radius4),
          ),
        ),
        const SizedBox(width: DesignTokens.space4),
        Text(
          label,
          style: DesignTokens.bodySmall.copyWith(
            color: DesignTokens.ink500,
          ),
        ),
      ],
    );
  }

  void _onDayTap(DateTime date, AdherenceStatus status) {
    if (widget.onDayTap != null) {
      widget.onDayTap!();
    }
    
    // Show day details
    _showDayDetails(date, status);
  }

  void _showDayDetails(DateTime date, AdherenceStatus status) {
    final logs = _dailyLogs[date] ?? [];
    final dateString = DateFormat('EEEE, MMMM d, yyyy').format(date);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  dateString,
                  style: DesignTokens.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: DesignTokens.space16),
            
            Container(
              padding: const EdgeInsets.all(DesignTokens.space12),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
                border: Border.all(
                  color: _getStatusColor(status).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                  ),
                  const SizedBox(width: DesignTokens.space8),
                  Text(
                    'Status: ${_getStatusLabel(status)}',
                    style: DesignTokens.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            if (logs.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.space16),
              Text(
                'Logs for this day:',
                style: DesignTokens.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DesignTokens.space8),
              ...logs.map((log) => _buildLogItem(log)),
            ] else ...[
              const SizedBox(height: DesignTokens.space16),
              Center(
                child: Text(
                  'No logs recorded for this day',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: DesignTokens.ink500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(SupplementLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.space8),
      child: ListTile(
        leading: Icon(
          _getStatusIcon(_determineStatus(log)),
          color: _getStatusColor(_determineStatus(log)),
        ),
        title: Text(
          '${log.status.toUpperCase()} at ${DateFormat('h:mm a').format(log.takenAt)}',
          style: DesignTokens.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: log.notes != null && log.notes!.isNotEmpty
            ? Text(log.notes!)
            : null,
        trailing: Text(
          DateFormat('MMM d').format(log.takenAt),
          style: DesignTokens.bodySmall.copyWith(
            color: DesignTokens.ink500,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AdherenceStatus status) {
    switch (status) {
      case AdherenceStatus.taken:
        return DesignTokens.success;
      case AdherenceStatus.skipped:
        return DesignTokens.danger;
      case AdherenceStatus.snoozed:
        return DesignTokens.warn;
      case AdherenceStatus.empty:
        return DesignTokens.ink100;
    }
  }

  Color _getStatusTextColor(AdherenceStatus status) {
    switch (status) {
      case AdherenceStatus.taken:
        return Colors.white;
      case AdherenceStatus.skipped:
        return Colors.white;
      case AdherenceStatus.snoozed:
        return Colors.white;
      case AdherenceStatus.empty:
        return DesignTokens.ink500;
    }
  }

  Color _getAdherenceColor(double percentage) {
    if (percentage >= 80) return DesignTokens.success;
    if (percentage >= 60) return DesignTokens.warn;
    return DesignTokens.danger;
  }

  IconData _getStatusIcon(AdherenceStatus status) {
    switch (status) {
      case AdherenceStatus.taken:
        return Icons.check_circle;
      case AdherenceStatus.skipped:
        return Icons.cancel;
      case AdherenceStatus.snoozed:
        return Icons.snooze;
      case AdherenceStatus.empty:
        return Icons.circle_outlined;
    }
  }

  String _getStatusLabel(AdherenceStatus status) {
    switch (status) {
      case AdherenceStatus.taken:
        return 'Taken';
      case AdherenceStatus.skipped:
        return 'Skipped';
      case AdherenceStatus.snoozed:
        return 'Snoozed';
      case AdherenceStatus.empty:
        return 'No Action';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}

enum AdherenceStatus {
  taken,
  skipped,
  snoozed,
  empty,
}
