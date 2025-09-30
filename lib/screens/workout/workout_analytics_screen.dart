import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/workout/analytics_models.dart';
import '../../services/workout/workout_analytics_service.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../theme/design_tokens.dart';

/// Comprehensive workout analytics screen
///
/// Shows detailed analytics including:
/// - Volume trends over time
/// - Muscle group distribution
/// - Strength progression per exercise
/// - Training frequency heatmap
/// - PR timeline
/// - Compliance metrics
/// - Injury risk indicators
class WorkoutAnalyticsScreen extends StatefulWidget {
  final String clientId;
  final bool isCoachView;

  const WorkoutAnalyticsScreen({
    Key? key,
    required this.clientId,
    this.isCoachView = false,
  }) : super(key: key);

  @override
  State<WorkoutAnalyticsScreen> createState() => _WorkoutAnalyticsScreenState();
}

class _WorkoutAnalyticsScreenState extends State<WorkoutAnalyticsScreen> {
  final WorkoutAnalyticsService _analyticsService = WorkoutAnalyticsService();

  String _selectedTimeframe = '12weeks';
  bool _isLoading = true;
  ComprehensiveReport? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final report = await _analyticsService.generateProgressReport(
        widget.clientId,
        timeframe: _selectedTimeframe,
      );

      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleHelper.t('workout_analytics', 'en')),
        actions: [
          // Timeframe selector
          PopupMenuButton<String>(
            initialValue: _selectedTimeframe,
            onSelected: (timeframe) {
              setState(() {
                _selectedTimeframe = timeframe;
              });
              _loadAnalytics();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: '4weeks',
                child: Text(LocaleHelper.t('4_weeks', 'en')),
              ),
              PopupMenuItem(
                value: '12weeks',
                child: Text(LocaleHelper.t('12_weeks', 'en')),
              ),
              PopupMenuItem(
                value: '6months',
                child: Text(LocaleHelper.t('6_months', 'en')),
              ),
              PopupMenuItem(
                value: '1year',
                child: Text(LocaleHelper.t('1_year', 'en')),
              ),
            ],
            icon: const Icon(Icons.date_range),
          ),
          // Export button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _report != null ? _exportReport : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnalytics,
                        child: Text(LocaleHelper.t('retry', 'en')),
                      ),
                    ],
                  ),
                )
              : _report == null
                  ? Center(child: Text(LocaleHelper.t('no_data', 'en')))
                  : RefreshIndicator(
                      onRefresh: _loadAnalytics,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Report header
                            _buildReportHeader(),
                            const SizedBox(height: 24),

                            // Summary card
                            _buildSummaryCard(),
                            const SizedBox(height: 24),

                            // Achievements
                            if (_report!.achievements.isNotEmpty) ...[
                              _buildAchievementsSection(),
                              const SizedBox(height: 24),
                            ],

                            // Volume metrics
                            _buildSectionTitle(LocaleHelper.t('volume_metrics', 'en')),
                            _buildVolumeMetricsCard(),
                            const SizedBox(height: 24),

                            // Strength gains
                            _buildSectionTitle(LocaleHelper.t('strength_gains', 'en')),
                            _buildStrengthGainsCard(),
                            const SizedBox(height: 24),

                            // Muscle distribution
                            _buildSectionTitle(LocaleHelper.t('muscle_distribution', 'en')),
                            _buildDistributionCard(),
                            const SizedBox(height: 24),

                            // Training patterns
                            _buildSectionTitle(LocaleHelper.t('training_patterns', 'en')),
                            _buildPatternsCard(),
                            const SizedBox(height: 24),

                            // Compliance
                            _buildSectionTitle(LocaleHelper.t('compliance', 'en')),
                            _buildComplianceCard(),
                            const SizedBox(height: 24),

                            // Personal records
                            if (_report!.personalRecords.isNotEmpty) ...[
                              _buildSectionTitle(LocaleHelper.t('personal_records', 'en')),
                              _buildPRTimeline(),
                              const SizedBox(height: 24),
                            ],

                            // Areas for improvement
                            if (_report!.areasForImprovement.isNotEmpty) ...[
                              _buildSectionTitle(LocaleHelper.t('areas_for_improvement', 'en')),
                              _buildImprovementCard(),
                            ],
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildReportHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _report!.clientName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${DateFormat('MMM d, yyyy').format(_report!.periodStart)} - ${DateFormat('MMM d, yyyy').format(_report!.periodEnd)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: DesignTokens.accentBlue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: DesignTokens.accentBlue),
                const SizedBox(width: 8),
                Text(
                  LocaleHelper.t('summary', 'en'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _report!.summary,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  LocaleHelper.t('achievements', 'en'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._report!.achievements.map((achievement) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          achievement,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeMetricsCard() {
    final metrics = _report!.volumeMetrics;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Total volume
            _buildMetricRow(
              LocaleHelper.t('total_volume', 'en'),
              metrics.totalVolumeDisplay,
              Icons.fitness_center,
              DesignTokens.accentBlue,
            ),
            const Divider(height: 24),

            // Average per session
            _buildMetricRow(
              LocaleHelper.t('avg_per_session', 'en'),
              '${metrics.avgVolumePerSession.toStringAsFixed(0)} kg',
              Icons.trending_up,
              Colors.blue,
            ),
            const Divider(height: 24),

            // Total sets and reps
            Row(
              children: [
                Expanded(
                  child: _buildMetricRow(
                    LocaleHelper.t('total_sets', 'en'),
                    metrics.totalSets.toString(),
                    Icons.format_list_numbered,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricRow(
                    LocaleHelper.t('total_reps', 'en'),
                    metrics.totalReps.toString(),
                    Icons.repeat,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Volume by muscle group (top 5)
            Text(
              LocaleHelper.t('volume_by_muscle_group', 'en'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...(metrics.volumeByMuscleGroup.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
                .take(5)
                .map((entry) {
                  final percentage = (entry.value / metrics.totalVolume) * 100;
                  return _buildProgressBar(
                    entry.key.toUpperCase(),
                    '${entry.value.toStringAsFixed(0)} kg',
                    percentage / 100,
                    _getMuscleGroupColor(entry.key),
                  );
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthGainsCard() {
    final gains = _report!.gainsReport;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall gains
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleHelper.t('overall_gain', 'en'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${gains.overallGainPercentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: gains.overallGainPercentage > 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      LocaleHelper.t('total_prs', 'en'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          gains.totalPRs.toString(),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Best and slowest gaining exercises
            if (gains.bestGainingExercise.isNotEmpty) ...[
              _buildGainBadge(
                LocaleHelper.t('best_gaining', 'en'),
                gains.bestGainingExercise,
                gains.gainsByExercise[gains.bestGainingExercise]!.gainPercentage,
                Colors.green,
              ),
              const SizedBox(height: 12),
            ],
            if (gains.slowestGainingExercise.isNotEmpty) ...[
              _buildGainBadge(
                LocaleHelper.t('needs_attention', 'en'),
                gains.slowestGainingExercise,
                gains.gainsByExercise[gains.slowestGainingExercise]!.gainPercentage,
                Colors.orange,
              ),
            ],
            const SizedBox(height: 24),

            // Per-exercise gains table
            Text(
              LocaleHelper.t('strength_by_exercise', 'en'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...gains.gainsByExercise.values.take(8).map((exerciseGain) =>
              _buildExerciseGainRow(exerciseGain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionCard() {
    final dist = _report!.distribution;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LocaleHelper.t('muscle_balance', 'en'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: dist.isBalanced ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dist.isBalanced
                        ? LocaleHelper.t('balanced', 'en')
                        : LocaleHelper.t('needs_adjustment', 'en'),
                    style: TextStyle(
                      color: dist.isBalanced ? Colors.green[800] : Colors.orange[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ratios
            Row(
              children: [
                Expanded(
                  child: _buildRatioCard(
                    LocaleHelper.t('push_pull', 'en'),
                    dist.pushPullRatio,
                    1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRatioCard(
                    LocaleHelper.t('upper_lower', 'en'),
                    dist.upperLowerRatio,
                    1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Muscle group percentages
            Text(
              LocaleHelper.t('distribution_by_muscle', 'en'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...(dist.percentageByMuscleGroup.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
                .map((entry) {
                  final isOverdeveloped = dist.overdevelopedGroups.contains(entry.key);
                  final isUnderdeveloped = dist.underdevelopedGroups.contains(entry.key);
                  final color = isOverdeveloped
                      ? Colors.red
                      : isUnderdeveloped
                          ? Colors.orange
                          : _getMuscleGroupColor(entry.key);

                  return _buildProgressBar(
                    entry.key.toUpperCase(),
                    '${entry.value.toStringAsFixed(1)}%',
                    entry.value / 100,
                    color,
                  );
                }),
            const SizedBox(height: 16),

            // Recommendations
            if (dist.recommendations.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 12),
              Text(
                LocaleHelper.t('recommendations', 'en'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...dist.recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Expanded(child: Text(rec, style: Theme.of(context).textTheme.bodySmall)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatternsCard() {
    final patterns = _report!.patterns;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Consistency score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LocaleHelper.t('consistency_score', 'en'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${patterns.consistencyScore}/100',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: _getConsistencyColor(patterns.consistencyScore),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: patterns.consistencyScore / 100,
              backgroundColor: Colors.grey[200],
              color: _getConsistencyColor(patterns.consistencyScore),
            ),
            const SizedBox(height: 24),

            // Metrics grid
            Row(
              children: [
                Expanded(
                  child: _buildPatternMetric(
                    LocaleHelper.t('sessions_per_week', 'en'),
                    patterns.avgSessionsPerWeek.toStringAsFixed(1),
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPatternMetric(
                    LocaleHelper.t('avg_duration', 'en'),
                    '${patterns.avgSessionDuration.toStringAsFixed(0)} min',
                    Icons.timer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Preferred training days
            if (patterns.preferredTrainingDays.isNotEmpty) ...[
              Text(
                LocaleHelper.t('preferred_days', 'en'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildWeekdayIndicator(patterns.preferredTrainingDays),
              const SizedBox(height: 24),
            ],

            // Patterns
            Text(
              LocaleHelper.t('insights', 'en'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...patterns.patterns.map((pattern) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.insights, size: 18, color: DesignTokens.accentBlue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(pattern, style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceCard() {
    final compliance = _report!.compliance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Completion rate
            Text(
              compliance.completionRateDisplay,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: _getComplianceColor(compliance.completionRate),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              LocaleHelper.t('completion_rate', 'en'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildComplianceStat(
                  LocaleHelper.t('completed', 'en'),
                  compliance.completedSessions.toString(),
                  Colors.green,
                ),
                _buildComplianceStat(
                  LocaleHelper.t('planned', 'en'),
                  compliance.plannedSessions.toString(),
                  Colors.blue,
                ),
                _buildComplianceStat(
                  LocaleHelper.t('missed', 'en'),
                  compliance.missedSessions.toString(),
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Trend indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getTrendColor(compliance.trend).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getTrendColor(compliance.trend)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getTrendIcon(compliance.trend), color: _getTrendColor(compliance.trend)),
                  const SizedBox(width: 8),
                  Text(
                    '${LocaleHelper.t('trend', 'en')}: ${compliance.trend}',
                    style: TextStyle(
                      color: _getTrendColor(compliance.trend),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPRTimeline() {
    final prs = _report!.personalRecords;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: prs.take(10).map((pr) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber[700], size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pr.exerciseName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pr.displayValue,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: DesignTokens.accentBlue,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('MMM d').format(pr.achievedDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildImprovementCard() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  LocaleHelper.t('areas_for_improvement', 'en'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._report!.areasForImprovement.map((area) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_forward, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          area,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(String label, String value, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0, 1),
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildGainBadge(String label, String exercise, double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
              ),
              Text(
                exercise,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            '${percentage >= 0 ? '+' : ''}${percentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseGainRow(ExerciseGains gain) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              gain.exerciseName,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              '${gain.startingWeight.toStringAsFixed(1)} → ${gain.currentWeight.toStringAsFixed(1)}kg',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: gain.gainPercentage > 0 ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${gain.gainPercentage >= 0 ? '+' : ''}${gain.gainPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: gain.gainPercentage > 0 ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioCard(String label, double ratio, double ideal) {
    final isBalanced = (ratio - ideal).abs() < 0.3;
    final color = isBalanced ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${ratio.toStringAsFixed(2)}:1',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: DesignTokens.accentBlue),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayIndicator(List<int> preferredDays) {
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final isPreferred = preferredDays.contains(index);
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isPreferred ? DesignTokens.accentBlue : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              dayNames[index],
              style: TextStyle(
                color: isPreferred ? Colors.white : Colors.grey[600],
                fontWeight: isPreferred ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildComplianceStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Color _getMuscleGroupColor(String muscleGroup) {
    final colors = {
      'chest': Colors.blue,
      'back': Colors.green,
      'shoulders': Colors.orange,
      'arms': Colors.purple,
      'legs': Colors.red,
      'core': Colors.teal,
      'quads': Colors.indigo,
      'hamstrings': Colors.pink,
      'glutes': Colors.deepOrange,
      'calves': Colors.cyan,
      'biceps': Colors.deepPurple,
      'triceps': Colors.amber,
    };
    return colors[muscleGroup.toLowerCase()] ?? Colors.grey;
  }

  Color _getConsistencyColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getComplianceColor(double rate) {
    if (rate >= 0.9) return Colors.green;
    if (rate >= 0.7) return Colors.blue;
    if (rate >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  void _exportReport() {
    // TODO: Implement export functionality (PDF, image, share)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(LocaleHelper.t('export_coming_soon', 'en'))),
    );
  }
}
