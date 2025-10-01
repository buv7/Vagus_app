import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/workout/plan_builder_header.dart';
import '../../widgets/workout/plan_search_filter_bar.dart';
import '../../widgets/workout/plan_metrics_cards.dart';
import '../../widgets/workout/plan_list_view.dart';
import 'coach_plan_builder_screen.dart';
import '../nutrition/nutrition_plan_builder.dart';

class ModernPlanBuilderScreen extends StatefulWidget {
  const ModernPlanBuilderScreen({super.key});

  @override
  State<ModernPlanBuilderScreen> createState() => _ModernPlanBuilderScreenState();
}

class _ModernPlanBuilderScreenState extends State<ModernPlanBuilderScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _filteredPlans = [];
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    // Mock data for now - replace with actual plan loading
    setState(() {
      _plans = [
        {
          'id': '1',
          'title': 'Full Body Strength Builder',
          'type': 'workout',
          'difficulty': 'Intermediate',
          'rating': 4.8,
          'duration': '12 weeks',
          'clientsAssigned': 8,
          'description': 'A comprehensive 12-week program focusing on building overall strength and muscle...',
          'tags': ['Strength', 'Muscle Building', 'Full Body'],
        },
        {
          'id': '2',
          'title': 'Mediterranean Meal Plan',
          'type': 'nutrition',
          'difficulty': 'Beginner',
          'rating': 4.9,
          'duration': '8 weeks',
          'clientsAssigned': 12,
          'description': 'Heart-healthy Mediterranean diet plan with balanced macros and delicious recipes.',
          'tags': ['Mediterranean', 'Heart Health', 'Weight Loss'],
        },
        {
          'id': '3',
          'title': 'HIIT Fat Burner',
          'type': 'workout',
          'difficulty': 'Advanced',
          'rating': 4.7,
          'duration': '6 weeks',
          'clientsAssigned': 5,
          'description': 'High-intensity interval training program designed for maximum fat loss.',
          'tags': ['HIIT', 'Fat Loss', 'Cardio'],
        },
        {
          'id': '4',
          'title': 'Plant-Based Performance',
          'type': 'nutrition',
          'difficulty': 'Intermediate',
          'rating': 4.6,
          'duration': '10 weeks',
          'clientsAssigned': 6,
          'description': 'Complete plant-based nutrition plan optimized for athletic performance.',
          'tags': ['Plant-Based', 'Performance', 'Vegan'],
        },
        {
          'id': '5',
          'title': 'Beginner\'s Foundation',
          'type': 'workout',
          'difficulty': 'Beginner',
          'rating': 4.9,
          'duration': '8 weeks',
          'clientsAssigned': 15,
          'description': 'Perfect starting point for fitness beginners with proper form focus.',
          'tags': ['Beginner', 'Foundation', 'Form'],
        },
      ];
      _filteredPlans = _plans;
      _loading = false;
    });
  }

  void _filterPlans() {
    setState(() {
      _filteredPlans = _plans.where((plan) {
        final matchesSearch = _searchQuery.isEmpty ||
            plan['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            plan['description'].toLowerCase().contains(_searchQuery.toLowerCase());
        
        return matchesSearch;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterPlans();
  }

  void _onNewWorkoutPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoachPlanBuilderScreen()),
    );
  }

  void _onNewNutritionPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NutritionPlanBuilder()),
    );
  }

  void _onEditPlan(Map<String, dynamic> plan) {
    // Navigate to plan editor
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing ${plan['title']}')),
    );
  }

  void _onAssignPlan(Map<String, dynamic> plan) {
    // Navigate to plan assignment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assigning ${plan['title']}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentGreen,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            PlanBuilderHeader(
              onNewWorkoutPlan: _onNewWorkoutPlan,
              onNewNutritionPlan: _onNewNutritionPlan,
            ),
            
            // Search and Filter Bar
            PlanSearchFilterBar(
              searchQuery: _searchQuery,
              onSearchChanged: _onSearchChanged,
            ),
            
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.accentGreen,
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                ),
                labelColor: AppTheme.primaryDark,
                unselectedLabelColor: AppTheme.lightGrey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: 'All Plans (${_plans.length})'),
                  Tab(text: 'Workout (${_plans.where((p) => p['type'] == 'workout').length})'),
                  Tab(text: 'Nutrition (${_plans.where((p) => p['type'] == 'nutrition').length})'),
                ],
              ),
            ),
            
            const SizedBox(height: DesignTokens.space16),
            
            // Metrics Cards
            PlanMetricsCards(
              totalPlans: _plans.length,
              activeClients: 46, // Mock data
              avgRating: 4.8, // Mock data
              thisMonth: 3, // Mock data
            ),
            
            const SizedBox(height: DesignTokens.space16),
            
            // Plans List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  PlanListView(
                    plans: _filteredPlans,
                    onEditPlan: _onEditPlan,
                    onAssignPlan: _onAssignPlan,
                  ),
                  PlanListView(
                    plans: _filteredPlans.where((p) => p['type'] == 'workout').toList(),
                    onEditPlan: _onEditPlan,
                    onAssignPlan: _onAssignPlan,
                  ),
                  PlanListView(
                    plans: _filteredPlans.where((p) => p['type'] == 'nutrition').toList(),
                    onEditPlan: _onEditPlan,
                    onAssignPlan: _onAssignPlan,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
