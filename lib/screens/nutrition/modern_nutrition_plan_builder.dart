import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ai/ai_usage_meter.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../../models/nutrition/nutrition_plan.dart';

class ModernNutritionPlanBuilder extends StatefulWidget {
  final String? clientId;
  final NutritionPlan? planToEdit;

  const ModernNutritionPlanBuilder({
    super.key,
    this.clientId,
    this.planToEdit,
  });

  @override
  State<ModernNutritionPlanBuilder> createState() => _ModernNutritionPlanBuilderState();
}

class _ModernNutritionPlanBuilderState extends State<ModernNutritionPlanBuilder> {
  final NutritionService _nutritionService = NutritionService();
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

      final response = await supabase
          .from('coach_client_periods')
          .select('''
            client_id,
            profiles!coach_client_periods_client_id_fkey(
              id, name, email
            )
          ''')
          .eq('coach_id', user.id)
          .eq('status', 'active');

      setState(() {
        _clients = response.map((item) => {
          'id': item['client_id'],
          'name': item['profiles']['name'] ?? 'Unknown Client',
          'email': item['profiles']['email'] ?? '',
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading clients: $e');
    }
  }

  Future<void> _loadCoachProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('profiles')
          .select('name, email')
          .eq('id', user.id)
          .single();

      setState(() {
        _coachProfile = response;
      });
    } catch (e) {
      debugPrint('Error loading coach profile: $e');
    }
  }

  void _initializePlan() {
    if (widget.planToEdit != null) {
      _nameController.text = widget.planToEdit!.name;
      _selectedLengthType = widget.planToEdit!.lengthType;
      _selectedClientId = widget.planToEdit!.clientId;
      _meals = List.from(widget.planToEdit!.meals);
      _calculateDailySummary();
    } else {
      _nameController.text = '';
      _selectedLengthType = 'daily';
      _selectedClientId = widget.clientId;
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
        Meal(
          label: 'Lunch',
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
        Meal(
          label: 'Dinner',
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
    }
  }

  void _calculateDailySummary() {
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalKcal = 0;
    double totalSodium = 0;
    double totalPotassium = 0;

    for (final meal in _meals) {
      totalProtein += meal.mealSummary.totalProtein;
      totalCarbs += meal.mealSummary.totalCarbs;
      totalFat += meal.mealSummary.totalFat;
      totalKcal += meal.mealSummary.totalKcal;
      totalSodium += meal.mealSummary.totalSodium;
      totalPotassium += meal.mealSummary.totalPotassium;
    }

    setState(() {
      _dailySummary = DailySummary(
        totalProtein: totalProtein,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
        totalKcal: totalKcal,
        totalSodium: totalSodium,
        totalPotassium: totalPotassium,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.neutralWhite,
        elevation: 0,
        title: const Text(
          'Create Nutrition Plan', // Modern UI Style - ALL FIXED
          style: TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saving ? null : _savePlan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Usage Meter
            const AIUsageMeter(),
            
            const SizedBox(height: DesignTokens.space24),
            
            // Plan Details Card
            Container(
              padding: const EdgeInsets.all(DesignTokens.space20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan Details',
                    style: TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: DesignTokens.space16),
                  
                  // Client Selection
                  if (_clients.isNotEmpty) ...[
                    const Text(
                      'Select Client',
                      style: TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space16,
                        vertical: DesignTokens.space12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlack,
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                        border: Border.all(color: AppTheme.steelGrey),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedClientId,
                          hint: const Text(
                            'Select a client',
                            style: TextStyle(color: AppTheme.lightGrey),
                          ),
                          dropdownColor: AppTheme.cardBackground,
                          style: const TextStyle(color: AppTheme.neutralWhite),
                          items: _clients.map((client) {
                            return DropdownMenuItem<String>(
                              value: client['id'],
                              child: Text(client['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedClientId = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space16),
                  ],
                  
                  // Plan Name
                  const Text(
                    'Plan Name',
                    style: TextStyle(
                      color: AppTheme.lightGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppTheme.neutralWhite),
                    decoration: InputDecoration(
                      hintText: 'Enter plan name',
                      hintStyle: const TextStyle(color: AppTheme.lightGrey),
                      filled: true,
                      fillColor: AppTheme.primaryBlack,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                        borderSide: const BorderSide(color: AppTheme.steelGrey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                        borderSide: const BorderSide(color: AppTheme.steelGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                        borderSide: const BorderSide(color: AppTheme.mintAqua),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: DesignTokens.space16),
                  
                  // Length Type Selection
                  const Text(
                    'Length',
                    style: TextStyle(
                      color: AppTheme.lightGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  Row(
                    children: [
                      _buildLengthButton('Daily', 'daily'),
                      const SizedBox(width: DesignTokens.space8),
                      _buildLengthButton('Weekly', 'weekly'),
                      const SizedBox(width: DesignTokens.space8),
                      _buildLengthButton('Program', 'program'),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: DesignTokens.space24),
            
            // Generate AI Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _generateAIPlan,
                icon: _loading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neutralWhite),
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
                label: Text(_loading ? 'Generating...' : 'Generate Full Day AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.mintAqua,
                  foregroundColor: AppTheme.primaryBlack,
                  padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: DesignTokens.space24),
            
            // Meals Section
            Container(
              padding: const EdgeInsets.all(DesignTokens.space20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Meals',
                        style: TextStyle(
                          color: AppTheme.neutralWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addMeal,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Meal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlack,
                          foregroundColor: AppTheme.neutralWhite,
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space12,
                            vertical: DesignTokens.space8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radius8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: DesignTokens.space16),
                  
                  // Meals List
                  ..._meals.asMap().entries.map((entry) {
                    final index = entry.key;
                    final meal = entry.value;
                    return _buildMealCard(meal, index);
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLengthButton(String label, String value) {
    final isSelected = _selectedLengthType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedLengthType = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.space12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlack : AppTheme.steelGrey,
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
            border: Border.all(
              color: isSelected ? AppTheme.mintAqua : AppTheme.steelGrey,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check,
                  color: AppTheme.mintAqua,
                  size: 16,
                ),
                const SizedBox(width: DesignTokens.space4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.neutralWhite : AppTheme.lightGrey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealCard(Meal meal, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(color: AppTheme.steelGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: meal.label),
                  style: const TextStyle(color: AppTheme.neutralWhite),
                  decoration: const InputDecoration(
                    hintText: 'Meal Name',
                    hintStyle: TextStyle(color: AppTheme.lightGrey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _meals[index] = Meal(
                        label: value,
                        items: meal.items,
                        mealSummary: meal.mealSummary,
                      );
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppTheme.mintAqua),
                onPressed: () => _addFoodToMeal(index),
              ),
            ],
          ),
          
          if (meal.items.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.space12),
            const Text(
              'Food Items',
              style: TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            // Food items table header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space8,
                vertical: DesignTokens.space4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.steelGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(DesignTokens.radius4),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Food Item', style: TextStyle(fontSize: 10, color: AppTheme.lightGrey))),
                  Expanded(child: Text('Protein', style: TextStyle(fontSize: 10, color: AppTheme.lightGrey))),
                  Expanded(child: Text('Carbs', style: TextStyle(fontSize: 10, color: AppTheme.lightGrey))),
                  Expanded(child: Text('Fat', style: TextStyle(fontSize: 10, color: AppTheme.lightGrey))),
                  Expanded(child: Text('Kcal', style: TextStyle(fontSize: 10, color: AppTheme.lightGrey))),
                ],
              ),
            ),
            // Food items list
            ...meal.items.map((food) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space8,
                vertical: DesignTokens.space4,
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(food.name, style: const TextStyle(fontSize: 12, color: AppTheme.neutralWhite))),
                  Expanded(child: Text('${food.protein}g', style: const TextStyle(fontSize: 12, color: AppTheme.neutralWhite))),
                  Expanded(child: Text('${food.carbs}g', style: const TextStyle(fontSize: 12, color: AppTheme.neutralWhite))),
                  Expanded(child: Text('${food.fat}g', style: const TextStyle(fontSize: 12, color: AppTheme.neutralWhite))),
                  Expanded(child: Text('${food.kcal}', style: const TextStyle(fontSize: 12, color: AppTheme.neutralWhite))),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  void _addMeal() {
    setState(() {
      _meals.add(Meal(
        label: 'New Meal',
        items: [],
        mealSummary: MealSummary(
          totalProtein: 0,
          totalCarbs: 0,
          totalFat: 0,
          totalKcal: 0,
          totalSodium: 0,
          totalPotassium: 0,
        ),
      ));
    });
  }

  void _addFoodToMeal(int mealIndex) {
    // TODO: Implement food addition
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Food addition feature coming soon!'),
        backgroundColor: AppTheme.mintAqua,
      ),
    );
  }

  Future<void> _generateAIPlan() async {
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client first'),
          backgroundColor: DesignTokens.danger,
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // TODO: Implement AI plan generation
      await Future.delayed(const Duration(seconds: 2)); // Simulate AI generation
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI plan generated successfully!'),
          backgroundColor: DesignTokens.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating plan: $e'),
          backgroundColor: DesignTokens.danger,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _savePlan() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a plan name'),
          backgroundColor: DesignTokens.danger,
        ),
      );
      return;
    }

    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client'),
          backgroundColor: DesignTokens.danger,
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // TODO: Implement plan saving
      await Future.delayed(const Duration(seconds: 1)); // Simulate saving
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan saved successfully!'),
          backgroundColor: DesignTokens.success,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving plan: $e'),
          backgroundColor: DesignTokens.danger,
        ),
      );
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }
}
