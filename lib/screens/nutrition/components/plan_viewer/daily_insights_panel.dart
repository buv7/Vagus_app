import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../models/nutrition/nutrition_plan.dart';
import '../../../../services/nutrition/locale_helper.dart';
import '../../widgets/shared/nutrition_card.dart';

/// Intelligent insights panel that provides contextual nutrition advice
class DailyInsightsPanel extends StatefulWidget {
  final NutritionPlan plan;
  final String userRole;

  const DailyInsightsPanel({
    super.key,
    required this.plan,
    required this.userRole,
  });

  @override
  State<DailyInsightsPanel> createState() => _DailyInsightsPanelState();
}

class _DailyInsightsPanelState extends State<DailyInsightsPanel>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;

  final List<_InsightItem> _insights = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _generateInsights();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(DailyInsightsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan.id != widget.plan.id) {
      _generateInsights();
      _initializeAnimations();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _generateInsights() {
    _insights.clear();
    final summary = widget.plan.dailySummary;
    
    // Get primary color from context - will be updated in didChangeDependencies
    final primaryColor = _primaryColor ?? AppTheme.accentGreen;

    // Analyze macros and generate insights
    _analyzeProtein(summary, primaryColor);
    _analyzeCarbs(summary, primaryColor);
    _analyzeFat(summary, primaryColor);
    _analyzeCalories(summary);
    _analyzeMealDistribution(primaryColor);
    _analyzeHydration();
    _analyzeMicronutrients(summary);
  }
  
  Color? _primaryColor;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _primaryColor = Theme.of(context).colorScheme.primary;
    // Regenerate insights with correct theme color
    _generateInsights();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Dispose old controllers
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    _itemControllers = [];
    _itemAnimations = [];

    // Create new controllers for each insight
    for (int i = 0; i < _insights.length; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 300 + (i * 100)),
        vsync: this,
      );
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
      );

      _itemControllers.add(controller);
      _itemAnimations.add(animation);

      // Stagger the animations
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) controller.forward();
      });
    }
  }

  void _analyzeProtein(DailySummary summary, Color primaryColor) {
    const proteinTarget = 150.0; // This could be dynamic per user
    final proteinPercentage = (summary.totalProtein / proteinTarget * 100).round();

    if (proteinPercentage >= 90) {
      _insights.add(_InsightItem(
        type: _InsightType.success,
        icon: Icons.fitness_center,
        title: 'Excellent Protein Intake',
        description: 'You\'re meeting your protein goals! This supports muscle recovery and growth.',
        color: primaryColor,
      ));
    } else if (proteinPercentage >= 70) {
      _insights.add(_InsightItem(
        type: _InsightType.warning,
        icon: Icons.trending_up,
        title: 'Good Protein Progress',
        description: 'Consider adding a protein snack to hit your target for optimal recovery.',
        color: Colors.orange,
      ));
    } else {
      _insights.add(_InsightItem(
        type: _InsightType.alert,
        icon: Icons.warning_outlined,
        title: 'Low Protein Intake',
        description: 'Add lean protein sources like chicken, fish, or legumes to your meals.',
        color: Colors.red,
      ));
    }
  }

  void _analyzeCarbs(DailySummary summary, Color primaryColor) {
    const carbsTarget = 200.0;
    final carbsPercentage = (summary.totalCarbs / carbsTarget * 100).round();

    if (carbsPercentage >= 80 && carbsPercentage <= 120) {
      _insights.add(_InsightItem(
        type: _InsightType.success,
        icon: Icons.battery_charging_full,
        title: 'Great Energy Balance',
        description: 'Your carb intake is perfect for sustained energy throughout the day.',
        color: primaryColor,
      ));
    } else if (carbsPercentage < 60) {
      _insights.add(_InsightItem(
        type: _InsightType.tip,
        icon: Icons.battery_alert,
        title: 'Energy Boost Needed',
        description: 'Add complex carbs like oats, quinoa, or sweet potatoes for steady energy.',
        color: Colors.blue,
      ));
    }
  }

  void _analyzeFat(DailySummary summary, Color primaryColor) {
    const fatTarget = 80.0;
    final fatPercentage = (summary.totalFat / fatTarget * 100).round();

    if (fatPercentage >= 70 && fatPercentage <= 110) {
      _insights.add(_InsightItem(
        type: _InsightType.success,
        icon: Icons.favorite,
        title: 'Healthy Fat Balance',
        description: 'Good mix of healthy fats for hormone production and nutrient absorption.',
        color: primaryColor,
      ));
    } else if (fatPercentage < 50) {
      _insights.add(_InsightItem(
        type: _InsightType.tip,
        icon: Icons.eco,
        title: 'Add Healthy Fats',
        description: 'Include avocado, nuts, olive oil, or fatty fish for essential nutrients.',
        color: Colors.green,
      ));
    }
  }

  void _analyzeCalories(DailySummary summary) {
    const calorieTarget = 2000.0;
    final calorieDeficit = calorieTarget - summary.totalKcal;

    if (calorieDeficit > 500) {
      _insights.add(_InsightItem(
        type: _InsightType.alert,
        icon: Icons.restaurant,
        title: 'Calories Too Low',
        description: 'You need ${calorieDeficit.toStringAsFixed(0)} more calories to meet your goals.',
        color: Colors.red,
      ));
    } else if (calorieDeficit < -200) {
      _insights.add(_InsightItem(
        type: _InsightType.warning,
        icon: Icons.warning,
        title: 'Slightly Over Target',
        description: 'Consider lighter snacks or smaller portions to stay on track.',
        color: Colors.orange,
      ));
    }
  }

  void _analyzeMealDistribution(Color primaryColor) {
    final mealCount = widget.plan.meals.length;

    if (mealCount >= 5) {
      _insights.add(_InsightItem(
        type: _InsightType.success,
        icon: Icons.schedule,
        title: 'Great Meal Frequency',
        description: 'Eating $mealCount times helps maintain stable blood sugar and metabolism.',
        color: primaryColor,
      ));
    } else if (mealCount <= 2) {
      _insights.add(_InsightItem(
        type: _InsightType.tip,
        icon: Icons.timer,
        title: 'Consider More Meals',
        description: 'Adding healthy snacks can help maintain energy and prevent overeating.',
        color: Colors.blue,
      ));
    }
  }

  void _analyzeHydration() {
    // Placeholder for hydration analysis
    _insights.add(_InsightItem(
      type: _InsightType.tip,
      icon: Icons.water_drop,
      title: 'Stay Hydrated',
      description: 'Aim for 8-10 glasses of water daily, especially with your current protein intake.',
      color: Colors.blue,
    ));
  }

  void _analyzeMicronutrients(DailySummary summary) {
    // Sodium analysis
    if (summary.totalSodium > 2300) {
      _insights.add(_InsightItem(
        type: _InsightType.warning,
        icon: Icons.health_and_safety,
        title: 'High Sodium Intake',
        description: 'Try to reduce processed foods and add more fresh ingredients.',
        color: Colors.orange,
      ));
    }

    // Potassium analysis
    if (summary.totalPotassium < 3500) {
      _insights.add(_InsightItem(
        type: _InsightType.tip,
        icon: Icons.eco,
        title: 'Boost Potassium',
        description: 'Add bananas, spinach, or potatoes for better heart health.',
        color: Colors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    if (_insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return NutritionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleHelper.t('daily_insights', locale),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      LocaleHelper.t('personalized_nutrition_tips', locale),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Text(
                  '${_insights.length}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.space20),

          // Insights list
          ..._insights.asMap().entries.map((entry) {
            final index = entry.key;
            final insight = entry.value;

            if (index >= _itemAnimations.length) {
              return const SizedBox.shrink();
            }

            return AnimatedBuilder(
              animation: _itemAnimations[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _itemAnimations[index].value)),
                  child: Opacity(
                    opacity: _itemAnimations[index].value,
                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: index < _insights.length - 1
                          ? DesignTokens.space12
                          : 0,
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
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(
          color: insight.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: Icon(
              insight.icon,
              color: insight.color,
              size: 18,
            ),
          ),

          const SizedBox(width: DesignTokens.space12),

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
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightTypeIcon(_InsightType type) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;

    switch (type) {
      case _InsightType.success:
        icon = Icons.check_circle;
        color = theme.colorScheme.primary;
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
        icon = Icons.tips_and_updates;
        color = Colors.blue;
        break;
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }
}

class _InsightItem {
  final _InsightType type;
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _InsightItem({
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

enum _InsightType {
  success,
  warning,
  alert,
  tip,
}