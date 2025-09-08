import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/modern_client_dashboard.dart';
import '../dashboard/coach_home_screen.dart';
import '../workouts/modern_workout_plan_viewer.dart';
import '../workout/coach_plan_builder_screen.dart';
import '../calendar/modern_calendar_viewer.dart';
import '../nutrition/modern_nutrition_plan_viewer.dart';
import '../nutrition/nutrition_plan_builder.dart';
import '../messaging/modern_messenger_screen.dart';
import '../messaging/coach_threads_screen.dart';
import '../calling/modern_live_calls_screen.dart';
import '../progress/modern_progress_tracker.dart';
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
        setState(() {
          _userRole = profile['role'] as String?;
        });
      }
    } catch (e) {
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
    
    return [
      NavTab(
        icon: Icons.home_rounded,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        screen: isCoach ? const CoachHomeScreen() : const ModernClientDashboard(),
      ),
      NavTab(
        icon: Icons.fitness_center_outlined,
        activeIcon: Icons.fitness_center_rounded,
        label: 'Workouts',
        screen: isCoach ? const CoachPlanBuilderScreen() : const ModernWorkoutPlanViewer(),
      ),
      const NavTab(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: 'Calendar',
        screen: ModernCalendarViewer(), // Shared for both roles
      ),
      NavTab(
        icon: Icons.restaurant_outlined,
        activeIcon: Icons.restaurant_rounded,
        label: 'Nutrition',
        screen: isCoach ? const NutritionPlanBuilder() : const ModernNutritionPlanViewer(),
      ),
      NavTab(
        icon: Icons.chat_outlined,
        activeIcon: Icons.chat_rounded,
        label: 'Messages',
        screen: isCoach 
          ? MessagingWrapper(
              onShowBottomNav: showBottomNavigation,
              onHideBottomNav: hideBottomNavigation,
              child: const CoachThreadsScreen(),
            )
          : MessagingWrapper(
              onShowBottomNav: showBottomNavigation,
              onHideBottomNav: hideBottomNavigation,
              child: const ModernMessengerScreen(),
            ),
        onEnter: () {
          // Hide bottom navigation when entering messages
          hideBottomNavigation();
        },
      ),
    ];
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
      setState(() {
        _currentIndex = _tabController.index;
      });
      
      // Call onEnter callback if it exists
      final tabs = _buildTabs();
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
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack,
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
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
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.space8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with active state
                  AnimatedContainer(
                    duration: DesignTokens.durationFast,
                    padding: const EdgeInsets.all(DesignTokens.space8),
                    decoration: BoxDecoration(
                      color: isActive 
                          ? AppTheme.mintAqua.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    ),
                    child: Icon(
                      isActive ? tab.activeIcon : tab.icon,
                      color: isActive 
                          ? AppTheme.mintAqua
                          : Colors.white.withValues(alpha: 0.6),
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(height: DesignTokens.space4),
                  
                  // Label with active state
                  AnimatedDefaultTextStyle(
                    duration: DesignTokens.durationFast,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    child: Text(tab.label),
                  ),
                  
                  // Active indicator line
                  AnimatedContainer(
                    duration: DesignTokens.durationFast,
                    margin: const EdgeInsets.only(top: DesignTokens.space4),
                    height: 2,
                    width: isActive ? 20 : 0,
                    decoration: BoxDecoration(
                      color: isActive 
                          ? AppTheme.mintAqua
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
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
