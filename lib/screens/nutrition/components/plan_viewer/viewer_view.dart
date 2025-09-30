import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../models/nutrition/nutrition_plan.dart';
import '../../../../services/nutrition/locale_helper.dart';
import '../../widgets/shared/nutrition_card.dart';
import '../../widgets/shared/macro_ring_chart.dart';
import '../../widgets/shared/empty_state_widget.dart';
import '../meal_detail/meal_detail_modal.dart';
import 'macro_progress_rings.dart';
import 'meal_timeline_card.dart';
import 'daily_insights_panel.dart';

/// Beautiful viewer for nutrition plans with rich visualizations
class ViewerView extends StatefulWidget {
  final NutritionPlan? currentPlan;
  final List<NutritionPlan> allPlans;
  final String userRole;
  final Function(String)? onPlanSelected;
  final VoidCallback? onEditPlan;

  const ViewerView({
    super.key,
    required this.currentPlan,
    required this.allPlans,
    required this.userRole,
    this.onPlanSelected,
    this.onEditPlan,
  });

  @override
  State<ViewerView> createState() => _ViewerViewState();
}

class _ViewerViewState extends State<ViewerView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    if (widget.currentPlan == null) {
      return EmptyStateWidget(
        type: EmptyStateType.noPlans,
        onActionPressed: widget.userRole == 'coach' ? widget.onEditPlan : null,
      );
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan header with metadata
                  _buildPlanHeader(locale),

                  const SizedBox(height: DesignTokens.space24),

                  // Macro progress rings
                  MacroProgressRings(
                    plan: widget.currentPlan!,
                    animated: true,
                  ),

                  const SizedBox(height: DesignTokens.space24),

                  // Meals timeline
                  _buildMealsSection(locale),

                  const SizedBox(height: DesignTokens.space24),

                  // Daily insights
                  DailyInsightsPanel(
                    plan: widget.currentPlan!,
                    userRole: widget.userRole,
                  ),

                  const SizedBox(height: DesignTokens.space24),

                  // Quick actions
                  _buildQuickActions(locale),

                  const SizedBox(height: DesignTokens.space48), // Bottom padding
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlanHeader(String locale) {
    final plan = widget.currentPlan!;

    return NutritionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Plan type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getPlanTypeColor(plan.lengthType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                ),
                child: Icon(
                  _getPlanTypeIcon(plan.lengthType),
                  color: _getPlanTypeColor(plan.lengthType),
                  size: 24,
                ),
              ),

              const SizedBox(width: DesignTokens.space16),

              // Plan info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space8,
                            vertical: DesignTokens.space4,
                          ),
                          decoration: BoxDecoration(
                            color: _getPlanTypeColor(plan.lengthType),
                            borderRadius: BorderRadius.circular(DesignTokens.radius8),
                          ),
                          child: Text(
                            _getPlanTypeLabel(plan.lengthType, locale),
                            style: const TextStyle(
                              color: AppTheme.primaryDark,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.space8),
                        if (plan.aiGenerated)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.space8,
                              vertical: DesignTokens.space4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(DesignTokens.radius8),
                              border: Border.all(
                                color: AppTheme.accentGreen.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 10,
                                  color: AppTheme.accentGreen,
                                ),
                                const SizedBox(width: DesignTokens.space4),
                                Text(
                                  'AI Generated',
                                  style: TextStyle(
                                    color: AppTheme.accentGreen,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit button (for coaches)
              if (widget.userRole == 'coach' && widget.onEditPlan != null)
                IconButton(
                  onPressed: widget.onEditPlan,
                  icon: const Icon(
                    Icons.edit,
                    color: AppTheme.accentGreen,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: DesignTokens.space16),

          // Plan metadata
          Row(
            children: [
              _buildMetadataChip(
                Icons.calendar_today,
                _formatDate(plan.createdAt),
                AppTheme.lightGrey,
              ),
              const SizedBox(width: DesignTokens.space8),
              _buildMetadataChip(
                Icons.restaurant_menu,
                '${plan.meals.length} ${LocaleHelper.t('meals', locale)}',
                AppTheme.accentOrange,
              ),
              const SizedBox(width: DesignTokens.space8),
              _buildMetadataChip(
                Icons.local_fire_department,
                '${plan.dailySummary.totalKcal.toStringAsFixed(0)} ${LocaleHelper.t('kcal', locale)}',
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space8,
        vertical: DesignTokens.space4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: DesignTokens.space4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsSection(String locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              LocaleHelper.t('todays_meals', locale),
              style: const TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${widget.currentPlan!.meals.length} ${LocaleHelper.t('meals', locale)}',
              style: const TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.space16),

        // Meals list
        ...widget.currentPlan!.meals.asMap().entries.map((entry) {
          final index = entry.key;
          final meal = entry.value;

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: DesignTokens.space12),
                    child: MealTimelineCard(
                      meal: meal,
                      index: index,
                      onTap: () => _showMealDetails(meal),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildQuickActions(String locale) {
    return NutritionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleHelper.t('quick_actions', locale),
            style: const TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: DesignTokens.space16),

          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.picture_as_pdf,
                  label: LocaleHelper.t('export_pdf', locale),
                  color: Colors.red,
                  onPressed: _exportToPdf,
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.shopping_cart,
                  label: LocaleHelper.t('grocery_list', locale),
                  color: Colors.green,
                  onPressed: _generateGroceryList,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.space8),

          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.calendar_today,
                  label: LocaleHelper.t('add_to_calendar', locale),
                  color: Colors.blue,
                  onPressed: _addToCalendar,
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share,
                  label: LocaleHelper.t('share', locale),
                  color: Colors.purple,
                  onPressed: _sharePlan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          vertical: DesignTokens.space12,
          horizontal: DesignTokens.space8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius8),
          side: BorderSide(
            color: color.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  void _showMealDetails(Meal meal) {
    MealDetailModal.show(
      context,
      meal: meal,
      userRole: widget.userRole,
      isReadOnly: widget.userRole == 'client',
    );
  }

  void _exportToPdf() {
    // TODO: Implement PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF export coming soon')),
    );
  }

  void _generateGroceryList() {
    // TODO: Implement grocery list generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grocery list generation coming soon')),
    );
  }

  void _addToCalendar() {
    // TODO: Implement calendar integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calendar integration coming soon')),
    );
  }

  void _sharePlan() {
    // TODO: Implement plan sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan sharing coming soon')),
    );
  }

  Color _getPlanTypeColor(String lengthType) {
    switch (lengthType) {
      case 'daily':
        return AppTheme.accentGreen;
      case 'weekly':
        return AppTheme.accentOrange;
      case 'program':
        return Colors.purple;
      default:
        return AppTheme.lightGrey;
    }
  }

  IconData _getPlanTypeIcon(String lengthType) {
    switch (lengthType) {
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.view_week;
      case 'program':
        return Icons.assignment;
      default:
        return Icons.help_outline;
    }
  }

  String _getPlanTypeLabel(String lengthType, String locale) {
    switch (lengthType) {
      case 'daily':
        return LocaleHelper.t('daily', locale);
      case 'weekly':
        return LocaleHelper.t('weekly', locale);
      case 'program':
        return LocaleHelper.t('program', locale);
      default:
        return LocaleHelper.t('unknown', locale);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}