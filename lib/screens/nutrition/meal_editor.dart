import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../models/nutrition/recipe.dart';
import '../../models/nutrition/preferences.dart';
import '../../models/nutrition/food_item.dart' as fi;
import '../../widgets/nutrition/macro_table_row.dart';
import '../../widgets/nutrition/file_attach_to_meal.dart';
import '../../widgets/nutrition/client_nutrition_comment_box.dart';
import '../../components/nutrition/recipe_item_tile.dart';
import '../../components/nutrition/recipe_quick_swap_sheet.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../../services/nutrition/preferences_service.dart';
import '../../services/nutrition/pantry_service.dart';
import 'recipe_library_screen.dart';
import 'barcode_scan_screen.dart';
import 'food_snap_screen.dart';


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
              decoration: BoxDecoration(color: Colors.black, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(hintText: 'Search foods', prefixIcon: Icon(Icons.search)),
                        onChanged: (v) => setSheet(() => query = v.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final c = await _showCreateCustomFoodDialog();
                        if (c != null) {
                          setSheet(() { selected[c.name] = {'food': c, 'quantity': 1.0, 'unit': 'serv'}; });
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Custom'),
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
                      return Card(
                        color: Colors.grey.shade900,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(f.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text('P ${f.protein}g • C ${f.carbs}g • F ${f.fat}g • ${f.kcal.toStringAsFixed(0)} kcal', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Favorite',
                                icon: Icon(_favoriteFoodNames.contains(f.name) ? Icons.favorite : Icons.favorite_border, color: Colors.greenAccent),
                                onPressed: () => setSheet(() { if (_favoriteFoodNames.contains(f.name)) _favoriteFoodNames.remove(f.name); else _favoriteFoodNames.add(f.name); }),
                              ),
                              IconButton(
                                icon: Icon(isSel ? Icons.check_circle : Icons.add_circle_outline, color: Colors.greenAccent),
                                onPressed: () => setSheet(() { if (isSel) selected.remove(f.name); else selected[f.name] = {'food': f, 'quantity': 100.0, 'unit': 'g'}; }),
                              ),
                            ],
                          ),
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
                          decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12)),
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
                    child: ElevatedButton.icon(
                      onPressed: () {
                        var updated = List<FoodItem>.from(widget.meal.items);
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
                      icon: const Icon(Icons.check),
                      label: const Text('Add to meal'),
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
        await PantryService().saveLeftoverFromFoodItem(item as fi.FoodItem, userId: Supabase.instance.client.auth.currentUser?.id ?? '');
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.add),
                    tooltip: LocaleHelper.t('add_food', language),
                    onSelected: (value) {
                      switch (value) {
                        case 'food':
                          _addItem();
                          break;
                        case 'recipe':
                          _addRecipe();
                          break;
                        case 'advanced_food':
                          unawaited(_addFoodAdvanced());
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'food',
                        child: Row(
                          children: [
                            const Icon(Icons.fastfood, size: 16),
                            const SizedBox(width: 8),
                            Text(LocaleHelper.t('add_food', language)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'advanced_food',
                        child: Row(
                          children: [
                            const Icon(Icons.add_circle_outline, size: 16),
                            const SizedBox(width: 8),
                            Text('Add Food (Advanced)'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'recipe',
                        child: Row(
                          children: [
                            const Icon(Icons.restaurant_menu, size: 16),
                            const SizedBox(width: 8),
                            Text(LocaleHelper.t('add_recipe', language)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            
            // Sodium warning chip
            if (_isDailySodiumExceeded()) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        LocaleHelper.t('sodium_above_limit', language),
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (!widget.isReadOnly)
                      TextButton(
                        onPressed: _autoReplaceHighSodiumItems,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          LocaleHelper.t('auto_replace', language),
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            
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

            // Direct food item cards (no table wrapper)
            if (widget.meal.items.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                child: Text(
                  'No food items added yet',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.meal.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  // Show recipe items with special tile
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

                  // Show regular food items with table row
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
            
            // Add item buttons
            if (!widget.isReadOnly) ...[
              const SizedBox(height: 8),
              
              // Use pantry first toggle
              Row(
                children: [
                  FilterChip(
                    selected: _usePantryFirst,
                    label: Text(LocaleHelper.t('use_pantry_first', Localizations.localeOf(context).languageCode)),
                    onSelected: (v) => setState(() => _usePantryFirst = v),
                    avatar: Icon(
                      _usePantryFirst ? Icons.inventory_2 : Icons.inventory_2_outlined,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.fastfood),
                      label: Text(LocaleHelper.t('add_food', Localizations.localeOf(context).languageCode)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addRecipe,
                      icon: const Icon(Icons.restaurant_menu),
                      label: Text(LocaleHelper.t('add_recipe', Localizations.localeOf(context).languageCode)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addViaPhoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(LocaleHelper.t('add_via_photo', Localizations.localeOf(context).languageCode)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scanBarcode,
                      icon: const Icon(Icons.qr_code_scanner_outlined),
                      label: Text(LocaleHelper.t('scan_barcode', Localizations.localeOf(context).languageCode)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.purple.shade700,
                        side: BorderSide(color: Colors.purple.shade300),
                      ),
                    ),
                  ),
                ],
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
