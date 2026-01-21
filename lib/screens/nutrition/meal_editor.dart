import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../theme/design_tokens.dart';
import '../../models/nutrition/recipe.dart';
import '../../models/nutrition/preferences.dart';
import '../../models/nutrition/food_item.dart' as fi;
import '../../widgets/nutrition/macro_table_row.dart';
import '../../components/nutrition/recipe_item_tile.dart';
import '../../components/nutrition/recipe_quick_swap_sheet.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../../services/nutrition/preferences_service.dart';
import '../../services/nutrition/pantry_service.dart';
import 'recipe_library_screen.dart';
import 'barcode_scan_screen.dart';
import 'food_snap_screen.dart';


/// A full-screen meal editor with proper navigation
class MealEditorScreen extends StatefulWidget {
  final Meal meal;
  final Function(Meal)? onMealSaved;

  const MealEditorScreen({
    super.key,
    required this.meal,
    this.onMealSaved,
  });

  @override
  State<MealEditorScreen> createState() => _MealEditorScreenState();
}

class _MealEditorScreenState extends State<MealEditorScreen> {
  late Meal _currentMeal;

  @override
  void initState() {
    super.initState();
    _currentMeal = widget.meal;
  }

  void _handleMealChanged(Meal updatedMeal) {
    setState(() {
      _currentMeal = updatedMeal;
    });
  }

  void _saveMeal() {
    widget.onMealSaved?.call(_currentMeal);
    Navigator.of(context).pop(_currentMeal);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? DesignTokens.darkBackground : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          _currentMeal.label.isEmpty ? 'New Meal' : _currentMeal.label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey.shade900,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: _saveMeal,
            icon: Icon(
              Icons.check_rounded,
              color: DesignTokens.accentBlue,
              size: 20,
            ),
            label: Text(
              'Save',
              style: TextStyle(
                color: DesignTokens.accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MealEditor(
            meal: _currentMeal,
            onMealChanged: _handleMealChanged,
            isReadOnly: false,
            isClientView: false,
          ),
        ),
      ),
    );
  }
}

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
  final NutritionService _nutritionService = NutritionService();
  final PreferencesService _preferencesService = PreferencesService();
  
  // Preferences and allergies for warnings
  Preferences? _userPreferences;
  
  // Pantry integration
  bool _usePantryFirst = false;

  // Advanced picker helpers
  final Set<String> _favoriteFoodNames = {};

  FoodItem _scaleFood(FoodItem base, double multiplier) {
    return FoodItem(
      name: base.name,
      amount: base.amount * multiplier,
      protein: base.protein * multiplier,
      carbs: base.carbs * multiplier,
      fat: base.fat * multiplier,
      kcal: base.kcal * multiplier,
      sodium: base.sodium * multiplier,
      potassium: base.potassium * multiplier,
      recipeId: base.recipeId,
      servings: base.servings * multiplier,
      costPerUnit: base.costPerUnit,
      currency: base.currency,
      estimated: base.estimated,
    );
  }


  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.meal.label);
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      // TODO: Get current user ID from auth service
      final userId = 'current_user_id'; // Replace with actual user ID
      
      final preferences = await _preferencesService.getPrefs(userId);
      await _preferencesService.getAllergies(userId);
      
      setState(() {
        _userPreferences = preferences;
      });
    } catch (e) {
      // Handle error silently - preferences are optional
    }
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

  Future<void> _addFoodAdvanced() async {
    if (widget.isReadOnly) return;
    // Local catalog (can be replaced by FoodCatalogService later)
    final defaults = [
      FoodItem(name: 'Chicken Breast 100g', protein: 31, carbs: 0, fat: 3.6, kcal: 165, sodium: 74, potassium: 256),
      FoodItem(name: 'White Rice 100g (cooked)', protein: 2.7, carbs: 28, fat: 0.3, kcal: 130, sodium: 1, potassium: 35),
      FoodItem(name: 'Salmon 100g', protein: 20, carbs: 0, fat: 13, kcal: 208, sodium: 59, potassium: 363),
    ];
    String query = '';
    String activeFilter = 'All';
    final Map<String, Map<String, dynamic>> selected = {}; // name -> {food, quantity, unit}
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, controller) => StatefulBuilder(
          builder: (context, setSheet) {
            final items = defaults.where((f) {
              final mt = f.name.toLowerCase().contains(query.toLowerCase());
              if (!mt) return false;
              if (activeFilter == 'All') return true;
              if (activeFilter == 'High Protein') return f.protein >= 15;
              if (activeFilter == 'Low Carb') return f.carbs <= 10;
              if (activeFilter == 'Low Fat') return f.fat <= 5;
              if (activeFilter == 'Under 200 kcal') return f.kcal <= 200;
              return true;
            }).toList();
            return Container(
              decoration: BoxDecoration(
                color: DesignTokens.darkBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: DesignTokens.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(DesignTokens.radius16),
                          border: Border.all(
                            color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search foods',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                            prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.8)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (v) => setSheet(() => query = v.trim()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                        border: Border.all(
                          color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final c = await _showCreateCustomFoodDialog();
                            if (c != null) {
                              setSheet(() { selected[c.name] = {'food': c, 'quantity': 1.0, 'unit': 'serv'}; });
                            }
                          },
                          borderRadius: BorderRadius.circular(DesignTokens.radius12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, color: Colors.white.withValues(alpha: 0.8)),
                                const SizedBox(width: 4),
                                const Text('Custom', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in const ['All','High Protein','Low Carb','Low Fat','Under 200 kcal'])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: activeFilter == f,
                            onSelected: (_) => setSheet(() => activeFilter = f),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final f = items[i];
                      final isSel = selected.containsKey(f.name);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: DesignTokens.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: ListTile(
                          title: Text(f.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          subtitle: Text('P ${f.protein}g • C ${f.carbs}g • F ${f.fat}g • ${f.kcal.toStringAsFixed(0)} kcal', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Favorite',
                                icon: Icon(_favoriteFoodNames.contains(f.name) ? Icons.favorite : Icons.favorite_border, color: DesignTokens.accentPink),
                                onPressed: () => setSheet(() { if (_favoriteFoodNames.contains(f.name)) {
                                  _favoriteFoodNames.remove(f.name);
                                } else {
                                  _favoriteFoodNames.add(f.name);
                                } }),
                              ),
                              IconButton(
                                icon: Icon(isSel ? Icons.check_circle : Icons.add_circle_outline, color: DesignTokens.accentBlue),
                                onPressed: () => setSheet(() { if (isSel) {
                                  selected.remove(f.name);
                                } else {
                                  selected[f.name] = {'food': f, 'quantity': 100.0, 'unit': 'g'};
                                } }),
                              ),
                            ],
                          ),
                          hoverColor: DesignTokens.accentBlue.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ),
                if (selected.isNotEmpty) ...[
                  const Divider(),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: selected.entries.map((e) {
                        final base = e.value['food'] as FoodItem;
                        final qty = e.value['quantity'] as double;
                        final unit = e.value['unit'] as String;
                        return Container(
                          width: 220,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: DesignTokens.accentBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(base.name, style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.white54), onPressed: () => setSheet((){ selected.remove(e.key); })),
                            ]),
                            Row(children: [
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(isDense: true, hintText: 'Qty'),
                                  onChanged: (v) => setSheet((){ selected[e.key]!['quantity'] = double.tryParse(v) ?? qty; }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: unit,
                                items: const [DropdownMenuItem(value: 'g', child: Text('g')), DropdownMenuItem(value: 'serv', child: Text('serv'))],
                                onChanged: (val){ if (val!=null) setSheet((){ selected[e.key]!['unit'] = val; }); },
                              ),
                            ]),
                          ]),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: DesignTokens.accentBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final updated = List<FoodItem>.from(widget.meal.items);
                            selected.forEach((_, v) {
                              final base = v['food'] as FoodItem;
                              final qty = v['quantity'] as double;
                              final unit = v['unit'] as String;
                              double mult;
                              if (unit == 'serv') {
                                mult = qty;
                              } else {
                                final isPer100g = base.name.contains('100g');
                                mult = isPer100g ? qty/100.0 : (qty / (base.amount == 0 ? 100 : base.amount));
                              }
                              updated.add(_scaleFood(base, mult));
                            });
                            final updatedMeal = widget.meal.copyWith(
                              items: updated,
                              mealSummary: NutritionPlan.recalcMealSummary(widget.meal.copyWith(items: updated)),
                            );
                            widget.onMealChanged(updatedMeal);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Add to meal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ]),
            );
          },
        ),
      ),
    );
  }

  Future<FoodItem?> _showCreateCustomFoodDialog() async {
    final nameController = TextEditingController();
    final proteinController = TextEditingController(text: '0');
    final carbsController = TextEditingController(text: '0');
    final fatController = TextEditingController(text: '0');
    final kcalController = TextEditingController(text: '0');
    final sodiumController = TextEditingController(text: '0');
    final potassiumController = TextEditingController(text: '0');
    final servingsController = TextEditingController(text: '1');

    return showDialog<FoodItem>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create custom food'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              Row(children: [
                Expanded(child: TextField(controller: proteinController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein (g)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: carbsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbs (g)'))),
              ]),
              Row(children: [
                Expanded(child: TextField(controller: fatController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fat (g)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: kcalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kcal'))),
              ]),
              Row(children: [
                Expanded(child: TextField(controller: sodiumController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sodium (mg)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: potassiumController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Potassium (mg)'))),
              ]),
              TextField(controller: servingsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Servings (default 1)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final p = double.tryParse(proteinController.text) ?? 0;
              final c = double.tryParse(carbsController.text) ?? 0;
              final f = double.tryParse(fatController.text) ?? 0;
              final kcal = double.tryParse(kcalController.text) ?? (p*4 + c*4 + f*9);
              final s = double.tryParse(sodiumController.text) ?? 0;
              final k = double.tryParse(potassiumController.text) ?? 0;
              final serv = double.tryParse(servingsController.text) ?? 1;
              Navigator.pop(context, FoodItem(name: name, protein: p, carbs: c, fat: f, kcal: kcal, sodium: s, potassium: k, servings: serv, amount: 0, estimated: true));
            },
            child: const Text('Create'),
          )
        ],
      ),
    );
  }

  Future<void> _addRecipe() async {
    if (widget.isReadOnly) return;

    try {
      final selectedRecipe = await Navigator.push<Recipe>(
        context,
        MaterialPageRoute(
          builder: (context) => const RecipeLibraryScreen(
            isPickerMode: true,
          ),
        ),
      );

      if (selectedRecipe != null) {
        // Create FoodItem from recipe with default 1 serving
        final recipeItem = await _nutritionService.createFoodItemFromRecipe(
          selectedRecipe.id,
          1.0,
        );

        final updatedItems = [...widget.meal.items, recipeItem];
        final updatedMeal = widget.meal.copyWith(items: updatedItems);
        widget.onMealChanged(updatedMeal);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add recipe: $e')),
        );
      }
    }
  }

  Future<void> _scanBarcode() async {
    if (widget.isReadOnly) return;

    try {
      final result = await Navigator.push<FoodItem>(
        context,
        MaterialPageRoute(
          builder: (_) => const BarcodeScanScreen(),
        ),
      );

      if (result != null) {
        // Add the scanned item to the meal
        final updatedItems = [...widget.meal.items, result];
        final updatedMeal = widget.meal.copyWith(items: updatedItems);
        widget.onMealChanged(updatedMeal);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleHelper.t('added_via_photo', Localizations.localeOf(context).languageCode)),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to scan barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addViaPhoto() async {
    if (widget.isReadOnly) return;

    try {
      final result = await Navigator.push<FoodItem>(
        context,
        MaterialPageRoute(
          builder: (_) => const FoodSnapScreen(),
        ),
      );

      if (result != null) {
        // Ensure the item is marked as estimated
        final estimatedItem = result.copyWith(estimated: true);
        
        // Add the photo-captured item to the meal
        final updatedItems = [...widget.meal.items, estimatedItem];
        final updatedMeal = widget.meal.copyWith(items: updatedItems);
        widget.onMealChanged(updatedMeal);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleHelper.t('added_via_photo', Localizations.localeOf(context).languageCode)),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _quickSwapRecipe(Recipe baseRecipe, int itemIndex) async {
    if (widget.isReadOnly) return;

    try {
      final selectedRecipe = await showRecipeQuickSwapSheet(
        context: context,
        baseRecipe: baseRecipe,
        preferPantry: _usePantryFirst,
      );

      if (selectedRecipe != null) {
        // Create new FoodItem from selected recipe with same servings
        final currentItem = widget.meal.items[itemIndex];
        final newRecipeItem = await _nutritionService.createFoodItemFromRecipe(
          selectedRecipe.id,
          currentItem.servings,
        );

        final updatedItems = List<FoodItem>.from(widget.meal.items);
        updatedItems[itemIndex] = newRecipeItem;
        
        final updatedMeal = widget.meal.copyWith(items: updatedItems);
        widget.onMealChanged(updatedMeal);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to swap recipe: $e')),
        );
      }
    }
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

  /// Convert FoodItem from nutrition_plan.dart to FoodItem from food_item.dart
  fi.FoodItem _convertToFoodItem(FoodItem item) {
    return fi.FoodItem(
      id: null,
      name: item.name,
      protein: item.protein,
      carbs: item.carbs,
      fat: item.fat,
      kcal: item.kcal,
      sodium: item.sodium,
      potassium: item.potassium,
      amount: item.amount,
      unit: 'g', // Default unit since nutrition_plan.FoodItem doesn't have unit
      estimated: item.estimated,
      source: 'meal',
    );
  }

  void _removeItem(int index) async {
    if (widget.isReadOnly) return;

    final item = widget.meal.items[index];
    
    // Show "Save as leftover" dialog
    final shouldSave = await showDialog<bool>(
      context: context, 
      builder: (_) => AlertDialog(
        title: Text(LocaleHelper.t('save_as_leftover', Localizations.localeOf(context).languageCode)),
        content: Text(LocaleHelper.t('save_as_leftover_desc', Localizations.localeOf(context).languageCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text(LocaleHelper.t('no', Localizations.localeOf(context).languageCode))
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(LocaleHelper.t('yes', Localizations.localeOf(context).languageCode))
          ),
        ],
      )
    ) ?? false;

    if (shouldSave) {
      try {
        final convertedItem = _convertToFoodItem(item);
        await PantryService().saveLeftoverFromFoodItem(convertedItem, userId: Supabase.instance.client.auth.currentUser?.id ?? '');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocaleHelper.t('leftover_saved', Localizations.localeOf(context).languageCode))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving leftover: $e')),
          );
        }
      }
    }

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

  bool _isDailySodiumExceeded() {
    if (_userPreferences == null) return false;
    
    final dailySodiumMg = (widget.meal.mealSummary.totalSodium * 1000).round();
    return _preferencesService.isDailySodiumExceeded(
      dailySodiumMg: dailySodiumMg,
      prefs: _userPreferences!,
    );
  }

  Future<void> _autoReplaceHighSodiumItems() async {
    if (widget.isReadOnly) return;

    try {
      // Find items with high sodium content
      final highSodiumItems = <int>[];
      for (int i = 0; i < widget.meal.items.length; i++) {
        final item = widget.meal.items[i];
        final sodiumPerServing = item.sodium * 1000; // Convert to mg
        if (sodiumPerServing > 500) { // High sodium threshold
          highSodiumItems.add(i);
        }
      }

      if (highSodiumItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleHelper.t('no_high_sodium_items', Localizations.localeOf(context).languageCode))),
        );
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(LocaleHelper.t('auto_replace_high_sodium', Localizations.localeOf(context).languageCode)),
          content: Text(LocaleHelper.t('auto_replace_confirmation', Localizations.localeOf(context).languageCode)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(LocaleHelper.t('cancel', Localizations.localeOf(context).languageCode)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(LocaleHelper.t('replace', Localizations.localeOf(context).languageCode)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Replace high sodium items with low-sodium alternatives
        final updatedItems = List<FoodItem>.from(widget.meal.items);
        for (final index in highSodiumItems.reversed) {
          // For now, just remove high sodium items
          // TODO: Implement smart replacement with low-sodium alternatives
          updatedItems.removeAt(index);
        }
        
        final updatedMeal = widget.meal.copyWith(items: updatedItems);
        widget.onMealChanged(updatedMeal);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleHelper.t('high_sodium_items_replaced', Localizations.localeOf(context).languageCode))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to replace items: $e')),
      );
    }
  }





  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.cardBackground : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? DesignTokens.glassBorder : Colors.grey.shade200,
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal header with name input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                  ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                        : DesignTokens.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant_rounded,
                    color: DesignTokens.accentBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _labelController,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? DesignTokens.neutralWhite : Colors.grey.shade900,
                    ),
                    decoration: InputDecoration(
                      hintText: LocaleHelper.t('meal_name', language),
                      hintStyle: TextStyle(
                        color: isDark ? DesignTokens.textTertiary : Colors.grey.shade400,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => _updateMeal(),
                    readOnly: widget.isReadOnly,
                  ),
                ),
                if (!widget.isReadOnly)
                  IconButton(
                    onPressed: () => _showAddFoodMenu(context, language),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DesignTokens.accentBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    tooltip: LocaleHelper.t('add_food', language),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          
          // Sodium warning
          if (_isDailySodiumExceeded())
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: DesignTokens.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: DesignTokens.accentOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: DesignTokens.accentOrange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      LocaleHelper.t('sodium_above_limit', language),
                      style: TextStyle(
                        color: DesignTokens.accentOrange,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (!widget.isReadOnly)
                    TextButton(
                      onPressed: _autoReplaceHighSodiumItems,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        backgroundColor: DesignTokens.accentOrange.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        LocaleHelper.t('auto_replace', language),
                        style: TextStyle(
                          color: DesignTokens.accentOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          // Client comment box (if client view) - moved up for better UX
          if (widget.isClientView)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildClientCommentSection(language, isDark),
            ),
          
          // Food items list or empty state
          Padding(
            padding: const EdgeInsets.all(16),
            child: widget.meal.items.isEmpty
                ? _buildEmptyState(language, isDark)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.meal.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      if (item.recipeId != null) {
                        return RecipeItemTile(
                          key: ValueKey('recipe_tile_${item.hashCode}_$index'),
                          item: item,
                          onItemChanged: (updatedItem) => _updateItem(index, updatedItem),
                          onRemove: () => _removeItem(index),
                          onQuickSwap: (recipe) => _quickSwapRecipe(recipe, index),
                          isReadOnly: widget.isReadOnly,
                        );
                      }

                      return MacroTableRow(
                        key: ValueKey('macro_row_${item.hashCode}_$index'),
                        item: item,
                        onChanged: (updatedItem) => _updateItem(index, updatedItem),
                        onDelete: () => _removeItem(index),
                        isReadOnly: widget.isReadOnly,
                        parentMeal: widget.meal,
                      );
                    }).toList(),
                  ),
          ),
          
          // Quick action buttons (streamlined)
          if (!widget.isReadOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildQuickActions(language, isDark),
            ),
          
          // Meal summary (only shown when there are items)
          if (widget.meal.items.isNotEmpty)
            _buildMealSummary(language, isDark),
          
          // Attachments section (cleaner design)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildAttachmentsSection(isDark),
          ),
          
          // Coach notes (only for non-client view)
          if (!widget.isClientView)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildCoachNotesSection(language, isDark),
            ),
        ],
      ),
      ),
    );
  }

  void _showAddFoodMenu(BuildContext context, String language) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              LocaleHelper.t('add_food', language),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? DesignTokens.neutralWhite : Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(
              icon: Icons.fastfood_rounded,
              label: LocaleHelper.t('add_food', language),
              color: DesignTokens.accentBlue,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _addItem();
              },
            ),
            _buildMenuOption(
              icon: Icons.menu_book_rounded,
              label: LocaleHelper.t('add_recipe', language),
              color: DesignTokens.accentPurple,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _addRecipe();
              },
            ),
            _buildMenuOption(
              icon: Icons.camera_alt_rounded,
              label: LocaleHelper.t('add_via_photo', language),
              color: DesignTokens.accentGreen,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _addViaPhoto();
              },
            ),
            _buildMenuOption(
              icon: Icons.qr_code_scanner_rounded,
              label: LocaleHelper.t('scan_barcode', language),
              color: DesignTokens.accentOrange,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _scanBarcode();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? DesignTokens.neutralWhite : Colors.grey.shade800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? DesignTokens.textTertiary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String language, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark 
                  ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 28,
              color: isDark ? DesignTokens.accentBlue : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            LocaleHelper.t('no_food_items', language),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? DesignTokens.textSecondary : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            LocaleHelper.t('tap_to_add', language),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? DesignTokens.textTertiary : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(String language, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pantry toggle (subtle)
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _usePantryFirst = !_usePantryFirst),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _usePantryFirst
                      ? DesignTokens.accentGreen.withValues(alpha: 0.15)
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _usePantryFirst
                        ? DesignTokens.accentGreen.withValues(alpha: 0.4)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _usePantryFirst ? Icons.inventory_2 : Icons.inventory_2_outlined,
                      size: 16,
                      color: _usePantryFirst
                          ? DesignTokens.accentGreen
                          : (isDark ? DesignTokens.textTertiary : Colors.grey.shade500),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      LocaleHelper.t('use_pantry_first', language),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _usePantryFirst ? FontWeight.w500 : FontWeight.normal,
                        color: _usePantryFirst
                            ? DesignTokens.accentGreen
                            : (isDark ? DesignTokens.textTertiary : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Quick action grid (2x2)
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.fastfood_rounded,
                label: LocaleHelper.t('add_food', language),
                color: DesignTokens.accentBlue,
                isDark: isDark,
                onTap: _addItem,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.menu_book_rounded,
                label: LocaleHelper.t('add_recipe', language),
                color: DesignTokens.accentPurple,
                isDark: isDark,
                onTap: _addRecipe,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.camera_alt_rounded,
                label: LocaleHelper.t('add_via_photo', language),
                color: DesignTokens.accentGreen,
                isDark: isDark,
                onTap: _addViaPhoto,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.qr_code_scanner_rounded,
                label: LocaleHelper.t('scan_barcode', language),
                color: DesignTokens.accentOrange,
                isDark: isDark,
                onTap: _scanBarcode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealSummary(String language, bool isDark) {
    final summary = widget.meal.mealSummary;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  DesignTokens.accentGreen.withValues(alpha: 0.15),
                  DesignTokens.accentBlue.withValues(alpha: 0.1),
                ]
              : [
                  Colors.green.shade50,
                  Colors.blue.shade50,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? DesignTokens.accentGreen.withValues(alpha: 0.2)
              : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                size: 16,
                color: isDark ? DesignTokens.accentGreen : Colors.green.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                LocaleHelper.t('meal_summary', language),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? DesignTokens.accentGreen : Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMacroChip(
                label: LocaleHelper.t('protein', language),
                value: '${summary.totalProtein.toStringAsFixed(0)}g',
                color: const Color(0xFFEF4444),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildMacroChip(
                label: LocaleHelper.t('carbs', language),
                value: '${summary.totalCarbs.toStringAsFixed(0)}g',
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildMacroChip(
                label: LocaleHelper.t('fat', language),
                value: '${summary.totalFat.toStringAsFixed(0)}g',
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildMacroChip(
                label: LocaleHelper.t('kcal', language),
                value: summary.totalKcal.toStringAsFixed(0),
                color: DesignTokens.accentGreen,
                isDark: isDark,
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isHighlighted
              ? color.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: isHighlighted
              ? Border.all(color: color.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? DesignTokens.textTertiary : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? DesignTokens.glassBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file_rounded,
                size: 16,
                color: isDark ? DesignTokens.textSecondary : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                LocaleHelper.t('attachments', Localizations.localeOf(context).languageCode),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? DesignTokens.textSecondary : Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              if (!widget.isReadOnly)
                TextButton.icon(
                  onPressed: () => _updateAttachments(widget.meal.attachments),
                  icon: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: DesignTokens.accentBlue,
                  ),
                  label: Text(
                    LocaleHelper.t('add_files', Localizations.localeOf(context).languageCode),
                    style: TextStyle(
                      fontSize: 12,
                      color: DesignTokens.accentBlue,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                ),
            ],
          ),
          if (widget.meal.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.meal.attachments.asMap().entries.map((entry) {
                return _buildAttachmentChip(entry.value, entry.key, isDark);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentChip(String attachment, int index, bool isDark) {
    final fileName = Uri.tryParse(attachment)?.pathSegments.lastOrNull ?? 'File';
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp']
        .any((ext) => fileName.toLowerCase().endsWith(ext));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? DesignTokens.glassBorder : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded,
            size: 14,
            color: isDark ? DesignTokens.textSecondary : Colors.grey.shade500,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              fileName,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? DesignTokens.textSecondary : Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!widget.isReadOnly) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                final updated = List<String>.from(widget.meal.attachments)
                  ..removeAt(index);
                _updateAttachments(updated);
              },
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: isDark ? DesignTokens.textTertiary : Colors.grey.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoachNotesSection(String language, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? DesignTokens.glassBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_rounded,
                size: 16,
                color: isDark ? DesignTokens.textSecondary : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                LocaleHelper.t('coach_notes', language),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? DesignTokens.textSecondary : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: widget.meal.clientComment,
            onChanged: _updateComment,
            maxLines: 2,
            readOnly: widget.isReadOnly,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? DesignTokens.neutralWhite : Colors.grey.shade800,
            ),
            decoration: InputDecoration(
              hintText: LocaleHelper.t('add_notes_hint', language),
              hintStyle: TextStyle(
                color: isDark ? DesignTokens.textTertiary : Colors.grey.shade400,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCommentSection(String language, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.accentGreen.withValues(alpha: isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DesignTokens.accentGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.comment_rounded,
                size: 16,
                color: DesignTokens.accentGreen,
              ),
              const SizedBox(width: 6),
              Text(
                LocaleHelper.t('client_comment', language),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: DesignTokens.accentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: widget.meal.clientComment,
            onChanged: (value) {
              final updatedMeal = widget.meal.copyWith(clientComment: value);
              widget.onMealChanged(updatedMeal);
            },
            maxLines: 2,
            readOnly: widget.isReadOnly,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? DesignTokens.neutralWhite : Colors.grey.shade800,
            ),
            decoration: InputDecoration(
              hintText: LocaleHelper.t('add_comment_hint', language),
              hintStyle: TextStyle(
                color: isDark ? DesignTokens.textTertiary : Colors.grey.shade400,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
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
