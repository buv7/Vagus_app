import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../../services/ai/nutrition_ai.dart';
import 'MealEditor.dart';
import '../../widgets/nutrition/DailySummaryCard.dart';
import '../../widgets/ai/ai_usage_meter.dart';

class NutritionPlanBuilder extends StatefulWidget {
  final String? clientId;
  final NutritionPlan? planToEdit;

  const NutritionPlanBuilder({
    super.key,
    this.clientId,
    this.planToEdit,
  });

  @override
  State<NutritionPlanBuilder> createState() => _NutritionPlanBuilderState();
}

class _NutritionPlanBuilderState extends State<NutritionPlanBuilder> {
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

  @override
  void initState() {
    super.initState();
    _loadClients();
    _loadCoachProfile();
    _initializePlan();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Load clients linked to the current coach
      final response = await supabase
          .from('coach_clients')
          .select('client_id, profiles:client_id (id, name, email)')
          .eq('coach_id', user.id);

      final clients = (response as List<dynamic>)
          .map((row) => row['profiles'] as Map<String, dynamic>)
          .toList();

      if (kDebugMode) {
        debugPrint('NutritionPlanBuilder: Raw response: $response');
        debugPrint('NutritionPlanBuilder: Processed clients: $clients');
        debugPrint('NutritionPlanBuilder: User ID: ${user.id}');
      }

      setState(() {
        _clients = clients;
      });

      // Set default client if provided or if clients are available
      if (widget.clientId != null) {
        // Verify the provided clientId exists in the loaded clients
        final clientExists = clients.any((client) => client['id'].toString() == widget.clientId);
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
          label: 'Meal ${_meals.length + 1}',
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

  Future<void> _generateFullDay() async {
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
        debugPrint('Generating full day with targets: $targets, mealCount: $mealCount');
      }

      final generatedMeals = await _nutritionAI.generateFullDay(targets, mealCount);
      
      if (kDebugMode) {
        debugPrint('Generated ${generatedMeals.length} meals');
        for (int i = 0; i < generatedMeals.length; i++) {
          debugPrint('Meal $i: ${generatedMeals[i].label} with ${generatedMeals[i].items.length} items');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Generation failed: $e')),
        );
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
        title: const Text('Number of Meals'),
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
                  const SnackBar(content: Text('Please enter a number between 1 and 10')),
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
        title: const Text('Target Macros'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plan name')),
      );
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
            content: Text(notifyClient 
                ? '✅ Plan saved and client notified'
                : '✅ Plan saved as draft'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Save failed: $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _exportToPdf() async {
    if (widget.planToEdit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please save the plan first before exporting')),
      );
      return;
    }

    try {
      final plan = widget.planToEdit!;
      final coachName = _coachProfile?['name'] ?? 'Unknown Coach';
      final clientName = _clients
          .firstWhere(
            (client) => client['id'].toString() == plan.clientId,
            orElse: () => {'name': 'Unknown Client'},
          )['name'] ?? 'Unknown Client';

      await _nutritionService.exportNutritionPlanToPdf(plan, coachName, clientName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Export failed: $e')),
        );
      }
    }
  }

  Future<void> _duplicatePlan() async {
    if (widget.planToEdit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please save the plan first before duplicating')),
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
      await _nutritionService.duplicateNutritionPlan(widget.planToEdit!, selectedClientId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Plan duplicated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Duplication failed: $e')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planToEdit != null ? 'Edit Nutrition Plan' : 'Create Nutrition Plan'),
        actions: [
          if (widget.planToEdit != null) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export to PDF',
              onPressed: _exportToPdf,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'duplicate':
                    _duplicatePlan();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.copy),
                      SizedBox(width: 8),
                      Text('Duplicate Plan'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI Usage Meter at the top
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AIUsageMeter(
                      isCompact: true,
                      onRefresh: () {
                        // Refresh any necessary data
                      },
                    ),
                  ),
                  
                  // Client selector
                  if (_clients.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'No clients available. Please add clients to your account first.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedClientId,
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
                        if (value != null) {
                          setState(() {
                            _selectedClientId = value;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a client';
                        }
                        return null;
                      },
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Plan name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Plan Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Length type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Length', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Daily'),
                            selected: _selectedLengthType == 'daily',
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedLengthType = 'daily');
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Weekly'),
                            selected: _selectedLengthType == 'weekly',
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedLengthType = 'weekly');
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Program'),
                            selected: _selectedLengthType == 'program',
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedLengthType = 'program');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // AI Generation button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateFullDay,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate Full Day (AI)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Meals section header
                  Row(
                    children: [
                      const Text(
                        'Meals',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _addMeal,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Meal'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Meals list - simplified stable layout
                  _meals.isEmpty
                      ? Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No meals added yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Use "Generate Full Day (AI)" or "Add Meal" to get started.',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _meals.asMap().entries.map((entry) {
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
                                    onMealChanged: (updatedMeal) => _updateMeal(index, updatedMeal),
                                    isReadOnly: false,
                                    isClientView: false,
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
                                          label: const Text('Remove Meal', style: TextStyle(color: Colors.red)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                  
                  const SizedBox(height: 24),
                  
                  // Daily summary
                  DailySummaryCard(summary: _dailySummary),
                  
                  const SizedBox(height: 24),
                  
                  // Save buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : () => _savePlan(notifyClient: false),
                          child: Text(_saving ? 'Saving...' : 'Save Draft'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : () => _savePlan(notifyClient: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(_saving ? 'Saving...' : 'Save & Notify'),
                        ),
                      ),
                    ],
                  ),
                  
                  // Add extra padding at bottom for better scrolling
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
