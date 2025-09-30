import 'package:flutter/material.dart';
import 'package:vagus_app/services/admin/admin_support_service.dart';
import '../../services/google/google_apps_service.dart';




class AdminOpsScreen extends StatefulWidget {
  const AdminOpsScreen({super.key});

  @override
  State<AdminOpsScreen> createState() => _AdminOpsScreenState();
}

class _AdminOpsScreenState extends State<AdminOpsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AdminSupportService _service = AdminSupportService.instance;
  final _google = GoogleAppsService.instance;
  
  OpsKpis? _kpis;
  Percentiles? _frtPercentiles;
  List<List<int>>? _agingHeatmap;
  List<Map<String, dynamic>>? _activeBreaches;
  bool _isLoading = true;
  String _selectedLookback = '7d';

  final Map<String, Duration> _lookbackOptions = {
    '24h': const Duration(hours: 24),
    '7d': const Duration(days: 7),
    '30d': const Duration(days: 30),
    '90d': const Duration(days: 90),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final duration = _lookbackOptions[_selectedLookback]!;
      
      final results = await Future.wait([
        _service.getOpsKpis(lookback: duration),
        _service.getFrtPercentiles(lookback: duration),
        _service.getAgingHeatmap(),
        _service.listActiveBreaches(),
      ]);
      
      if (!mounted) return;
      
      setState(() {
        _kpis = results[0] as OpsKpis;
        _frtPercentiles = results[1] as Percentiles;
        _agingHeatmap = results[2] as List<List<int>>;
        _activeBreaches = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Ops Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Export KPIs to Sheets',
            icon: const Icon(Icons.table_view_outlined),
            onPressed: () async {
              final k = _kpis; final p = _frtPercentiles;
              if (k == null || p == null) return;
              final rows = [
                ['metric','value'],
                ['open', k.openTickets],
                ['totalTickets', k.totalTickets],
                ['avgResponseTime_minutes', k.avgResponseTime.inMinutes],
                ['avgResolutionTime_minutes', k.avgResolutionTime.inMinutes],
                ['slaCompliance_percentage', k.slaCompliancePercentage],
                ['avgTicketsPerAgent', k.avgTicketsPerAgent],
                ['frt_p50_minutes', p.p50.inMinutes],
                ['frt_p90_minutes', p.p90.inMinutes],
                ['frt_p99_minutes', p.p99.inMinutes],
              ];
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final ok = await _google.exportKpisToSheets(
                title: 'LiveOps KPIs',
                sheetName: 'kpis',
                rows: rows,
              );
              if (!mounted) return;
              scaffoldMessenger.showSnackBar(SnackBar(content: Text(ok ? 'Exported to Sheets' : 'Export failed')));
            },
          ),
          _buildLookbackSelector(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Aging', icon: Icon(Icons.timeline)),
            Tab(text: 'Breaches', icon: Icon(Icons.warning)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAgingTab(),
                _buildBreachesTab(),
              ],
            ),
    );
  }

  Widget _buildLookbackSelector() {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: DropdownButton<String>(
        value: _selectedLookback,
        items: _lookbackOptions.keys.map((key) {
          return DropdownMenuItem(
            value: key,
            child: Text(key),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedLookback = value);
            _loadData();
          }
        },
        underline: Container(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_kpis == null || _frtPercentiles == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiGrid(),
          const SizedBox(height: 24),
          _buildFrtPercentiles(),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildKpiCard(
          'Total Tickets',
          _kpis!.totalTickets.toString(),
          Icons.inbox,
          Colors.blue,
        ),
        _buildKpiCard(
          'Open Tickets',
          _kpis!.openTickets.toString(),
          Icons.folder_open,
          Colors.orange,
        ),
        _buildKpiCard(
          'Avg Response Time',
          _formatDuration(_kpis!.avgResponseTime),
          Icons.timer,
          Colors.green,
        ),
        _buildKpiCard(
          'Avg Resolution Time',
          _formatDuration(_kpis!.avgResolutionTime),
          Icons.check_circle,
          Colors.purple,
        ),
        _buildKpiCard(
          'SLA Compliance',
          '${_kpis!.slaCompliancePercentage.toStringAsFixed(1)}%',
          Icons.verified,
          _kpis!.slaCompliancePercentage >= 95 ? Colors.green : Colors.red,
        ),
        _buildKpiCard(
          'Agent Productivity',
          _kpis!.avgTicketsPerAgent.toStringAsFixed(1),
          Icons.person,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
                        Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrtPercentiles() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'First Response Time Percentiles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildPercentileRow('P50', _frtPercentiles!.p50),
            _buildPercentileRow('P75', _frtPercentiles!.p75),
            _buildPercentileRow('P90', _frtPercentiles!.p90),
            _buildPercentileRow('P95', _frtPercentiles!.p95),
            _buildPercentileRow('P99', _frtPercentiles!.p99),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentileRow(String label, Duration duration) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: duration.inMinutes / (24 * 60), // Normalize to 24 hours
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getPercentileColor(duration),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text(
              _formatDuration(duration),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPercentileColor(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes <= 60) return Colors.green;
    if (minutes <= 240) return Colors.orange;
    if (minutes <= 480) return Colors.red;
    return Colors.purple;
  }

  Widget _buildAgingTab() {
    if (_agingHeatmap == null) {
      return const Center(child: Text('No aging data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ticket Aging Heatmap',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildAgingHeatmap(),
        ],
      ),
    );
  }

  Widget _buildAgingHeatmap() {
    final ageRanges = ['0-1h', '1-4h', '4-8h', '8-24h', '1-3d', '3-7d', '7d+'];
    final statuses = ['New', 'Open', 'Pending', 'Resolved'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header row
            Row(
              children: [
                const SizedBox(width: 80), // Space for status labels
                ...ageRanges.map((range) => Expanded(
                  child: Text(
                    range,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )),
              ],
            ),
            const SizedBox(height: 8),
            // Data rows
            ...List.generate(statuses.length, (statusIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        statuses[statusIndex],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ...List.generate(ageRanges.length, (ageIndex) {
                      final count = _agingHeatmap![statusIndex][ageIndex];
                      final intensity = count > 0 ? (count / 10).clamp(0.1, 1.0) : 0.0;
                      
                      return Expanded(
                        child: Container(
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: intensity),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              count.toString(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: intensity > 0.5 ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBreachesTab() {
    if (_activeBreaches == null) {
      return const Center(child: Text('No breach data available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeBreaches!.length,
      itemBuilder: (context, index) {
        final breach = _activeBreaches![index];
        return _buildBreachCard(breach);
      },
    );
  }

  Widget _buildBreachCard(Map<String, dynamic> breach) {
    final severity = breach['severity'] ?? 'medium';
    final severityColor = _getSeverityColor(severity);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: severityColor,
          child: const Icon(
            Icons.warning,
            color: Colors.white,
          ),
        ),
        title: Text(
          breach['ticketId'] ?? 'Unknown Ticket',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Policy: ${breach['policyName'] ?? 'Unknown'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Breached: ${_formatDuration(Duration(minutes: breach['breachMinutes'] ?? 0))} ago',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: severityColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleBreachAction(action, breach),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'acknowledge',
              child: Row(
                children: [
                  Icon(Icons.check),
                  SizedBox(width: 8),
                  Text('Acknowledge'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'extend',
              child: Row(
                children: [
                  Icon(Icons.schedule),
                  SizedBox(width: 8),
                  Text('Extend SLA'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'escalate',
              child: Row(
                children: [
                  Icon(Icons.priority_high),
                  SizedBox(width: 8),
                  Text('Escalate'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.orange;
      case 'medium':
        return Colors.red;
      case 'high':
        return Colors.purple;
      case 'critical':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  void _handleBreachAction(String action, Map<String, dynamic> breach) {
    // Handle breach actions
    switch (action) {
      case 'acknowledge':
        // TODO: Implement acknowledge
        break;
      case 'extend':
        // TODO: Implement extend
        break;
      case 'escalate':
        // TODO: Implement escalate
        break;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    }
  }
}
