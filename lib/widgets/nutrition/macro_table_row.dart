import 'package:flutter/material.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../services/ai/nutrition_ai.dart';
import '../../widgets/anim/blocking_overlay.dart';

class MacroTableRow extends StatefulWidget {
  final FoodItem item;
  final Function(FoodItem) onChanged;
  final VoidCallback onDelete;
  final bool isReadOnly;
  final String language;

  const MacroTableRow({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
    this.isReadOnly = false,
    this.language = 'en',
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
  
  final NutritionAI _nutritionAI = NutritionAI();
  bool _isLoadingAI = false;

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

  void _updateItem() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final protein = double.tryParse(_proteinController.text) ?? 0.0;
    final carbs = double.tryParse(_carbsController.text) ?? 0.0;
    final fat = double.tryParse(_fatController.text) ?? 0.0;
    final sodium = double.tryParse(_sodiumController.text) ?? 0.0;
    final potassium = double.tryParse(_potassiumController.text) ?? 0.0;
    final kcal = NutritionPlan.calcKcal(protein, carbs, fat);

    final updatedItem = widget.item.copyWith(
      name: _nameController.text,
      amount: amount,
      protein: protein,
      carbs: carbs,
      fat: fat,
      kcal: kcal,
      sodium: sodium,
      potassium: potassium,
    );

    widget.onChanged(updatedItem);
  }

  Future<void> _generateFromTargetMacros() async {
    if (widget.isReadOnly) return;
    
    final targetProtein = double.tryParse(_targetProteinController.text);
    final targetCarbs = double.tryParse(_targetCarbsController.text);
    final targetFat = double.tryParse(_targetFatController.text);
    
    // Check if at least one target macro is specified
    if (targetProtein == null && targetCarbs == null && targetFat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one target macro amount')),
      );
      return;
    }
    
    // Check if food name is provided
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a food name first')),
      );
      return;
    }

    setState(() => _isLoadingAI = true);

    try {
      // Create target macro map
      final targets = <String, double>{};
      if (targetProtein != null) targets['protein'] = targetProtein;
      if (targetCarbs != null) targets['carbs'] = targetCarbs;
      if (targetFat != null) targets['fat'] = targetFat;

      // Generate food item with target macros
      final generatedItems = await runWithBlockingLoader(
        context,
        _nutritionAI.generateFoodWithTargetMacros(
          calories: targets['calories'] ?? 0.0,
          protein: targets['protein'] ?? 0.0,
          carbs: targets['carbs'] ?? 0.0,
          fat: targets['fat'] ?? 0.0,
          locale: Localizations.localeOf(context).languageCode,
        ),
        showSuccess: true,
      );

      if (generatedItems.isNotEmpty) {
        final generatedItem = generatedItems.first;
        
        // Update the form fields with generated data
        _nameController.text = generatedItem.name;
        _amountController.text = generatedItem.amount > 0 ? generatedItem.amount.toString() : '';
        _proteinController.text = generatedItem.protein.toString();
        _carbsController.text = generatedItem.carbs.toString();
        _fatController.text = generatedItem.fat.toString();
        _sodiumController.text = generatedItem.sodium.toString();
        _potassiumController.text = generatedItem.potassium.toString();
        
        // Clear target macro fields
        _targetProteinController.clear();
        _targetCarbsController.clear();
        _targetFatController.clear();
        
        // Update the item
        _updateItem();
        
        if (!mounted || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Food item generated with target macros')),
        );
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to generate food item: $e')),
      );
    } finally {
      setState(() => _isLoadingAI = false);
    }
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main macro row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Food Name
                SizedBox(
                  width: 120, // Match header width
                  child: TextFormField(
                    controller: _nameController,
                    enabled: !widget.isReadOnly,
                    decoration: const InputDecoration(
                      hintText: 'Food name',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (_) => _updateItem(),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Amount
                SizedBox(
                  width: 60, // Match header width
                  child: TextFormField(
                    controller: _amountController,
                    enabled: !widget.isReadOnly,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: InputBorder.none,
                      isDense: true,
                      suffixText: 'g',
                    ),
                    onChanged: (_) => _updateItem(),
                  ),
                ),
              const SizedBox(width: 8),
              
              // Protein
              SizedBox(
                width: 60,
                child: TextFormField(
                  controller: _proteinController,
                  enabled: !widget.isReadOnly,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    suffixText: 'g',
                  ),
                  onChanged: (_) => _updateItem(),
                ),
              ),
              const SizedBox(width: 8),
              
              // Carbs
              SizedBox(
                width: 60,
                child: TextFormField(
                  controller: _carbsController,
                  enabled: !widget.isReadOnly,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    suffixText: 'g',
                  ),
                  onChanged: (_) => _updateItem(),
                ),
              ),
              const SizedBox(width: 8),
              
              // Fat
              SizedBox(
                width: 60,
                child: TextFormField(
                  controller: _fatController,
                  enabled: !widget.isReadOnly,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    suffixText: 'g',
                  ),
                  onChanged: (_) => _updateItem(),
                ),
              ),
              const SizedBox(width: 8),
              
              // Kcal (read-only)
              SizedBox(
                width: 70,
                child: Text(
                  '${widget.item.kcal.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Sodium
              SizedBox(
                width: 60,
                child: TextFormField(
                  controller: _sodiumController,
                  enabled: !widget.isReadOnly,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    suffixText: 'mg',
                  ),
                  onChanged: (_) => _updateItem(),
                ),
              ),
              const SizedBox(width: 8),
              
              // Potassium
              SizedBox(
                width: 60,
                child: TextFormField(
                  controller: _potassiumController,
                  enabled: !widget.isReadOnly,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    suffixText: 'mg',
                  ),
                  onChanged: (_) => _updateItem(),
                ),
              ),
              const SizedBox(width: 8),
              
              // AI Generate button
              if (!widget.isReadOnly)
                IconButton(
                  icon: _isLoadingAI 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
                  onPressed: _isLoadingAI ? null : _generateFromTargetMacros,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Generate from target macros',
                ),
              
              const SizedBox(width: 8),
              
              // Delete button
              if (!widget.isReadOnly)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Target macro row (only show if not read-only)
          if (!widget.isReadOnly) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Target Macro Label
                    SizedBox(
                      width: 120, // Match header width
                      child: Text(
                        'Target Macros:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  
                  // Target Protein
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      controller: _targetProteinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        isDense: true,
                        suffixText: 'g',
                        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Target Carbs
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      controller: _targetCarbsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        isDense: true,
                        suffixText: 'g',
                        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Target Fat
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      controller: _targetFatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        isDense: true,
                        suffixText: 'g',
                        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Generate button
                  ElevatedButton(
                    onPressed: _isLoadingAI ? null : _generateFromTargetMacros,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: _isLoadingAI
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Generate', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }
}
