import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../services/nutrition/locale_helper.dart';
import '../workout/revolutionary_plan_builder_screen.dart';
import '../nutrition/nutrition_plan_builder.dart';

class PlansDashboardScreen extends StatefulWidget {
  const PlansDashboardScreen({super.key});

  @override
  State<PlansDashboardScreen> createState() => _PlansDashboardScreenState();
}

class _PlansDashboardScreenState extends State<PlansDashboardScreen> {
  final supabase = Supabase.instance.client;

  // Data
  List<Map<String, dynamic>> _workoutPlans = [];
  List<Map<String, dynamic>> _nutritionPlans = [];
  List<Map<String, dynamic>> _templates = [];
  bool _loading = true;

  // View settings
  bool _isGridView = true;
  String _selectedFilter = 'all'; // all, workout, nutrition, templates
  String _searchQuery = '';

  // Stats
  int _totalPlans = 0;
  int _activeClients = 0;
  int _templatesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _loading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Load workout plans
      final workoutPlans = await supabase
          .from('workout_plans')
          .select('*')
          .eq('created_by', userId)
          .order('updated_at', ascending: false);

      // Load nutrition plans
      final nutritionPlans = await supabase
          .from('nutrition_plans')
          .select('*')
          .eq('created_by', userId)
          .order('updated_at', ascending: false);

      // Collect all unique client IDs
      final clientIds = <String>{};
      for (var plan in [...workoutPlans, ...nutritionPlans]) {
        if (plan['client_id'] != null) {
          clientIds.add(plan['client_id']);
        }
      }

      // Fetch client profiles in one query
      final Map<String, Map<String, dynamic>> clientProfiles = {};
      if (clientIds.isNotEmpty) {
        final profiles = await supabase
            .from('profiles')
            .select('id, full_name, avatar_url')
            .inFilter('id', clientIds.toList());

        for (var profile in profiles) {
          clientProfiles[profile['id']] = profile;
        }
      }

      // Attach client profile data to plans
      for (var plan in [...workoutPlans, ...nutritionPlans]) {
        if (plan['client_id'] != null && clientProfiles.containsKey(plan['client_id'])) {
          plan['client_profile'] = clientProfiles[plan['client_id']];
        }
      }

      // Filter templates
      final templates = [
        ...workoutPlans.where((p) => p['is_template'] == true),
        ...nutritionPlans.where((p) => p['is_template'] == true),
      ];

      if (mounted) {
        setState(() {
          _workoutPlans = List<Map<String, dynamic>>.from(workoutPlans);
          _nutritionPlans = List<Map<String, dynamic>>.from(nutritionPlans);
          _templates = templates;
          _totalPlans = workoutPlans.length + nutritionPlans.length;
          _activeClients = clientIds.length;
          _templatesCount = templates.length;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading plans: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPlans {
    List<Map<String, dynamic>> plans = [];

    if (_selectedFilter == 'all' || _selectedFilter == 'workout') {
      plans.addAll(_workoutPlans.where((p) => p['is_template'] != true));
    }
    if (_selectedFilter == 'all' || _selectedFilter == 'nutrition') {
      plans.addAll(_nutritionPlans.where((p) => p['is_template'] != true));
    }
    if (_selectedFilter == 'templates') {
      plans.addAll(_templates);
    }

    if (_searchQuery.isNotEmpty) {
      plans = plans.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query);
      }).toList();
    }

    return plans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _loading ? _buildLoadingState() : _buildDashboard(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: DesignTokens.accentGreen),
    );
  }

  Widget _buildDashboard() {
    return CustomScrollView(
      slivers: [
        // Header with Create Buttons
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Title
                Text(
                  LocaleHelper.t('plans_hub', 'Plans Hub'),
                  style: const TextStyle(
                    fontSize: 32,
                    color: DesignTokens.neutralWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  LocaleHelper.t('manage_all_plans', 'Create and manage workout and nutrition plans for your clients'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: DesignTokens.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                // Create Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildCreateButton(
                        icon: Icons.fitness_center,
                        label: LocaleHelper.t('create_workout_plan', 'Create Workout Plan'),
                        gradient: const LinearGradient(
                          colors: [DesignTokens.accentGreen, Color(0xFF00B383)],
                        ),
                        onTap: () => _navigateToWorkoutBuilder(),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: _buildCreateButton(
                        icon: Icons.restaurant,
                        label: LocaleHelper.t('create_nutrition_plan', 'Create Nutrition Plan'),
                        gradient: const LinearGradient(
                          colors: [DesignTokens.accentOrange, Color(0xFFFF8A00)],
                        ),
                        onTap: () => _navigateToNutritionBuilder(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.description,
                        label: LocaleHelper.t('total_plans', 'Total Plans'),
                        value: _totalPlans.toString(),
                        color: DesignTokens.accentBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.people,
                        label: LocaleHelper.t('active_clients', 'Active Clients'),
                        value: _activeClients.toString(),
                        color: DesignTokens.accentGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.folder_special,
                        label: LocaleHelper.t('templates', 'Templates'),
                        value: _templatesCount.toString(),
                        color: DesignTokens.accentPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Search and Filter Bar
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Search Bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: DesignTokens.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DesignTokens.glassBorder),
                  ),
                  child: TextField(
                    style: const TextStyle(color: DesignTokens.neutralWhite),
                    decoration: InputDecoration(
                      hintText: LocaleHelper.t('search_plans', 'Search plans...'),
                      hintStyle: const TextStyle(color: DesignTokens.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: DesignTokens.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Filter Chips Row with horizontal scroll
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Filter Chips
                      _buildFilterChip('all', 'All', Icons.grid_view),
                      const SizedBox(width: 8),
                      _buildFilterChip('workout', 'Workout', Icons.fitness_center),
                      const SizedBox(width: 8),
                      _buildFilterChip('nutrition', 'Nutrition', Icons.restaurant),
                      const SizedBox(width: 8),
                      _buildFilterChip('templates', 'Templates', Icons.folder_special),

                      const SizedBox(width: 12),

                      // View Toggle
                      IconButton(
                        onPressed: () {
                          setState(() => _isGridView = !_isGridView);
                        },
                        icon: Icon(
                          _isGridView ? Icons.view_list : Icons.grid_view,
                          color: DesignTokens.neutralWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Plans Grid/List
        _filteredPlans.isEmpty
            ? SliverToBoxAdapter(child: _buildEmptyState())
            : _isGridView
                ? _buildPlansGrid()
                : _buildPlansList(),
      ],
    );
  }

  Widget _buildCreateButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              color: DesignTokens.neutralWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: DesignTokens.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;

    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = filter);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? DesignTokens.accentGreen : DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? DesignTokens.accentGreen : DesignTokens.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : DesignTokens.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : DesignTokens.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPlanCard(_filteredPlans[index]),
          childCount: _filteredPlans.length,
        ),
      ),
    );
  }

  Widget _buildPlansList() {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPlanListItem(_filteredPlans[index]),
          ),
          childCount: _filteredPlans.length,
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isWorkout = plan['weeks'] != null; // workout plans have weeks
    final clientName = plan['client_profile']?['full_name'] ?? 'No client assigned';
    final clientAvatar = plan['client_profile']?['avatar_url'];

    return InkWell(
      onTap: () => _editPlan(plan),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(10), // Reduced from 12
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Take minimum space needed
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6), // Reduced from 8
                        decoration: BoxDecoration(
                          color: isWorkout
                              ? DesignTokens.accentGreen.withValues(alpha: 0.2)
                              : DesignTokens.accentOrange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isWorkout ? Icons.fitness_center : Icons.restaurant,
                          color: isWorkout ? DesignTokens.accentGreen : DesignTokens.accentOrange,
                          size: 18, // Reduced from 20
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: DesignTokens.textSecondary),
                        color: DesignTokens.cardBackground,
                        onSelected: (value) => _handlePlanAction(value, plan),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                          const PopupMenuItem(value: 'template', child: Text('Save as Template')),
                          const PopupMenuItem(value: 'assign', child: Text('Assign to Client')),
                          const PopupMenuItem(value: 'archive', child: Text('Archive')),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 4), // Reduced from 6

                  // Plan Name
                  Text(
                    plan['name'] ?? 'Untitled Plan',
                    style: const TextStyle(
                      fontSize: 13, // Reduced from 14
                      color: DesignTokens.neutralWhite,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4), // Reduced from 6

                  // Client Info
                  Row(
                    children: [
                      if (clientAvatar != null)
                        CircleAvatar(
                          radius: 8, // Reduced from 10
                          backgroundImage: NetworkImage(clientAvatar),
                        )
                      else
                        CircleAvatar(
                          radius: 8, // Reduced from 10
                          backgroundColor: DesignTokens.accentBlue.withValues(alpha: 0.3),
                          child: const Icon(Icons.person, size: 8, color: DesignTokens.accentBlue), // Reduced from 10
                        ),
                      const SizedBox(width: 4), // Reduced from 6
                      Expanded(
                        child: Text(
                          clientName,
                          style: const TextStyle(
                            fontSize: 9, // Reduced from 10
                            color: DesignTokens.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildPlanListItem(Map<String, dynamic> plan) {
    final isWorkout = plan['weeks'] != null;
    final clientName = plan['client_profile']?['full_name'] ?? 'No client assigned';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Row(
        children: [
          Icon(
            isWorkout ? Icons.fitness_center : Icons.restaurant,
            color: isWorkout ? DesignTokens.accentGreen : DesignTokens.accentOrange,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan['name'] ?? 'Untitled Plan',
                  style: const TextStyle(
                    fontSize: 14,
                    color: DesignTokens.neutralWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  clientName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editPlan(plan),
            icon: const Icon(Icons.edit, color: DesignTokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: DesignTokens.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            LocaleHelper.t('no_plans_found', 'No plans found'),
            style: const TextStyle(
              fontSize: 16,
              color: DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LocaleHelper.t('create_first_plan', 'Create your first plan to get started'),
            style: const TextStyle(
              fontSize: 13,
              color: DesignTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToWorkoutBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RevolutionaryPlanBuilderScreen(),
      ),
    ).then((_) => _loadPlans()); // Reload when returning
  }

  void _navigateToNutritionBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NutritionPlanBuilder(),
      ),
    ).then((_) => _loadPlans()); // Reload when returning
  }

  void _editPlan(Map<String, dynamic> plan) {
    final isWorkout = plan['weeks'] != null;

    if (isWorkout) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RevolutionaryPlanBuilderScreen(
            planId: plan['id'],
          ),
        ),
      ).then((_) => _loadPlans());
    } else {
      // Navigate to nutrition plan editor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NutritionPlanBuilder(),
        ),
      ).then((_) => _loadPlans());
    }
  }

  void _handlePlanAction(String action, Map<String, dynamic> plan) {
    switch (action) {
      case 'edit':
        _editPlan(plan);
        break;
      case 'duplicate':
        // TODO: Implement duplicate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicate plan - Coming soon')),
        );
        break;
      case 'template':
        // TODO: Implement save as template
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save as template - Coming soon')),
        );
        break;
      case 'assign':
        // TODO: Implement assign to client
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assign to client - Coming soon')),
        );
        break;
      case 'archive':
        // TODO: Implement archive
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archive plan - Coming soon')),
        );
        break;
    }
  }
}
