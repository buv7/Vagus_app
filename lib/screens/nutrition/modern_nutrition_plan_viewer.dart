import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/navigation/vagus_side_menu.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../../models/nutrition/nutrition_plan.dart';

class ModernNutritionPlanViewer extends StatefulWidget {
  const ModernNutritionPlanViewer({super.key});

  @override
  State<ModernNutritionPlanViewer> createState() => _ModernNutritionPlanViewerState();
}

class _ModernNutritionPlanViewerState extends State<ModernNutritionPlanViewer> {
  // Real data from Supabase
  List<NutritionPlan> _nutritionPlans = [];
  NutritionPlan? _currentPlan;
  bool _isLoading = true;
  String? _error;
  String _role = 'client';
  
  // Macro tracking (with defaults)
  int _currentProtein = 165;
  int _targetProtein = 180;
  int _currentCarbs = 280;
  int _targetCarbs = 320;
  int _currentFat = 85;
  int _targetFat = 95;
  int _currentHydration = 6;
  int _targetHydration = 8;
  
  final NutritionService _nutritionService = NutritionService();

  @override
  void initState() {
    super.initState();
    _loadNutritionPlans();
  }

  Future<void> _loadNutritionPlans() async {
    if (!mounted) return;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get user role
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      _role = (profile['role'] ?? 'client').toString();

      // Load nutrition plans based on role
      List<NutritionPlan> plans;
      if (_role == 'coach') {
        plans = await _nutritionService.fetchPlansByCoach(user.id);
      } else {
        plans = await _nutritionService.fetchPlansForClient(user.id);
      }

      if (mounted) {
        setState(() {
          _nutritionPlans = plans;
          if (_nutritionPlans.isNotEmpty) {
            _currentPlan = _nutritionPlans.first;
            // Update macro targets from plan
            _updateMacroTargets();
          }
          _isLoading = false;
          _error = null;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _updateMacroTargets() {
    if (_currentPlan != null) {
      final dailySummary = _currentPlan!.dailySummary;
      // Use the actual totals as targets for now, or set reasonable defaults
      _targetProtein = dailySummary.totalProtein.toInt();
      _targetCarbs = dailySummary.totalCarbs.toInt();
      _targetFat = dailySummary.totalFat.toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      drawerEdgeDragWidth: 24,
      drawer: const VagusSideMenu(isClient: true),
      body: SafeArea(
        child: _isLoading 
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.mintAqua,
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        Text(
                          'Error loading nutrition plans',
                          style: DesignTokens.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space8),
                        Text(
                          _error!,
                          style: DesignTokens.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        ElevatedButton(
                          onPressed: _loadNutritionPlans,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.mintAqua,
                            foregroundColor: AppTheme.primaryBlack,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _nutritionPlans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_outlined,
                              color: Colors.white70,
                              size: 48,
                            ),
                            const SizedBox(height: DesignTokens.space16),
                            Text(
                              'No nutrition plans found',
                              style: DesignTokens.titleMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.space8),
                            Text(
                              'Your coach will create nutrition plans for you',
                              style: DesignTokens.bodyMedium.copyWith(
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(DesignTokens.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with hamburger menu
                            _buildHeader(),
                            
                            const SizedBox(height: DesignTokens.space24),
                            
                            // Macro Summary Section
                            _buildMacroSummarySection(),
                            
                            const SizedBox(height: DesignTokens.space24),
                            
                            // Day Insights Section
                            _buildDayInsightsSection(),
                            
                            const SizedBox(height: DesignTokens.space24),
                            
                            // Supplements Section
                            _buildSupplementsSection(),
                            
                            const SizedBox(height: DesignTokens.space24),
              
              // Today's Meals Section
              _buildTodaysMealsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Hamburger menu
        Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        
        // Title
        Expanded(
          child: Text(
            'Nutrition',
            style: DesignTokens.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Protein
        _buildMacroProgressBar(
          'Protein',
          _currentProtein,
          _targetProtein,
          AppTheme.softYellow,
          84,
        ),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Carbs
        _buildMacroProgressBar(
          'Carbs',
          _currentCarbs,
          _targetCarbs,
          AppTheme.softYellow,
          92,
        ),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Fat
        _buildMacroProgressBar(
          'Fat',
          _currentFat,
          _targetFat,
          const Color(0xFFD4A574), // Light brown/orange color
          88,
        ),
        
        const SizedBox(height: DesignTokens.space8),
        
        // Overall percentage
        Center(
          child: Text(
            '89%',
            style: DesignTokens.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroProgressBar(String label, int current, int target, Color color, int percentage) {
    final progress = (current / target).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: DesignTokens.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            Text(
              '$percentage%',
              style: DesignTokens.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$current/$target',
              style: DesignTokens.bodySmall.copyWith(
                color: Colors.white70,
              ),
            ),
            Text(
              'g',
              style: DesignTokens.bodySmall.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day Insights',
          style: DesignTokens.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Hydration
        _buildHydrationSection(),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Insights
        _buildInsightsList(),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Macro Balance
        _buildMacroBalance(),
      ],
    );
  }

  Widget _buildHydrationSection() {
    final hydrationProgress = _currentHydration / _targetHydration;
    final hydrationPercentage = (hydrationProgress * 100).round();
    
    return Row(
      children: [
        const Icon(
          Icons.water_drop,
          color: AppTheme.mintAqua,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Hydration',
          style: DesignTokens.bodyMedium.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$_currentHydration / $_targetHydration glasses',
          style: DesignTokens.bodyMedium.copyWith(
            color: Colors.white70,
          ),
        ),
        const Spacer(),
        Container(
          width: 60,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: hydrationProgress,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.mintAqua,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$hydrationPercentage%',
          style: DesignTokens.bodyMedium.copyWith(
            color: AppTheme.mintAqua,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.trending_up,
              color: AppTheme.mintAqua,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Insights',
              style: DesignTokens.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: DesignTokens.space8),
        
        _buildInsightItem(
          'Great protein intake today! You\'re on track to meet your muscle-building goals.',
          AppTheme.mintAqua,
        ),
        
        _buildInsightItem(
          'Consider adding more complex carbs before your evening workout.',
          AppTheme.softYellow,
        ),
        
        _buildInsightItem(
          'You\'re 460 calories below your target. Add a healthy snack.',
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildInsightItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: DesignTokens.bodySmall.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBalance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Macro Balance',
          style: DesignTokens.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: DesignTokens.space8),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMacroBalanceItem('28%', 'Protein', AppTheme.softYellow),
            _buildMacroBalanceItem('48%', 'Carbs', AppTheme.softYellow),
            _buildMacroBalanceItem('24%', 'Fat', AppTheme.softYellow),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroBalanceItem(String percentage, String label, Color color) {
    return Column(
      children: [
        Text(
          percentage,
          style: DesignTokens.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: DesignTokens.bodySmall.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSupplementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Supplements',
              style: DesignTokens.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space12,
                vertical: DesignTokens.space8,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlack.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add Supplement',
                    style: DesignTokens.bodySmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: DesignTokens.space12),
        
        // Supplement tags
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSupplementTag('Whey Protein • Post-workout', true),
            _buildSupplementTag('Multivitamin • Morning', true),
            _buildSupplementTag('Vitamin D • Morning', true),
            _buildSupplementTag('Creatine • Daily', false),
            _buildSupplementTag('Omega-3 • With meals', false),
          ],
        ),
      ],
    );
  }

  Widget _buildSupplementTag(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.mintAqua : AppTheme.primaryBlack.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: DesignTokens.bodySmall.copyWith(
          color: isActive ? AppTheme.primaryBlack : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTodaysMealsSection() {
    // Get meals from current nutrition plan
    List<Map<String, dynamic>> meals = [];
    
    if (_currentPlan != null) {
      for (final meal in _currentPlan!.meals) {
        meals.add({
          'name': meal.label,
          'type': meal.label, // You could add meal type to the model
          'time': 'Scheduled', // You could add time to the model
          'calories': '${meal.mealSummary.totalKcal.toInt()} cal',
          'protein': '${meal.mealSummary.totalProtein.toInt()}g protein',
          'highlighted': false,
        });
      }
    }
    
    // Fallback to mock data if no real data
    if (meals.isEmpty) {
      meals = [
        {
          'name': 'Power Breakfast Bowl',
          'type': 'Breakfast',
          'time': '7:00 AM',
          'calories': '520 cal',
          'protein': '28g protein',
        },
        {
          'name': 'Pre-Workout Snack',
          'type': 'Snack',
          'time': '10:00 AM',
          'calories': '180 cal',
          'protein': '8g protein',
          'highlighted': true,
        },
        {
          'name': 'Grilled Chicken & Rice',
          'type': 'Lunch',
          'time': '1:00 PM',
          'calories': '680 cal',
          'protein': '45g protein',
        },
        {
          'name': 'Post-Workout Shake',
          'type': 'Snack',
          'time': '4:00 PM',
          'calories': '320 cal',
          'protein': '35g protein',
        },
        {
          'name': 'Salmon & Vegetables',
          'type': 'Dinner',
          'time': '7:00 PM',
          'calories': '580 cal',
          'protein': '42g protein',
        },
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Meals',
          style: DesignTokens.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: DesignTokens.space16),
        
        ...meals.map((meal) => _buildMealCard(meal)),
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final isHighlighted = meal['highlighted'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: isHighlighted 
          ? AppTheme.softYellow.withOpacity(0.1)
          : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted 
          ? Border.all(color: AppTheme.softYellow.withOpacity(0.3))
          : null,
      ),
      child: Row(
        children: [
          // Food icon placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.restaurant,
              color: Colors.white70,
              size: 20,
            ),
          ),
          
          const SizedBox(width: DesignTokens.space12),
          
          // Meal details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal['name'],
                  style: DesignTokens.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        meal['type'],
                        style: DesignTokens.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.access_time,
                      color: Colors.white70,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      meal['time'],
                      style: DesignTokens.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${meal['calories']} • ${meal['protein']}',
                  style: DesignTokens.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
