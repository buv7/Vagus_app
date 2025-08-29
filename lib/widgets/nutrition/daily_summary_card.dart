import 'package:flutter/material.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../theme/design_tokens.dart';
import '../../services/share/share_card_service.dart';
import '../../screens/share/share_picker.dart';

class DailySummaryCard extends StatelessWidget {
  final DailySummary summary;
  final bool isCompact;

  const DailySummaryCard({
    super.key,
    required this.summary,
    this.isCompact = false,
  });

  void _showShareOptions(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    final now = DateTime.now();
    final shareData = ShareDataModel(
      title: LocaleHelper.t('daily_totals', language),
      subtitle: '${now.day}/${now.month}/${now.year}',
      metrics: {
        LocaleHelper.t('protein', language): '${summary.totalProtein.toStringAsFixed(1)} g',
        LocaleHelper.t('carbs', language): '${summary.totalCarbs.toStringAsFixed(1)} g',
        LocaleHelper.t('fat', language): '${summary.totalFat.toStringAsFixed(1)} g',
        LocaleHelper.t('calories', language): '${summary.totalKcal.toStringAsFixed(0)} kcal',
      },
      date: now,
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
    // Get global language from context
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    return GestureDetector(
      onLongPress: () => _showShareOptions(context),
      child: Card(
        color: DesignTokens.blue50,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calculate, color: DesignTokens.blue600),
                  const SizedBox(width: DesignTokens.space8),
                  Text(
                    LocaleHelper.t('daily_totals', language),
                    style: DesignTokens.titleMedium.copyWith(
                      color: DesignTokens.blue600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space12),

              // Macros row
              Row(
                children: [
                  Expanded(
                    child: _buildMacroItem(
                      LocaleHelper.t('protein', language),
                      '${summary.totalProtein.toStringAsFixed(1)} g',
                      Colors.red.shade600,
                    ),
                  ),
                  Expanded(
                    child: _buildMacroItem(
                      LocaleHelper.t('carbs', language),
                      '${summary.totalCarbs.toStringAsFixed(1)} g',
                      Colors.orange.shade600,
                    ),
                  ),
                  Expanded(
                    child: _buildMacroItem(
                      LocaleHelper.t('fat', language),
                      '${summary.totalFat.toStringAsFixed(1)} g',
                      Colors.yellow.shade700,
                    ),
                  ),
                  Expanded(
                    child: _buildMacroItem(
                      LocaleHelper.t('calories', language),
                      '${summary.totalKcal.toStringAsFixed(0)} kcal',
                      Colors.green.shade600,
                    ),
                  ),
                ],
              ),

              if (!isCompact) ...[
                const SizedBox(height: DesignTokens.space12),

                // Minerals row
                Row(
                  children: [
                    Expanded(
                      child: _buildMineralItem(
                        LocaleHelper.t('sodium', language),
                        '${summary.totalSodium.toStringAsFixed(0)} mg',
                        summary.totalSodium,
                        isSodium: true,
                      ),
                    ),
                    Expanded(
                      child: _buildMineralItem(
                        LocaleHelper.t('potassium', language),
                        '${summary.totalPotassium.toStringAsFixed(0)} mg',
                        summary.totalPotassium,
                        isSodium: false,
                      ),
                    ),
                  ],
                ),

                // Warnings
                if (_hasWarnings()) ...[
                  const SizedBox(height: DesignTokens.space12),
                  _buildWarnings(language),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        // Label (14sp, medium, 60-70% opacity)
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: DesignTokens.ink500.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        // Value (20-24sp, semibold)
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMineralItem(String label, String value, double amount, {required bool isSodium}) {
    final isHigh = isSodium ? amount > 2300 : amount > 4700;
    final isLow = isSodium ? amount < 500 : amount < 3500;

    Color color = DesignTokens.ink500;
    if (isHigh) {
      color = DesignTokens.danger;
    } else if (isLow) {
      color = DesignTokens.warn;
    }

    return Column(
      children: [
        // Label (14sp, medium, 60-70% opacity)
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: DesignTokens.ink500.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        // Value (20-24sp, semibold)
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  bool _hasWarnings() {
    return summary.totalSodium > 2300 ||
        summary.totalSodium < 500 ||
        summary.totalPotassium > 4700 ||
        summary.totalPotassium < 3500;
  }

  Widget _buildWarnings(String language) {
    final warnings = <String>[];

    if (summary.totalSodium > 2300) {
      warnings.add(LocaleHelper.t('high_sodium', language));
    } else if (summary.totalSodium < 500) {
      warnings.add(LocaleHelper.t('low_sodium', language));
    }

    if (summary.totalPotassium > 4700) {
      warnings.add(LocaleHelper.t('high_potassium', language));
    } else if (summary.totalPotassium < 3500) {
      warnings.add(LocaleHelper.t('low_potassium', language));
    }

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: DesignTokens.warnBg,
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(color: DesignTokens.warn.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: warnings.map((warning) => Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: DesignTokens.warn,
            ),
            const SizedBox(width: DesignTokens.space8),
            Expanded(
              child: Text(
                warning,
                style: DesignTokens.labelMedium.copyWith(
                  color: DesignTokens.warn,
                ),
              ),
            ),
          ],
        )).toList(),
      ),
    );
  }
}