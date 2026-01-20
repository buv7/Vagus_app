import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../theme/design_tokens.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../../services/ai/nutrition_ai.dart';
import '../../services/nutrition/locale_helper.dart';
import 'meal_editor.dart';
import '../../widgets/nutrition/daily_summary_card.dart';
import '../../widgets/ai/ai_usage_meter.dart';
import '../../widgets/anim/blocking_overlay.dart';
import '../supplements/supplement_editor_sheet.dart';
import '../../widgets/nutrition/animated/animated_glass_text_field.dart';
import '../../widgets/supplements/pill_icon.dart';

class NutritionPlanBuilder extends StatefulWidget {
  final String? clientId;
  final NutritionPlan? planToEdit;

  const NutritionPlanBuilder({super.key, this.clientId, this.planToEdit});

  @override
  State<NutritionPlanBuilder> createState() => _NutritionPlanBuilderState();
}

class _NutritionPlanBuilderState extends State<NutritionPlanBuilder>
    with TickerProviderStateMixin {
  final NutritionService _nutritionService = NutritionService();
  final NutritionAI _nutritionAI = NutritionAI();
  final supabase = Supabase.instance.client;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  String _selectedLengthType = 'daily';
  String? _selectedClientId;

  // Plan data
  List<Meal> _meals = [];
  DailySummary _dailySummary = DailySummary(
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    totalKcal: 0,
    totalSodium: 0,
    totalPotassium: 0,
  );

  // UI state
  bool _loading = false;
  bool _saving = false;
  List<Map<String, dynamic>> _clients = [];
  Map<String, dynamic>? _coachProfile;

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Advanced food picker lightweight catalog (offline-friendly)
  final List<FoodItem> _defaultFoods = [
    FoodItem(
      name: 'Chicken Breast 100g',
      protein: 31,
      carbs: 0,
      fat: 3.6,
      kcal: 165,
      sodium: 74,
      potassium: 256,
    ),
    FoodItem(
      name: 'White Rice 100g (cooked)',
      protein: 2.7,
      carbs: 28,
      fat: 0.3,
      kcal: 130,
      sodium: 1,
      potassium: 35,
    ),
    FoodItem(
      name: 'Salmon 100g',
      protein: 20,
      carbs: 0,
      fat: 13,
      kcal: 208,
      sodium: 59,
      potassium: 363,
    ),
    FoodItem(
      name: 'Whole Egg (1 large)',
      protein: 6,
      carbs: 0.6,
      fat: 5,
      kcal: 72,
      sodium: 71,
      potassium: 69,
    ),
    FoodItem(
      name: 'Avocado 100g',
      protein: 2,
      carbs: 9,
      fat: 15,
      kcal: 160,
      sodium: 7,
      potassium: 485,
    ),
    FoodItem(
      name: 'Broccoli 100g',
      protein: 2.8,
      carbs: 7,
      fat: 0.4,
      kcal: 35,
      sodium: 33,
      potassium: 316,
    ),
    FoodItem(
      name: 'Greek Yogurt 170g',
      protein: 17,
      carbs: 6,
      fat: 0,
      kcal: 100,
      sodium: 61,
      potassium: 240,
    ),
  ];

  // Favorites and recents (in-memory)
  final Set<String> _favoriteFoodNames = {};
  final List<String> _recentFoodNames = [];

  // Scale helper to adjust macros by multiplier
  FoodItem _scaleFood(FoodItem base, double multiplier, {String? newName}) {
    return FoodItem(
      name: newName ?? base.name,
      amount: (base.amount) * multiplier,
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

    // Initialize animation controllers
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentAnimationController,
            curve: Curves.easeOut,
          ),
        );

    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _contentAnimationController.forward();
      }
    });

    _loadClients();
    _loadCoachProfile();
    _initializePlan();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Load clients linked to the current coach
      final links = await supabase
          .from('coach_clients')
          .select('client_id')
          .eq('coach_id', user.id);

      List<Map<String, dynamic>> clients = [];
      if (links.isNotEmpty) {
        final clientIds = links
            .map((row) => row['client_id'] as String)
            .toList();

        final response = await supabase
            .from('profiles')
            .select('id, name, email')
            .inFilter('id', clientIds);

        clients = List<Map<String, dynamic>>.from(response);
      }

      if (kDebugMode) {
        debugPrint('NutritionPlanBuilder: Processed clients: $clients');
        debugPrint('NutritionPlanBuilder: User ID: ${user.id}');
      }

      setState(() {
        _clients = clients;
      });

      // Set default client if provided or if clients are available
      if (widget.clientId != null) {
        // Verify the provided clientId exists in the loaded clients
        final clientExists = clients.any(
          (client) => client['id'].toString() == widget.clientId,
        );
        if (clientExists) {
          _selectedClientId = widget.clientId;
        } else if (clients.isNotEmpty) {
          _selectedClientId = clients.first['id'].toString();
        }
      } else if (clients.isNotEmpty) {
        _selectedClientId = clients.first['id'].toString();
      }
    } catch (e) {
      debugPrint('Failed to load clients: $e');
    }
  }

  Future<void> _loadCoachProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _coachProfile = response;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to load coach profile: $e');
      }
    }
  }

  void _initializePlan() {
    if (widget.planToEdit != null) {
      final plan = widget.planToEdit!;
      _nameController.text = plan.name;
      _selectedLengthType = plan.lengthType;
      _selectedClientId = plan.clientId;
      _meals = List<Meal>.from(plan.meals);
      _dailySummary = plan.dailySummary;
    } else {
      // Create empty plan
      _meals = [
        Meal(
          label: 'Breakfast',
          items: [],
          mealSummary: MealSummary(
            totalProtein: 0,
            totalCarbs: 0,
            totalFat: 0,
            totalKcal: 0,
            totalSodium: 0,
            totalPotassium: 0,
          ),
        ),
      ];
      _recalculateDailySummary();
    }
  }

  void _recalculateDailySummary() {
    _dailySummary = NutritionPlan.recalcDailySummary(_meals);
  }

  void _addMeal() {
    setState(() {
      _meals.add(
        Meal(
          label:
              '${LocaleHelper.t('meal', Localizations.localeOf(context).languageCode)} ${_meals.length + 1}',
          items: [],
          mealSummary: MealSummary(
            totalProtein: 0,
            totalCarbs: 0,
            totalFat: 0,
            totalKcal: 0,
            totalSodium: 0,
            totalPotassium: 0,
          ),
        ),
      );
    });
    _recalculateDailySummary();
  }

  void _removeMeal(int index) {
    setState(() {
      _meals.removeAt(index);
    });
    _recalculateDailySummary();
  }

  void _updateMeal(int index, Meal meal) {
    setState(() {
      _meals[index] = meal;
    });
    _recalculateDailySummary();
  }

  // Advanced picker (reuses same UX as modern builder, simplified here)
  void _openAdvancedFoodPicker(int mealIndex) {
    String query = '';
    String activeFilter = 'All';
    final Map<String, Map<String, dynamic>> selected = {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                final items = _defaultFoods
                    .where(
                      (f) => f.name.toLowerCase().contains(query.toLowerCase()),
                    )
                    .toList();
                return Container(
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryDark,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    border: Border.all(color: DesignTokens.glassBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search foods',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (v) =>
                                  setModalState(() => query = v.trim()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final custom =
                                  await _showCreateCustomFoodDialog();
                              if (custom != null) {
                                setModalState(() {
                                  _defaultFoods.insert(0, custom);
                                  selected[custom.name] = {
                                    'food': custom,
                                    'quantity': 1.0,
                                    'unit': 'serv',
                                  };
                                });
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
                            for (final f in const [
                              'All',
                              'High Protein',
                              'Low Carb',
                              'Low Fat',
                              'Under 200 kcal',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(f),
                                  selected: activeFilter == f,
                                  onSelected: (_) =>
                                      setModalState(() => activeFilter = f),
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
                            final isSelected = selected.containsKey(f.name);
                            return Card(
                              color: DesignTokens.cardBackground,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  f.name,
                                  style: const TextStyle(color: DesignTokens.neutralWhite),
                                ),
                                subtitle: Text(
                                  'P ${f.protein}g • C ${f.carbs}g • F ${f.fat}g • ${f.kcal.toStringAsFixed(0)} kcal',
                                  style: const TextStyle(
                                    color: DesignTokens.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Favorite',
                                      icon: Icon(
                                        _favoriteFoodNames.contains(f.name)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: DesignTokens.accentGreen,
                                      ),
                                      onPressed: () => setModalState(() {
                                        if (_favoriteFoodNames.contains(
                                          f.name,
                                        )) {
                                          _favoriteFoodNames.remove(f.name);
                                        } else {
                                          _favoriteFoodNames.add(f.name);
                                        }
                                      }),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.add_circle_outline,
                                        color: DesignTokens.accentGreen,
                                      ),
                                      onPressed: () => setModalState(() {
                                        if (isSelected) {
                                          selected.remove(f.name);
                                        } else {
                                          selected[f.name] = {
                                            'food': f,
                                            'quantity': 100.0,
                                            'unit': 'g',
                                          };
                                        }
                                      }),
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
                                decoration: BoxDecoration(
                                  color: DesignTokens.cardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            base.name,
                                            style: const TextStyle(
                                              color: DesignTokens.neutralWhite,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: DesignTokens.textSecondary,
                                          ),
                                          onPressed: () => setModalState(() {
                                            selected.remove(e.key);
                                          }),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              hintText: 'Qty',
                                            ),
                                            onChanged: (v) => setModalState(() {
                                              selected[e.key]!['quantity'] =
                                                  double.tryParse(v) ?? qty;
                                            }),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        DropdownButton<String>(
                                          value: unit,
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'g',
                                              child: Text('g'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'serv',
                                              child: Text('serv'),
                                            ),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setModalState(() {
                                                selected[e.key]!['unit'] = val;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              selected.forEach((_, v) {
                                final base = v['food'] as FoodItem;
                                final qty = v['quantity'] as double;
                                final unit = v['unit'] as String;
                                double multiplier;
                                if (unit == 'serv') {
                                  multiplier = qty;
                                } else {
                                  final isPer100g = base.name.contains('100g');
                                  multiplier = isPer100g
                                      ? qty / 100.0
                                      : (qty /
                                            (base.amount == 0
                                                ? 100
                                                : base.amount));
                                }
                                final scaled = _scaleFood(base, multiplier);
                                _appendFoodToMeal(mealIndex, scaled);
                                _recentFoodNames.remove(base.name);
                                _recentFoodNames.insert(0, base.name);
                                if (_recentFoodNames.length > 10) {
                                  _recentFoodNames.removeLast();
                                }
                              });
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Add to meal'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _appendFoodToMeal(int mealIndex, FoodItem food) {
    final meal = _meals[mealIndex];
    final updatedItems = List<FoodItem>.from(meal.items)..add(food);
    final updatedSummary = NutritionPlan.recalcMealSummary(
      meal.copyWith(items: updatedItems),
    );
    setState(() {
      _meals[mealIndex] = meal.copyWith(
        items: updatedItems,
        mealSummary: updatedSummary,
      );
    });
  }

  Future<void> _generateFullDay() async {
    final locale = Localizations.localeOf(context).languageCode;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client first')),
      );
      return;
    }

    // Show meal count dialog first
    final mealCount = await _showMealCountDialog();
    if (mealCount == null) return;

    // Show target macros dialog
    final targets = await _showTargetMacrosDialog();
    if (targets == null) return;

    try {
      setState(() => _loading = true);

      if (kDebugMode) {
        debugPrint(
          'Generating full day with targets: $targets, mealCount: $mealCount',
        );
      }
      if (!mounted) return;
      final generatedMeals = await runWithBlockingLoader(
        context,
        _nutritionAI.generateFullDay(
          calories: targets['calories'] ?? 0.0,
          protein: targets['protein'] ?? 0.0,
          carbs: targets['carbs'] ?? 0.0,
          fat: targets['fat'] ?? 0.0,
          locale: locale,
        ),
        showSuccess: true,
      );

      if (kDebugMode) {
        debugPrint('Generated ${generatedMeals.length} meals');
        for (int i = 0; i < generatedMeals.length; i++) {
          debugPrint(
            'Meal $i: ${generatedMeals[i].label} with ${generatedMeals[i].items.length} items',
          );
        }
      }

      // Ensure we're still mounted before updating state
      if (!mounted) return;

      // Simple state update without complex layout
      setState(() {
        _meals = generatedMeals;
        _recalculateDailySummary();
      });

      if (kDebugMode) {
        debugPrint('Updated _meals list with ${_meals.length} meals');
      }

      // Simple success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Full day generated successfully')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating full day: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Generation failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<int?> _showMealCountDialog() async {
    final mealCountController = TextEditingController(text: '4');

    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          LocaleHelper.t(
            'number_of_meals',
            Localizations.localeOf(context).languageCode,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How many meals do you want to split these macros and calories into?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: mealCountController,
              decoration: const InputDecoration(
                labelText: 'Number of Meals',
                border: OutlineInputBorder(),
                helperText: 'Enter a number between 1 and 10',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final mealCount = int.tryParse(mealCountController.text) ?? 4;
              if (mealCount >= 1 && mealCount <= 10) {
                Navigator.pop(context, mealCount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a number between 1 and 10'),
                  ),
                );
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, double>?> _showTargetMacrosDialog() async {
    final proteinController = TextEditingController(text: '160');
    final carbsController = TextEditingController(text: '140');
    final fatController = TextEditingController(text: '50');
    final kcalController = TextEditingController(text: '1860');

    return showDialog<Map<String, double>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          LocaleHelper.t(
            'target_macros',
            Localizations.localeOf(context).languageCode,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: proteinController,
              decoration: const InputDecoration(
                labelText: 'Protein (g)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: carbsController,
              decoration: const InputDecoration(
                labelText: 'Carbs (g)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: fatController,
              decoration: const InputDecoration(
                labelText: 'Fat (g)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: kcalController,
              decoration: const InputDecoration(
                labelText: 'Calories',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final protein = double.tryParse(proteinController.text) ?? 0;
              final carbs = double.tryParse(carbsController.text) ?? 0;
              final fat = double.tryParse(fatController.text) ?? 0;
              final kcal = double.tryParse(kcalController.text) ?? 0;

              Navigator.pop(context, {
                'protein': protein,
                'carbs': carbs,
                'fat': fat,
                'kcal': kcal,
              });
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePlan({bool notifyClient = false}) async {
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a client')));
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a plan name')));
      return;
    }

    try {
      setState(() => _saving = true);

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final plan = NutritionPlan(
        id: widget.planToEdit?.id,
        clientId: _selectedClientId!,
        name: _nameController.text.trim(),
        lengthType: _selectedLengthType,
        createdBy: user.id,
        createdAt: widget.planToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        meals: _meals,
        dailySummary: _dailySummary,
        aiGenerated: false,
        unseenUpdate: notifyClient,
      );

      if (widget.planToEdit != null) {
        await _nutritionService.updatePlan(plan);
      } else {
        await _nutritionService.createPlan(plan);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              notifyClient
                  ? '✅ Plan saved and client notified'
                  : '✅ Plan saved as draft',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Save failed: $e')));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _exportToPdf() async {
    if (widget.planToEdit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save the plan first before exporting'),
        ),
      );
      return;
    }

    try {
      final plan = widget.planToEdit!;
      final coachName = _coachProfile?['name'] ?? 'Unknown Coach';
      final clientName =
          _clients.firstWhere(
            (client) => client['id'].toString() == plan.clientId,
            orElse: () => {'name': 'Unknown Client'},
          )['name'] ??
          'Unknown Client';

      await _nutritionService.exportNutritionPlanToPdf(
        plan,
        coachName,
        clientName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Export failed: $e')));
      }
    }
  }

  Future<void> _duplicatePlan() async {
    if (widget.planToEdit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save the plan first before duplicating'),
        ),
      );
      return;
    }

    if (_clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No clients available for duplication')),
      );
      return;
    }

    // Show client selection dialog
    final selectedClientId = await _showClientSelectionDialog();
    if (selectedClientId == null) return;

    try {
      await _nutritionService.duplicateNutritionPlan(
        widget.planToEdit!,
        selectedClientId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Plan duplicated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Duplication failed: $e')));
      }
    }
  }

  Future<String?> _showClientSelectionDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Target Client'),
        content: SizedBox(
          width: double.maxFinite,
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Client',
              border: OutlineInputBorder(),
            ),
            items: _clients.map((client) {
              final clientId = client['id']?.toString() ?? '';
              final clientName = client['name'] ?? client['email'] ?? 'Unknown';
              return DropdownMenuItem<String>(
                value: clientId,
                child: Text(clientName),
              );
            }).toList(),
            onChanged: (value) {
              Navigator.pop(context, value);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshNutritionData() async {
    try {
      // Refresh the current plan data if editing an existing plan
      if (widget.planToEdit != null) {
        // Reload the plan data - this is a simple refresh since we don't have a _loadPlan method
        setState(() {
          // Trigger a rebuild to show any updated data
        });
      }
    } catch (_) {
      // no-op
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocaleHelper.isRTL(
      Localizations.localeOf(context).languageCode,
    );

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildGlassmorphismAppBar(context),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: SafeArea(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            DesignTokens.accentGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          LocaleHelper.t(
                            'loading',
                            Localizations.localeOf(context).languageCode,
                          ),
                          style: const TextStyle(
                            color: DesignTokens.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAnimatedSection(
                              delay: 0,
                              child: _buildAIUsageMeter(context),
                            ),
                            const SizedBox(height: 24),
                            _buildAnimatedSection(
                              delay: 100,
                              child: _buildClientSelector(context),
                            ),
                            const SizedBox(height: 20),
                            _buildAnimatedSection(
                              delay: 200,
                              child: _buildPlanNameInput(context),
                            ),
                            const SizedBox(height: 20),
                            _buildAnimatedSection(
                              delay: 300,
                              child: _buildLengthSelector(context),
                            ),
                            const SizedBox(height: 24),
                            _buildAnimatedSection(
                              delay: 400,
                              child: _buildAIGenerateButton(context),
                            ),
                            const SizedBox(height: 32),
                            _buildAnimatedSection(
                              delay: 500,
                              child: _buildMealsSection(context),
                            ),
                            const SizedBox(height: 24),
                            _buildAnimatedSection(
                              delay: 600,
                              child: DailySummaryCard(summary: _dailySummary),
                            ),
                            const SizedBox(height: 24),
                            _buildAnimatedSection(
                              delay: 700,
                              child: _buildSaveButtons(context),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(context),
      ),
    );
  }

  PreferredSizeWidget _buildGlassmorphismAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              border: const Border(
                bottom: BorderSide(color: Colors.white10, width: 1),
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: DesignTokens.neutralWhite),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      title: Text(
        widget.planToEdit != null
            ? LocaleHelper.t(
                'edit_nutrition_plan',
                Localizations.localeOf(context).languageCode,
              )
            : LocaleHelper.t(
                'create_nutrition_plan',
                Localizations.localeOf(context).languageCode,
              ),
        style: const TextStyle(
          color: DesignTokens.neutralWhite,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Add supplement',
          icon: const PillIcon(size: 24),
          onPressed: () async {
            if (!context.mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SupplementEditorSheet(
                  clientId: _selectedClientId,
                  onSaved: (supplement) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Supplement created')),
                    );
                    unawaited(_refreshNutritionData());
                  },
                ),
              ),
            );
          },
        ),
        if (widget.planToEdit != null)
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: DesignTokens.neutralWhite),
            tooltip: LocaleHelper.t(
              'export_pdf',
              Localizations.localeOf(context).languageCode,
            ),
            onPressed: _exportToPdf,
          ),
        if (widget.planToEdit != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: DesignTokens.neutralWhite),
            onSelected: (value) {
              if (value == 'duplicate') {
                _duplicatePlan();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'duplicate',
                child: Row(
                  children: [
                    const Icon(Icons.copy),
                    const SizedBox(width: 8),
                    Text(
                      LocaleHelper.t(
                        'duplicate_plan',
                        Localizations.localeOf(context).languageCode,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAnimatedSection({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
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
        backgroundColor: DesignTokens.cardBackground,
        title: const Text(
          'Create custom food',
          style: TextStyle(color: DesignTokens.neutralWhite),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMacroField('Name', nameController, text: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMacroField('Protein (g)', proteinController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMacroField('Carbs (g)', carbsController),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildMacroField('Fat (g)', fatController)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMacroField('Kcal', kcalController)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMacroField('Sodium (mg)', sodiumController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMacroField(
                      'Potassium (mg)',
                      potassiumController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildMacroField('Servings (default 1)', servingsController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final protein = double.tryParse(proteinController.text) ?? 0;
              final carbs = double.tryParse(carbsController.text) ?? 0;
              final fat = double.tryParse(fatController.text) ?? 0;
              final kcal =
                  double.tryParse(kcalController.text) ??
                  (protein * 4 + carbs * 4 + fat * 9);
              final sodium = double.tryParse(sodiumController.text) ?? 0;
              final potassium = double.tryParse(potassiumController.text) ?? 0;
              final serv = double.tryParse(servingsController.text) ?? 1;

              final food = FoodItem(
                name: name,
                protein: protein,
                carbs: carbs,
                fat: fat,
                kcal: kcal,
                sodium: sodium,
                potassium: potassium,
                servings: serv,
                amount: 0,
                estimated: true,
              );
              Navigator.pop(context, food);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroField(
    String label,
    TextEditingController c, {
    bool text = false,
  }) {
    return TextField(
      controller: c,
      keyboardType: text ? TextInputType.text : TextInputType.number,
      style: const TextStyle(color: DesignTokens.neutralWhite),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: DesignTokens.textSecondary),
        filled: true,
        fillColor: DesignTokens.primaryDark,
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: DesignTokens.glassBorder),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // GLASSMORPHISM UI COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildAIUsageMeter(BuildContext context) {
    return AIUsageMeter(
      isCompact: true,
      onRefresh: () {
        // Refresh any necessary data
      },
    );
  }

  Widget _buildClientSelector(BuildContext context) {
    if (_clients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.15),
              Colors.orange.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                LocaleHelper.t(
                  'no_clients_add_first',
                  Localizations.localeOf(context).languageCode,
                ),
                style: const TextStyle(color: DesignTokens.textSecondary, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    final selectedClient = _clients.firstWhere(
      (client) => client['id']?.toString() == _selectedClientId,
      orElse: () => _clients.first,
    );
    final clientName =
        selectedClient['name'] ?? selectedClient['email'] ?? 'Unknown';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showClientSelectorDialog(context),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [DesignTokens.accentGreen, DesignTokens.accentBlue],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: DesignTokens.neutralWhite,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocaleHelper.t(
                              'client',
                              Localizations.localeOf(context).languageCode,
                            ),
                            style: const TextStyle(
                              color: DesignTokens.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            clientName,
                            style: const TextStyle(
                              color: DesignTokens.neutralWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: DesignTokens.textSecondary,
                      size: 24,
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

  void _showClientSelectorDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Client',
                style: TextStyle(
                  color: DesignTokens.neutralWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _clients.length,
              itemBuilder: (context, index) {
                final client = _clients[index];
                final clientId = client['id']?.toString() ?? '';
                final clientName =
                    client['name'] ?? client['email'] ?? 'Unknown';
                final isSelected = clientId == _selectedClientId;

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? DesignTokens.accentGreen
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person,
                      color: isSelected ? DesignTokens.neutralWhite : DesignTokens.textSecondary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    clientName,
                    style: const TextStyle(color: DesignTokens.neutralWhite, fontSize: 16),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: DesignTokens.accentGreen)
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedClientId = clientId;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanNameInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plan Name',
          style: TextStyle(
            color: DesignTokens.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedGlassTextField(
          controller: _nameController,
          hint: LocaleHelper.t(
            'plan_name',
            Localizations.localeOf(context).languageCode,
          ),
          icon: Icons.edit_note,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildLengthSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleHelper.t(
            'length',
            Localizations.localeOf(context).languageCode,
          ),
          style: const TextStyle(
            color: DesignTokens.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildLengthChip(context, 'daily', 'Daily'),
            const SizedBox(width: 12),
            _buildLengthChip(context, 'weekly', 'Weekly'),
            const SizedBox(width: 12),
            _buildLengthChip(context, 'program', 'Program'),
          ],
        ),
      ],
    );
  }

  Widget _buildLengthChip(BuildContext context, String value, String label) {
    final isSelected = _selectedLengthType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedLengthType = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [DesignTokens.accentGreen, DesignTokens.accentBlue],
                  )
                : null,
            color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? DesignTokens.accentGreen
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: DesignTokens.accentGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            LocaleHelper.t(value, Localizations.localeOf(context).languageCode),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DesignTokens.neutralWhite,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIGenerateButton(BuildContext context) {
    return GestureDetector(
      onTap: _loading
          ? null
          : () {
              HapticFeedback.mediumImpact();
              _generateFullDay();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _loading
                ? [Colors.grey, Colors.grey.shade700]
                : [const Color(0xFFAA4FFF), const Color(0xFF8B3FE8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _loading
                  ? Colors.transparent
                  : const Color(0xFFAA4FFF).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Icon(Icons.auto_awesome, color: DesignTokens.neutralWhite, size: 22),
            const SizedBox(width: 12),
            Text(
              _loading
                  ? 'Generating...'
                  : LocaleHelper.t(
                      'generate_full_day_ai',
                      Localizations.localeOf(context).languageCode,
                    ),
              style: const TextStyle(
                color: DesignTokens.neutralWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LocaleHelper.t(
                'meals',
                Localizations.localeOf(context).languageCode,
              ),
              style: const TextStyle(
                color: DesignTokens.neutralWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addMeal,
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                LocaleHelper.t(
                  'add_meal',
                  Localizations.localeOf(context).languageCode,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.accentGreen,
                foregroundColor: DesignTokens.neutralWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_meals.isEmpty)
          _buildEmptyMealsState(context)
        else
          ..._meals.asMap().entries.map((entry) {
            final index = entry.key;
            final meal = entry.value;
            return Padding(
              key: ValueKey('meal_${meal.hashCode}_$index'),
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MealEditor(
                    key: ValueKey('meal_editor_${meal.hashCode}_$index'),
                    meal: meal,
                    onMealChanged: (updatedMeal) =>
                        _updateMeal(index, updatedMeal),
                    isReadOnly: false,
                    isClientView: false,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _openAdvancedFoodPicker(index),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Add Food (Advanced)'),
                    ),
                  ),
                  if (_meals.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _removeMeal(index),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: Text(
                            LocaleHelper.t(
                              'remove_meal',
                              Localizations.localeOf(context).languageCode,
                            ),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildEmptyMealsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            LocaleHelper.t(
              'no_meals_added',
              Localizations.localeOf(context).languageCode,
            ),
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LocaleHelper.t(
              'use_ai_or_add_meal',
              Localizations.localeOf(context).languageCode,
            ),
            style: const TextStyle(color: DesignTokens.textTertiary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _saving
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _savePlan(notifyClient: false);
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _saving
                      ? [Colors.grey, Colors.grey.shade700]
                      : [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                _saving
                    ? LocaleHelper.t(
                        'saving',
                        Localizations.localeOf(context).languageCode,
                      )
                    : LocaleHelper.t(
                        'save_draft',
                        Localizations.localeOf(context).languageCode,
                      ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: DesignTokens.neutralWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: _saving
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _savePlan(notifyClient: true);
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _saving
                      ? [Colors.grey, Colors.grey.shade700]
                      : [DesignTokens.accentGreen, DesignTokens.accentBlue],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _saving
                    ? []
                    : [
                        BoxShadow(
                          color: DesignTokens.accentGreen.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, color: DesignTokens.neutralWhite, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _saving
                        ? LocaleHelper.t(
                            'saving',
                            Localizations.localeOf(context).languageCode,
                          )
                        : LocaleHelper.t(
                            'save_notify',
                            Localizations.localeOf(context).languageCode,
                          ),
                    style: const TextStyle(
                      color: DesignTokens.neutralWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    return null; // We're using inline save buttons instead
  }
}
