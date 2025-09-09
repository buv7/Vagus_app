import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/modern_client_dashboard.dart';
import '../dashboard/coach_home_screen.dart';
import '../dashboard/modern_coach_dashboard.dart';
import '../workouts/modern_workout_plan_viewer.dart';
import '../workout/coach_plan_builder_screen.dart';
import '../workout/modern_plan_builder_screen.dart';
import '../calendar/modern_calendar_viewer.dart';
import '../nutrition/modern_nutrition_plan_viewer.dart';
import '../nutrition/modern_nutrition_plan_builder.dart';
import '../messaging/modern_messenger_screen.dart';
import '../messaging/coach_threads_screen.dart';
import '../messaging/modern_coach_messenger_screen.dart';
import '../messaging/modern_client_messages_screen.dart';
import '../coach/modern_client_management_screen.dart';
import '../coach/my_coach_screen.dart';
import '../calling/modern_live_calls_screen.dart';
import '../progress/modern_progress_tracker.dart';
import '../menu/modern_coach_menu_screen.dart';
import '../../components/common/quick_add_sheet.dart';
import '../../widgets/fab/simple_glassmorphism_fab.dart';
import '../../widgets/fab/camera_glassmorphism_fab.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/messaging/messaging_wrapper.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  String? _userRole;
  late AnimationController _tabAnimationController;
  late Animation<double> _tabScaleAnimation;
  
  // Bottom navigation visibility control
  bool _showBottomNav = true;
  late AnimationController _bottomNavAnimationController;
  late Animation<double> _bottomNavSlideAnimation;
  
  // Camera FAB key for coordination
  final GlobalKey<CameraGlassmorphismFABState> _cameraFABKey = GlobalKey<CameraGlassmorphismFABState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadUserRole();
    
    // Initialize tab animation controller
    _tabAnimationController = AnimationController(
      duration: DesignTokens.durationFast,
      vsync: this,
    );
    _tabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _tabAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize bottom navigation animation controller
    _bottomNavAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bottomNavSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bottomNavAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Start with bottom nav visible
    _bottomNavAnimationController.value = 1.0;
  }

  Future<void> _loadUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();
        final role = profile['role'] as String?;
        debugPrint('🔧 MainNav: User role detected: $role');
        setState(() {
          _userRole = role;
        });
      }
    } catch (e) {
      debugPrint('❌ MainNav: Role detection failed: $e');
      // Default to client if role detection fails
      setState(() {
        _userRole = 'client';
      });
    }
  }

  void _openCameraFAB() {
    _cameraFABKey.currentState?.openCameraFAB();
  }

  // Build tabs based on user role
  List<NavTab> _buildTabs() {
    final isCoach = _userRole == 'coach';
    debugPrint('🔧 MainNav: Building tabs for role: $_userRole, isCoach: $isCoach');
    
    if (isCoach) {
      // Coach navigation
      return [
        NavTab(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: 'Dashboard',
          screen: const ModernCoachDashboard(),
        ),
        NavTab(
          icon: Icons.people_outline,
          activeIcon: Icons.people_rounded,
          label: 'Clients',
          screen: const ModernClientManagementScreen(),
        ),
        NavTab(
          icon: Icons.fitness_center_outlined,
          activeIcon: Icons.fitness_center_rounded,
          label: 'Plans',
          screen: const ModernPlanBuilderScreen(),
        ),
        const NavTab(
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month_rounded,
          label: 'Calendar',
          screen: ModernCalendarViewer(),
        ),
        NavTab(
          icon: Icons.chat_outlined,
          activeIcon: Icons.chat_rounded,
          label: 'Messages',
          screen: const ModernClientMessagesScreen(),
          onEnter: () {
            hideBottomNavigation();
          },
        ),
      ];
    } else {
      // Client navigation - matching the design
      return [
        NavTab(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Home',
          screen: const ModernClientDashboard(),
        ),
        NavTab(
          icon: Icons.fitness_center_outlined,
          activeIcon: Icons.fitness_center_rounded,
          label: 'Workouts',
          screen: const ModernWorkoutPlanViewer(),
        ),
        const NavTab(
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month_rounded,
          label: 'Calendar',
          screen: ModernCalendarViewer(),
        ),
        NavTab(
          icon: Icons.restaurant_outlined,
          activeIcon: Icons.restaurant_rounded,
          label: 'Nutrition',
          screen: const ModernNutritionPlanViewer(),
        ),
        NavTab(
          icon: Icons.chat_outlined,
          activeIcon: Icons.chat_rounded,
          label: 'Messages',
          screen: MessagingWrapper(
            onShowBottomNav: showBottomNavigation,
            onHideBottomNav: hideBottomNavigation,
            child: const ModernMessengerScreen(),
          ),
          onEnter: () {
            hideBottomNavigation();
          },
        ),
      ];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabAnimationController.dispose();
    _bottomNavAnimationController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      final previousIndex = _currentIndex;
      setState(() {
        _currentIndex = _tabController.index;
      });
      
      // Handle navigation bar visibility based on tab changes
      final tabs = _buildTabs();
      
      // If leaving messages tab, show navigation bar
      if (previousIndex == 4 && _currentIndex != 4) { // Messages tab is index 4
        showBottomNavigation();
      }
      
      // Call onEnter callback if it exists
      if (_currentIndex < tabs.length && tabs[_currentIndex].onEnter != null) {
        tabs[_currentIndex].onEnter!();
      }
      
      // Light haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _onTabTapped(int index) async {
    // Animate tab press
    unawaited(_tabAnimationController.forward().then((_) {
      _tabAnimationController.reverse();
    }));
    
    setState(() {
      _currentIndex = index;
    });
    _tabController.animateTo(index);
    
    // Light haptic feedback
    await HapticFeedback.lightImpact();
  }

  /// Hide the bottom navigation bar with animation
  void hideBottomNavigation() {
    if (_showBottomNav) {
      setState(() {
        _showBottomNav = false;
      });
      _bottomNavAnimationController.reverse();
    }
  }

  /// Show the bottom navigation bar with animation
  void showBottomNavigation() {
    if (!_showBottomNav) {
      setState(() {
        _showBottomNav = true;
      });
      _bottomNavAnimationController.forward();
    }
  }

  /// Toggle bottom navigation visibility
  void toggleBottomNavigation() {
    if (_showBottomNav) {
      hideBottomNavigation();
    } else {
      showBottomNavigation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final tabs = _buildTabs();

    return Scaffold(
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: tabs.map((tab) => tab.screen).toList(),
          ),
          // Camera FAB - positioned in upper half (hidden icon but functional)
          if (_currentIndex == 0) 
            Positioned(
              right: 0,
              top: 100,
              child: CameraGlassmorphismFAB(
                key: _cameraFABKey,
                isCoach: _userRole == 'coach',
              ),
            ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? SimpleGlassmorphismFAB(
        isCoach: _userRole == 'coach',
        onOpenCameraFAB: _openCameraFAB,
      ) : null,
      bottomNavigationBar: _showBottomNav ? AnimatedBuilder(
        animation: _bottomNavSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _bottomNavSlideAnimation.value) * 100),
            child: SafeArea(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack,
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.steelGrey,
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                    top: DesignTokens.space8,
                  ),
                  child: Row(
                    children: tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      final isActive = index == _currentIndex;
                      
                      return Expanded(
                        child: _buildTabItem(
                          tab: tab,
                          index: index,
                          isActive: isActive,
                          isRTL: isRTL,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ) : null,
    );
  }

  Widget _buildTabItem({
    required NavTab tab,
    required int index,
    required bool isActive,
    required bool isRTL,
  }) {
    final tabs = _buildTabs();
    final actualIndex = isRTL ? (tabs.length - 1 - index) : index;
    
    return GestureDetector(
      onTapDown: (_) => _tabAnimationController.forward(),
      onTapUp: (_) => _tabAnimationController.reverse(),
      onTapCancel: () => _tabAnimationController.reverse(),
      onTap: () => _onTabTapped(actualIndex),
      child: AnimatedBuilder(
        animation: _tabScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: index == _currentIndex ? _tabScaleAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.space4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with active state
                  Icon(
                    isActive ? tab.activeIcon : tab.icon,
                    color: isActive 
                        ? AppTheme.mintAqua
                        : AppTheme.lightGrey,
                    size: 20,
                  ),
                  
                  const SizedBox(height: DesignTokens.space2),
                  
                  // Label with active state
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: isActive ? AppTheme.neutralWhite : AppTheme.lightGrey,
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;
  final VoidCallback? onEnter;

  const NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
    this.onEnter,
  });
}
