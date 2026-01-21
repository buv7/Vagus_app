import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/premium_login_screen.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../theme/theme_colors.dart';
import '../progress/modern_progress_tracker.dart';
import '../progress/progress_gallery.dart';
import '../workouts/modern_workout_plan_viewer.dart';
import '../nutrition/nutrition_hub_screen.dart';
import '../messaging/modern_messenger_screen.dart';
import '../billing/upgrade_screen.dart';
import '../settings/profile_settings_screen.dart';
import '../settings/notifications_settings_screen.dart';
import '../support/help_center_screen.dart';
import '../../widgets/ads/ad_banner_strip.dart';
import '../../widgets/common/fatigue_recovery_icon.dart';
import '../client/client_coach_marketplace.dart';
import '../fatigue/fatigue_dashboard_screen.dart';
import '../../services/config/feature_flags.dart';
import '../../services/retention/dopamine_service.dart';
import '../../services/retention/daily_missions_service.dart';
import '../../models/retention/mission_models.dart';
import '../retention/daily_missions_screen.dart';
import '../../services/growth/passive_virality_service.dart';
import '../../services/share/share_card_service.dart';
import '../../services/health/health_service.dart';
import '../settings/health_connections_screen.dart';

class ModernClientDashboard extends StatefulWidget {
  const ModernClientDashboard({super.key});

  @override
  State<ModernClientDashboard> createState() => _ModernClientDashboardState();
}

class _ModernClientDashboardState extends State<ModernClientDashboard> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;
  
  // Dashboard data
  List<Map<String, dynamic>> _recentActivity = [];
  Map<String, dynamic>? _userStats;
  
  // Real data from Supabase
  Map<String, dynamic>? _coachProfile;
  List<Map<String, dynamic>> _supplements = [];
  Map<String, dynamic>? _progressData;
  Map<String, dynamic>? _streakData;
  Map<String, dynamic>? _rankData;
  
  // Health data from health platforms
  Map<String, dynamic>? _healthData;
  bool _hasHealthSources = false;
  
  // Supplement states
  Map<String, bool> _supplementStates = {};

  // ✅ VAGUS ADD: daily-missions-helper START
  Future<List<DailyMission>> _loadDailyMissions() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return <DailyMission>[];
      final missions = await DailyMissionsService.I.getTodayMissions(userId: user.id);
      if (missions.isEmpty) {
        await DailyMissionsService.I.generateDailyMissions(userId: user.id);
        return await DailyMissionsService.I.getTodayMissions(userId: user.id);
      }
      return missions;
    } catch (_) {
      return <DailyMission>[];
    }
  }
  // ✅ VAGUS ADD: daily-missions-helper END

  @override
  void initState() {
    super.initState();
    unawaited(_loadUserData());
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          unawaited(Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PremiumLoginScreen()),
          ));
        }
        return;
      }

      // Load all dashboard data in parallel with timeout
      final profileFuture = Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single()
          .timeout(const Duration(seconds: 10));
      
      final recentActivityFuture = _loadRecentActivity(user.id);
      final userStatsFuture = _loadUserStats(user.id);

      // Load additional data in background
      unawaited(Future.wait([
        _loadCoachData(),
        _loadSupplements(),
        _loadProgressData(),
        _loadStreakData(),
        _loadRankData(),
        _loadHealthData(),
      ]));

      // Wait for all futures to complete with timeout
      final results = await Future.wait<dynamic>([
        profileFuture,
        recentActivityFuture,
        userStatsFuture,
      ]).timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>;
          _recentActivity = results[1] as List<Map<String, dynamic>>;
          _userStats = results[2] as Map<String, dynamic>?;
          _isLoading = false;
          _error = null;
        });
      }

    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = 'Request timed out. Please check your connection.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCoachData() async {
    if (!mounted) return;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get coach relationship with timeout (tolerate 0 rows)
      final coachRelation = await Supabase.instance.client
          .from('coach_clients')
          .select('coach_id')
          .eq('client_id', user.id)
          .eq('status', 'active')
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (coachRelation == null || coachRelation['coach_id'] == null) {
        if (mounted) {
          setState(() {
            _coachProfile = null;
          });
        }
        return;
      }

      // Get coach profile with timeout
      final coachProfile = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', coachRelation['coach_id'])
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _coachProfile = coachProfile;
        });
      }
    } on TimeoutException {
      debugPrint('Timeout loading coach data');
    } catch (e) {
      debugPrint('Error loading coach data: $e');
    }
  }

  Future<void> _loadSupplements() async {
    if (!mounted) return;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final supplements = await Supabase.instance.client
          .from('supplements')
          .select('*')
          .eq('client_id', user.id)
          .eq('is_active', true)
          .timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _supplements = List<Map<String, dynamic>>.from(supplements);
          // Initialize supplement states
          _supplementStates = Map.fromEntries(
            _supplements.map((s) => MapEntry(
              s['name'] ?? '',
              s['taken_today'] ?? false,
            )),
          );
        });
      }
    } on TimeoutException {
      debugPrint('Timeout loading supplements');
    } catch (e) {
      debugPrint('Error loading supplements: $e');
    }
  }

  Future<void> _loadProgressData() async {
    if (!mounted) return;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final progressData = await Supabase.instance.client
          .from('progress_entries')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _progressData = progressData;
        });
      }
    } on TimeoutException {
      debugPrint('Timeout loading progress data');
    } catch (e) {
      debugPrint('Error loading progress data: $e');
    }
  }

  Future<void> _loadStreakData() async {
    if (!mounted) return;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final streakData = await Supabase.instance.client
          .from('user_streaks')
          .select('*')
          .eq('user_id', user.id)
          .eq('streak_type', 'workout')
          .single()
          .timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _streakData = streakData;
        });
      }
    } on TimeoutException {
      debugPrint('Timeout loading streak data');
    } catch (e) {
      debugPrint('Error loading streak data: $e');
    }
  }

  Future<void> _loadRankData() async {
    if (!mounted) return;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final rankData = await Supabase.instance.client
          .from('user_ranks')
          .select('*')
          .eq('user_id', user.id)
          .single()
          .timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _rankData = rankData;
        });
      }
    } on TimeoutException {
      debugPrint('Timeout loading rank data');
    } catch (e) {
      debugPrint('Error loading rank data: $e');
    }
  }


  Future<List<Map<String, dynamic>>> _loadRecentActivity(String userId) async {
    try {
      // Load recent workouts, meals, and progress updates
      final activities = <Map<String, dynamic>>[];
      
      // Add mock recent activities for now
      activities.addAll([
        {
          'type': 'workout',
          'title': 'Upper Body Strength',
          'time': '2 hours ago',
          'icon': Icons.fitness_center,
          'color': AppTheme.accentGreen,
        },
        {
          'type': 'meal',
          'title': 'Chicken & Rice Bowl',
          'time': '4 hours ago',
          'icon': Icons.restaurant,
          'color': AppTheme.accentOrange,
        },
        {
          'type': 'progress',
          'title': 'Weight: 75.2 kg',
          'time': '1 day ago',
          'icon': Icons.trending_up,
          'color': AppTheme.accentGreen,
        },
      ]);
      
      return activities;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> _loadUserStats(String userId) async {
    try {
      // Load user statistics like streak, rank, level
      return {
        'current_streak': 12,
        'longest_streak': 28,
        'rank': 'Gold Tier',
        'level': 8,
        'xp': 2450,
        'xp_to_next': 550,
        'total_workouts': 156,
        'total_meals_logged': 423,
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadHealthData() async {
    if (!mounted) return;
    
    try {
      final healthService = HealthService();
      
      // Check if user has connected health sources
      final sources = await healthService.getConnectedSources();
      final hasHealthSources = sources.isNotEmpty;
      
      // Get today's health summary from database
      final today = DateTime.now();
      final dailySummary = await healthService.getDailySummary(today);
      
      if (mounted) {
        setState(() {
          _hasHealthSources = hasHealthSources;
          _healthData = dailySummary ?? {
            'steps': 0,
            'active_kcal': 0,
            'exercise_minutes': 0,
            'stand_hours': 0,
            'distance_km': 0.0,
          };
        });
      }
    } on TimeoutException {
      debugPrint('Timeout loading health data');
    } catch (e) {
      debugPrint('Error loading health data: $e');
      if (mounted) {
        setState(() {
          _healthData = {
            'steps': 0,
            'active_kcal': 0,
            'exercise_minutes': 0,
            'stand_hours': 0,
            'distance_km': 0.0,
          };
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentGreen),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text('Error: $_error', style: TextStyle(color: theme.colorScheme.onSurface)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ VAGUS ADD: daily-dopamine START
              FutureBuilder<bool>(
                future: FeatureFlags.instance.isEnabled(FeatureFlags.dailyDopamine),
                builder: (context, flagSnapshot) {
                  if (!(flagSnapshot.data ?? false)) return const SizedBox.shrink();
                  return FutureBuilder<String?>(
                    future: () async {
                      try {
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user == null) return null;
                        return await DopamineService.I.triggerDopamineOnOpen(userId: user.id);
                      } catch (_) {
                        return null;
                      }
                    }(),
                    builder: (context, snapshot) {
                      final message = snapshot.data;
                      if (message == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade400, Colors.orange.shade600],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.celebration, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              // ✅ VAGUS ADD: daily-dopamine END
              
              // Header
              _buildHeader(),
              
              const SizedBox(height: 16),
              
              // Ad Banner Strip
              const AdBannerStrip(audience: 'client'),
              
              const SizedBox(height: 24),
              
              // ✅ VAGUS ADD: daily-missions START
              FutureBuilder<bool>(
                future: FeatureFlags.instance.isEnabled(FeatureFlags.dailyMissions),
                builder: (context, flagSnapshot) {
                  if (!(flagSnapshot.data ?? false)) return const SizedBox.shrink();
                  
                  return FutureBuilder<List<DailyMission>>(
                    future: _loadDailyMissions(),
                    builder: (context, snapshot) {
                      final missions = snapshot.data ?? [];
                      if (missions.isEmpty) return const SizedBox.shrink();
                      
                      final completedCount = missions.where((m) => m.completed).length;
                      final totalCount = missions.length;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DailyMissionsScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.flag, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Daily Missions',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$completedCount/$totalCount',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: totalCount > 0 ? completedCount / totalCount : 0,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to view all missions',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // ✅ VAGUS ADD: daily-missions END
              
              // ✅ VAGUS ADD: passive-virality START
              FutureBuilder<bool>(
                future: FeatureFlags.instance.isEnabled(FeatureFlags.passiveVirality),
                builder: (context, flagSnapshot) {
                  if (!(flagSnapshot.data ?? false)) return const SizedBox.shrink();
                  
                  return FutureBuilder<ShareableMomentData?>(
                    future: () async {
                      try {
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user == null) return null;
                        return await PassiveViralityService.I.detectShareableMoments(userId: user.id);
                      } catch (_) {
                        return null;
                      }
                    }(),
                    builder: (context, snapshot) {
                      final moment = snapshot.data;
                      if (moment == null) return const SizedBox.shrink();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.blue.shade50,
                        child: InkWell(
                          onTap: () async {
                            try {
                              final user = Supabase.instance.client.auth.currentUser;
                              if (user == null) return;

                              // Generate share card
                              final shareData = ShareDataModel(
                                title: moment.title,
                                subtitle: moment.subtitle,
                                metrics: moment.metrics,
                              );

                              // Generate share asset (for future use when share sheet is implemented)
                              // ignore: unused_local_variable
                              final shareAsset = await ShareCardService().buildStory(
                                ShareTemplate.minimal,
                                shareData,
                              );

                              // Log viral event
                              await PassiveViralityService.I.triggerPassiveShare(
                                userId: user.id,
                                moment: moment,
                                source: 'dashboard_suggestion',
                              );

                              // TODO: Open native share sheet with shareAsset
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Share card generated! (Share sheet coming soon)')),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.share, color: Colors.blue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Shareable Moment',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        moment.title,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // ✅ VAGUS ADD: passive-virality END
              
              const SizedBox(height: 24),
              
              // Profile Card
              _buildProfileCard(),
              
              // Progress Metrics Card
              _buildProgressMetricsCard(),
              
              // Supplements Card
              _buildSupplementsCard(),
              
              const SizedBox(height: 24),
              
              // Horizontal Scroll: Health Rings, Streak, Rank, AI Usage
              _buildHorizontalScrollSection(),
              
              const SizedBox(height: 24),
              
              // Bottom Grid: Quick Actions, Recent Activity
              _buildBottomGrid(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final userName = _profile?['name']?.toString() ?? 'User';
    final avatarUrl = _profile?['avatar_url']?.toString();
    final tc = context.tc;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Welcome message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName!',
                  style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Ready to crush your fitness goals today?',
                  style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Search coaches button
          IconButton(
            onPressed: _goToCoachSearch,
            icon: Icon(
              Icons.search,
              color: tc.iconSecondary,
              size: 24,
            ),
            tooltip: 'Search Coaches',
          ),
          
          // Profile picture with dropdown
          GestureDetector(
            onTap: () => _showProfileMenu(context),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: tc.avatarBg,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty 
                      ? NetworkImage(avatarUrl) 
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty 
                      ? Icon(Icons.person, color: tc.avatarIcon) 
                      : null,
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, color: tc.iconSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext parentContext) {
    final tc = parentContext.tc;
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ThemeColors.wrap(
        context: parentContext,
        child: Builder(
          builder: (ctx) {
            final sheetTc = ctx.tc;
            return Container(
              decoration: sheetTc.modalDecoration,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetTc.textDisabled,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Profile info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: sheetTc.avatarBg,
                          backgroundImage: _profile?['avatar_url'] != null 
                              ? NetworkImage(_profile!['avatar_url']) 
                              : null,
                          child: _profile?['avatar_url'] == null 
                              ? Icon(Icons.person, color: sheetTc.avatarIcon) 
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profile?['name']?.toString() ?? 'User',
                                style: TextStyle(
                                  color: sheetTc.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _profile?['email']?.toString() ?? '',
                                style: TextStyle(
                                  color: sheetTc.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Menu items
                  _buildMenuTile(
                    context: ctx,
                    icon: Icons.person_outline,
                    title: 'Profile Settings',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        parentContext,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    context: ctx,
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        parentContext,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    context: ctx,
                    icon: Icons.star_outline,
                    title: 'Upgrade to Pro',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        parentContext,
                        MaterialPageRoute(
                          builder: (context) => const UpgradeScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    context: ctx,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        parentContext,
                        MaterialPageRoute(
                          builder: (context) => const HelpCenterScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    context: ctx,
                    iconWidget: FatigueRecoveryIcon(size: 24),
                    title: 'Fatigue Dashboard',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        parentContext,
                        MaterialPageRoute(
                          builder: (context) => const FatigueDashboardScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    context: ctx,
                    icon: Icons.logout,
                    title: 'Sign Out',
                    textColor: sheetTc.danger,
                    onTap: () {
                      Navigator.pop(ctx);
                      _logout();
                    },
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    IconData? icon,
    Widget? iconWidget,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final tc = context.tc;
    return ListTile(
      leading: iconWidget ?? (icon != null ? Icon(icon, color: textColor ?? tc.iconSecondary) : null),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? tc.textPrimary,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        unawaited(Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PremiumLoginScreen()),
          (route) => false,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goToCoachSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientCoachMarketplace(),
      ),
    );
  }

  Widget _buildProfileCard() {
    final userName = _profile?['name']?.toString() ?? 'User';
    final avatarUrl = _profile?['avatar_url']?.toString();
    final tc = context.tc;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: tc.cardDecoration,
      child: Row(
        children: [
          // Profile image
          CircleAvatar(
            radius: 30,
            backgroundColor: tc.avatarBg,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty 
                ? NetworkImage(avatarUrl) 
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty 
                ? Icon(Icons.person, size: 30, color: tc.avatarIcon) 
                : null,
          ),
          
          const SizedBox(width: 16),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Premium Client',
                  style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Coach info
                if (_coachProfile != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tc.surfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, color: tc.iconSecondary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Coach: ${_coachProfile!['name'] ?? 'Unknown'}',
                          style: TextStyle(
                            color: tc.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // Streak and Rank
                Row(
                  children: [
                    const Icon(Icons.flash_on, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_streakData?['current_streak'] ?? 0} Day Streak',
                      style: TextStyle(
                        color: tc.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Rank: ${_rankData?['rank_name'] ?? 'Bronze'}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetricsCard() {
    final tc = context.tc;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: tc.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Metrics',
            style: TextStyle(
              color: tc.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Weight display
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_progressData?['weight'] ?? '0.0'} lbs',
                      style: TextStyle(
                        color: tc.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          (_progressData?['weight_change'] ?? 0) >= 0 
                              ? Icons.trending_up 
                              : Icons.trending_down, 
                          color: (_progressData?['weight_change'] ?? 0) >= 0 
                              ? tc.danger 
                              : tc.success, 
                          size: 16
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(_progressData?['weight_change'] ?? 0) >= 0 ? '+' : ''}${_progressData?['weight_change'] ?? 0} lbs this week',
                          style: TextStyle(
                            color: (_progressData?['weight_change'] ?? 0) >= 0 
                                ? tc.danger 
                                : tc.success,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Goal info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Goal: ${_progressData?['goal_weight'] ?? '0'} lbs',
                    style: TextStyle(
                      color: tc.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${((_progressData?['goal_weight'] ?? 0) - (_progressData?['weight'] ?? 0)).toStringAsFixed(1)} lbs to go',
                    style: TextStyle(
                      color: tc.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Body measurements
          Row(
            children: [
              Text(
                'Waist ${_progressData?['waist'] ?? '0.0"'}',
                style: TextStyle(
                  color: tc.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Chest ${_progressData?['chest'] ?? '0.0"'}',
                style: TextStyle(
                  color: tc.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Add progress photo button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProgressGallery(userId: user.id),
                    ),
                  );
                }
              },
              icon: Icon(Icons.camera_alt, color: tc.textOnDark),
              label: Text(
                'Add Progress Photo',
                style: TextStyle(color: tc.textOnDark),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: tc.info,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplementsCard() {
    final tc = context.tc;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: tc.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supplements Today',
            style: TextStyle(
              color: tc.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Display real supplements
          if (_supplements.isEmpty)
            Text(
              'No supplements scheduled for today',
              style: TextStyle(
                color: tc.textSecondary,
                fontSize: 14,
              ),
            )
          else
            ..._supplements.map((supplement) {
              final name = supplement['name'] ?? '';
              final time = supplement['time_of_day'] ?? 'Morning';
              final isTaken = _supplementStates[name] ?? false;
              
              return Column(
                children: [
                  _buildSupplementItem(
                    name,
                    time,
                    isTaken,
                    onTap: () {
                      _markSupplementTaken(supplement['id'], name);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
        ],
      ),
    );
  }

  Future<void> _markSupplementTaken(String supplementId, String name) async {
    if (!mounted) return;
    
    try {
      // Update in Supabase with timeout
      await Supabase.instance.client
          .from('supplements')
          .update({'taken_today': true})
          .eq('id', supplementId)
          .timeout(const Duration(seconds: 5));

      // Update local state
      if (mounted) {
        setState(() {
          _supplementStates[name] = true;
        });
      }
    } on TimeoutException {
      debugPrint('Timeout marking supplement as taken');
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request timed out. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking supplement as taken: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSupplementItem(String name, String time, bool isTaken, {VoidCallback? onTap}) {
    final tc = context.tc;
    return Row(
      children: [
        Icon(Icons.access_time, color: tc.iconSecondary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  color: tc.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        if (isTaken)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: tc.success,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.check,
              color: tc.textOnDark,
              size: 16,
            ),
          )
        else
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tc.info,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Mark Taken',
                style: TextStyle(
                  color: tc.textOnDark,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }


  Widget _buildHorizontalScrollSection() {
    final tc = context.tc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: TextStyle(
            color: tc.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildHealthRingsCard(),
              const SizedBox(width: 16),
              _buildStepsCard(),
              const SizedBox(width: 16),
              _buildStreakCard(),
              const SizedBox(width: 16),
              _buildRankCard(),
              const SizedBox(width: 16),
              _buildAIUsageCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthRingsCard() {
    final tc = context.tc;
    
    // Get real health data or use defaults
    final activeKcal = (_healthData?['active_kcal'] as num?)?.toInt() ?? 0;
    final exerciseMins = (_healthData?['exercise_minutes'] as num?)?.toInt() ?? 0;
    final standHours = (_healthData?['stand_hours'] as num?)?.toInt() ?? 0;
    
    // Calculate progress (goals: 500 kcal, 30 min, 12 hours)
    final activityProgress = (activeKcal / 500).clamp(0.0, 1.0);
    final exerciseProgress = (exerciseMins / 30).clamp(0.0, 1.0);
    final standProgress = (standHours / 12).clamp(0.0, 1.0);
    
    return GestureDetector(
      onTap: () {
        // Navigate to health connections if no data
        if (!_hasHealthSources) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HealthConnectionsScreen()),
          );
        }
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tc.accent.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: tc.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Health Rings',
                    style: TextStyle(
                      color: tc.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!_hasHealthSources)
                  Icon(Icons.link_off, color: tc.textSecondary, size: 16),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Health rings with real data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _HealthRingWidget(
                  label: 'Activity',
                  progress: activityProgress,
                  color: AppTheme.accentGreen,
                  value: '$activeKcal',
                ),
                _HealthRingWidget(
                  label: 'Exercise',
                  progress: exerciseProgress,
                  color: DesignTokens.accentBlue,
                  value: '$exerciseMins',
                ),
                _HealthRingWidget(
                  label: 'Stand',
                  progress: standProgress,
                  color: DesignTokens.accentPink,
                  value: '$standHours',
                ),
              ],
            ),
            
            // Connect prompt if no health sources
            if (!_hasHealthSources) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap to connect health app',
                  style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCard() {
    final tc = context.tc;
    
    // Get real steps data
    final steps = (_healthData?['steps'] as num?)?.toInt() ?? 0;
    final distanceKm = (_healthData?['distance_km'] as num?)?.toDouble() ?? 0.0;
    
    // Goal: 10,000 steps
    const stepsGoal = 10000;
    final progress = (steps / stepsGoal).clamp(0.0, 1.0);
    
    // Format steps with thousands separator
    String formatSteps(int value) {
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}k';
      }
      return value.toString();
    }
    
    return GestureDetector(
      onTap: () {
        if (!_hasHealthSources) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HealthConnectionsScreen()),
          );
        }
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentGreen.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_walk, color: AppTheme.accentGreen, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Steps',
                    style: TextStyle(
                      color: tc.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!_hasHealthSources)
                  Icon(Icons.link_off, color: tc.textSecondary, size: 14),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Steps count with ring
            Center(
              child: SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: AppTheme.accentGreen.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatSteps(steps),
                          style: TextStyle(
                            color: tc.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'steps',
                          style: TextStyle(
                            color: tc.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Distance and goal info
            Center(
              child: Column(
                children: [
                  Text(
                    '${distanceKm.toStringAsFixed(1)} km',
                    style: TextStyle(
                      color: tc.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Goal: ${formatSteps(stepsGoal)}',
                    style: TextStyle(
                      color: tc.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            
            // Connect prompt if no health sources
            if (!_hasHealthSources) ...[
              const Spacer(),
              Center(
                child: Text(
                  'Connect health app',
                  style: TextStyle(
                    color: tc.info,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildStreakCard() {
    final tc = context.tc;
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.accentPurple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: DesignTokens.accentPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Streak',
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_userStats?['current_streak'] ?? 0}',
                  style: TextStyle(
                    color: tc.warning,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'days',
                  style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Longest: ${_userStats?['longest_streak'] ?? 0} days',
                  style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard() {
    final tc = context.tc;
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tc.warning.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: tc.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Rank & Level',
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tc.info, tc.info.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _userStats?['rank'] ?? 'Bronze Tier',
                    style: TextStyle(
                      color: tc.textOnDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Level ${_userStats?['level'] ?? 1}',
                  style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_userStats?['xp'] ?? 0} / ${(_userStats?['xp'] ?? 0) + (_userStats?['xp_to_next'] ?? 0)} XP',
                  style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (_userStats?['xp'] ?? 0) / ((_userStats?['xp'] ?? 0) + (_userStats?['xp_to_next'] ?? 1)),
                  backgroundColor: tc.border,
                  valueColor: AlwaysStoppedAnimation<Color>(tc.info),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIUsageCard() {
    final tc = context.tc;
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tc.accent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: tc.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Usage',
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '45 / 100',
                  style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'requests this month',
                  style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 8,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: 0.45,
                  backgroundColor: tc.border,
                  valueColor: AlwaysStoppedAnimation<Color>(tc.accent),
                ),
                const SizedBox(height: 2),
                Text(
                  '55 remaining',
                  style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 8,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UpgradeScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tc.accent,
                      foregroundColor: tc.textOnDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    child: const Text(
                      'Upgrade for More',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 768;
        
        if (isTablet) {
          // 2-column layout for tablet
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildQuickActionsCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildRecentActivityCard()),
            ],
          );
        } else {
          // Single column layout for mobile
          return Column(
            children: [
              _buildQuickActionsCard(),
              const SizedBox(height: 16),
              _buildRecentActivityCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildQuickActionsCard() {
    final tc = context.tc;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tc.accent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: tc.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildQuickActionButton('Start Workout', Icons.fitness_center, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernWorkoutPlanViewer(),
                  ),
                );
              }),
              _buildQuickActionButton('Log Meal', Icons.restaurant, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NutritionHubScreen(mode: NutritionHubMode.auto),
                  ),
                );
              }),
              _buildQuickActionButton('Add Photo', Icons.camera_alt, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernProgressTracker(),
                  ),
                );
              }),
              _buildQuickActionButton('Message Coach', Icons.message, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernMessengerScreen(),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onTap) {
    final tc = context.tc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tc.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tc.accent.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: tc.accent, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: tc.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final tc = context.tc;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tc.accent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: tc.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Activity list
          ...(_recentActivity.map((activity) => _buildActivityItem(activity))),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final tc = context.tc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  activity['time'] as String,
                  style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 12,
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

// Const widget for health rings to optimize rebuilds
class _HealthRingWidget extends StatelessWidget {
  const _HealthRingWidget({
    required this.label,
    required this.progress,
    required this.color,
    required this.value,
  });

  final String label;
  final double progress;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: tc.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}