import 'package:flutter/material.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../theme/design_tokens.dart';

/// Week-by-week progress bar showing completion status
///
/// Shows:
/// - Week completion status
/// - Volume increase indicators
/// - Current week highlight
/// - Deload week markers
///
/// Example:
/// ```dart
/// WeekProgressBar(
///   totalWeeks: 12,
///   currentWeek: 3,
///   completedWeeks: [1, 2],
///   deloadWeeks: [4, 8, 12],
///   weekVolumeChanges: {1: 0, 2: 5.2, 3: 3.1},
/// )
/// ```
class WeekProgressBar extends StatelessWidget {
  final int totalWeeks;
  final int currentWeek;
  final List<int> completedWeeks;
  final List<int> deloadWeeks;
  final Map<int, double>? weekVolumeChanges; // % change from previous week
  final Function(int)? onWeekTap;

  const WeekProgressBar({
    super.key,
    required this.totalWeeks,
    required this.currentWeek,
    this.completedWeeks = const [],
    this.deloadWeeks = const [],
    this.weekVolumeChanges,
    this.onWeekTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
          child: Text(
            LocaleHelper.t('week_progress', language),
            style: DesignTokens.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.space12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
          child: Row(
            children: List.generate(totalWeeks, (index) {
              final weekNumber = index + 1;
              return _buildWeekItem(weekNumber, language);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekItem(int weekNumber, String language) {
    final isCompleted = completedWeeks.contains(weekNumber);
    final isCurrent = weekNumber == currentWeek;
    final isDeload = deloadWeeks.contains(weekNumber);
    final volumeChange = weekVolumeChanges?[weekNumber];

    return GestureDetector(
      onTap: onWeekTap != null ? () => onWeekTap!(weekNumber) : null,
      child: Container(
        width: 60,
        margin: const EdgeInsets.only(right: DesignTokens.space8),
        child: Column(
          children: [
            // Week number container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getWeekColor(isCompleted, isCurrent, isDeload),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent
                      ? DesignTokens.blue600
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: DesignTokens.blue600.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Week number
                  Text(
                    '$weekNumber',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getWeekTextColor(isCompleted, isCurrent, isDeload),
                    ),
                  ),

                  // Completion checkmark
                  if (isCompleted)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Deload marker
                  if (isDeload)
                    Positioned(
                      left: 2,
                      top: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.battery_charging_full,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Volume change indicator
            if (volumeChange != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    volumeChange > 0 ? Icons.trending_up : Icons.trending_down,
                    size: 12,
                    color: volumeChange > 0
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${volumeChange.abs().toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: volumeChange > 0
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              const SizedBox(height: 14),

            const SizedBox(height: 2),

            // Week label
            Text(
              'W$weekNumber',
              style: DesignTokens.labelSmall.copyWith(
                color: isCurrent
                    ? DesignTokens.blue600
                    : DesignTokens.ink500.withValues(alpha: 0.6),
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getWeekColor(bool isCompleted, bool isCurrent, bool isDeload) {
    if (isCompleted) {
      return isDeload
          ? Colors.orange.shade100
          : Colors.green.shade100;
    } else if (isCurrent) {
      return DesignTokens.blue600.withValues(alpha: 0.2);
    } else {
      return DesignTokens.ink500.withValues(alpha: 0.1);
    }
  }

  Color _getWeekTextColor(bool isCompleted, bool isCurrent, bool isDeload) {
    if (isCompleted) {
      return isDeload ? Colors.orange.shade900 : Colors.green.shade900;
    } else if (isCurrent) {
      return DesignTokens.blue600;
    } else {
      return DesignTokens.ink500.withValues(alpha: 0.4);
    }
  }
}