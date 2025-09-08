import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../branding/vagus_logo.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../services/navigation/app_navigator.dart';
import '../../screens/nutrition/nutrition_plan_viewer.dart';
import '../../screens/learn/learn_client_screen.dart';
import '../../screens/learn/learn_coach_screen.dart';

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
  String _searchQuery = '';

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
      backgroundColor: AppTheme.primaryBlack,
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
                  onTap: () => Navigator.pop(context),
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
                  title: 'Edit Profile',
                  onTap: widget.onEditProfile ?? () => AppNavigator.editProfile(context),
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
    );
  }

  Widget _buildHeader(String subtitle) {
    return Container(
      width: double.infinity,
      color: AppTheme.primaryBlack,
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
                    color: Color(0xFFE0E0E0),
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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.7),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppTheme.mintAqua,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppTheme.cardBackground,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
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
            color: Colors.white.withOpacity(0.1),
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
            side: BorderSide(color: Colors.white.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
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
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      hoverColor: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
