import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../models/nutrition/nutrition_plan.dart';
import '../../../../services/nutrition/locale_helper.dart';
import '../../widgets/shared/nutrition_card.dart';
import 'food_list_panel.dart';
import 'macro_breakdown_chart.dart';
import 'attachments_gallery.dart';
import 'comments_thread.dart';

/// Unified meal detail modal that replaces all fragmented meal detail sheets
/// Features: glassmorphism design, smooth animations, comprehensive meal info
class MealDetailModal extends StatefulWidget {
  final Meal meal;
  final String userRole;
  final bool isReadOnly;
  final Function(Meal)? onMealUpdated;
  final Function(String)? onAddFood;
  final Function()? onAddAttachment;

  const MealDetailModal({
    super.key,
    required this.meal,
    required this.userRole,
    this.isReadOnly = false,
    this.onMealUpdated,
    this.onAddFood,
    this.onAddAttachment,
  });

  /// Show the meal detail modal with beautiful animations
  static Future<T?> show<T>(
    BuildContext context, {
    required Meal meal,
    required String userRole,
    bool isReadOnly = false,
    Function(Meal)? onMealUpdated,
    Function(String)? onAddFood,
    Function()? onAddAttachment,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close meal details',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return MealDetailModal(
          meal: meal,
          userRole: userRole,
          isReadOnly: isReadOnly,
          onMealUpdated: onMealUpdated,
          onAddFood: onAddFood,
          onAddAttachment: onAddAttachment,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<MealDetailModal> createState() => _MealDetailModalState();
}

class _MealDetailModalState extends State<MealDetailModal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  late Meal _currentMeal;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentMeal = widget.meal;
    _commentController.text = _currentMeal.clientComment;

    _tabController = TabController(length: 4, vsync: this);
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onMealChanged(Meal updatedMeal) {
    setState(() {
      _currentMeal = updatedMeal;
    });
    widget.onMealUpdated?.call(updatedMeal);
  }


  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isRTL = LocaleHelper.isRTL(locale);

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: SafeArea(
              child: Column(
                children: [
                  // Custom header with glassmorphism
                  _buildHeader(locale),

                  // Content tabs
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(DesignTokens.space16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(DesignTokens.radius20),
                        border: Border.all(
                          color: AppTheme.mediumGrey.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(DesignTokens.radius20),
                        child: Column(
                          children: [
                            // Tab bar
                            _buildTabBar(locale),

                            // Tab content
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildOverviewTab(),
                                  _buildFoodItemsTab(),
                                  _buildAttachmentsTab(),
                                  _buildCommentsTab(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String locale) {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(DesignTokens.space16),
              padding: const EdgeInsets.all(DesignTokens.space20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
                border: Border.all(
                  color: AppTheme.mediumGrey.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header row
                  Row(
                    children: [
                      // Meal icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _getMealTypeColor(_currentMeal.label).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(DesignTokens.radius12),
                        ),
                        child: Icon(
                          _getMealTypeIcon(_currentMeal.label),
                          color: _getMealTypeColor(_currentMeal.label),
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: DesignTokens.space16),

                      // Meal title and info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentMeal.label,
                              style: const TextStyle(
                                color: AppTheme.neutralWhite,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.space4),
                            Text(
                              '${_currentMeal.items.length} ${LocaleHelper.t('items', locale)} • ${_currentMeal.mealSummary.totalKcal.toStringAsFixed(0)} ${LocaleHelper.t('kcal', locale)}',
                              style: const TextStyle(
                                color: AppTheme.lightGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Close button
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.neutralWhite,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.mediumGrey.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radius8),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: DesignTokens.space16),

                  // Quick macro summary
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickMacroItem(
                          LocaleHelper.t('protein', locale),
                          '${_currentMeal.mealSummary.totalProtein.toStringAsFixed(1)}g',
                          Colors.red,
                        ),
                      ),
                      Expanded(
                        child: _buildQuickMacroItem(
                          LocaleHelper.t('carbs', locale),
                          '${_currentMeal.mealSummary.totalCarbs.toStringAsFixed(1)}g',
                          Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _buildQuickMacroItem(
                          LocaleHelper.t('fat', locale),
                          '${_currentMeal.mealSummary.totalFat.toStringAsFixed(1)}g',
                          Colors.yellow.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickMacroItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(String locale) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radius20),
          topRight: Radius.circular(DesignTokens.radius20),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.accentGreen,
        indicatorWeight: 3,
        labelColor: AppTheme.neutralWhite,
        unselectedLabelColor: AppTheme.lightGrey,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(
            icon: const Icon(Icons.dashboard, size: 20),
            text: LocaleHelper.t('overview', locale),
          ),
          Tab(
            icon: const Icon(Icons.restaurant_menu, size: 20),
            text: LocaleHelper.t('food_items', locale),
          ),
          Tab(
            icon: const Icon(Icons.attach_file, size: 20),
            text: LocaleHelper.t('photos', locale),
          ),
          Tab(
            icon: const Icon(Icons.comment, size: 20),
            text: LocaleHelper.t('notes', locale),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        children: [
          // Macro breakdown chart
          MacroBreakdownChart(
            meal: _currentMeal,
          ),

          const SizedBox(height: DesignTokens.space24),

          // Detailed macro info
          NutritionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nutritional Breakdown',
                  style: TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: DesignTokens.space16),

                _buildNutrientRow('Calories', '${_currentMeal.mealSummary.totalKcal.toStringAsFixed(0)} kcal', Colors.green),
                _buildNutrientRow('Protein', '${_currentMeal.mealSummary.totalProtein.toStringAsFixed(1)} g', Colors.red),
                _buildNutrientRow('Carbohydrates', '${_currentMeal.mealSummary.totalCarbs.toStringAsFixed(1)} g', Colors.orange),
                _buildNutrientRow('Fat', '${_currentMeal.mealSummary.totalFat.toStringAsFixed(1)} g', Colors.yellow.shade700),
                _buildNutrientRow('Sodium', '${_currentMeal.mealSummary.totalSodium.toStringAsFixed(0)} mg', Colors.purple),
                _buildNutrientRow('Potassium', '${_currentMeal.mealSummary.totalPotassium.toStringAsFixed(0)} mg', Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItemsTab() {
    return FoodListPanel(
      meal: _currentMeal,
      userRole: widget.userRole,
      isReadOnly: widget.isReadOnly,
      onMealUpdated: _onMealChanged,
      onAddFood: widget.onAddFood,
    );
  }

  Widget _buildAttachmentsTab() {
    return AttachmentsGallery(
      meal: _currentMeal,
      userRole: widget.userRole,
      isReadOnly: widget.isReadOnly,
      onMealUpdated: _onMealChanged,
      onAddAttachment: widget.onAddAttachment,
    );
  }

  Widget _buildCommentsTab() {
    return CommentsThread(
      meal: _currentMeal,
      userRole: widget.userRole,
      isReadOnly: widget.isReadOnly,
      onMealUpdated: _onMealChanged,
    );
  }

  Color _getMealTypeColor(String mealName) {
    final name = mealName.toLowerCase();
    if (name.contains('breakfast')) return Colors.orange;
    if (name.contains('lunch')) return Colors.green;
    if (name.contains('dinner')) return Colors.purple;
    if (name.contains('snack')) return Colors.blue;
    return AppTheme.accentGreen;
  }

  IconData _getMealTypeIcon(String mealName) {
    final name = mealName.toLowerCase();
    if (name.contains('breakfast')) return Icons.wb_sunny;
    if (name.contains('lunch')) return Icons.wb_sunny_outlined;
    if (name.contains('dinner')) return Icons.nightlight_round;
    if (name.contains('snack')) return Icons.cookie;
    return Icons.restaurant_menu;
  }
}