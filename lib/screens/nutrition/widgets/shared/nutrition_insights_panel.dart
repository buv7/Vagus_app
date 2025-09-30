import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../models/nutrition/nutrition_plan.dart';
import '../../../../services/nutrition/locale_helper.dart';
import 'nutrition_card.dart';

/// AI-powered nutrition insights with beautiful animations and sparklines
/// Features: Dynamic insights, meal balance, comparisons, weekly trends
class NutritionInsightsPanel extends StatefulWidget {
  final NutritionPlan plan;
  final NutritionPlan? yesterdayPlan;
  final List<double>? weeklyCalories; // For sparkline trends
  final String userRole;

  const NutritionInsightsPanel({
    super.key,
    required this.plan,
    this.yesterdayPlan,
    this.weeklyCalories,
    this.userRole = 'client',
  });

  @override
  State<NutritionInsightsPanel> createState() => _NutritionInsightsPanelState();
}

class _NutritionInsightsPanelState extends State<NutritionInsightsPanel>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late List<AnimationController> _insightControllers;
  late List<Animation<double>> _insightAnimations;

  List<_InsightItem> _insights = [];

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _generateInsights();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(NutritionInsightsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan.id != widget.plan.id) {
      _generateInsights();
      _initializeAnimations();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    for (final controller in _insightControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _generateInsights() {
    _insights.clear();
    final summary = widget.plan.dailySummary;

    // Generate AI-powered insights
    _generateProteinInsights(summary);
    _generateCalorieInsights(summary);
    _generateFiberInsights(summary);
    _generateHydrationInsights();
    _generateMealBalanceInsights();
    _generateComparisonInsights();
    _generateTrendInsights();
  }

  void _initializeAnimations() {
    // Dispose old controllers
    for (final controller in _insightControllers) {
      controller.dispose();
    }
    _insightControllers = [];
    _insightAnimations = [];

    // Create new controllers
    for (int i = 0; i < _insights.length; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 400 + (i * 150)),
        vsync: this,
      );

      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
      );

      _insightControllers.add(controller);
      _insightAnimations.add(animation);

      // Stagger animations
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) controller.forward();
      });
    }

    _mainController.forward();
  }

  void _generateProteinInsights(DailySummary summary) {
    const proteinTarget = 150.0;
    final proteinProgress = summary.totalProtein / proteinTarget;

    if (proteinProgress >= 1.0) {
      _insights.add(_InsightItem(
        type: _InsightType.success,
        emoji: '💪',
        title: 'Great job! Protein goal crushed',
        description: 'You\'ve hit ${(proteinProgress * 100).toStringAsFixed(0)}% of your protein target. This supports muscle recovery and growth.',
        color: AppTheme.accentGreen,
        intensity: _InsightIntensity.high,
      ));
    } else if (proteinProgress >= 0.8) {
      _insights.add(_InsightItem(
        type: _InsightType.positive,
        emoji: '📈',
        title: 'Almost there with protein!',
        description: 'You\'re at ${(proteinProgress * 100).toStringAsFixed(0)}% of your protein goal. Add a protein-rich snack to complete your target.',
        color: Colors.blue,
        intensity: _InsightIntensity.medium,
      ));
    } else {
      _insights.add(_InsightItem(
        type: _InsightType.warning,
        emoji: '⚠️',
        title: 'Protein intake needs attention',
        description: 'You\'re only at ${(proteinProgress * 100).toStringAsFixed(0)}% of your protein goal. Consider adding lean meats, fish, or legumes.',
        color: Colors.orange,
        intensity: _InsightIntensity.high,
      ));
    }
  }

  void _generateCalorieInsights(DailySummary summary) {
    const calorieTarget = 2000.0;
    final difference = summary.totalKcal - calorieTarget;

    if (difference.abs() <= 100) {
      _insights.add(_InsightItem(
        type: _InsightType.success,
        emoji: '🎯',
        title: 'Perfect calorie balance!',
        description: 'You\'re right on target with ${summary.totalKcal.toStringAsFixed(0)} calories. Great job maintaining your goals!',
        color: AppTheme.accentGreen,
        intensity: _InsightIntensity.medium,
      ));
    } else if (difference < -300) {
      _insights.add(_InsightItem(
        type: _InsightType.alert,
        emoji: '📉',
        title: 'Calories too low today',
        description: 'You\'re ${(-difference).toStringAsFixed(0)} calories below target. Your body needs adequate fuel to function optimally.',
        color: Colors.red,
        intensity: _InsightIntensity.high,
      ));
    } else if (difference > 300) {
      _insights.add(_InsightItem(
        type: _InsightType.caution,
        emoji: '📊',
        title: 'Slight calorie surplus',
        description: 'You\'re ${difference.toStringAsFixed(0)} calories over target. Consider lighter portions or more activity.',
        color: Colors.orange,
        intensity: _InsightIntensity.medium,
      ));
    }
  }

  void _generateFiberInsights(DailySummary summary) {
    // Estimate fiber (not in current model, but we can simulate)
    final estimatedFiber = summary.totalCarbs * 0.15; // Rough estimation
    const fiberTarget = 30.0;

    if (estimatedFiber < 15) {
      _insights.add(_InsightItem(
        type: _InsightType.tip,
        emoji: '🥬',
        title: 'Boost your fiber intake',
        description: 'You\'re low on fiber today (~${estimatedFiber.toStringAsFixed(0)}g / ${fiberTarget.toStringAsFixed(0)}g). Add more vegetables, fruits, and whole grains.',
        color: Colors.green,
        intensity: _InsightIntensity.medium,
      ));
    }
  }

  void _generateHydrationInsights() {
    // Simulate hydration tracking
    final glassesConsumed = 4; // This would come from actual tracking
    const targetGlasses = 8;

    if (glassesConsumed < 6) {
      _insights.add(_InsightItem(
        type: _InsightType.reminder,
        emoji: '💧',
        title: 'Remember to hydrate!',
        description: 'Only $glassesConsumed glasses so far. Aim for $targetGlasses glasses daily, especially with your current protein intake.',
        color: Colors.blue,
        intensity: _InsightIntensity.medium,
      ));
    }
  }

  void _generateMealBalanceInsights() {
    final summary = widget.plan.dailySummary;
    final totalCals = summary.totalKcal;

    if (totalCals > 0) {
      final proteinPercent = (summary.totalProtein * 4 / totalCals * 100);
      final carbsPercent = (summary.totalCarbs * 4 / totalCals * 100);
      final fatPercent = (summary.totalFat * 9 / totalCals * 100);

      // Check if carbs are too high
      if (carbsPercent > 60) {
        _insights.add(_InsightItem(
          type: _InsightType.info,
          emoji: '⚖️',
          title: 'Carb-heavy day detected',
          description: 'Carbs: ${carbsPercent.toStringAsFixed(0)}% (target ~50%). Consider balancing with more protein and healthy fats.',
          color: Colors.purple,
          intensity: _InsightIntensity.low,
        ));
      }
    }
  }

  void _generateComparisonInsights() {
    if (widget.yesterdayPlan == null) return;

    final todayCalories = widget.plan.dailySummary.totalKcal;
    final yesterdayCalories = widget.yesterdayPlan!.dailySummary.totalKcal;
    final difference = todayCalories - yesterdayCalories;

    if (difference.abs() > 200) {
      final isHigher = difference > 0;
      _insights.add(_InsightItem(
        type: _InsightType.comparison,
        emoji: isHigher ? '↗️' : '↘️',
        title: '${isHigher ? '+' : ''}${difference.toStringAsFixed(0)} kcal vs yesterday',
        description: 'You\'re eating ${difference.abs().toStringAsFixed(0)} calories ${isHigher ? 'more' : 'less'} than yesterday. ${isHigher ? 'Make sure this aligns with your goals.' : 'Ensure you\'re getting adequate nutrition.'}',
        color: isHigher ? Colors.orange : Colors.blue,
        intensity: _InsightIntensity.low,
      ));
    }
  }

  void _generateTrendInsights() {
    if (widget.weeklyCalories == null || widget.weeklyCalories!.length < 3) return;

    final calories = widget.weeklyCalories!;
    final recentAvg = calories.take(3).reduce((a, b) => a + b) / 3;
    final olderAvg = calories.skip(3).take(3).reduce((a, b) => a + b) / 3;
    final trendDiff = recentAvg - olderAvg;

    if (trendDiff.abs() > 150) {
      final isIncreasing = trendDiff > 0;
      _insights.add(_InsightItem(
        type: _InsightType.trend,
        emoji: isIncreasing ? '📈' : '📉',
        title: 'Weekly trend: ${isIncreasing ? 'Increasing' : 'Decreasing'} calories',
        description: '${isIncreasing ? 'Up' : 'Down'} ${trendDiff.abs().toStringAsFixed(0)} kcal/day this week vs last. ${isIncreasing ? 'Watch your targets.' : 'Ensure adequate nutrition.'}',
        color: isIncreasing ? Colors.red : Colors.green,
        intensity: _InsightIntensity.low,
        sparklineData: calories,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    if (_insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return NutritionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with AI badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGreen,
                      AppTheme.accentGreen.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleHelper.t('ai_insights', locale),
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      LocaleHelper.t('personalized_recommendations', locale),
                      style: const TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space8,
                  vertical: DesignTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.psychology,
                      size: 12,
                      color: AppTheme.accentGreen,
                    ),
                    const SizedBox(width: DesignTokens.space4),
                    Text(
                      'AI',
                      style: TextStyle(
                        color: AppTheme.accentGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.space20),

          // Insights list
          ..._insights.asMap().entries.map((entry) {
            final index = entry.key;
            final insight = entry.value;

            if (index >= _insightAnimations.length) {
              return _buildInsightCard(insight);
            }

            return AnimatedBuilder(
              animation: _insightAnimations[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _insightAnimations[index].value)),
                  child: Opacity(
                    opacity: _insightAnimations[index].value,
                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: index < _insights.length - 1 ? DesignTokens.space12 : 0,
                      ),
                      child: _buildInsightCard(insight),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightCard(_InsightItem insight) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: insight.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: insight.color.withOpacity(0.3),
          width: insight.intensity == _InsightIntensity.high ? 2 : 1,
        ),
        boxShadow: insight.intensity == _InsightIntensity.high
          ? [
              BoxShadow(
                color: insight.color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: insight.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: Center(
              child: Text(
                insight.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),

          const SizedBox(width: DesignTokens.space12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        insight.title,
                        style: TextStyle(
                          color: insight.color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildInsightTypeIcon(insight.type),
                  ],
                ),

                const SizedBox(height: DesignTokens.space4),

                Text(
                  insight.description,
                  style: const TextStyle(
                    color: AppTheme.lightGrey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                // Sparkline for trend insights
                if (insight.sparklineData != null) ...[
                  const SizedBox(height: DesignTokens.space8),
                  _buildSparkline(insight.sparklineData!, insight.color),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightTypeIcon(_InsightType type) {
    IconData icon;
    Color color;

    switch (type) {
      case _InsightType.success:
        icon = Icons.check_circle;
        color = AppTheme.accentGreen;
        break;
      case _InsightType.positive:
        icon = Icons.trending_up;
        color = Colors.blue;
        break;
      case _InsightType.warning:
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case _InsightType.alert:
        icon = Icons.error;
        color = Colors.red;
        break;
      case _InsightType.tip:
        icon = Icons.lightbulb_outline;
        color = Colors.green;
        break;
      case _InsightType.reminder:
        icon = Icons.notifications_outlined;
        color = Colors.blue;
        break;
      case _InsightType.info:
        icon = Icons.info_outline;
        color = Colors.purple;
        break;
      case _InsightType.comparison:
        icon = Icons.compare_arrows;
        color = Colors.grey;
        break;
      case _InsightType.trend:
        icon = Icons.show_chart;
        color = Colors.grey;
        break;
      case _InsightType.caution:
        icon = Icons.priority_high;
        color = Colors.orange;
        break;
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  Widget _buildSparkline(List<double> data, Color color) {
    return Container(
      height: 30,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(data: data, color: color),
      ),
    );
  }
}

class _InsightItem {
  final _InsightType type;
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final _InsightIntensity intensity;
  final List<double>? sparklineData;

  _InsightItem({
    required this.type,
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.intensity,
    this.sparklineData,
  });
}

enum _InsightType {
  success,
  positive,
  warning,
  alert,
  tip,
  reminder,
  info,
  comparison,
  trend,
  caution,
}

enum _InsightIntensity {
  low,
  medium,
  high,
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final max = data.reduce((a, b) => a > b ? a : b);
    final min = data.reduce((a, b) => a < b ? a : b);
    final range = max - min;

    if (range == 0) return;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - min) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}