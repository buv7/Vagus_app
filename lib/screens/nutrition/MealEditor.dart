import 'package:flutter/material.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../widgets/nutrition/MacroTableRow.dart';
import '../../widgets/nutrition/FileAttachToMeal.dart';
import '../../widgets/nutrition/ClientNutritionCommentBox.dart';
import '../../services/ai/nutrition_ai.dart';

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
  final NutritionAI _nutritionAI = NutritionAI();

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

  Future<void> _autoFillFromText() async {
    if (widget.isReadOnly) return;

    final textController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-Fill from Text'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter food items (e.g., "100g chicken breast + 1 cup rice")'),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Food items...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('Auto-Fill'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final items = await _nutritionAI.autoFillFromText(result);
        
        if (items.isNotEmpty) {
          final updatedItems = [...widget.meal.items, ...items];
          final mealSummary = NutritionPlan.recalcMealSummary(
            widget.meal.copyWith(items: updatedItems),
          );
          
          final updatedMeal = widget.meal.copyWith(
            items: updatedItems,
            mealSummary: mealSummary,
          );
          
          widget.onMealChanged(updatedMeal);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Auto-filled successfully')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Auto-fill failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Meal header
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _labelController,
                    enabled: !widget.isReadOnly,
                    decoration: const InputDecoration(
                      labelText: 'Meal Label',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _updateMeal(),
                  ),
                ),
                const SizedBox(width: 8),
                if (!widget.isReadOnly)
                  IconButton(
                    onPressed: _autoFillFromText,
                    icon: const Icon(Icons.auto_awesome),
                    tooltip: 'Auto-Fill (AI)',
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Items table header and data together
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 200,
                          child: Text(
                            'Food Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Amount',
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
                            'Protein',
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
                            'Carbs',
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
                            'Fat',
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
                            'Kcal',
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
                            'Sodium',
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
                            'Potassium',
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
                        : Column(
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
                ],
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
                  label: const Text('Add Food Item'),
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
                      'Meal Summary',
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
                            'Protein',
                            '${widget.meal.mealSummary.totalProtein.toStringAsFixed(1)}g',
                            Colors.red.shade600,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            'Carbs',
                            '${widget.meal.mealSummary.totalCarbs.toStringAsFixed(1)}g',
                            Colors.orange.shade600,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            'Fat',
                            '${widget.meal.mealSummary.totalFat.toStringAsFixed(1)}g',
                            Colors.yellow.shade700,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            'Calories',
                            '${widget.meal.mealSummary.totalKcal.toStringAsFixed(0)} kcal',
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
