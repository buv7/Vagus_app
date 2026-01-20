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

  // Selection mode
  bool _isSelectionMode = false;
  Set<String> _selectedPlanIds = {};

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

      // Attach client profile data to plans and mark plan types
      for (var plan in workoutPlans) {
        plan['plan_type'] = 'workout'; // Mark workout plans
        if (plan['client_id'] != null && clientProfiles.containsKey(plan['client_id'])) {
          plan['client_profile'] = clientProfiles[plan['client_id']];
        }
      }
      for (var plan in nutritionPlans) {
        plan['plan_type'] = 'nutrition'; // Mark nutrition plans
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

                // Selection mode toggle and create buttons row
                Row(
                  children: [
                    if (!_isSelectionMode) ...[
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
                    ] else ...[
                      Expanded(
                        child: Text(
                          '${_selectedPlanIds.length} ${_selectedPlanIds.length == 1 ? 'plan' : 'plans'} selected',
                          style: const TextStyle(
                            fontSize: 16,
                            color: DesignTokens.neutralWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _exitSelectionMode,
                        icon: const Icon(Icons.close, color: DesignTokens.textSecondary),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(color: DesignTokens.textSecondary),
                        ),
                      ),
                    ],
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

                      // Selection Mode Toggle
                      IconButton(
                        onPressed: _toggleSelectionMode,
                        icon: Icon(
                          _isSelectionMode ? Icons.done : Icons.checklist,
                          color: _isSelectionMode ? DesignTokens.accentGreen : DesignTokens.neutralWhite,
                        ),
                        tooltip: _isSelectionMode ? 'Exit selection mode' : 'Select plans',
                      ),

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

        // Bulk Actions Bar (when plans are selected)
        if (_isSelectionMode && _selectedPlanIds.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildBulkActionsBar(),
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
    final planId = plan['id']?.toString() ?? '';
    final isSelected = _selectedPlanIds.contains(planId);

    return InkWell(
      onTap: _isSelectionMode
          ? () => _togglePlanSelection(planId)
          : () => _editPlan(plan),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.accentGreen.withValues(alpha: 0.2)
              : DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? DesignTokens.accentGreen : DesignTokens.glassBorder,
            width: isSelected ? 2 : 1,
          ),
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
                      // Selection checkbox (when in selection mode)
                      if (_isSelectionMode) ...[
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected ? DesignTokens.accentGreen : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? DesignTokens.accentGreen : DesignTokens.textSecondary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: DesignTokens.neutralWhite,
                                  size: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
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
                      ],
                      const Spacer(),
                      if (!_isSelectionMode)
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
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: DesignTokens.danger),
                                  SizedBox(width: 12),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: DesignTokens.danger),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 4), // Reduced from 6

                  // Plan Name
                  Text(
                    plan['name'] ?? plan['title'] ?? 'Untitled Plan',
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
    final planId = plan['id']?.toString() ?? '';
    final isSelected = _selectedPlanIds.contains(planId);

    return InkWell(
      onTap: _isSelectionMode
          ? () => _togglePlanSelection(planId)
          : () => _editPlan(plan),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.accentGreen.withValues(alpha: 0.2)
              : DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? DesignTokens.accentGreen : DesignTokens.glassBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection checkbox (when in selection mode)
            if (_isSelectionMode) ...[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected ? DesignTokens.accentGreen : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? DesignTokens.accentGreen : DesignTokens.textSecondary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: DesignTokens.neutralWhite,
                        size: 14,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
            ] else ...[
              Icon(
                isWorkout ? Icons.fitness_center : Icons.restaurant,
                color: isWorkout ? DesignTokens.accentGreen : DesignTokens.accentOrange,
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan['name'] ?? plan['title'] ?? 'Untitled Plan',
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
            if (!_isSelectionMode)
              IconButton(
                onPressed: () => _editPlan(plan),
                icon: const Icon(Icons.edit, color: DesignTokens.textSecondary),
              ),
          ],
        ),
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
      case 'delete':
        _deletePlan(plan);
        break;
    }
  }

  Future<void> _deletePlan(Map<String, dynamic> plan) async {
    final planId = plan['id']?.toString();
    if (planId == null) return;

    // Determine plan type from the plan's plan_type marker (set during load)
    // Fallback to checking lists if marker is missing
    final planTypeMarker = plan['plan_type'] as String?;
    final isWorkout = planTypeMarker == 'workout' || 
        (planTypeMarker == null && _workoutPlans.any((p) => p['id']?.toString() == planId));
    final planType = isWorkout ? 'workout' : 'nutrition';
    final planName = plan['name'] ?? plan['title'] ?? 'Untitled Plan';

    // Check if plan is assigned to any clients
    bool isAssigned = false;
    try {
      final assignments = await supabase
          .from('plan_assignments')
          .select('id')
          .eq('plan_id', planId)
          .eq('plan_type', planType)
          .limit(1);

      isAssigned = assignments.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking plan assignments: $e');
      // Continue with deletion even if check fails
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.cardBackground,
        title: const Text(
          'Delete plan?',
          style: TextStyle(color: DesignTokens.neutralWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete "$planName" and all its weeks/days/exercises. This can\'t be undone.',
              style: const TextStyle(color: DesignTokens.textSecondary),
            ),
            if (isAssigned) ...[
              const SizedBox(height: 12),
              Text(
                '⚠️ This plan is assigned to a client; they will lose access immediately.',
                style: const TextStyle(
                  color: DesignTokens.warn,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: DesignTokens.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.danger,
              foregroundColor: DesignTokens.neutralWhite,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Perform deletion in proper order (children first, then parent)
    try {
      // Delete related records first (plan_assignments and plan_ratings don't have CASCADE)
      // These are safe to delete even if they don't exist
      try {
        await supabase
            .from('plan_assignments')
            .delete()
            .eq('plan_id', planId)
            .eq('plan_type', planType);
      } catch (e) {
        debugPrint('Warning: Could not delete plan_assignments: $e');
        // Continue with deletion even if this fails
      }

      try {
        await supabase
            .from('plan_ratings')
            .delete()
            .eq('plan_id', planId)
            .eq('plan_type', planType);
      } catch (e) {
        debugPrint('Warning: Could not delete plan_ratings: $e');
        // Continue with deletion even if this fails
      }

      // Delete the plan itself (this will cascade to workout_weeks, workout_days, etc. if they have FK constraints)
      if (isWorkout) {
        await supabase.from('workout_plans').delete().eq('id', planId);
      } else {
        await supabase.from('nutrition_plans').delete().eq('id', planId);
      }

      // Reload plans to update UI
      await _loadPlans();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan deleted'),
            backgroundColor: DesignTokens.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete plan: ${e.toString()}'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }

  // ==================== SELECTION MODE METHODS ====================

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedPlanIds.clear();
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedPlanIds.clear();
    });
  }

  void _togglePlanSelection(String planId) {
    setState(() {
      if (_selectedPlanIds.contains(planId)) {
        _selectedPlanIds.remove(planId);
      } else {
        _selectedPlanIds.add(planId);
      }
    });
  }

  Widget _buildBulkActionsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.accentGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedPlanIds.length} ${_selectedPlanIds.length == 1 ? 'plan' : 'plans'} selected',
              style: const TextStyle(
                color: DesignTokens.neutralWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Share button
          ElevatedButton.icon(
            onPressed: _selectedPlanIds.isNotEmpty ? _bulkSharePlans : null,
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.accentBlue,
              foregroundColor: DesignTokens.neutralWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          // Delete button
          ElevatedButton.icon(
            onPressed: _selectedPlanIds.isNotEmpty ? _bulkDeletePlans : null,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.danger,
              foregroundColor: DesignTokens.neutralWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkDeletePlans() async {
    if (_selectedPlanIds.isEmpty) return;

    final count = _selectedPlanIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.cardBackground,
        title: const Text(
          'Delete plans?',
          style: TextStyle(color: DesignTokens.neutralWhite),
        ),
        content: Text(
          'This will permanently delete $count ${count == 1 ? 'plan' : 'plans'} and all their weeks/days/exercises. This can\'t be undone.',
          style: const TextStyle(color: DesignTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: DesignTokens.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.danger,
              foregroundColor: DesignTokens.neutralWhite,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Get plans to delete with their types
    final plansToDelete = <Map<String, String>>[];
    for (final planId in _selectedPlanIds) {
      final plan = _filteredPlans.firstWhere(
        (p) => p['id']?.toString() == planId,
        orElse: () => {},
      );
      if (plan.isNotEmpty) {
        final planTypeMarker = plan['plan_type'] as String?;
        final isWorkout = planTypeMarker == 'workout' ||
            (planTypeMarker == null &&
                _workoutPlans.any((p) => p['id']?.toString() == planId));
        plansToDelete.add({
          'id': planId,
          'type': isWorkout ? 'workout' : 'nutrition',
        });
      }
    }

    int successCount = 0;
    int failCount = 0;

    for (final planInfo in plansToDelete) {
      final planId = planInfo['id'];
      final planType = planInfo['type'];
      
      // Skip if id or type is null (shouldn't happen, but safety check)
      if (planId == null || planType == null) {
        failCount++;
        continue;
      }

      try {
        // Delete related records first
        try {
          await supabase
              .from('plan_assignments')
              .delete()
              .eq('plan_id', planId)
              .eq('plan_type', planType);
        } catch (e) {
          debugPrint('Warning: Could not delete plan_assignments: $e');
        }

        try {
          await supabase
              .from('plan_ratings')
              .delete()
              .eq('plan_id', planId)
              .eq('plan_type', planType);
        } catch (e) {
          debugPrint('Warning: Could not delete plan_ratings: $e');
        }

        // Delete the plan
        if (planType == 'workout') {
          await supabase.from('workout_plans').delete().eq('id', planId);
        } else {
          await supabase.from('nutrition_plans').delete().eq('id', planId);
        }

        successCount++;
      } catch (e) {
        debugPrint('Error deleting plan $planId: $e');
        failCount++;
      }
    }

    // Reload plans and exit selection mode
    await _loadPlans();
    _exitSelectionMode();

    if (mounted) {
      if (failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount ${successCount == 1 ? 'plan' : 'plans'} deleted'),
            backgroundColor: DesignTokens.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$successCount deleted, $failCount failed',
            ),
            backgroundColor: DesignTokens.warn,
          ),
        );
      }
    }
  }

  Future<void> _bulkSharePlans() async {
    if (_selectedPlanIds.isEmpty) return;

    // Get selected plans
    final selectedPlans = _filteredPlans
        .where((plan) => _selectedPlanIds.contains(plan['id']?.toString()))
        .toList();

    if (selectedPlans.isEmpty) return;

    // For now, share plans by exporting their details
    // In a full implementation, this could generate share cards or export as files
    try {
      final planNames = selectedPlans
          .map((p) => p['name'] ?? p['title'] ?? 'Untitled Plan')
          .join(', ');

      // TODO: Implement proper share functionality (export as JSON, generate share cards, etc.)
      // For now, show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sharing ${selectedPlans.length} ${selectedPlans.length == 1 ? 'plan' : 'plans'}: $planNames'),
            backgroundColor: DesignTokens.info,
            duration: const Duration(seconds: 3),
          ),
        );

        // Close selection mode after sharing
        _exitSelectionMode();
      }
    } catch (e) {
      debugPrint('Error sharing plans: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share plans: ${e.toString()}'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }
}
