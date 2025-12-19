import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../services/nutrition/nutrition_service.dart';
import 'nutrition_hub_screen.dart';
import 'dart:ui';

/// Coach Nutrition Dashboard - View and manage all client nutrition plans
class CoachNutritionDashboard extends StatefulWidget {
  const CoachNutritionDashboard({super.key});

  @override
  State<CoachNutritionDashboard> createState() => _CoachNutritionDashboardState();
}

class _CoachNutritionDashboardState extends State<CoachNutritionDashboard> with SingleTickerProviderStateMixin {
  final NutritionService _nutritionService = NutritionService();
  final supabase = Supabase.instance.client;

  List<NutritionPlan> _plans = [];
  Map<String, String> _clientNames = {};
  bool _loading = true;
  String _error = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Load all nutrition plans created by this coach
      final plans = await _nutritionService.fetchPlansByCoach(user.id);

      // Get unique client IDs
      final clientIds = plans
          .map((p) => p.clientId)
          .toSet()
          .toList();

      // Fetch client names
      if (clientIds.isNotEmpty) {
        final profiles = await supabase
            .from('profiles')
            .select('id, name')
            .inFilter('id', clientIds);

        final names = <String, String>{};
        for (final profile in profiles) {
          names[profile['id']] = profile['name'] ?? 'Unknown';
        }

        setState(() {
          _plans = plans;
          _clientNames = names;
          _loading = false;
        });
      } else {
        setState(() {
          _plans = plans;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentGreen,
                      ),
                    )
                  : _error.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Error loading plans',
                                style: TextStyle(
                                  color: AppTheme.neutralWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error,
                                style: const TextStyle(
                                  color: AppTheme.lightGrey,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loadPlans,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentGreen,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildActiveTab(),
                            _buildAllTab(),
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NutritionHubScreen(mode: NutritionHubMode.builder),
            ),
          ).then((_) => _loadPlans());
        },
        backgroundColor: AppTheme.accentGreen,
        icon: const Icon(Icons.add),
        label: const Text('New Plan'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.accentGreen.withValues(alpha: 0.2),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nutrition Plans',
                style: DesignTokens.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_plans.length} plans',
                style: const TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.accentGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.lightGrey,
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'All Plans'),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    // For now, show all plans (no isActive field in model)
    // In the future, add isActive to NutritionPlan model
    if (_plans.isEmpty) {
      return _buildEmptyState('No active nutrition plans');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        return _buildPlanCard(_plans[index]);
      },
    );
  }

  Widget _buildAllTab() {
    if (_plans.isEmpty) {
      return _buildEmptyState('No nutrition plans yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        return _buildPlanCard(_plans[index]);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 80,
            color: AppTheme.lightGrey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NutritionHubScreen(mode: NutritionHubMode.builder),
                ),
              ).then((_) => _loadPlans());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create First Plan'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(NutritionPlan plan) {
    final clientName = _clientNames[plan.clientId] ?? 'Template';
    final summary = plan.dailySummary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentGreen.withValues(alpha: 0.1),
            blurRadius: 15,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NutritionHubScreen(mode: NutritionHubMode.viewer, planToEdit: plan),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.accentGreen.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.accentGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientName,
                                style: const TextStyle(
                                  color: AppTheme.neutralWhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                plan.name,
                                style: const TextStyle(
                                  color: AppTheme.lightGrey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // TODO: Add isActive field to NutritionPlan model
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: AppTheme.accentGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white70),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NutritionHubScreen(mode: NutritionHubMode.builder, planToEdit: plan),
                              ),
                            ).then((_) => _loadPlans());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildMacroChip(
                          'Protein',
                          '${summary.totalProtein.toInt()}g',
                          AppTheme.accentGreen,
                        ),
                        const SizedBox(width: 8),
                        _buildMacroChip(
                          'Carbs',
                          '${summary.totalCarbs.toInt()}g',
                          AppTheme.accentOrange,
                        ),
                        const SizedBox(width: 8),
                        _buildMacroChip(
                          'Fat',
                          '${summary.totalFat.toInt()}g',
                          AppTheme.lightBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: AppTheme.accentOrange,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${summary.totalKcal.toInt()} kcal',
                          style: const TextStyle(
                            color: AppTheme.neutralWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.restaurant,
                          color: AppTheme.lightGrey,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${plan.meals.length} meals',
                          style: const TextStyle(
                            color: AppTheme.lightGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
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

  Widget _buildMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}