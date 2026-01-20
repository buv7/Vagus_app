import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/modern_login_screen.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../progress/modern_progress_tracker.dart';
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
            MaterialPageRoute(builder: (context) => const ModernLoginScreen()),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Ready to crush your fitness goals today?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Search coaches button
          IconButton(
            onPressed: _goToCoachSearch,
            icon: const Icon(
              Icons.search,
              color: Colors.white70,
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
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty 
                      ? NetworkImage(avatarUrl) 
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty 
                      ? const Icon(Icons.person, color: Colors.white) 
                      : null,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2A2D2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
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
                    backgroundImage: _profile?['avatar_url'] != null 
                        ? NetworkImage(_profile!['avatar_url']) 
                        : null,
                    child: _profile?['avatar_url'] == null 
                        ? const Icon(Icons.person, color: Colors.white) 
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile?['name']?.toString() ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _profile?['email']?.toString() ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
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
              icon: Icons.person_outline,
              title: 'Profile Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsScreen(),
                  ),
                );
              },
            ),
            _buildMenuTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsSettingsScreen(),
                  ),
                );
              },
            ),
            _buildMenuTile(
              icon: Icons.star_outline,
              title: 'Upgrade to Pro',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UpgradeScreen(),
                  ),
                );
              },
            ),
            _buildMenuTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpCenterScreen(),
                  ),
                );
              },
            ),
            _buildMenuTile(
              iconWidget: FatigueRecoveryIcon(size: 24),
              title: 'Fatigue Dashboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FatigueDashboardScreen(),
                  ),
                );
              },
            ),
            _buildMenuTile(
              icon: Icons.logout,
              title: 'Sign Out',
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    IconData? icon,
    Widget? iconWidget,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: iconWidget ?? (icon != null ? Icon(icon, color: textColor ?? Colors.white70) : null),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white,
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
          MaterialPageRoute(builder: (context) => const ModernLoginScreen()),
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
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Profile image
          CircleAvatar(
            radius: 30,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty 
                ? NetworkImage(avatarUrl) 
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty 
                ? const Icon(Icons.person, size: 30, color: Colors.white) 
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Premium Client',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Coach info
                if (_coachProfile != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Coach: ${_coachProfile!['name'] ?? 'Unknown'}',
                          style: const TextStyle(
                            color: Colors.white70,
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
                      style: const TextStyle(
                        color: Colors.white70,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Metrics',
            style: TextStyle(
              color: Colors.white,
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
                      style: const TextStyle(
                        color: Colors.white,
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
                              ? Colors.red 
                              : Colors.green, 
                          size: 16
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(_progressData?['weight_change'] ?? 0) >= 0 ? '+' : ''}${_progressData?['weight_change'] ?? 0} lbs this week',
                          style: TextStyle(
                            color: (_progressData?['weight_change'] ?? 0) >= 0 
                                ? Colors.red 
                                : Colors.green,
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
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${((_progressData?['goal_weight'] ?? 0) - (_progressData?['weight'] ?? 0)).toStringAsFixed(1)} lbs to go',
                    style: const TextStyle(
                      color: Colors.grey,
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
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Chest ${_progressData?['chest'] ?? '0.0"'}',
                style: const TextStyle(
                  color: Colors.white70,
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
                // Add progress photo functionality
              },
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text(
                'Add Progress Photo',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Supplements Today',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Display real supplements
          if (_supplements.isEmpty)
            const Text(
              'No supplements scheduled for today',
              style: TextStyle(
                color: Colors.grey,
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
    return Row(
      children: [
        const Icon(Icons.access_time, color: Colors.grey, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.grey,
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
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          )
        else
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Mark Taken',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }


  Widget _buildHorizontalScrollSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Overview',
          style: TextStyle(
            color: Colors.white,
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
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: AppTheme.accentGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Health Rings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
        SizedBox(height: 16),
        
        // Health rings
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _HealthRingWidget(label: 'Activity', progress: 0.75, color: AppTheme.accentGreen, value: '450'),
            _HealthRingWidget(label: 'Exercise', progress: 0.60, color: DesignTokens.accentBlue, value: '30'),
            _HealthRingWidget(label: 'Stand', progress: 0.90, color: DesignTokens.accentPink, value: '12'),
          ],
        ),
        ],
      ),
    );
  }


  Widget _buildStreakCard() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.accentPurple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department, color: DesignTokens.accentPurple, size: 20),
              SizedBox(width: 8),
              Text(
                'Streak',
                style: TextStyle(
                  color: Colors.white,
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
                  style: const TextStyle(
                    color: AppTheme.accentOrange,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'days',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Longest: ${_userStats?['longest_streak'] ?? 0} days',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
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
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentOrange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: DesignTokens.accentBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Rank & Level',
                style: TextStyle(
                  color: Colors.white,
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
                      colors: [DesignTokens.accentBlue, DesignTokens.accentBlue.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _userStats?['rank'] ?? 'Bronze Tier',
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Level ${_userStats?['level'] ?? 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_userStats?['xp'] ?? 0} / ${(_userStats?['xp'] ?? 0) + (_userStats?['xp_to_next'] ?? 0)} XP',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (_userStats?['xp'] ?? 0) / ((_userStats?['xp'] ?? 0) + (_userStats?['xp_to_next'] ?? 1)),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(DesignTokens.accentBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIUsageCard() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: AppTheme.accentGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'AI Usage',
                style: TextStyle(
                  color: Colors.white,
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
                const Text(
                  '45 / 100',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'requests this month',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: 0.45,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                ),
                const SizedBox(height: 2),
                Text(
                  '55 remaining',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
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
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.white,
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flash_on, color: AppTheme.accentGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.white,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.accentGreen, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: AppTheme.accentGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: TextStyle(
                  color: Colors.white,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  activity['time'] as String,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
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
                style: const TextStyle(
                  color: Colors.white,
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
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}