import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/supplements/supplement_models.dart';
import '../../services/supplements/supplement_service.dart';
import '../../theme/design_tokens.dart';
import '../../components/supplements/adherence_heatmap.dart';

/// Screen showing supplement intake history and adherence statistics
class SupplementHistoryScreen extends StatefulWidget {
  final String supplementId;
  final String? userId;

  const SupplementHistoryScreen({
    super.key,
    required this.supplementId,
    this.userId,
  });

  @override
  State<SupplementHistoryScreen> createState() => _SupplementHistoryScreenState();
}

class _SupplementHistoryScreenState extends State<SupplementHistoryScreen> {
  final SupplementService _supplementService = SupplementService.instance;
  
  Supplement? _supplement;
  List<SupplementLog> _logs = [];
  Map<String, dynamic> _streakInfo = {};
  bool _loading = true;
  String? _error;
  String _selectedPeriod = '30'; // days

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      
      // Load supplement details
      final supplement = await _supplementService.getSupplement(widget.supplementId);
      if (supplement == null) {
        throw Exception('Supplement not found');
      }
      
      // Load logs for the selected period
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: int.parse(_selectedPeriod)));
      
      final logs = await _supplementService.getLogsForUser(
        userId: widget.userId,
        supplementId: widget.supplementId,
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );
      
      // Load streak information
      final streakInfo = await _supplementService.getSupplementStreak(
        supplementId: widget.supplementId,
        userId: widget.userId,
      );
      
      setState(() {
        _supplement = supplement;
        _logs = logs;
        _streakInfo = streakInfo;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onPeriodChanged(String? period) {
    if (period != null && period != _selectedPeriod) {
      setState(() => _selectedPeriod = period);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_supplement?.name ?? 'Supplement History'),
        backgroundColor: DesignTokens.blue600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _supplement == null
                  ? _buildNotFoundState()
                  : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: DesignTokens.danger,
            size: 64,
          ),
          const SizedBox(height: DesignTokens.space16),
          Text(
            'Failed to load supplement history',
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.ink900,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            _error!,
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.ink500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.space16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.medication_outlined,
            color: DesignTokens.ink500,
            size: 64,
          ),
          const SizedBox(height: DesignTokens.space16),
          Text(
            'Supplement not found',
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.ink900,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'The supplement you\'re looking for doesn\'t exist or has been deleted.',
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.ink500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          _buildPeriodSelector(),
          const SizedBox(height: DesignTokens.space16),
          
          // Statistics cards
          _buildStatisticsCards(),
          const SizedBox(height: DesignTokens.space16),
          
          // Adherence Heatmap
          _buildAdherenceHeatmap(),
          const SizedBox(height: DesignTokens.space16),
          
          // Streak information
          _buildStreakCard(),
          const SizedBox(height: DesignTokens.space16),
          
          // History list
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Period',
              style: DesignTokens.titleSmall.copyWith(
                color: DesignTokens.ink900,
              ),
            ),
            const SizedBox(height: DesignTokens.space12),
            DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.space12,
                  vertical: DesignTokens.space8,
                ),
              ),
              items: const [
                DropdownMenuItem(value: '7', child: Text('Last 7 days')),
                DropdownMenuItem(value: '30', child: Text('Last 30 days')),
                DropdownMenuItem(value: '90', child: Text('Last 90 days')),
                DropdownMenuItem(value: '365', child: Text('Last year')),
              ],
              onChanged: _onPeriodChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final totalLogs = _logs.length;
    final takenCount = _logs.where((log) => log.status == 'taken').length;
    final skippedCount = _logs.where((log) => log.status == 'skipped').length;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            totalLogs.toString(),
            Icons.list,
            DesignTokens.blue600,
          ),
        ),
        const SizedBox(width: DesignTokens.space12),
        Expanded(
          child: _buildStatCard(
            'Taken',
            takenCount.toString(),
            Icons.check_circle,
            DesignTokens.success,
          ),
        ),
        const SizedBox(width: DesignTokens.space12),
        Expanded(
          child: _buildStatCard(
            'Skipped',
            skippedCount.toString(),
            Icons.close,
            DesignTokens.danger,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              value,
              style: DesignTokens.titleLarge.copyWith(
                color: DesignTokens.ink900,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.ink500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceHeatmap() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adherence Overview',
              style: DesignTokens.titleMedium.copyWith(
                color: DesignTokens.ink900,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space16),
            AdherenceHeatmap(
              supplementId: widget.supplementId,
              supplementName: _supplement?.name ?? '',
              onDayTap: () {
                // Refresh data when a day is tapped
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    final currentStreak = _streakInfo['currentStreak'] as int? ?? 0;
    final longestStreak = _streakInfo['longestStreak'] as int? ?? 0;
    final lastTaken = _streakInfo['lastTaken'] as String?;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: DesignTokens.warn,
                  size: 24,
                ),
                const SizedBox(width: DesignTokens.space12),
                Text(
                  'Streak Information',
                  style: DesignTokens.titleMedium.copyWith(
                    color: DesignTokens.ink900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStreakStat(
                    'Current',
                    currentStreak.toString(),
                    currentStreak > 0 ? DesignTokens.success : DesignTokens.ink500,
                  ),
                ),
                Expanded(
                  child: _buildStreakStat(
                    'Longest',
                    longestStreak.toString(),
                    DesignTokens.blue600,
                  ),
                ),
              ],
            ),
            
            if (lastTaken != null) ...[
              const SizedBox(height: DesignTokens.space12),
              Text(
                'Last taken: ${DateFormat('MMM d, yyyy').format(DateTime.parse(lastTaken))}',
                style: DesignTokens.bodySmall.copyWith(
                  color: DesignTokens.ink500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreakStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: DesignTokens.titleLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: DesignTokens.bodySmall.copyWith(
            color: DesignTokens.ink500,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (_logs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space32),
          child: Column(
            children: [
              const Icon(
                Icons.history,
                color: DesignTokens.ink500,
                size: 48,
              ),
              const SizedBox(height: DesignTokens.space16),
              Text(
                'No history yet',
                style: DesignTokens.titleMedium.copyWith(
                  color: DesignTokens.ink900,
                ),
              ),
              const SizedBox(height: DesignTokens.space8),
              Text(
                'Start taking your supplements to see your history here',
                style: DesignTokens.bodyMedium.copyWith(
                  color: DesignTokens.ink500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intake History',
          style: DesignTokens.titleMedium.copyWith(
            color: DesignTokens.ink900,
          ),
        ),
        const SizedBox(height: DesignTokens.space12),
        
        ..._logs.map((log) => _buildHistoryItem(log)),
      ],
    );
  }

  Widget _buildHistoryItem(SupplementLog log) {
    final isToday = log.isToday;
    final statusColor = log.status == 'taken' 
        ? DesignTokens.success 
        : log.status == 'skipped' 
            ? DesignTokens.danger 
            : DesignTokens.warn;
    
    final statusIcon = log.status == 'taken' 
        ? Icons.check_circle 
        : log.status == 'skipped' 
            ? Icons.close 
            : Icons.snooze;
    
    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.space8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
        ),
        title: Text(
          log.statusDisplayName,
          style: DesignTokens.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: DesignTokens.ink900,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM d, yyyy').format(log.takenAt),
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.ink500,
              ),
            ),
            if (log.notes != null)
              Text(
                log.notes!,
                style: DesignTokens.bodySmall.copyWith(
                  color: DesignTokens.ink500,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: isToday
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space8,
                  vertical: DesignTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.blue50,
                  borderRadius: BorderRadius.circular(DesignTokens.radius4),
                ),
                child: Text(
                  'Today',
                  style: DesignTokens.bodySmall.copyWith(
                    color: DesignTokens.blue600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
