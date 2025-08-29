import 'package:flutter/material.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../widgets/nutrition/macro_table_row.dart';
import '../../widgets/nutrition/file_attach_to_meal.dart';
import '../../widgets/nutrition/client_nutrition_comment_box.dart';
import '../../services/nutrition/locale_helper.dart';


class MealEditor extends StatefulWidget {
  final Meal meal;
  final Function(Meal) onMealChanged;
  final bool isReadOnly;
  final bool isClientView;
  final VoidCallback? onCommentSave;

  const MealEditor({
    super.key,
    required this.meal,
    required this.onMealChanged,
    this.isReadOnly = false,
    this.isClientView = false,
    this.onCommentSave,
  });

  @override
  State<MealEditor> createState() => _MealEditorState();
}

class _MealEditorState extends State<MealEditor> {
  late TextEditingController _labelController;


  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.meal.label);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _updateMeal() {
    final updatedMeal = widget.meal.copyWith(
      label: _labelController.text,
    );
    widget.onMealChanged(updatedMeal);
  }

  void _addItem() {
    if (widget.isReadOnly) return;

    final newItem = FoodItem(
      name: '',
      amount: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      kcal: 0,
      sodium: 0,
      potassium: 0,
    );

    final updatedItems = [...widget.meal.items, newItem];
    final updatedMeal = widget.meal.copyWith(items: updatedItems);
    widget.onMealChanged(updatedMeal);
  }

  void _updateItem(int index, FoodItem item) {
    final updatedItems = List<FoodItem>.from(widget.meal.items);
    updatedItems[index] = item;
    
    // Recalculate meal summary
    final mealSummary = NutritionPlan.recalcMealSummary(
      widget.meal.copyWith(items: updatedItems),
    );
    
    final updatedMeal = widget.meal.copyWith(
      items: updatedItems,
      mealSummary: mealSummary,
    );
    
    widget.onMealChanged(updatedMeal);
  }

  void _removeItem(int index) {
    if (widget.isReadOnly) return;

    final updatedItems = List<FoodItem>.from(widget.meal.items);
    updatedItems.removeAt(index);
    
    // Recalculate meal summary
    final mealSummary = NutritionPlan.recalcMealSummary(
      widget.meal.copyWith(items: updatedItems),
    );
    
    final updatedMeal = widget.meal.copyWith(
      items: updatedItems,
      mealSummary: mealSummary,
    );
    
    widget.onMealChanged(updatedMeal);
  }

  void _updateAttachments(List<String> attachments) {
    final updatedMeal = widget.meal.copyWith(attachments: attachments);
    widget.onMealChanged(updatedMeal);
  }

  void _updateComment(String comment) {
    final updatedMeal = widget.meal.copyWith(clientComment: comment);
    widget.onMealChanged(updatedMeal);
  }





  @override
  Widget build(BuildContext context) {
    // Get global language from context
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal header
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _labelController,
                    decoration: InputDecoration(
                      labelText: LocaleHelper.t('meal_name', language),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => _updateMeal(),
                    readOnly: widget.isReadOnly,
                  ),
                ),
                if (!widget.isReadOnly) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addItem,
                    tooltip: LocaleHelper.t('add_food', language),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Client comment box (if client view)
            if (widget.isClientView)
              ClientNutritionCommentBox(
                comment: widget.meal.clientComment,
                onCommentChanged: (comment) {
                  final updatedMeal = widget.meal.copyWith(clientComment: comment);
                  widget.onMealChanged(updatedMeal);
                },
                onSave: widget.onCommentSave,
                isReadOnly: widget.isReadOnly,
              ),
            
            const SizedBox(height: 16),
            
            // Macro table header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 120, // Fixed width for food item
                      child: Text(
                        LocaleHelper.t('food_item', language),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        LocaleHelper.t('protein', language),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        LocaleHelper.t('carbs', language),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        LocaleHelper.t('fat', language),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        LocaleHelper.t('kcal', language),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        LocaleHelper.t('sodium', language),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        LocaleHelper.t('potassium', language),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Table data
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: widget.meal.items.isEmpty
                  ? Container(
                      height: 50,
                      alignment: Alignment.center,
                      child: Text(
                        'No food items added yet',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.meal.items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          
                          return MacroTableRow(
                            key: ValueKey('macro_row_${item.hashCode}_$index'),
                            item: item,
                            onChanged: (updatedItem) => _updateItem(index, updatedItem),
                            onDelete: () => _removeItem(index),
                            isReadOnly: widget.isReadOnly,
                          );
                        }).toList(),
                      ),
                    ),
            ),
            
            // Add item button
            if (!widget.isReadOnly) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: Text(LocaleHelper.t('add_food', Localizations.localeOf(context).languageCode)),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Meal summary
            if (widget.meal.items.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleHelper.t('daily_summary', Localizations.localeOf(context).languageCode),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            LocaleHelper.t('protein', Localizations.localeOf(context).languageCode),
                            '${widget.meal.mealSummary.totalProtein.toStringAsFixed(1)}${LocaleHelper.t('grams', Localizations.localeOf(context).languageCode)}',
                            Colors.red.shade600,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            LocaleHelper.t('carbs', Localizations.localeOf(context).languageCode),
                            '${widget.meal.mealSummary.totalCarbs.toStringAsFixed(1)}${LocaleHelper.t('grams', Localizations.localeOf(context).languageCode)}',
                            Colors.orange.shade600,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            LocaleHelper.t('fat', Localizations.localeOf(context).languageCode),
                            '${widget.meal.mealSummary.totalFat.toStringAsFixed(1)}${LocaleHelper.t('grams', Localizations.localeOf(context).languageCode)}',
                            Colors.yellow.shade700,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            LocaleHelper.t('calories', Localizations.localeOf(context).languageCode),
                            '${widget.meal.mealSummary.totalKcal.toStringAsFixed(0)} ${LocaleHelper.t('kcal', Localizations.localeOf(context).languageCode)}',
                            Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Attachments
            FileAttachToMeal(
              attachments: widget.meal.attachments,
              onAttachmentsChanged: _updateAttachments,
              isReadOnly: widget.isReadOnly,
            ),
            
            const SizedBox(height: 16),
            
            // Comment box
            ClientNutritionCommentBox(
              comment: widget.meal.clientComment,
              onCommentChanged: _updateComment,
              isReadOnly: widget.isReadOnly,
              isClientView: widget.isClientView,
              onSave: widget.onCommentSave,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
