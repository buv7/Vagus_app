import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/modern_client_dashboard.dart';
import '../dashboard/modern_coach_dashboard.dart';
import '../workouts/modern_workout_plan_viewer.dart';
import '../plans/plans_dashboard_screen.dart';
import '../calendar/modern_calendar_viewer.dart';
import '../nutrition/nutrition_hub_screen.dart';
import '../messaging/modern_client_messages_screen.dart';
import '../messaging/client_chat_list_screen.dart';
import '../coach/modern_client_management_screen.dart';
import '../admin/admin_hub_screen.dart';
import '../../widgets/fab/simple_glassmorphism_fab.dart';
import '../../widgets/fab/camera_glassmorphism_fab.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_colors.dart';
import '../../widgets/navigation/vagus_side_menu.dart';

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
    _tabController = TabController(length: 5, vsync: this); // Will be updated after role is loaded
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
          // Update tab controller length based on role
          final tabs = _buildTabs();
          _tabController.dispose();
          _tabController = TabController(length: tabs.length, vsync: this);
          _tabController.addListener(_handleTabChange);
        });
      }
    } catch (e) {
      debugPrint('❌ MainNav: Role detection failed: $e');
      // Default to client if role detection fails
      setState(() {
        _userRole = 'client';
        // Update tab controller for client
        final tabs = _buildTabs();
        _tabController.dispose();
        _tabController = TabController(length: tabs.length, vsync: this);
        _tabController.addListener(_handleTabChange);
      });
    }
  }

  void _openCameraFAB() {
    _cameraFABKey.currentState?.openCameraFAB();
  }

  // Build tabs based on user role
  List<NavTab> _buildTabs() {
    final isCoach = _userRole == 'coach';
    final isAdmin = _userRole == 'admin';
    debugPrint('🔧 MainNav: Building tabs for role: $_userRole, isCoach: $isCoach, isAdmin: $isAdmin');
    
    if (isAdmin) {
      // Admin navigation - single tab to admin hub
      return [
        const NavTab(
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings_rounded,
          label: 'Admin Hub',
          screen: AdminHubScreen(),
        ),
      ];
    } else if (isCoach) {
      // Coach navigation
      return [
        const NavTab(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: 'Dashboard',
          screen: ModernCoachDashboard(),
        ),
        const NavTab(
          icon: Icons.people_outline,
          activeIcon: Icons.people_rounded,
          label: 'Clients',
          screen: ModernClientManagementScreen(),
        ),
        const NavTab(
          icon: Icons.fitness_center_outlined,
          activeIcon: Icons.fitness_center_rounded,
          label: 'Plans',
          screen: PlansDashboardScreen(),
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
        const NavTab(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Home',
          screen: ModernClientDashboard(),
        ),
        const NavTab(
          icon: Icons.fitness_center_outlined,
          activeIcon: Icons.fitness_center_rounded,
          label: 'Workouts',
          screen: ModernWorkoutPlanViewer(),
        ),
        const NavTab(
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month_rounded,
          label: 'Calendar',
          screen: ModernCalendarViewer(),
        ),
        const NavTab(
          icon: Icons.restaurant_outlined,
          activeIcon: Icons.restaurant_rounded,
          label: 'Nutrition',
          screen: NutritionHubScreen(mode: NutritionHubMode.auto),
        ),
        NavTab(
          icon: Icons.chat_outlined,
          activeIcon: Icons.chat_rounded,
          label: 'Messages',
          screen: ClientChatListScreen(
            onShowBottomNav: showBottomNavigation,
            onHideBottomNav: hideBottomNavigation,
          ),
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
      
      // Find the messages tab index dynamically
      int? messagesTabIndex;
      for (int i = 0; i < tabs.length; i++) {
        if (tabs[i].label == 'Messages') {
          messagesTabIndex = i;
          break;
        }
      }
      
      // If leaving messages tab, show navigation bar
      if (messagesTabIndex != null && previousIndex == messagesTabIndex && _currentIndex != messagesTabIndex) {
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
    
    final tabs = _buildTabs();
    
    // Find the messages tab index dynamically
    int? messagesTabIndex;
    for (int i = 0; i < tabs.length; i++) {
      if (tabs[i].label == 'Messages') {
        messagesTabIndex = i;
        break;
      }
    }
    
    // Show navigation bar when tapping any tab except messages
    if (messagesTabIndex != null && index != messagesTabIndex) {
      showBottomNavigation();
    }
    
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
    final isAdmin = _userRole == 'admin';

    return Scaffold(
      drawer: Builder(
        builder: (drawerContext) => VagusSideMenu(
          isClient: _userRole != 'coach',
          onLogout: () async {
            try {
              await Supabase.instance.client.auth.signOut();
              if (!drawerContext.mounted) return;
              unawaited(Navigator.of(drawerContext).pushNamedAndRemoveUntil('/', (route) => false));
            } catch (e) {
              debugPrint('Logout error: $e');
            }
          },
        ),
      ),
      appBar: isAdmin ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return IconButton(
              icon: Icon(
                Icons.menu,
                color: isDark ? Colors.white : const Color(0xFF0B1220),
                size: 24,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
      extendBodyBehindAppBar: !isAdmin,
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: tabs.map((tab) => tab.screen).toList(),
          ),
          // Camera FAB - positioned in upper half (hidden icon but functional) - not for admin
          if (_currentIndex == 0 && !isAdmin) 
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
      floatingActionButton: (_currentIndex == 0 && !isAdmin) ? SimpleGlassmorphismFAB(
        isCoach: _userRole == 'coach',
        onOpenCameraFAB: _openCameraFAB,
      ) : null,
      bottomNavigationBar: (_showBottomNav && !isAdmin) ? AnimatedBuilder(
        animation: _bottomNavSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _bottomNavSlideAnimation.value) * 100),
            child: SafeArea(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      // Glassmorphism style matching FAB
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 2.0,
                        colors: [
                          DesignTokens.accentBlue.withValues(alpha: 0.25),
                          DesignTokens.accentBlue.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, -8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, -4),
                        ),
                      ],
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
                  // Icon with active state - white like FAB
                  Icon(
                    isActive ? tab.activeIcon : tab.icon,
                    color: isActive 
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  
                  const SizedBox(height: DesignTokens.space2),
                  
                  // Label with active state - white like FAB
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: isActive 
                          ? Colors.white 
                          : Colors.white.withValues(alpha: 0.6),
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
