import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../branding/vagus_logo.dart';
import '../../theme/app_theme.dart';
import '../../services/navigation/app_navigator.dart';
import '../../screens/nutrition/nutrition_plan_viewer.dart';
import '../../screens/learn/learn_client_screen.dart';
import '../../screens/learn/learn_coach_screen.dart';

class VagusSideMenu extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Try provided override, else auto-detect from role
    String resolvedSubtitle = portalSubtitle ?? 'Client Portal';
    try {
      // Get user role from Supabase profiles table
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Try to get role from current profile data if available
        // This will work if the parent screen has already loaded the profile
        // For now, we'll use the isClient parameter as a fallback
        if (!isClient) {
          resolvedSubtitle = 'Coach Portal';
        } else {
          resolvedSubtitle = 'Client Portal';
        }
      }
    } catch (_) {
      // Fallback to isClient parameter if role detection fails
      if (!isClient) {
        resolvedSubtitle = 'Coach Portal';
      } else {
        resolvedSubtitle = 'Client Portal';
      }
    }

    return Drawer(
      child: Column(
        children: [
          // Header (FULL-WIDTH BLACK)
          Container(
            width: double.infinity,
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
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
                        resolvedSubtitle, // Auto-detected or overridden
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12), // reduce gap so text and logo are near
                const VagusLogo(size: 36, white: true), // slightly bigger logo
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  icon: Icons.person,
                  title: 'Edit Profile',
                  onTap: onEditProfile ?? () => AppNavigator.editProfile(context),
                ),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: onSettings ?? () => AppNavigator.settings(context),
                ),
                _buildMenuItem(
                  icon: Icons.star,
                  title: 'Upgrade to Pro',
                  onTap: onBillingUpgrade ?? () => AppNavigator.billingUpgrade(context),
                ),
                _buildMenuItem(
                  icon: Icons.health_and_safety,
                  title: 'Health connections',
                  onTap: onManageDevices ?? () => AppNavigator.manageDevices(context),
                ),
                _buildMenuItem(
                  icon: Icons.psychology,
                  title: 'AI Usage',
                  onTap: onAIUsage ?? () => AppNavigator.aiUsage(context),
                ),
                _buildMenuItem(
                  icon: Icons.download,
                  title: 'Export Progress',
                  onTap: onExportProgress ?? () => AppNavigator.exportProgress(context),
                ),
                // Only show "Apply to become a coach" for clients
                if (isClient && onApplyCoach != null)
                  _buildMenuItem(
                    icon: Icons.school,
                    title: 'Apply to become a Coach',
                    onTap: onApplyCoach ?? () => AppNavigator.applyCoach(context),
                  ),
                // Nutrition Plans - only for clients
                if (isClient)
                  _buildMenuItem(
                    icon: Icons.restaurant_menu,
                    title: 'Nutrition Plans',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NutritionPlanViewer(),
                        ),
                      );
                    },
                  ),
                // Learn/Master VAGUS - role-specific
                _buildMenuItem(
                  icon: Icons.school,
                  title: isClient ? 'Master VAGUS (Client)' : 'Master VAGUS (Coach)',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => isClient 
                            ? const LearnClientScreen()
                            : const LearnCoachScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help,
                  title: 'Support',
                  onTap: onSupport ?? () => AppNavigator.support(context),
                ),
              ],
            ),
          ),

          // Footer with logout
          if (onLogout != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.lightGrey,
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlack,
                    side: const BorderSide(color: AppTheme.primaryBlack),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
        ],
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
        color: AppTheme.primaryBlack,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryBlack,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
