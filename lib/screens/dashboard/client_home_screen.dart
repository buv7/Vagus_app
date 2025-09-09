import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../auth/modern_login_screen.dart';
import 'edit_profile_screen.dart';
import '../coach/coach_search_screen.dart';

import '../files/file_manager_screen.dart';
import '../../services/progress/progress_service.dart';
import '../../widgets/progress/metrics_card.dart';
import '../../widgets/progress/photos_card.dart';
import '../../widgets/progress/checkins_card.dart';
import '../../widgets/progress/export_card.dart';
import '../../components/progress/compliance_stats_card.dart';
import '../progress/client_check_in_calendar.dart';
import '../calendar/calendar_screen.dart';
import '../calendar/booking_form.dart';
import '../billing/upgrade_screen.dart';
import '../../services/billing/plan_access_manager.dart';
import '../../services/calendar/event_service.dart';
import '../../services/calendar/ics_service.dart';
import '../../widgets/ai/ai_usage_meter.dart';
import '../../widgets/files/file_previewer.dart';
import '../../components/rank/neon_rank_chip.dart';
import '../rank/rank_hub_screen.dart';
import '../supplements/supplement_today_card.dart';
import '../supplements/supplement_list_screen.dart';
import '../../components/streak/streak_chip.dart';
import '../streaks/streak_screen.dart';
import '../../components/health/health_rings.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/navigation/vagus_side_menu.dart';
import '../../services/intake/intake_service.dart';
import '../intake/intake_wizard_screen.dart';
import '../nutrition/nutrition_plan_viewer.dart';
import '../../services/nutrition/hydration_service.dart';
import '../../components/nutrition/hydration_ring.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Feature flags for personalized flows
const bool kShowWelcomeFlow = true;
const bool kShowTrendingPrograms = true;
const bool kShowQuickStats = true;

// Safe image handling helpers
bool _isValidHttpUrl(String? url) {
  if (url == null) return false;
  final u = url.trim();
  return u.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://'));
}

Widget _imagePlaceholder({double? w, double? h}) {
  return Container(
    width: w,
    height: h,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppTheme.lightGrey,
      borderRadius: BorderRadius.circular(DesignTokens.radius8),
    ),
    child: const Icon(
      Icons.image_not_supported,
      color: AppTheme.steelGrey,
    ),
  );
}

Widget safeNetImage(String? url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (_isValidHttpUrl(url)) {
    return Image.network(
      url!.trim(),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _imagePlaceholder(w: width, h: height),
    );
  }
  return _imagePlaceholder(w: width, h: height);
}

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final supabase = Supabase.instance.client;
  final ProgressService _progressService = ProgressService();
  final EventService _eventService = EventService();
  final IntakeService _intakeService = IntakeService();
  final HydrationService _hydrationService = HydrationService();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _coaches = [];
  List<Map<String, dynamic>> _metrics = [];
  List<Map<String, dynamic>> _photos = [];
  List<Map<String, dynamic>> _checkins = [];
  
  // Hydration tracking
  int _todayHydration = 0;
  int _hydrationTarget = 3000;
  bool _loading = true;
  String _error = '';
  bool _coachFoundViaFallback = false;
  
  // Calendar Polish v1.1: Upcoming session
  Event? _upcomingSession;
  
  // User maturity state
  bool _isNewUser = true;
  bool _isRepeatUser = false;
  bool _isSuperUser = false;
  
  // Intake form status
  String? _intakeStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadHydrationData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload coach data when page is re-entered to avoid stale cache
    if (!_loading && _coaches.isEmpty) {
      unawaited(_loadCoach());
    }
  }

  Future<void> _loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _profile = profile;
        });
      }

      // Load coach data with robust fallback
      unawaited(_loadCoach());

      // Load progress data
      await _loadProgressData();
      
      // Calendar Polish v1.1: Load upcoming session
      await _loadUpcomingSession();
      
      // Check intake form status
      await _checkIntakeStatus();
      
      // Determine user maturity level
      _determineUserMaturity();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadHydrationData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      final hydrationLog = await _hydrationService.getDaily(user.id, today);
      final target = await _hydrationService.getDailyTarget(user.id);
      
      if (mounted) {
        setState(() {
          _todayHydration = hydrationLog.ml;
          _hydrationTarget = target;
        });
      }
    } catch (e) {
      // Silently ignore hydration loading errors
    }
  }

  Future<void> _addWater(int ml) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      await _hydrationService.addWater(user.id, today, ml);
      
      if (mounted) {
        setState(() {
          _todayHydration += ml;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${ml}ml of water'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add water: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _determineUserMaturity() {
    // Simple logic: check if user has metrics, photos, or check-ins
    final hasProgressData = _metrics.isNotEmpty || _photos.isNotEmpty || _checkins.isNotEmpty;
    final hasCoach = _coaches.isNotEmpty;
    final hasUpcomingSession = _upcomingSession != null;
    
    setState(() {
      if (hasProgressData && hasCoach && hasUpcomingSession) {
        _isNewUser = false;
        _isRepeatUser = false;
        _isSuperUser = true;
      } else if (hasProgressData || hasCoach) {
        _isNewUser = false;
        _isRepeatUser = true;
        _isSuperUser = false;
      } else {
        _isNewUser = true;
        _isRepeatUser = false;
        _isSuperUser = false;
      }
    });
  }

  Future<void> _loadCoach() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final role = _profile?['role'] ?? '';
    if (kDebugMode) {
      debugPrint('Loading coach for user ${user.id} with role: $role');
    }

    try {
      List<String> coachIds = [];

      // Primary lookup via link table for clients
      if (role == 'client') {
        // First try coach_clients table
        final links = await supabase
            .from('coach_clients')
            .select('coach_id')
            .eq('client_id', user.id);

        if (links.isNotEmpty) {
          coachIds = links.map((link) => link['coach_id'] as String).toList();
          _coachFoundViaFallback = false;
          if (kDebugMode) {
            debugPrint('Found ${coachIds.length} coach(es) via coach_clients table');
          }
        } else {
          // Second try coach_client_links table
          final links2 = await supabase
              .from('coach_client_links')
              .select('coach_id')
              .eq('client_id', user.id);

          if (links2.isNotEmpty) {
            coachIds = links2.map((link) => link['coach_id'] as String).toList();
            _coachFoundViaFallback = false;
            if (kDebugMode) {
              debugPrint('Found ${coachIds.length} coach(es) via coach_client_links table');
            }
          } else {
            // Fallback: Check workout plans for this client's coach_id
            final workoutPlans = await supabase
                .from('workout_plans')
                .select('coach_id')
                .eq('client_id', user.id)
                .not('coach_id', 'is', null);

            if (workoutPlans.isNotEmpty) {
              final workoutCoachIds = workoutPlans
                  .map((plan) => plan['coach_id'] as String)
                  .where((id) => id.isNotEmpty)
                  .toSet()
                  .toList();

              if (workoutCoachIds.isNotEmpty) {
                coachIds = workoutCoachIds;
                _coachFoundViaFallback = true;
                if (kDebugMode) {
                  debugPrint('Found ${coachIds.length} coach(es) via workout_plans fallback');
                }
              }
            }

            // If still no coaches found, check nutrition plans
            if (coachIds.isEmpty) {
              final nutritionPlans = await supabase
                  .from('nutrition_plans')
                  .select('created_by')
                  .eq('client_id', user.id)
                  .not('created_by', 'is', null);

              if (nutritionPlans.isNotEmpty) {
                final nutritionCoachIds = nutritionPlans
                    .map((plan) => plan['created_by'] as String)
                    .where((id) => id.isNotEmpty)
                    .toSet()
                    .toList();

                if (nutritionCoachIds.isNotEmpty) {
                  coachIds = nutritionCoachIds;
                  _coachFoundViaFallback = true;
                  if (kDebugMode) {
                    debugPrint('Found ${coachIds.length} coach(es) via nutrition_plans fallback');
                  }
                }
              }
            }
          }
        }
      } else if (role == 'coach') {
        // For coaches, fetch their linked clients (existing logic)
        final links = await supabase
            .from('coach_clients')
            .select('client_id')
            .eq('coach_id', user.id);

        if (links.isNotEmpty) {
          final clientIds = links.map((link) => link['client_id'] as String).toList();
          final clients = await supabase
              .from('profiles')
              .select()
              .inFilter('id', clientIds);

        if (mounted) {
          setState(() {
            _coaches = List<Map<String, dynamic>>.from(clients);
            _loading = false;
          });
        }
          return;
        }
      }

      // Fetch coach profiles if we found any coach IDs
      if (coachIds.isNotEmpty) {
        final coaches = await supabase
            .from('profiles')
            .select()
            .inFilter('id', coachIds);

        if (mounted) {
          setState(() {
            _coaches = List<Map<String, dynamic>>.from(coaches);
            _loading = false;
          });
        }

        // If we found coaches via fallback and there's exactly one, offer to create the link
        if (role == 'client' && coachIds.length == 1 && _coachFoundViaFallback) {
          if (kDebugMode) {
            debugPrint('Found single coach via fallback, offering to create link');
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _coaches = [];
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading coach: $e');
      }
      if (mounted) {
        setState(() {
          _coaches = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadProgressData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final metrics = await _progressService.fetchMetrics(user.id);
      final photos = await _progressService.fetchProgressPhotos(user.id);
      final checkins = await _progressService.fetchCheckins(user.id);

      if (mounted) {
        setState(() {
          _metrics = metrics;
          _photos = photos;
          _checkins = checkins;
        });
      }
    } catch (e) {
      // Silently handle progress data loading errors
      debugPrint('Failed to load progress data: $e');
    }
  }

  Future<void> _checkIntakeStatus() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final status = await _intakeService.getResponseStatus(userId);
      if (mounted) {
        setState(() {
          _intakeStatus = status;
        });
      }
    } catch (e) {
      // Silently ignore intake check errors
      debugPrint('Intake status check failed: $e');
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ModernLoginScreen()),
          (route) => false,
    );
  }

  void _goToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  void _goToCoachSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoachSearchScreen()),
    );
  }

  Future<void> _connectCoach(String coachId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('coach_clients')
          .upsert({
            'coach_id': coachId,
            'client_id': user.id,
            'created_at': DateTime.now().toIso8601String(),
          }, onConflict: 'coach_id,client_id');

      if (kDebugMode) {
        debugPrint('Successfully connected coach $coachId to client ${user.id}');
      }

      // Reload coach data to refresh the UI
      unawaited(_loadCoach());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Coach connected successfully!')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error connecting coach: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to connect coach: $e')),
        );
      }
    }
  }

  Widget _buildCoachCard(Map<String, dynamic> coach) {
    final String? imgUrl = coach['avatar_url'];
    final String coachId = coach['id'] as String;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: DesignTokens.space8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: _isValidHttpUrl(imgUrl)
              ? NetworkImage(imgUrl!.trim())
              : null,
          child: !_isValidHttpUrl(imgUrl) ? const Icon(Icons.person) : null,
        ),
        title: Text(
          coach['name'] ?? 'No name',
          style: DesignTokens.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          coach['email'] ?? '',
          style: DesignTokens.bodySmall.copyWith(
            color: DesignTokens.ink500,
          ),
        ),
        trailing: _coachFoundViaFallback && _profile?['role'] == 'client'
            ? OutlinedButton(
                onPressed: () => unawaited(_connectCoach(coachId)),
                child: const Text('Connect'),
              )
            : null,
      ),
    );
  }

  Widget _buildWelcomeFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome message
        Text(
          'Welcome to Vagus!',
          style: DesignTokens.displaySmall.copyWith(
            color: AppTheme.primaryBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DesignTokens.space8),
        Text(
          'Let\'s get you started on your fitness journey',
          style: DesignTokens.bodyMedium.copyWith(
            color: AppTheme.steelGrey,
          ),
        ),
        const SizedBox(height: DesignTokens.space24),
        
        // Set weekly goal card
        Card(
          color: AppTheme.lightGrey,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.flag_rounded,
                      color: AppTheme.primaryBlack,
                    ),
                    const SizedBox(width: DesignTokens.space8),
                    Text(
                      'Set Your Weekly Goal',
                      style: DesignTokens.titleMedium.copyWith(
                        color: AppTheme.primaryBlack,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space12),
                Text(
                  'What would you like to achieve this week?',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: AppTheme.steelGrey,
                  ),
                ),
                const SizedBox(height: DesignTokens.space16),
                Wrap(
                  spacing: DesignTokens.space8,
                  runSpacing: DesignTokens.space8,
                  children: [
                    ActionChip(
                      label: const Text('Lose Weight'),
                      onPressed: () {
                        // TODO: Implement goal setting
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Goal setting coming soon!')),
                        );
                      },
                    ),
                    ActionChip(
                      label: const Text('Build Muscle'),
                      onPressed: () {
                        // TODO: Implement goal setting
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Goal setting coming soon!')),
                        );
                      },
                    ),
                    ActionChip(
                      label: const Text('Improve Fitness'),
                      onPressed: () {
                        // TODO: Implement goal setting
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Goal setting coming soon!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.space16),
        
        // Trending programs
        if (kShowTrendingPrograms) ...[
          Text(
            'Trending Programs',
            style: DesignTokens.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space12),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTrendingProgramCard('Beginner Strength', '3 weeks', AppTheme.primaryBlack),
                _buildTrendingProgramCard('Cardio Blast', '4 weeks', AppTheme.steelGrey),
                _buildTrendingProgramCard('Flexibility Flow', '2 weeks', AppTheme.primaryBlack),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrendingProgramCard(String title, String duration, Color color) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: DesignTokens.space12),
      child: Card(
        color: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DesignTokens.titleSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                duration,
                style: DesignTokens.labelMedium.copyWith(
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepeatUserFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Today's Plan
        Text(
          'Today\'s Plan',
          style: DesignTokens.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DesignTokens.space16),
        
        Card(
          color: AppTheme.lightGrey,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Row(
              children: [
                const Icon(
                  Icons.fitness_center_rounded,
                  color: AppTheme.primaryBlack,
                  size: 32,
                ),
                const SizedBox(width: DesignTokens.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upper Body Strength',
                        style: DesignTokens.titleMedium.copyWith(
                          color: AppTheme.primaryBlack,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '45 minutes • 8 exercises',
                        style: DesignTokens.bodyMedium.copyWith(
                          color: AppTheme.steelGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Navigate to workout
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Workout details coming soon!')),
                    );
                  },
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    color: DesignTokens.success,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.space24),
        
        // Quick Stats
        if (kShowQuickStats) ...[
          Text(
            'Quick Stats',
            style: DesignTokens.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  'Duration',
                  '45 min',
                  Icons.timer,
                  AppTheme.primaryBlack,
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              Expanded(
                child: _buildQuickStatCard(
                  'Calories',
                  '320',
                  Icons.local_fire_department,
                  AppTheme.steelGrey,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQuickStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: DesignTokens.space8),
            // Value (bigger, heavier)
            Text(
              value,
              style: DesignTokens.displaySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            // Label (smaller, softer)
            Text(
              label,
              style: DesignTokens.labelMedium.copyWith(
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperUserFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live stats row
        Row(
          children: [
            Expanded(
              child: _buildLiveStatCard(
                'Current Weight',
                '${_metrics.isNotEmpty ? _metrics.last['weight_kg']?.toStringAsFixed(1) ?? '--' : '--'} kg',
                Icons.monitor_weight,
                AppTheme.primaryBlack,
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: _buildLiveStatCard(
                'Weekly Goal',
                'On Track',
                Icons.trending_up,
                AppTheme.primaryBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space16),
        
        // Diet suggestions
        Card(
          color: AppTheme.lightGrey,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.restaurant_menu_rounded,
                      color: AppTheme.steelGrey,
                    ),
                    const SizedBox(width: DesignTokens.space8),
                    Text(
                      'Today\'s Nutrition',
                      style: DesignTokens.titleMedium.copyWith(
                        color: AppTheme.steelGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space12),
                Text(
                  'Focus on protein-rich foods to support your workout recovery',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: AppTheme.steelGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: DesignTokens.space8),
            // Value (bigger, heavier)
            Text(
              value,
              style: DesignTokens.displaySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            // Label (smaller, softer)
            Text(
              label,
              style: DesignTokens.labelMedium.copyWith(
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _profile?['name'] ?? 'Unknown';
    final email = _profile?['email'] ?? '';
    final role = _profile?['role'] ?? '';
    final avatarUrl = _profile?['avatar_url'];

    return Scaffold(
      drawerEdgeDragWidth: 24, // left-edge swipe area
              drawer: VagusSideMenu(
          isClient: true, // show "Apply to become a coach"
          onLogout: _logout,
        ),
      appBar: VagusAppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          '📋 Client Dashboard',
          style: DesignTokens.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'Nutrition Plans',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NutritionPlanViewer(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Coaches',
            onPressed: _goToCoachSearch,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Edit Profile',
            onPressed: _goToEditProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => unawaited(_logout()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(DesignTokens.space24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile section
              if (_isValidHttpUrl(avatarUrl))
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(avatarUrl!.trim()),
                )
              else
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.lightGrey,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              const SizedBox(height: DesignTokens.space16),
              Text(
                name,
                style: DesignTokens.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                email,
                style: DesignTokens.bodyMedium.copyWith(
                  color: DesignTokens.ink500,
                ),
              ),
              const SizedBox(height: DesignTokens.space8),
              Chip(
                label: Text(
                  role.toUpperCase(),
                  style: DesignTokens.labelMedium.copyWith(
                    color: AppTheme.primaryBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: AppTheme.lightGrey,
                side: BorderSide(color: AppTheme.primaryBlack.withValues(alpha: 0.3)),
              ),
              const SizedBox(height: DesignTokens.space16),
              
              // Intake form gate
              if (_intakeStatus != 'approved')
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: DesignTokens.space16),
                  padding: const EdgeInsets.all(DesignTokens.space16),
                  decoration: BoxDecoration(
                    color: DesignTokens.warn,
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    border: Border.all(color: DesignTokens.ink100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: DesignTokens.space8),
                          Expanded(
                            child: Text(
                              'Intake Form Required',
                              style: DesignTokens.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.space8),
                      Text(
                        'Please complete your intake form before accessing your dashboard.',
                        style: DesignTokens.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const IntakeWizardScreen(
                                  showRequiredBanner: true,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: DesignTokens.warn,
                          ),
                          child: const Text('Complete Intake Form'),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Neon Rank Chip
              NeonRankChip(
                streak: 7, // TODO: Get from actual streak data
                rank: 'Bronze',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RankHubScreen()),
                  );
                },
                isPro: true, // TODO: Get from actual Pro status
              ),
              const SizedBox(height: DesignTokens.space12),
              
              // Streak Chip
              StreakChip(
                userId: _profile?['id'] ?? '',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StreakScreen()),
                  );
                },
              ),
              const SizedBox(height: DesignTokens.space16),
              
              // Health Rings
              HealthRings(
                userId: _profile?['id'] ?? '',
              ),
              const SizedBox(height: DesignTokens.space16),
              
              // Hydration Ring
              HydrationRing(
                ml: _todayHydration,
                targetMl: _hydrationTarget,
                onAdd250: () => _addWater(250),
                onAdd500: () => _addWater(500),
              ),
              const SizedBox(height: DesignTokens.space24),
              
              // Personalized content based on user maturity
              if (_isNewUser) ...[
                _buildWelcomeFlow(),
              ] else if (_isRepeatUser) ...[
                _buildRepeatUserFlow(),
              ] else if (_isSuperUser) ...[
                _buildSuperUserFlow(),
              ],
              
              const SizedBox(height: DesignTokens.space24),
              
              // AI Usage Meter with Upgrade CTA
              const AIUsageMeter(),
              const SizedBox(height: DesignTokens.space16),
              
              // Supplements Today Card
              SupplementTodayCard(
                userId: _profile?['id'] ?? '',
                onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SupplementListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: DesignTokens.space16),
              
              // Calendar Polish v1.1: Upcoming Session Card
              if (_upcomingSession != null) ...[
                _buildUpcomingSessionCard(),
                const SizedBox(height: DesignTokens.space16),
              ],
              
              // Upgrade to Pro CTA
              FutureBuilder<int>(
                future: PlanAccessManager.instance.remainingAICalls(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data! <= 20) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space8),
                      child: ActionChip(
                        avatar: const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        label: const Text('Upgrade to Pro'),
                        backgroundColor: Colors.amber.shade50,
                        side: BorderSide(color: Colors.amber.shade300),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              const SizedBox(height: DesignTokens.space32),
              const Divider(),
              Text(
                '👨‍🏫 Your Coach',
                style: DesignTokens.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DesignTokens.space8),
              if (_coaches.isEmpty)
                Text(
                  'No coach connected yet.',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: DesignTokens.ink500,
                  ),
                )
              else
                Column(children: _coaches.map(_buildCoachCard).toList()),

              const SizedBox(height: DesignTokens.space32),

              // ✅ NUTRITION PLANS BUTTON
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NutritionPlanViewer(),
                    ),
                  );
                },
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Nutrition Plans'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: DesignTokens.space16),

                             // ✅ FILE MANAGER BUTTON
               ElevatedButton.icon(
                 onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (_) => const FileManagerScreen(),
                     ),
                   );
                 },
                 icon: const Icon(Icons.folder),
                 label: const Text('File Manager'),
                 style: ElevatedButton.styleFrom(
                   minimumSize: const Size.fromHeight(50),
                 ),
               ),

               const SizedBox(height: DesignTokens.space16),

               // ✅ BOOK A SESSION BUTTON
               ElevatedButton.icon(
                 onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (_) => const BookingForm(),
                     ),
                   );
                 },
                 icon: const Icon(Icons.event_available),
                 label: const Text('Book a Session'),
                 style: ElevatedButton.styleFrom(
                   minimumSize: const Size.fromHeight(50),
                 ),
               ),

              const SizedBox(height: DesignTokens.space32),
              const Divider(),
              const SizedBox(height: DesignTokens.space16),

              // Progress System Section
              Text(
                '📊 Progress Tracking',
                style: DesignTokens.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DesignTokens.space16),

              // Compliance Stats Card (top row)
              const ComplianceStatsCard(),

              const SizedBox(height: DesignTokens.space16),

              // Check-In Calendar Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClientCheckInCalendar(),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Check-In Calendar'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: DesignTokens.success,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: DesignTokens.space16),

              // Metrics Card
              MetricsCard(
                userId: _profile?['id'] ?? '',
                metrics: _metrics,
                onRefresh: _loadProgressData,
              ),

              const SizedBox(height: DesignTokens.space16),

              // Photos Card
              PhotosCard(
                userId: _profile?['id'] ?? '',
                photos: _photos,
                onRefresh: _loadProgressData,
              ),

              const SizedBox(height: DesignTokens.space16),

              // Check-ins Card
              CheckinsCard(
                userId: _profile?['id'] ?? '',
                checkins: _checkins,
                coaches: _coaches,
                onRefresh: _loadProgressData,
              ),

              const SizedBox(height: DesignTokens.space16),

              // Export Card
              ExportCard(
                userId: _profile?['id'] ?? '',
                metrics: _metrics,
                photos: _photos,
                checkins: _checkins,
                userName: _profile?['name'] ?? 'Unknown',
              ),

              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.space12),
                  child: Text(
                    _error,
                    style: DesignTokens.bodyMedium.copyWith(
                      color: DesignTokens.danger,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // === Calendar Polish v1.1 Methods ===

  /// Load upcoming session for the user
  Future<void> _loadUpcomingSession() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      final events = await _eventService.fetchEvents(
        start: now,
        end: nextWeek,
        userId: user.id,
      );

      // Find the next upcoming event for this user
      Event? upcoming;
      DateTime? closestTime;

      for (final event in events) {
        if (event.clientId == user.id && event.startAt.isAfter(now)) {
          if (closestTime == null || event.startAt.isBefore(closestTime)) {
            upcoming = event;
            closestTime = event.startAt;
          }
        }
      }

      if (mounted) {
        setState(() {
          _upcomingSession = upcoming;
        });
      }
    } catch (e) {
      debugPrint('Failed to load upcoming session: $e');
    }
  }

  /// Build upcoming session card
  Widget _buildUpcomingSessionCard() {
    if (_upcomingSession == null) return const SizedBox.shrink();

    final session = _upcomingSession!;
    final isToday = session.startAt.year == DateTime.now().year &&
        session.startAt.month == DateTime.now().month &&
        session.startAt.day == DateTime.now().day;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          gradient: LinearGradient(
            colors: [DesignTokens.blue50, DesignTokens.blue50.withValues(alpha: 0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.upcoming,
                  color: AppTheme.primaryBlack,
                ),
                const SizedBox(width: DesignTokens.space8),
                Text(
                  'Upcoming Session',
                  style: DesignTokens.titleMedium.copyWith(
                    color: AppTheme.primaryBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space8,
                      vertical: DesignTokens.space4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.warn,
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    ),
                    child: Text(
                      'TODAY',
                      style: DesignTokens.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.space12),
            
            Text(
              session.title,
              style: DesignTokens.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: DesignTokens.ink500,
                ),
                const SizedBox(width: DesignTokens.space4),
                Text(
                  DateFormat('EEEE, MMM dd').format(session.startAt),
                  style: DesignTokens.bodyMedium.copyWith(
                    color: DesignTokens.ink500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space4),
            
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: DesignTokens.ink500,
                ),
                const SizedBox(width: DesignTokens.space4),
                Text(
                  '${_formatTime(session.startAt)} - ${_formatTime(session.endAt)}',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: DesignTokens.ink500,
                  ),
                ),
              ],
            ),
            
            if (session.location != null && session.location!.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.space4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: DesignTokens.ink500,
                  ),
                  const SizedBox(width: DesignTokens.space4),
                  Expanded(
                    child: Text(
                      session.location!,
                      style: DesignTokens.bodyMedium.copyWith(
                        color: DesignTokens.ink500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: DesignTokens.space12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => unawaited(_exportSessionIcs(session)),
                    icon: const Icon(Icons.file_download, size: 16),
                    label: const Text('Add to Calendar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlack,
                      side: BorderSide(color: AppTheme.primaryBlack.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.space8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => unawaited(_openCalendar(session.startAt)),
                    icon: const Icon(Icons.calendar_view_day, size: 16),
                    label: const Text('View in Calendar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlack,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Export session as ICS and open with FilePreviewer
  Future<void> _exportSessionIcs(Event session) async {
    try {
      final eventData = {
        'id': session.id,
        'title': session.title,
        'description': session.notes ?? '',
        'location': session.location ?? '',
        'start_at': session.startAt.toIso8601String(),
        'end_at': session.endAt.toIso8601String(),
        'recurrence_rule': session.recurrenceRule,
      };

      final icsContent = IcsService.eventToIcs(eventData);
      final fileName = 'session_${session.id}.ics';
      
      // Save to temporary file and open with FilePreviewer
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(icsContent);
      
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FilePreviewer(
              fileUrl: file.path,
              fileName: fileName,
              fileType: 'ics',
              category: 'calendar',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export session: $e')),
        );
      }
    }
  }

  /// Open calendar screen focused on session date
  Future<void> _openCalendar(DateTime focusDate) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalendarScreen(),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    try {
      // Validate the DateTime by checking if it's not null and has valid components
      if (dateTime.year > 0 && dateTime.month >= 1 && dateTime.month <= 12 && 
          dateTime.day >= 1 && dateTime.day <= 31 && 
          dateTime.hour >= 0 && dateTime.hour <= 23 && 
          dateTime.minute >= 0 && dateTime.minute <= 59) {
        return TimeOfDay.fromDateTime(dateTime).format(context);
      } else {
        return 'Invalid time';
      }
    } catch (e) {
      // Fallback to a simple time format if TimeOfDay conversion fails
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
