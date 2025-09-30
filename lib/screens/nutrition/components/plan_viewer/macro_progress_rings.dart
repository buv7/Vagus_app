import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../models/nutrition/nutrition_plan.dart';
import '../../../../services/nutrition/locale_helper.dart';
import '../../widgets/shared/macro_ring_chart.dart';
import '../../widgets/shared/nutrition_card.dart';

/// Animated macro progress rings with detailed breakdown
class MacroProgressRings extends StatefulWidget {
  final NutritionPlan plan;
  final bool animated;
  final bool showTargets;

  const MacroProgressRings({
    super.key,
    required this.plan,
    this.animated = true,
    this.showTargets = true,
  });

  @override
  State<MacroProgressRings> createState() => _MacroProgressRingsState();
}

class _MacroProgressRingsState extends State<MacroProgressRings>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // Default macro targets (can be customized per plan in future)
  final Map<String, double> _defaultTargets = {
    'protein': 150.0, // grams
    'carbs': 200.0,   // grams
    'fat': 80.0,      // grams
    'calories': 2000.0, // kcal
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    if (widget.animated) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final summary = widget.plan.dailySummary;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: NutritionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      LocaleHelper.t('daily_progress', locale),
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space8,
                        vertical: DesignTokens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                      ),
                      child: Text(
                        '${_calculateOverallProgress()}%',
                        style: const TextStyle(
                          color: AppTheme.accentGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DesignTokens.space24),

                // Multi-ring chart
                Center(
                  child: MultiMacroRingChart(
                    protein: summary.totalProtein,
                    proteinTarget: _defaultTargets['protein']!,
                    carbs: summary.totalCarbs,
                    carbsTarget: _defaultTargets['carbs']!,
                    fat: summary.totalFat,
                    fatTarget: _defaultTargets['fat']!,
                    size: 200,
                    showLabels: true,
                  ),
                ),

                const SizedBox(height: DesignTokens.space24),

                // Individual macro cards
                Row(
                  children: [
                    Expanded(
                      child: _buildMacroCard(
                        LocaleHelper.t('protein', locale),
                        summary.totalProtein,
                        _defaultTargets['protein']!,
                        'g',
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space8),
                    Expanded(
                      child: _buildMacroCard(
                        LocaleHelper.t('carbs', locale),
                        summary.totalCarbs,
                        _defaultTargets['carbs']!,
                        'g',
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space8),
                    Expanded(
                      child: _buildMacroCard(
                        LocaleHelper.t('fat', locale),
                        summary.totalFat,
                        _defaultTargets['fat']!,
                        'g',
                        Colors.yellow.shade700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DesignTokens.space16),

                // Calories card
                _buildCaloriesCard(
                  summary.totalKcal,
                  _defaultTargets['calories']!,
                  locale,
                ),

                if (widget.showTargets) ...[
                  const SizedBox(height: DesignTokens.space16),
                  _buildTargetsInfo(locale),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMacroCard(
    String label,
    double current,
    double target,
    String unit,
    Color color,
  ) {
    final percentage = ((current / target) * 100).round();
    final isOverTarget = current > target;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            '${current.toStringAsFixed(0)}$unit',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (current / target).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isOverTarget ? Colors.orange : color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            '$percentage%',
            style: TextStyle(
              color: isOverTarget ? Colors.orange : color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesCard(double current, double target, String locale) {
    final percentage = ((current / target) * 100).round();
    final remaining = target - current;
    final isOverTarget = current > target;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: AppTheme.accentGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppTheme.accentGreen,
              size: 24,
            ),
          ),

          const SizedBox(width: DesignTokens.space16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleHelper.t('calories', locale),
                  style: const TextStyle(
                    color: AppTheme.lightGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                Row(
                  children: [
                    Text(
                      '${current.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / ${target.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space8),
                LinearProgressIndicator(
                  value: (current / target).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.mediumGrey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverTarget ? Colors.orange : AppTheme.accentGreen,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: DesignTokens.space16),

          Column(
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  color: isOverTarget ? Colors.orange : AppTheme.accentGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: DesignTokens.space4),
              Text(
                isOverTarget
                  ? '+${(current - target).toStringAsFixed(0)}'
                  : '${remaining.toStringAsFixed(0)} left',
                style: TextStyle(
                  color: isOverTarget ? Colors.orange : AppTheme.lightGrey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetsInfo(String locale) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: AppTheme.mediumGrey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.lightGrey,
                size: 16,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                LocaleHelper.t('daily_targets', locale),
                style: const TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'P: ${_defaultTargets['protein']!.toStringAsFixed(0)}g • '
            'C: ${_defaultTargets['carbs']!.toStringAsFixed(0)}g • '
            'F: ${_defaultTargets['fat']!.toStringAsFixed(0)}g • '
            'Cal: ${_defaultTargets['calories']!.toStringAsFixed(0)}kcal',
            style: const TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateOverallProgress() {
    final summary = widget.plan.dailySummary;

    final proteinProgress = (summary.totalProtein / _defaultTargets['protein']!).clamp(0.0, 1.0);
    final carbsProgress = (summary.totalCarbs / _defaultTargets['carbs']!).clamp(0.0, 1.0);
    final fatProgress = (summary.totalFat / _defaultTargets['fat']!).clamp(0.0, 1.0);

    final averageProgress = (proteinProgress + carbsProgress + fatProgress) / 3;
    return (averageProgress * 100).round();
  }
}