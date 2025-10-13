import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../branding/vagus_logo.dart';
import '../../theme/design_tokens.dart';
import '../../services/navigation/app_navigator.dart';
import '../../screens/learn/learn_client_screen.dart';
import '../../screens/learn/learn_coach_screen.dart';
import '../../screens/nutrition/coach_nutrition_dashboard.dart';

class VagusSideMenu extends StatefulWidget {
  final bool isClient;
  final String? portalSubtitle;
  final VoidCallback? onEditProfile;
  final VoidCallback? onSettings;
  final VoidCallback? onBillingUpgrade;
  final VoidCallback? onManageDevices;
  final VoidCallback? onAIUsage;
  final VoidCallback? onExportProgress;
  final VoidCallback? onApplyCoach; // only visible if isClient == true
  final VoidCallback? onSupport;
  final VoidCallback? onLogout;

  const VagusSideMenu({
    super.key,
    required this.isClient,
    this.portalSubtitle,
    this.onEditProfile,
    this.onSettings,
    this.onBillingUpgrade,
    this.onManageDevices,
    this.onAIUsage,
    this.onExportProgress,
    this.onApplyCoach,
    this.onSupport,
    this.onLogout,
  });

  @override
  State<VagusSideMenu> createState() => _VagusSideMenuState();
}

class _VagusSideMenuState extends State<VagusSideMenu> {
  final TextEditingController _searchController = TextEditingController();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
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
        if (mounted) {
          setState(() {
            _userRole = profile['role'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Try provided override, else auto-detect from role
    String resolvedSubtitle = widget.portalSubtitle ?? 'Client Portal';
    try {
      // Get user role from Supabase profiles table
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Try to get role from current profile data if available
        // This will work if the parent screen has already loaded the profile
        // For now, we'll use the isClient parameter as a fallback
        if (!widget.isClient) {
          resolvedSubtitle = 'Coach Portal';
        } else {
          resolvedSubtitle = 'Client Portal';
        }
      }
    } catch (_) {
      // Fallback to isClient parameter if role detection fails
      if (!widget.isClient) {
        resolvedSubtitle = 'Coach Portal';
      } else {
        resolvedSubtitle = 'Client Portal';
      }
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: DesignTokens.darkGradient,
        ),
        child: Column(
          children: [
            // Header with VAGUS branding
            _buildHeader(resolvedSubtitle),

            // Search Bar
            _buildSearchBar(),

            // Menu items
            Expanded(
              child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Navigation Section
                _buildSectionHeader('Navigation'),
                _buildMenuItem(
                  icon: Icons.home,
                  title: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  icon: Icons.fitness_center,
                  title: 'Workouts',
                  onTap: () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  icon: Icons.calendar_month,
                  title: 'Calendar',
                  onTap: () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  icon: Icons.restaurant,
                  title: 'Nutrition',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to coach nutrition dashboard for coaches
                    if (!widget.isClient) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CoachNutritionDashboard(),
                        ),
                      );
                    }
                  },
                ),
                _buildMenuItem(
                  icon: Icons.chat,
                  title: 'Messages',
                  onTap: () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  icon: Icons.videocam,
                  title: 'Calls',
                  onTap: () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  icon: Icons.trending_up,
                  title: 'Progress',
                  onTap: () => Navigator.pop(context),
                ),

                const SizedBox(height: DesignTokens.space16),

                // Quick Access Section
                _buildSectionHeader('Quick Access'),
                _buildMenuItem(
                  icon: Icons.person,
                  title: widget.isClient ? 'Edit Profile' : 'My Profile',
                  subtitle: !widget.isClient ? 'Manage profile, media & marketplace' : null,
                  onTap: !widget.isClient
                      ? () => AppNavigator.myCoachProfile(context)
                      : (widget.onEditProfile ?? () => AppNavigator.editProfile(context)),
                ),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: widget.onSettings ?? () => AppNavigator.settings(context),
                ),
                _buildMenuItem(
                  icon: Icons.download,
                  title: 'Export Progress',
                  onTap: widget.onExportProgress ?? () => AppNavigator.exportProgress(context),
                ),

                const SizedBox(height: DesignTokens.space16),

                // Account Management Section
                _buildSectionHeader('Account'),
                // Account Switcher (available for all users)
                _buildMenuItem(
                  icon: Icons.swap_horiz,
                  title: 'Switch Account',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.pushNamed(context, '/account-switch');
                  },
                ),
                // Admin Panel (only for admin role)
                if (_userRole == 'admin')
                  _buildMenuItem(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Panel',
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.pushNamed(context, '/admin');
                    },
                  ),
                _buildMenuItem(
                  icon: Icons.star,
                  title: 'Upgrade to Pro',
                  onTap: widget.onBillingUpgrade ?? () => AppNavigator.billingUpgrade(context),
                ),
                _buildMenuItem(
                  icon: Icons.health_and_safety,
                  title: 'Health Connections',
                  onTap: widget.onManageDevices ?? () => AppNavigator.manageDevices(context),
                ),
                _buildMenuItem(
                  icon: Icons.psychology,
                  title: 'AI Usage',
                  onTap: widget.onAIUsage ?? () => AppNavigator.aiUsage(context),
                ),
                // Only show "Apply to become a coach" for clients
                if (widget.isClient && widget.onApplyCoach != null)
                  _buildMenuItem(
                    icon: Icons.school,
                    title: 'Apply to become a Coach',
                    onTap: widget.onApplyCoach ?? () => AppNavigator.applyCoach(context),
                  ),

                const SizedBox(height: DesignTokens.space16),

                // Learn Section
                _buildSectionHeader('Learn'),
                _buildMenuItem(
                  icon: Icons.school,
                  title: widget.isClient ? 'Master VAGUS (Client)' : 'Master VAGUS (Coach)',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => widget.isClient 
                            ? const LearnClientScreen()
                            : const LearnCoachScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help,
                  title: 'Support',
                  onTap: widget.onSupport ?? () => AppNavigator.support(context),
                ),
              ],
            ),
          ),

          // Footer with logout
          if (widget.onLogout != null)
            _buildFooter(),
        ],
        ),
      ),
    );
  }

  Widget _buildHeader(String subtitle) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DesignTokens.blurSm, sigmaY: DesignTokens.blurSm),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: DesignTokens.cardBackground,
            border: const Border(
              bottom: BorderSide(color: DesignTokens.glassBorder, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentGreen.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(DesignTokens.space16, 28, DesignTokens.space16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VAGUS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const VagusLogo(size: 36, white: true),
        ],
        ),
      ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: DesignTokens.blurSm, sigmaY: DesignTokens.blurSm),
          child: Container(
            decoration: BoxDecoration(
              color: DesignTokens.cardBackground,
              borderRadius: BorderRadius.circular(DesignTokens.radius16),
              border: Border.all(color: DesignTokens.glassBorder),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: DesignTokens.neutralWhite),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: const TextStyle(color: DesignTokens.textSecondary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: DesignTokens.accentGreen,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius16),
                  borderSide: const BorderSide(
                    color: DesignTokens.accentGreen,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space16,
                  vertical: DesignTokens.space12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignTokens.space16, DesignTokens.space16, DesignTokens.space16, DesignTokens.space8),
      child: Text(
        title,
        style: DesignTokens.bodySmall.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout, color: Colors.white70),
          label: const Text('Logout', style: TextStyle(color: Colors.white70)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white70,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: DesignTokens.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      hoverColor: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
