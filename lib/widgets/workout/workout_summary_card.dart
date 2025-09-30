import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/workout/workout_plan.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../theme/design_tokens.dart';
import '../../services/share/share_card_service.dart';
import '../../screens/share/share_picker.dart';

/// Workout summary card displaying weekly metrics and progress
///
/// Shows:
/// - Weekly volume (total tonnage)
/// - Training duration
/// - Muscle group distribution pie chart
/// - Rest day indicators
/// - Progress vs previous week
///
/// Example:
/// ```dart
/// WorkoutSummaryCard(
///   summary: weekSummary,
///   previousWeekSummary: lastWeekSummary,
///   isCompact: false,
/// )
/// ```
class WorkoutSummaryCard extends StatelessWidget {
  final WeeklySummary summary;
  final WeeklySummary? previousWeekSummary;
  final bool isCompact;

  const WorkoutSummaryCard({
    Key? key,
    required this.summary,
    this.previousWeekSummary,
    this.isCompact = false,
  }) : super(key: key);

  void _showShareOptions(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    final shareData = ShareDataModel(
      title: LocaleHelper.t('weekly_summary', language),
      subtitle: 'Week ${summary.weekNumber}',
      metrics: {
        LocaleHelper.t('total_volume', language): '${summary.totalVolume.toStringAsFixed(0)} kg',
        LocaleHelper.t('training_days', language): '${summary.completedDays}',
        LocaleHelper.t('total_duration', language): '${summary.totalDuration} min',
        LocaleHelper.t('total_sets', language): '${summary.totalSets}',
      },
      date: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharePicker(data: shareData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    return GestureDetector(
      onLongPress: () => _showShareOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.accentBlue.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.fitness_center, color: DesignTokens.blue600),
                      const SizedBox(width: DesignTokens.space8),
                      Text(
                        LocaleHelper.t('weekly_summary', language),
                        style: DesignTokens.titleMedium.copyWith(
                          color: DesignTokens.blue600,
                        ),
                      ),
                      const Spacer(),
                      if (!isCompact)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space8,
                            vertical: DesignTokens.space4,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.blue600.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(DesignTokens.radius8),
                          ),
                          child: Text(
                            'Week ${summary.weekNumber}',
                            style: DesignTokens.labelSmall.copyWith(
                              color: DesignTokens.blue600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space16),

                  // Key metrics row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          LocaleHelper.t('volume', language),
                          '${summary.totalVolume.toStringAsFixed(0)} kg',
                          Colors.purple.shade600,
                          _getVolumeChange(),
                        ),
                      ),
                      Expanded(
                        child: _buildMetricItem(
                          LocaleHelper.t('duration', language),
                          '${summary.totalDuration} min',
                          Colors.blue.shade600,
                          _getDurationChange(),
                        ),
                      ),
                      Expanded(
                        child: _buildMetricItem(
                          LocaleHelper.t('sets', language),
                          '${summary.totalSets}',
                          Colors.green.shade600,
                          _getSetsChange(),
                        ),
                      ),
                    ],
                  ),

                  if (!isCompact) ...[
                    const SizedBox(height: DesignTokens.space16),

                    // Training days and rest days
                    Row(
                      children: [
                        Expanded(
                          child: _buildDayIndicators(language),
                        ),
                        const SizedBox(width: DesignTokens.space16),
                        if (summary.muscleGroupDistribution.isNotEmpty)
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: _buildMuscleGroupChart(),
                          ),
                      ],
                    ),

                    // Progress comparison
                    if (previousWeekSummary != null) ...[
                      const SizedBox(height: DesignTokens.space12),
                      _buildProgressComparison(language),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color, double? change) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: DesignTokens.ink500.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (change != null) ...[
          const SizedBox(height: DesignTokens.space4),
          _buildChangeIndicator(change),
        ],
      ],
    );
  }

  Widget _buildChangeIndicator(double change) {
    final isPositive = change > 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          '${change.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDayIndicators(String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleHelper.t('training_days', language),
          style: DesignTokens.labelMedium.copyWith(
            color: DesignTokens.ink500.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: DesignTokens.space8),
        Wrap(
          spacing: DesignTokens.space8,
          runSpacing: DesignTokens.space8,
          children: List.generate(7, (index) {
            final dayNum = index + 1;
            final isCompleted = summary.completedDays >= dayNum;
            final isRestDay = summary.restDays.contains(dayNum);

            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isRestDay
                    ? Colors.grey.shade300
                    : isCompleted
                        ? DesignTokens.blue600
                        : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isRestDay
                      ? Colors.grey.shade400
                      : isCompleted
                          ? DesignTokens.blue600
                          : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: isRestDay
                    ? Icon(
                        Icons.hotel,
                        size: 16,
                        color: Colors.grey.shade600,
                      )
                    : Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? Colors.white
                              : DesignTokens.ink500.withValues(alpha: 0.4),
                        ),
                      ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMuscleGroupChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: _buildPieSections(),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    final entries = summary.muscleGroupDistribution.entries.toList();
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final muscleEntry = entry.value;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: muscleEntry.value.toDouble(),
        title: muscleEntry.value > 5 ? '${muscleEntry.value}' : '',
        radius: 35,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildProgressComparison(String language) {
    final volumeChange = _getVolumeChange();
    final durationChange = _getDurationChange();

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: DesignTokens.blue600.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(
          color: DesignTokens.blue600.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            size: 16,
            color: DesignTokens.blue600,
          ),
          const SizedBox(width: DesignTokens.space8),
          Expanded(
            child: Text(
              volumeChange != null && volumeChange > 0
                  ? LocaleHelper.t('volume_increased', language)
                  : LocaleHelper.t('volume_decreased', language),
              style: DesignTokens.labelMedium.copyWith(
                color: DesignTokens.blue600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double? _getVolumeChange() {
    if (previousWeekSummary == null || previousWeekSummary!.totalVolume == 0) {
      return null;
    }
    return ((summary.totalVolume - previousWeekSummary!.totalVolume) /
            previousWeekSummary!.totalVolume) *
        100;
  }

  double? _getDurationChange() {
    if (previousWeekSummary == null || previousWeekSummary!.totalDuration == 0) {
      return null;
    }
    return ((summary.totalDuration - previousWeekSummary!.totalDuration) /
            previousWeekSummary!.totalDuration) *
        100;
  }

  double? _getSetsChange() {
    if (previousWeekSummary == null || previousWeekSummary!.totalSets == 0) {
      return null;
    }
    return ((summary.totalSets - previousWeekSummary!.totalSets) /
            previousWeekSummary!.totalSets) *
        100;
  }
}