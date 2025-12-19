import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../widgets/branding/vagus_appbar.dart';
import 'components/plan_builder/builder_view.dart';
import 'components/plan_viewer/viewer_view.dart';

/// Unified nutrition hub that replaces all duplicate builders/viewers
/// Provides smart role-based views for both coaches and clients
class NutritionHubScreen extends StatefulWidget {
  final String? clientId;
  final NutritionPlan? planToEdit;
  final NutritionHubMode mode;

  const NutritionHubScreen({
    super.key,
    this.clientId,
    this.planToEdit,
    this.mode = NutritionHubMode.auto,
  });

  @override
  State<NutritionHubScreen> createState() => _NutritionHubScreenState();
}

enum NutritionHubMode {
  auto,     // Determine mode based on user role and context
  builder,  // Force builder mode (coach creating/editing)
  viewer,   // Force viewer mode (client/coach viewing)
}

class _NutritionHubScreenState extends State<NutritionHubScreen>
    with TickerProviderStateMixin {
  final NutritionService _nutritionService = NutritionService();
  final supabase = Supabase.instance.client;

  // Core state
  String _userRole = 'client';
  bool _loading = true;
  String? _error;

  // Plan state
  List<NutritionPlan> _plans = [];
  NutritionPlan? _currentPlan;

  // UI state
  late TabController _tabController;
  NutritionHubMode _resolvedMode = NutritionHubMode.viewer;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _loading = false;
        });
        return;
      }

      // Get user profile and role
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      _userRole = profile['role']?.toString() ?? 'client';

      // Resolve mode based on widget parameters and user role
      _resolveMode();

      // Load plans based on role and mode
      await _loadPlans();

      // Set current plan
      if (widget.planToEdit != null) {
        _currentPlan = widget.planToEdit;
      } else if (_plans.isNotEmpty) {
        _currentPlan = _plans.first;
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _resolveMode() {
    switch (widget.mode) {
      case NutritionHubMode.auto:
        // Auto-detect based on context
        if (widget.planToEdit != null) {
          _resolvedMode = NutritionHubMode.builder; // Editing existing plan
          _isEditMode = true;
        } else if (_userRole == 'coach') {
          _resolvedMode = NutritionHubMode.builder; // Coach defaults to builder
        } else {
          _resolvedMode = NutritionHubMode.viewer; // Client defaults to viewer
        }
        break;
      case NutritionHubMode.builder:
        _resolvedMode = NutritionHubMode.builder;
        break;
      case NutritionHubMode.viewer:
        _resolvedMode = NutritionHubMode.viewer;
        break;
    }
  }

  Future<void> _loadPlans() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      List<NutritionPlan> plans;
      if (_userRole == 'coach') {
        // Load plans created by this coach
        plans = await _nutritionService.fetchPlansByCoach(user.id);
      } else {
        // Load plans for this client
        plans = await _nutritionService.fetchPlansForClient(user.id);
      }

      setState(() {
        _plans = plans;
      });
    } catch (e) {
      // Handle error silently - will show empty state
    }
  }

  void _switchMode() {
    setState(() {
      if (_resolvedMode == NutritionHubMode.viewer) {
        _resolvedMode = NutritionHubMode.builder;
        _isEditMode = true;
      } else {
        _resolvedMode = NutritionHubMode.viewer;
        _isEditMode = false;
      }
    });
  }

  void _onPlanCreated(NutritionPlan plan) {
    setState(() {
      _plans.insert(0, plan);
      _currentPlan = plan;
      _resolvedMode = NutritionHubMode.viewer;
      _isEditMode = false;
    });
  }

  void _onPlanUpdated(NutritionPlan plan) {
    setState(() {
      final index = _plans.indexWhere((p) => p.id == plan.id);
      if (index >= 0) {
        _plans[index] = plan;
      }
      _currentPlan = plan;
      _resolvedMode = NutritionHubMode.viewer;
      _isEditMode = false;
    });
  }

  void _onPlanSelected(String planId) {
    final plan = _plans.firstWhere((p) => p.id == planId);
    setState(() {
      _currentPlan = plan;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    if (_loading) {
      return Scaffold(
        appBar: VagusAppBar(
          title: Text(LocaleHelper.t('nutrition', locale)),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: VagusAppBar(
          title: Text(LocaleHelper.t('nutrition', locale)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading nutrition data',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _init();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: VagusAppBar(
        title: Text(LocaleHelper.t('nutrition', locale)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: AppTheme.neutralWhite,
        actions: [
          // Mode switch button (for coaches)
          if (_userRole == 'coach')
            IconButton(
              icon: Icon(
                _resolvedMode == NutritionHubMode.builder
                  ? Icons.visibility
                  : Icons.edit,
                color: AppTheme.neutralWhite,
              ),
              tooltip: _resolvedMode == NutritionHubMode.builder
                ? 'Switch to View Mode'
                : 'Switch to Edit Mode',
              onPressed: _switchMode,
            ),

          // Plan selector
          if (_plans.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.list_alt, color: AppTheme.neutralWhite),
              tooltip: 'Select Plan',
              onSelected: _onPlanSelected,
              itemBuilder: (context) => _plans.map((plan) =>
                PopupMenuItem<String>(
                  value: plan.id,
                  child: Row(
                    children: [
                      Expanded(child: Text(plan.name)),
                      if (plan.unseenUpdate)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ).toList(),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryDark.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_resolvedMode) {
      case NutritionHubMode.builder:
        return BuilderView(
          clientId: widget.clientId,
          planToEdit: _isEditMode ? _currentPlan : null,
          userRole: _userRole,
          availableClients: [], // Will be loaded by BuilderView
          onPlanCreated: _onPlanCreated,
          onPlanUpdated: _onPlanUpdated,
          onCancel: () => _switchMode(),
        );

      case NutritionHubMode.viewer:
        if (_plans.isEmpty) {
          return _buildEmptyState();
        }

        return ViewerView(
          currentPlan: _currentPlan,
          allPlans: _plans,
          userRole: _userRole,
          onPlanSelected: _onPlanSelected,
          onEditPlan: _userRole == 'coach' ? () => _switchMode() : null,
        );

      default:
        return _buildEmptyState();
    }
  }

  Widget _buildEmptyState() {
    final locale = Localizations.localeOf(context).languageCode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: AppTheme.mediumGrey.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 48,
                color: AppTheme.accentGreen,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              LocaleHelper.t('no_nutrition_plans', locale),
              style: const TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              _userRole == 'coach'
                ? LocaleHelper.t('create_first_plan_coach', locale)
                : LocaleHelper.t('coach_will_create_plan', locale),
              style: const TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            if (_userRole == 'coach')
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 300),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _resolvedMode = NutritionHubMode.builder;
                      _isEditMode = false;
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(LocaleHelper.t('create_nutrition_plan', locale)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: AppTheme.primaryDark,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space16,
                      horizontal: DesignTokens.space24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}