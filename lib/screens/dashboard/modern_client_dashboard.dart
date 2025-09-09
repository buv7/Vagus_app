import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../auth/modern_login_screen.dart';
import 'edit_profile_screen.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../../services/progress/progress_service.dart';
import '../../services/nutrition/grocery_service.dart';
import '../../services/nutrition/calendar_bridge.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../components/health/health_rings.dart';
import '../../components/streak/streak_chip.dart';
import '../../components/rank/neon_rank_chip.dart';
import '../../widgets/ai/ai_usage_meter.dart';
import '../supplements/supplements_today_screen.dart';
import '../progress/modern_progress_tracker.dart';
import '../workouts/modern_workout_plan_viewer.dart';
import '../nutrition/modern_nutrition_plan_viewer.dart';
import '../calendar/modern_calendar_viewer.dart';
import '../messaging/modern_messenger_screen.dart';
import '../rank/rank_hub_screen.dart';
import '../streaks/streak_screen.dart';
import '../billing/upgrade_screen.dart';
import '../../widgets/ads/ad_banner_strip.dart';

class ModernClientDashboard extends StatefulWidget {
  const ModernClientDashboard({super.key});

  @override
  State<ModernClientDashboard> createState() => _ModernClientDashboardState();
}

class _ModernClientDashboardState extends State<ModernClientDashboard> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  List<NutritionPlan> _nutritionPlans = [];
  Map<String, dynamic>? _dailyProgress;
  
  final NutritionService _nutritionService = NutritionService();
  final ProgressService _progressService = ProgressService();
  final GroceryService _groceryService = GroceryService();
  final NutritionCalendarBridge _calendarBridge = NutritionCalendarBridge();
  String? _error;
  
  // Dashboard data
  Map<String, dynamic>? _upcomingSession;
  List<Map<String, dynamic>> _recentActivity = [];
  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? _healthData;
  
  // Real data from Supabase
  Map<String, dynamic>? _coachProfile;
  List<Map<String, dynamic>> _supplements = [];
  Map<String, dynamic>? _progressData;
  Map<String, dynamic>? _streakData;
  Map<String, dynamic>? _rankData;
  String? _selectedNutritionPlan;
  int _currentCalories = 0;
  int _targetCalories = 0;
  int _currentProtein = 0;
  int _targetProtein = 0;
  
  // Supplement states
  Map<String, bool> _supplementStates = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ModernLoginScreen()),
          );
        }
        return;
      }

      // Load all dashboard data in parallel
      final profileFuture = Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single() as Future<Map<String, dynamic>>;
      
      final nutritionPlansFuture = _nutritionService.fetchPlansForClient(user.id);
      final dailyProgressFuture = _loadDailyProgress(user.id);
      final upcomingSessionFuture = _loadUpcomingSession(user.id);
      final recentActivityFuture = _loadRecentActivity(user.id);
      final userStatsFuture = _loadUserStats(user.id);
      final healthDataFuture = _loadHealthData(user.id);

      // Load additional data
      await Future.wait([
        _loadCoachData(),
        _loadSupplements(),
        _loadProgressData(),
        _loadStreakData(),
        _loadRankData(),
      ]);

      // Wait for all futures to complete
      final results = await Future.wait<dynamic>([
        profileFuture,
        nutritionPlansFuture,
        dailyProgressFuture,
        upcomingSessionFuture,
        recentActivityFuture,
        userStatsFuture,
        healthDataFuture,
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>;
          _nutritionPlans = results[1] as List<NutritionPlan>;
          _dailyProgress = results[2] as Map<String, dynamic>?;
          _upcomingSession = results[3] as Map<String, dynamic>?;
          _recentActivity = results[4] as List<Map<String, dynamic>>;
          _userStats = results[5] as Map<String, dynamic>?;
          _healthData = results[6] as Map<String, dynamic>?;
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

  Future<void> _loadCoachData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get coach relationship
      final coachRelation = await Supabase.instance.client
          .from('coach_clients')
          .select('coach_id')
          .eq('client_id', user.id)
          .eq('status', 'active')
          .single();

      if (coachRelation != null) {
        // Get coach profile
        final coachProfile = await Supabase.instance.client
            .from('profiles')
            .select('*')
            .eq('id', coachRelation['coach_id'])
            .single();

        if (mounted) {
          setState(() {
            _coachProfile = coachProfile;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading coach data: $e');
    }
  }

  Future<void> _loadSupplements() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final supplements = await Supabase.instance.client
          .from('supplements')
          .select('*')
          .eq('client_id', user.id)
          .eq('is_active', true);

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
    } catch (e) {
      debugPrint('Error loading supplements: $e');
    }
  }

  Future<void> _loadProgressData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final progressData = await Supabase.instance.client
          .from('progress_entries')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _progressData = progressData;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress data: $e');
    }
  }

  Future<void> _loadStreakData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final streakData = await Supabase.instance.client
          .from('user_streaks')
          .select('*')
          .eq('user_id', user.id)
          .eq('streak_type', 'workout')
          .single();

      if (mounted) {
        setState(() {
          _streakData = streakData;
        });
      }
    } catch (e) {
      debugPrint('Error loading streak data: $e');
    }
  }

  Future<void> _loadRankData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final rankData = await Supabase.instance.client
          .from('user_ranks')
          .select('*')
          .eq('user_id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _rankData = rankData;
        });
      }
    } catch (e) {
      debugPrint('Error loading rank data: $e');
    }
  }

  Future<Map<String, dynamic>?> _loadDailyProgress(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final progressData = await _progressService.fetchMetrics(userId);
      return progressData.isNotEmpty 
          ? progressData.firstWhere(
              (metric) => metric['date'] == today,
              orElse: () => {},
            )
          : {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>?> _loadUpcomingSession(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('calendar_events')
          .select('*')
          .eq('user_id', userId)
          .gte('start_at', DateTime.now().toIso8601String())
          .order('start_at')
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
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
          'color': AppTheme.mintAqua,
        },
        {
          'type': 'meal',
          'title': 'Chicken & Rice Bowl',
          'time': '4 hours ago',
          'icon': Icons.restaurant,
          'color': AppTheme.softYellow,
        },
        {
          'type': 'progress',
          'title': 'Weight: 75.2 kg',
          'time': '1 day ago',
          'icon': Icons.trending_up,
          'color': AppTheme.mintAqua,
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

  Future<Map<String, dynamic>?> _loadHealthData(String userId) async {
    try {
      // Load health data for rings
      return {
        'activity_ring': 0.75,
        'exercise_ring': 0.60,
        'stand_ring': 0.90,
        'activity_value': 450,
        'exercise_value': 30,
        'stand_value': 12,
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ModernLoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  void _goToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1C1E),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.mintAqua),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1C1E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text('Error: $_error', style: const TextStyle(color: Colors.white)),
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
      backgroundColor: const Color(0xFF1A1C1E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              
              const SizedBox(height: 16),
              
              // Ad Banner Strip
              const AdBannerStrip(audience: 'client'),
              
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
    final userName = _profile?['name'] ?? 'User';
    final userEmail = _profile?['email'] ?? '';
    final avatarUrl = _profile?['avatar_url'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Hamburger menu icon
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              // Menu functionality can be added here
            },
          ),
          
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
          
          // Profile picture with dropdown
          GestureDetector(
            onTap: () {
              // Profile menu functionality
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
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

  Widget _buildProfileCard() {
    final userName = _profile?['name'] ?? 'User';
    final userEmail = _profile?['email'] ?? '';
    final avatarUrl = _profile?['avatar_url'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Profile image
          CircleAvatar(
            radius: 30,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? const Icon(Icons.person, size: 30, color: Colors.white) : null,
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
        color: const Color(0xFF2A2D2E),
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
        color: const Color(0xFF2A2D2E),
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
            }).toList(),
        ],
      ),
    );
  }

  Future<void> _markSupplementTaken(String supplementId, String name) async {
    try {
      // Update in Supabase
      await Supabase.instance.client
          .from('supplements')
          .update({'taken_today': true})
          .eq('id', supplementId);

      // Update local state
      setState(() {
        _supplementStates[name] = true;
      });
    } catch (e) {
      debugPrint('Error marking supplement as taken: $e');
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

  Widget _buildOldHeader() {return Row(
      children: [
        // Hamburger menu
        Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        
        // Welcome message
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, ${_profile?['full_name'] ?? _profile?['name'] ?? 'User'}!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready to crush your fitness goals today?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        
        // Profile dropdown
        PopupMenuButton<String>(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.mintAqua,
                backgroundImage: _profile?['avatar_url'] != null 
                  ? NetworkImage(_profile!['avatar_url']) 
                  : null,
                child: _profile?['avatar_url'] == null 
                  ? Text(
                      (_profile?['first_name'] ?? 'A')[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
          color: const Color(0xFF2C2F33),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 8,
          onSelected: (String value) {
            switch (value) {
              case 'edit_profile':
                _goToEditProfile();
                break;
              case 'logout':
                _logout();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'edit_profile',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Edit Profile',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 768;
        final isDesktop = constraints.maxWidth > 1024;
        
        if (isDesktop) {
          // 3-column layout for desktop
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildProfileCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildProgressCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildSupplementsCard()),
            ],
          );
        } else if (isTablet) {
          // 2-column layout for tablet
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildProfileCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildProgressCard()),
                ],
              ),
              const SizedBox(height: 16),
              _buildSupplementsCard(),
            ],
          );
        } else {
          // Single column layout for mobile
          return Column(
            children: [
              _buildProfileCard(),
              const SizedBox(height: 16),
              _buildProgressCard(),
              const SizedBox(height: 16),
              _buildSupplementsCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mintAqua.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and basic info
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.mintAqua,
                backgroundImage: _profile?['avatar_url'] != null 
                  ? NetworkImage(_profile!['avatar_url']) 
                  : null,
                child: _profile?['avatar_url'] == null 
                  ? Text(
                      (_profile?['first_name'] ?? 'A')[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile?['full_name'] ?? _profile?['name'] ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Client',
                      style: TextStyle(
                        color: AppTheme.mintAqua,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_userStats != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.local_fire_department, 
                               color: AppTheme.softYellow, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_userStats!['current_streak']} day streak',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats row
          if (_userStats != null)
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Level', '${_userStats!['level']}'),
                ),
                Expanded(
                  child: _buildStatItem('XP', '${_userStats!['xp']}'),
                ),
                Expanded(
                  child: _buildStatItem('Workouts', '${_userStats!['total_workouts']}'),
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goToEditProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.mintAqua,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mintAqua.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppTheme.mintAqua, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Weight tracking
          _buildProgressItem('Weight', '75.2 kg', '↗ +0.3 kg', AppTheme.mintAqua),
          
          const SizedBox(height: 12),
          
          // Body fat
          _buildProgressItem('Body Fat', '12.5%', '↘ -0.2%', AppTheme.softYellow),
          
          const SizedBox(height: 12),
          
          // Muscle mass
          _buildProgressItem('Muscle', '68.1 kg', '↗ +0.5 kg', AppTheme.mintAqua),
          
          const SizedBox(height: 16),
          
          // View all progress button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernProgressTracker(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.mintAqua,
                side: BorderSide(color: AppTheme.mintAqua),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('View All Progress'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, String change, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              change,
              style: TextStyle(
                color: color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupplementsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mintAqua.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication, color: AppTheme.mintAqua, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Supplements Today',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Supplement list
          _buildSupplementItem('Whey Protein', 'Morning', _supplementStates['Whey Protein'] ?? false, (value) {
            setState(() {
              _supplementStates['Whey Protein'] = value ?? false;
            });
          }),
          _buildSupplementItem('Creatine', 'Pre-Workout', _supplementStates['Creatine'] ?? false, (value) {
            setState(() {
              _supplementStates['Creatine'] = value ?? false;
            });
          }),
          _buildSupplementItem('Multivitamin', 'Evening', _supplementStates['Multivitamin'] ?? false, (value) {
            setState(() {
              _supplementStates['Multivitamin'] = value ?? false;
            });
          }),
          
          const SizedBox(height: 16),
          
          // Progress bar
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _getSupplementsProgress(),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.mintAqua),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_getSupplementsTakenCount()}/3',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // View all supplements button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupplementsTodayScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.mintAqua,
                side: BorderSide(color: AppTheme.mintAqua),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('View All Supplements'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplementItem(String name, String time, bool isTaken, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: isTaken,
            onChanged: onChanged,
            activeColor: AppTheme.mintAqua,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isTaken ? Colors.white70 : Colors.white,
                    fontSize: 14,
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
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

  double _getSupplementsProgress() {
    final takenCount = _supplementStates.values.where((taken) => taken).length;
    return takenCount / _supplementStates.length;
  }

  int _getSupplementsTakenCount() {
    return _supplementStates.values.where((taken) => taken).length;
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
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mintAqua.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: AppTheme.mintAqua, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Health Rings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Health rings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHealthRing('Activity', 0.75, AppTheme.mintAqua, '450'),
              _buildHealthRing('Exercise', 0.60, AppTheme.softYellow, '30'),
              _buildHealthRing('Stand', 0.90, const Color(0xFFFF5A5A), '12'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRing(String label, double progress, Color color, String value) {
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

  Widget _buildStreakCard() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.softYellow.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department, color: AppTheme.softYellow, size: 20),
              const SizedBox(width: 8),
              const Text(
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
                    color: AppTheme.softYellow,
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
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.softYellow.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppTheme.softYellow, size: 20),
              const SizedBox(width: 8),
              const Text(
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
                      colors: [AppTheme.softYellow, AppTheme.softYellow.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _userStats?['rank'] ?? 'Bronze Tier',
                    style: const TextStyle(
                      color: AppTheme.primaryBlack,
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
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.softYellow),
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
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mintAqua.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppTheme.mintAqua, size: 20),
              const SizedBox(width: 8),
              const Text(
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
                Text(
                  '45 / 100',
                  style: const TextStyle(
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
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.mintAqua),
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
                      backgroundColor: AppTheme.mintAqua,
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
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mintAqua.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: AppTheme.mintAqua, size: 20),
              const SizedBox(width: 8),
              const Text(
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
                    builder: (context) => const ModernNutritionPlanViewer(),
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
          color: AppTheme.primaryBlack.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.mintAqua.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.mintAqua, size: 24),
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
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mintAqua.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppTheme.mintAqua, size: 20),
              const SizedBox(width: 8),
              const Text(
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


  // Export nutrition plan to PDF
  Future<void> _exportNutritionPlanToPDF() async {
    if (_nutritionPlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No nutrition plan available to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final plan = _nutritionPlans.first;
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
        ),
      );

      // Generate PDF using the existing service
      await _nutritionService.exportNutritionPlanToPdf(
        plan,
        'Your Coach',
        _profile?['name'] ?? 'Client',
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Generate grocery list
  Future<void> _generateGroceryList() async {
    if (_nutritionPlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No nutrition plan available for grocery list'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final plan = _nutritionPlans.first;
      
      // Show week selection dialog
      final weekIndex = await _showWeekSelectionDialog();
      if (weekIndex == null) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating grocery list...'),
            ],
          ),
        ),
      );

      // Generate grocery list
      final groceryList = await _groceryService.generateForPlanWeek(
        planId: plan.id!,
        weekIndex: weekIndex,
        ownerId: user.id,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to grocery list screen
      if (mounted) {
        Navigator.pushNamed(context, '/grocery-list', arguments: groceryList);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate grocery list: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add nutrition plan to calendar
  Future<void> _addToCalendar() async {
    if (_nutritionPlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No nutrition plan available to add to calendar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final plan = _nutritionPlans.first;
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Adding to calendar...'),
            ],
          ),
        ),
      );

      // Export to calendar
      await NutritionCalendarBridge.exportDayToCalendar(
        date: DateTime.now(),
        meals: _convertPlanToMeals(plan),
        language: 'en',
        dayTitle: 'Nutrition Plan - ${plan.name}',
        includePrepReminders: false,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to calendar successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to calendar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add prep reminders
  Future<void> _addPrepReminders() async {
    if (_nutritionPlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No nutrition plan available for prep reminders'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final plan = _nutritionPlans.first;
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Setting up prep reminders...'),
            ],
          ),
        ),
      );

      // Export to calendar with prep reminders
      await NutritionCalendarBridge.exportDayToCalendar(
        date: DateTime.now(),
        meals: _convertPlanToMeals(plan),
        language: 'en',
        dayTitle: 'Prep Reminders - ${plan.name}',
        includePrepReminders: true,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prep reminders added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add prep reminders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to show week selection dialog
  Future<int?> _showWeekSelectionDialog() async {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Week'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) => ListTile(
            title: Text('Week ${index + 1}'),
            onTap: () => Navigator.of(context).pop(index),
          )),
        ),
      ),
    );
  }

  // Helper method to convert nutrition plan to meals format
  Map<String, List<Map<String, dynamic>>> _convertPlanToMeals(NutritionPlan plan) {
    final meals = <String, List<Map<String, dynamic>>>{};
    
    for (final meal in plan.meals) {
      final mealType = meal.label.toLowerCase();
      final mealItems = <Map<String, dynamic>>[];
      
      for (final item in meal.items) {
        mealItems.add({
          'name': item.name,
          'prep_minutes': 0, // Default prep time
        });
      }
      
      meals[mealType] = mealItems;
    }
    
    return meals;
  }
}
