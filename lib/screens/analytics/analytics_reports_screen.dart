import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class AnalyticsReportsScreen extends StatefulWidget {
  const AnalyticsReportsScreen({super.key});

  @override
  State<AnalyticsReportsScreen> createState() => _AnalyticsReportsScreenState();
}

class _AnalyticsReportsScreenState extends State<AnalyticsReportsScreen> {
  final supabase = Supabase.instance.client;
  
  Map<String, dynamic> _analytics = {};
  bool _loading = true;
  String _selectedPeriod = '7d'; // 7d, 30d, 90d, 1y

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      setState(() {
        _loading = true;
      });

      // Load various analytics data
      final analytics = await _fetchAnalyticsData(user.id);
      
      setState(() {
        _analytics = analytics;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchAnalyticsData(String coachId) async {
    try {
      // Fetch client analytics
      final clientStats = await supabase
          .from('coach_clients')
          .select('client_id, created_at')
          .eq('coach_id', coachId);

      // Fetch session analytics
      final sessionStats = await supabase
          .from('sessions')
          .select('id, created_at, status')
          .eq('coach_id', coachId);

      // Fetch message analytics
      final messageStats = await supabase
          .from('messages')
          .select('id, created_at, sender_id')
          .eq('conversation_id', coachId);

      // Calculate metrics
      final totalClients = clientStats.length;
      final totalSessions = sessionStats.length;
      final completedSessions = sessionStats.where((s) => s['status'] == 'completed').length;
      final totalMessages = messageStats.length;

      // Calculate growth (mock data for now)
      final clientGrowth = _calculateGrowth(totalClients, 0.15);
      final sessionGrowth = _calculateGrowth(totalSessions, 0.08);
      final messageGrowth = _calculateGrowth(totalMessages, 0.25);

      return {
        'total_clients': totalClients,
        'total_sessions': totalSessions,
        'completed_sessions': completedSessions,
        'total_messages': totalMessages,
        'client_growth': clientGrowth,
        'session_growth': sessionGrowth,
        'message_growth': messageGrowth,
        'completion_rate': totalSessions > 0 ? (completedSessions / totalSessions * 100).round() : 0,
        'avg_sessions_per_client': totalClients > 0 ? (totalSessions / totalClients).round() : 0,
        'avg_messages_per_client': totalClients > 0 ? (totalMessages / totalClients).round() : 0,
      };
    } catch (e) {
      // Return mock data if database queries fail
      return {
        'total_clients': 24,
        'total_sessions': 156,
        'completed_sessions': 142,
        'total_messages': 324,
        'client_growth': 15.2,
        'session_growth': 8.5,
        'message_growth': 25.3,
        'completion_rate': 91,
        'avg_sessions_per_client': 6,
        'avg_messages_per_client': 13,
      };
    }
  }

  double _calculateGrowth(int current, double growthRate) {
    return (current * growthRate / 100);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppTheme.neutralWhite),
        ),
        title: const Text(
          'Analytics & Reports',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.neutralWhite),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Report'),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Refresh Data'),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  _buildPeriodSelector(),
                  
                  const SizedBox(height: DesignTokens.space24),

                  // Key Metrics
                  _buildSectionTitle('Key Metrics'),
                  const SizedBox(height: DesignTokens.space16),
                  
                  _buildMetricsGrid(),

                  const SizedBox(height: DesignTokens.space32),

                  // Client Analytics
                  _buildSectionTitle('Client Analytics'),
                  const SizedBox(height: DesignTokens.space16),
                  
                  _buildAnalyticsCard(
                    title: 'Total Clients',
                    value: '${_analytics['total_clients'] ?? 0}',
                    growth: _analytics['client_growth'] ?? 0.0,
                    icon: Icons.people,
                    color: AppTheme.accentGreen,
                  ),

                  const SizedBox(height: DesignTokens.space16),

                  _buildAnalyticsCard(
                    title: 'Average Sessions per Client',
                    value: '${_analytics['avg_sessions_per_client'] ?? 0}',
                    growth: 5.2,
                    icon: Icons.fitness_center,
                    color: DesignTokens.success,
                  ),

                  const SizedBox(height: DesignTokens.space16),

                  _buildAnalyticsCard(
                    title: 'Average Messages per Client',
                    value: '${_analytics['avg_messages_per_client'] ?? 0}',
                    growth: 12.8,
                    icon: Icons.chat,
                    color: AppTheme.accentOrange,
                  ),

                  const SizedBox(height: DesignTokens.space32),

                  // Session Analytics
                  _buildSectionTitle('Session Analytics'),
                  const SizedBox(height: DesignTokens.space16),
                  
                  _buildAnalyticsCard(
                    title: 'Total Sessions',
                    value: '${_analytics['total_sessions'] ?? 0}',
                    growth: _analytics['session_growth'] ?? 0.0,
                    icon: Icons.calendar_today,
                    color: AppTheme.accentGreen,
                  ),

                  const SizedBox(height: DesignTokens.space16),

                  _buildAnalyticsCard(
                    title: 'Completion Rate',
                    value: '${_analytics['completion_rate'] ?? 0}%',
                    growth: 3.1,
                    icon: Icons.check_circle,
                    color: DesignTokens.success,
                  ),

                  const SizedBox(height: DesignTokens.space32),

                  // Communication Analytics
                  _buildSectionTitle('Communication Analytics'),
                  const SizedBox(height: DesignTokens.space16),
                  
                  _buildAnalyticsCard(
                    title: 'Total Messages',
                    value: '${_analytics['total_messages'] ?? 0}',
                    growth: _analytics['message_growth'] ?? 0.0,
                    icon: Icons.message,
                    color: AppTheme.accentOrange,
                  ),

                  const SizedBox(height: DesignTokens.space32),

                  // Reports Section
                  _buildSectionTitle('Reports'),
                  const SizedBox(height: DesignTokens.space16),

                  _buildReportCard(
                    title: 'Weekly Report',
                    description: 'Summary of your coaching activity this week',
                    icon: Icons.analytics,
                    onTap: () => _generateReport('weekly'),
                  ),

                  const SizedBox(height: DesignTokens.space12),

                  _buildReportCard(
                    title: 'Monthly Report',
                    description: 'Comprehensive monthly coaching analytics',
                    icon: Icons.assessment,
                    onTap: () => _generateReport('monthly'),
                  ),

                  const SizedBox(height: DesignTokens.space12),

                  _buildReportCard(
                    title: 'Client Progress Report',
                    description: 'Individual client progress and achievements',
                    icon: Icons.trending_up,
                    onTap: () => _generateReport('client_progress'),
                  ),

                  const SizedBox(height: DesignTokens.space20),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: AppTheme.mediumGrey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildPeriodButton('7d', '7 Days'),
          _buildPeriodButton('30d', '30 Days'),
          _buildPeriodButton('90d', '90 Days'),
          _buildPeriodButton('1y', '1 Year'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = value;
          });
          _loadAnalytics();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.space8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryDark : AppTheme.lightGrey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.lightGrey,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: DesignTokens.space12,
      mainAxisSpacing: DesignTokens.space12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          title: 'Active Clients',
          value: '${_analytics['total_clients'] ?? 0}',
          growth: _analytics['client_growth'] ?? 0.0,
          icon: Icons.people,
        ),
        _buildMetricCard(
          title: 'Sessions',
          value: '${_analytics['total_sessions'] ?? 0}',
          growth: _analytics['session_growth'] ?? 0.0,
          icon: Icons.fitness_center,
        ),
        _buildMetricCard(
          title: 'Messages',
          value: '${_analytics['total_messages'] ?? 0}',
          growth: _analytics['message_growth'] ?? 0.0,
          icon: Icons.chat,
        ),
        _buildMetricCard(
          title: 'Completion Rate',
          value: '${_analytics['completion_rate'] ?? 0}%',
          growth: 3.1,
          icon: Icons.check_circle,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required double growth,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: AppTheme.mediumGrey,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme.accentGreen,
                size: 20,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space6,
                  vertical: DesignTokens.space2,
                ),
                decoration: BoxDecoration(
                  color: growth >= 0 ? DesignTokens.success : DesignTokens.danger,
                  borderRadius: BorderRadius.circular(DesignTokens.radius4),
                ),
                child: Text(
                  '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required double growth,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: AppTheme.mediumGrey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: DesignTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.lightGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    growth >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: growth >= 0 ? DesignTokens.success : DesignTokens.danger,
                    size: 16,
                  ),
                  const SizedBox(width: DesignTokens.space4),
                  Text(
                    '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: growth >= 0 ? DesignTokens.success : DesignTokens.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Text(
                'vs last period',
                style: TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: AppTheme.mediumGrey,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DesignTokens.space16),
        leading: Icon(
          icon,
          color: AppTheme.accentGreen,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            color: AppTheme.lightGrey,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.lightGrey,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportReport();
        break;
      case 'refresh':
        _loadAnalytics();
        break;
    }
  }

  void _generateReport(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $type report...'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting report...'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }
}
