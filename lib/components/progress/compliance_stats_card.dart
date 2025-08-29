import 'package:flutter/material.dart';
import '../../services/progress/progress_service.dart';
import '../../theme/design_tokens.dart';

class ComplianceStatsCard extends StatefulWidget {
  const ComplianceStatsCard({super.key});

  @override
  State<ComplianceStatsCard> createState() => _ComplianceStatsCardState();
}

class _ComplianceStatsCardState extends State<ComplianceStatsCard> {
  final ProgressService _progressService = ProgressService();
  
  bool _loading = true;
  String? _error;
  
  double _weeklyCompliance = 0.0;
  double _monthlyCompliance = 0.0;
  int _streak = 0;
  Duration? _avgReplyTime;
  List<bool> _last7DaysActivity = [];

  @override
  void initState() {
    super.initState();
    _loadComplianceData();
  }

  Future<void> _loadComplianceData() async {
    try {
      setState(() => _loading = true);
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Calculate date ranges
      final week7Start = today.subtract(const Duration(days: 6));
      final month30Start = today.subtract(const Duration(days: 29));
      
      // Get activity data
      final weeklyActivity = await _progressService.getActivityDays(
        start: week7Start,
        end: today,
      );
      
      final monthlyActivity = await _progressService.getActivityDays(
        start: month30Start,
        end: today,
      );
      
      // Get reply time
      final replyTime = await _progressService.averageCoachReplyTime(
        start: month30Start,
        end: today,
      );
      
      // Calculate compliance percentages
      final weeklySet = weeklyActivity.map((d) => DateTime(d.year, d.month, d.day)).toSet();
      final monthlySet = monthlyActivity.map((d) => DateTime(d.year, d.month, d.day)).toSet();
      
      final weeklyCompliance = weeklySet.length / 7.0 * 100;
      final monthlyCompliance = monthlySet.length / 30.0 * 100;
      
      // Calculate streak
      int streak = 0;
      DateTime currentDate = today;
      while (true) {
        if (monthlySet.contains(currentDate)) {
          streak++;
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      
      // Build 7-day activity list for sparkline
      final last7Days = <bool>[];
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        last7Days.add(weeklySet.contains(date));
      }
      
      setState(() {
        _weeklyCompliance = weeklyCompliance;
        _monthlyCompliance = monthlyCompliance;
        _streak = streak;
        _avgReplyTime = replyTime;
        _last7DaysActivity = last7Days;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '—';
    final hours = duration.inHours;
    if (hours < 24) {
      return '${hours}h';
    } else {
      final days = hours ~/ 24;
      return '${days}d';
    }
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: DesignTokens.space4),
          Text(
            value,
            style: DesignTokens.displaySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            title,
            style: DesignTokens.labelSmall.copyWith(
              color: DesignTokens.ink500.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSparkline() {
    return SizedBox(
      height: 30,
      child: CustomPaint(
        painter: SparklinePainter(_last7DaysActivity),
        child: Container(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: DesignTokens.purple500),
                const SizedBox(width: DesignTokens.space8),
                Text(
                  'Compliance Stats',
                  style: DesignTokens.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadComplianceData,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.space16),
            
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadComplianceData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Metrics grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: '7-Day %',
                      value: '${_weeklyCompliance.toInt()}%',
                      color: DesignTokens.blue600,
                      icon: Icons.calendar_view_week,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space8),
                  Expanded(
                    child: _buildMetricTile(
                      title: '30-Day %',
                      value: '${_monthlyCompliance.toInt()}%',
                      color: DesignTokens.success,
                      icon: Icons.calendar_month,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space8),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Streak',
                      value: '${_streak}d',
                      color: DesignTokens.warn,
                      icon: Icons.local_fire_department,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space8),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Avg Reply',
                      value: _formatDuration(_avgReplyTime),
                      color: DesignTokens.purple500,
                      icon: Icons.reply,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: DesignTokens.space16),
              
              // Sparkline
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '7-Day Activity',
                    style: DesignTokens.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.ink500,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  _buildSparkline(),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<bool> activityData;

  SparklinePainter(this.activityData);

  @override
  void paint(Canvas canvas, Size size) {
    if (activityData.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / activityData.length;
    
    for (int i = 0; i < activityData.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final hasActivity = activityData[i];
      
      paint.color = hasActivity ? DesignTokens.success : DesignTokens.ink100;
      
      canvas.drawCircle(
        Offset(x, size.height / 2),
        hasActivity ? 4 : 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
