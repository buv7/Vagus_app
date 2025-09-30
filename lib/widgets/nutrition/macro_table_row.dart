import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../widgets/nutrition/meal_detail_sheet.dart';
import '../../widgets/nutrition/file_attach_to_meal.dart';
import '../../widgets/nutrition/client_nutrition_comment_box.dart';
import '../../widgets/nutrition/food_item_card.dart';
import '../../widgets/nutrition/animated_food_item_edit_modal.dart';
import '../../widgets/nutrition/animated/food_item_modal_route.dart';
import '../../theme/design_tokens.dart';

class MacroTableRow extends StatefulWidget {
  final FoodItem item;
  final Function(FoodItem) onChanged;
  final VoidCallback onDelete;
  final bool isReadOnly;
  final String language;
  final Meal? parentMeal; // Add parent meal for detail sheet

  const MacroTableRow({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
    this.isReadOnly = false,
    this.language = 'en',
    this.parentMeal,
  });

  @override
  State<MacroTableRow> createState() => _MacroTableRowState();
}

class _MacroTableRowState extends State<MacroTableRow> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _sodiumController;
  late TextEditingController _potassiumController;
  
  // Target macro controllers
  late TextEditingController _targetProteinController;
  late TextEditingController _targetCarbsController;
  late TextEditingController _targetFatController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _amountController = TextEditingController(text: widget.item.amount > 0 ? widget.item.amount.toString() : '');
    _proteinController = TextEditingController(text: widget.item.protein.toString());
    _carbsController = TextEditingController(text: widget.item.carbs.toString());
    _fatController = TextEditingController(text: widget.item.fat.toString());
    _sodiumController = TextEditingController(text: widget.item.sodium.toString());
    _potassiumController = TextEditingController(text: widget.item.potassium.toString());
    
    // Initialize target macro controllers
    _targetProteinController = TextEditingController();
    _targetCarbsController = TextEditingController();
    _targetFatController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _sodiumController.dispose();
    _potassiumController.dispose();
    _targetProteinController.dispose();
    _targetCarbsController.dispose();
    _targetFatController.dispose();
    super.dispose();
  }



  void _openMealDetailSheet() {
    if (widget.parentMeal == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MealDetailSheet(
        meal: widget.parentMeal!,
        coachNotes: const SizedBox.shrink(), // No coach notes for individual food items
        foodItems: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Food Item Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text(widget.item.name),
              subtitle: Text('${widget.item.amount.toStringAsFixed(1)}g'),
              trailing: Text('${widget.item.kcal.toStringAsFixed(0)} kcal'),
            ),
          ],
        ),
        onAddFood: () {},
        mealSummary: Text(
          'P: ${widget.item.protein.toStringAsFixed(1)}g • C: ${widget.item.carbs.toStringAsFixed(1)}g • F: ${widget.item.fat.toStringAsFixed(1)}g • ${widget.item.kcal.toStringAsFixed(0)} kcal',
        ),
        attachments: FileAttachToMeal(
          attachments: widget.parentMeal!.attachments,
          onAttachmentsChanged: (_) {},
          isReadOnly: widget.isReadOnly,
        ),
        onAddFile: () {},
        clientComment: ClientNutritionCommentBox(
          comment: widget.parentMeal!.clientComment,
          onCommentChanged: (_) {},
          isReadOnly: widget.isReadOnly,
          isClientView: false,
        ),
      ),
    );
  }

  void _openEditModal() {
    if (widget.isReadOnly) return;

    // Use custom route with spring physics and animations
    showFoodItemModal(
      context,
      modal: AnimatedFoodItemEditModal(
        foodItem: widget.item,
        onSave: (updatedItem) {
          widget.onChanged(updatedItem);
        },
        // TODO: Implement these callbacks
        // onSearchDatabase: () {},
        // onScanBarcode: () {},
        // onAIGenerate: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If read-only, still show the old cramped row (for client view compatibility)
    if (widget.isReadOnly) {
      return _buildOldRow();
    }

    // Use new FoodItemCard design for editable items
    return FoodItemCard(
      foodItem: widget.item,
      onTap: _openEditModal,
      onDelete: widget.onDelete,
      showTargetMacros: false,
    );
  }

  // Keep the old row design for read-only mode (client view)
  Widget _buildOldRow() {
    return GestureDetector(
      onTap: _openMealDetailSheet,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Food Name
                    SizedBox(
                      width: 120,
                      child: Text(
                        widget.item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Protein
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${widget.item.protein.toStringAsFixed(1)}g P',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Carbs
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${widget.item.carbs.toStringAsFixed(1)}g C',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Fat
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${widget.item.fat.toStringAsFixed(1)}g F',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Kcal
                    Text(
                      '${widget.item.kcal.toStringAsFixed(0)} kcal',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
