import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../services/health/health_service.dart';
import '../../screens/settings/health_connections_screen.dart';

class HealthRings extends StatefulWidget {
  final String userId;

  const HealthRings({
    super.key,
    required this.userId,
  });

  @override
  State<HealthRings> createState() => _HealthRingsState();
}

class _HealthRingsState extends State<HealthRings> {
  final HealthService _healthService = HealthService();
  Map<String, dynamic>? _todayData;
  bool _loading = true;
  bool _hasConnectedSources = false;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    try {
      // Check if user has connected health sources
      final sources = await _healthService.getConnectedSources();
      final hasSources = sources.isNotEmpty;
      
      // Get today's health data
      final today = DateTime.now();
      final dailyData = await _healthService.getDailySummary(today);
      
      if (mounted) {
        setState(() {
          _todayData = dailyData;
          _hasConnectedSources = hasSources;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _openHealthConnections() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HealthConnectionsScreen(),
      ),
    );
  }

  Widget _buildRing({
    required String label,
    required double progress,
    required Color color,
    required String value,
    required String unit,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          // Ring container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 6,
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                // Icon
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          // Value
          Text(
            value,
            style: DesignTokens.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: DesignTokens.ink900,
            ),
          ),
          // Unit
          Text(
            unit,
            style: DesignTokens.labelSmall.copyWith(
              color: DesignTokens.ink500,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          // Label
          Text(
            label,
            style: DesignTokens.labelMedium.copyWith(
              color: DesignTokens.ink700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          gradient: LinearGradient(
            colors: [
              DesignTokens.accentBlue.withValues(alpha: 0.1),
              DesignTokens.accentBlue.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          children: [
            const Icon(
              Icons.favorite,
              size: 48,
              color: DesignTokens.accentBlue,
            ),
            const SizedBox(height: DesignTokens.space16),
            Text(
              'Connect Health',
              style: DesignTokens.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: DesignTokens.accentBlue,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              'Track your activity and sleep to see your daily rings',
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.ink500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space16),
            ElevatedButton.icon(
              onPressed: _openHealthConnections,
              icon: const Icon(Icons.add),
              label: const Text('Connect Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.blue600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.space16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Show empty state if no health sources connected
    if (!_hasConnectedSources) {
      return _buildEmptyState();
    }

    // Show rings if we have data
    if (_todayData != null) {
      final activeKcal = _todayData!['active_kcal']?.toDouble() ?? 0.0;
      final sleepMinutes = _todayData!['sleep_minutes']?.toDouble() ?? 0.0;
      
      // Calculate progress (assuming 500 kcal goal and 8 hours sleep goal)
      final activityProgress = (activeKcal / 500.0).clamp(0.0, 1.0);
      final sleepProgress = (sleepMinutes / 480.0).clamp(0.0, 1.0); // 8 hours = 480 minutes
      
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
            Row(
              children: [
                const Icon(
                  Icons.favorite,
                  color: DesignTokens.accentBlue,
                ),
                const SizedBox(width: DesignTokens.space8),
                Text(
                  'Health Rings',
                  style: DesignTokens.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _openHealthConnections,
                  tooltip: 'Health Settings',
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space16),
              Row(
                children: [
                  _buildRing(
                    label: 'Move',
                    progress: activityProgress,
                    color: DesignTokens.success,
                    value: activeKcal.toInt().toString(),
                    unit: 'kcal',
                    icon: Icons.directions_run,
                  ),
                  _buildRing(
                    label: 'Sleep',
                    progress: sleepProgress,
                    color: DesignTokens.accentBlue,
                    value: (sleepMinutes / 60).toInt().toString(),
                    unit: 'hrs',
                    icon: Icons.bedtime,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Fallback empty state
    return _buildEmptyState();
  }
}
