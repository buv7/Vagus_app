import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../models/nutrition/nutrition_plan.dart';
import '../../../../services/nutrition/locale_helper.dart';
import '../../../../services/haptics.dart';
import '../../widgets/shared/nutrition_card.dart';
import '../../widgets/shared/empty_state_widget.dart';

/// Panel for displaying and managing food items within a meal
class FoodListPanel extends StatefulWidget {
  final Meal meal;
  final String userRole;
  final bool isReadOnly;
  final Function(Meal)? onMealUpdated;
  final Function(String)? onAddFood;

  const FoodListPanel({
    super.key,
    required this.meal,
    required this.userRole,
    this.isReadOnly = false,
    this.onMealUpdated,
    this.onAddFood,
  });

  @override
  State<FoodListPanel> createState() => _FoodListPanelState();
}

class _FoodListPanelState extends State<FoodListPanel>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  final List<AnimationController> _itemControllers = [];
  final List<Animation<double>> _itemAnimations = [];

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _initializeItemAnimations();
    _listAnimationController.forward();
  }

  @override
  void didUpdateWidget(FoodListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meal.items.length != widget.meal.items.length) {
      _initializeItemAnimations();
    }
  }

  void _initializeItemAnimations() {
    // Dispose old controllers
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    _itemControllers.clear();
    _itemAnimations.clear();

    // Create new controllers for each item
    for (int i = 0; i < widget.meal.items.length; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 300 + (i * 100)),
        vsync: this,
      );
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutBack,
        ),
      );

      _itemControllers.add(controller);
      _itemAnimations.add(animation);

      // Stagger the animations
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _removeFoodItem(int index) {
    if (widget.isReadOnly) return;

    Haptics.impact();

    // Animate out the item being removed
    _itemControllers[index].reverse().then((_) {
      if (!mounted) return;

      final updatedItems = List<FoodItem>.from(widget.meal.items);
      updatedItems.removeAt(index);

      final updatedMeal = widget.meal.copyWith(
        items: updatedItems,
        mealSummary: NutritionPlan.recalcMealSummary(
          widget.meal.copyWith(items: updatedItems),
        ),
      );

      widget.onMealUpdated?.call(updatedMeal);
    });
  }

  void _editFoodItem(int index) {
    if (widget.isReadOnly) return;

    final item = widget.meal.items[index];
    _showFoodItemEditor(item, index);
  }

  void _showFoodItemEditor(FoodItem item, int index) {
    final amountController = TextEditingController(
      text: item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 1),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DesignTokens.radius20),
            topRight: Radius.circular(DesignTokens.radius20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: DesignTokens.space12),
              decoration: BoxDecoration(
                color: AppTheme.mediumGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space20,
                vertical: DesignTokens.space8,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit,
                    color: AppTheme.accentGreen,
                  ),
                  const SizedBox(width: DesignTokens.space8),
                  Expanded(
                    child: Text(
                      'Edit ${item.name}',
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.lightGrey,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: AppTheme.mediumGrey),

            // Editor content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount input
                    const Text(
                      'Amount',
                      style: TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space8),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.neutralWhite),
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        hintStyle: const TextStyle(color: AppTheme.lightGrey),
                        filled: true,
                        fillColor: AppTheme.primaryDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radius8),
                          borderSide: const BorderSide(color: AppTheme.mediumGrey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radius8),
                          borderSide: const BorderSide(color: AppTheme.mediumGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radius8),
                          borderSide: const BorderSide(color: AppTheme.accentGreen),
                        ),
                        suffixText: 'g',
                        suffixStyle: const TextStyle(color: AppTheme.lightGrey),
                      ),
                    ),

                    const SizedBox(height: DesignTokens.space24),

                    // Current macros preview
                    NutritionCard(
                      padding: const EdgeInsets.all(DesignTokens.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Macros',
                            style: TextStyle(
                              color: AppTheme.neutralWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.space12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMacroPreview('Protein', '${item.protein.toStringAsFixed(1)}g', Colors.red),
                              _buildMacroPreview('Carbs', '${item.carbs.toStringAsFixed(1)}g', Colors.orange),
                              _buildMacroPreview('Fat', '${item.fat.toStringAsFixed(1)}g', Colors.yellow.shade700),
                              _buildMacroPreview('Calories', item.kcal.toStringAsFixed(0), Colors.green),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final newAmount = double.tryParse(amountController.text) ?? item.amount;
                          _updateFoodItemAmount(index, newAmount);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          foregroundColor: AppTheme.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radius12),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroPreview(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _updateFoodItemAmount(int index, double newAmount) {
    if (widget.isReadOnly) return;

    final item = widget.meal.items[index];
    final ratio = newAmount / item.amount;

    // Scale all macros proportionally
    final updatedItem = FoodItem(
      name: item.name,
      amount: newAmount,
      protein: item.protein * ratio,
      carbs: item.carbs * ratio,
      fat: item.fat * ratio,
      kcal: item.kcal * ratio,
      sodium: item.sodium * ratio,
      potassium: item.potassium * ratio,
      recipeId: item.recipeId,
      servings: item.servings * ratio,
      costPerUnit: item.costPerUnit,
      currency: item.currency,
      estimated: item.estimated,
    );

    final updatedItems = List<FoodItem>.from(widget.meal.items);
    updatedItems[index] = updatedItem;

    final updatedMeal = widget.meal.copyWith(
      items: updatedItems,
      mealSummary: NutritionPlan.recalcMealSummary(
        widget.meal.copyWith(items: updatedItems),
      ),
    );

    widget.onMealUpdated?.call(updatedMeal);
    Haptics.success();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    if (widget.meal.items.isEmpty) {
      return EmptyStateWidget(
        type: EmptyStateType.noFoodItems,
        onActionPressed: widget.isReadOnly ? null : () {
          widget.onAddFood?.call(widget.meal.label);
        },
      );
    }

    return Column(
      children: [
        // Add food button (for coaches)
        if (!widget.isReadOnly && widget.userRole == 'coach')
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(DesignTokens.space16),
            child: ElevatedButton.icon(
              onPressed: () => widget.onAddFood?.call(widget.meal.label),
              icon: const Icon(Icons.add_circle_outline),
              label: Text(LocaleHelper.t('add_food_items', locale)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.space12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
              ),
            ),
          ),

        // Food items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
            itemCount: widget.meal.items.length,
            itemBuilder: (context, index) {
              if (index >= _itemAnimations.length) return const SizedBox.shrink();

              final item = widget.meal.items[index];
              return AnimatedBuilder(
                animation: _itemAnimations[index],
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - _itemAnimations[index].value)),
                    child: Opacity(
                      opacity: _itemAnimations[index].value,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: DesignTokens.space12),
                        child: FoodItemCard(
                          name: item.name,
                          amount: item.amount,
                          unit: 'g',
                          protein: item.protein,
                          carbs: item.carbs,
                          fat: item.fat,
                          kcal: item.kcal,
                          isRecipe: item.recipeId != null,
                          onTap: widget.isReadOnly ? null : () => _editFoodItem(index),
                          onRemove: widget.isReadOnly ? null : () => _removeFoodItem(index),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}