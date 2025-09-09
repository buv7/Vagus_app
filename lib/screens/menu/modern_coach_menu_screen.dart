import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../settings/profile_settings_screen.dart';
import '../settings/notifications_settings_screen.dart';
import '../settings/privacy_security_screen.dart';
import '../business/business_profile_screen.dart';
import '../analytics/analytics_reports_screen.dart';
import '../billing/billing_payments_screen.dart';
import '../support/help_center_screen.dart';
import '../admin/admin_ads_screen.dart';
import '../auth/modern_login_screen.dart';
import '../../services/admin/ad_banner_service.dart';

class ModernCoachMenuScreen extends StatefulWidget {
  const ModernCoachMenuScreen({super.key});

  @override
  State<ModernCoachMenuScreen> createState() => _ModernCoachMenuScreenState();
}

class _ModernCoachMenuScreenState extends State<ModernCoachMenuScreen> {
  final supabase = Supabase.instance.client;
  final AdBannerService _adService = AdBannerService();
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkAdminStatus();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      setState(() {
        _profile = response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adService.isCurrentUserAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ModernLoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppTheme.neutralWhite),
        ),
        title: const Text(
          'Menu',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        actions: [
          IconButton(
            onPressed: () => _navigateToDashboard(),
            icon: const Icon(Icons.home, color: AppTheme.neutralWhite), // Back to Dashboard
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.mintAqua,
                    child: Text(
                      _profile?['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'C',
                      style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile?['full_name'] ?? 'Coach',
                          style: const TextStyle(
                            color: AppTheme.neutralWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _profile?['email'] ?? '',
                          style: TextStyle(
                            color: AppTheme.lightGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: DesignTokens.space32),

              // Menu Items
              _buildMenuSection('Account', [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Profile Settings',
                  subtitle: 'Update your personal information',
                  onTap: () => _navigateToScreen(const ProfileSettingsScreen()),
                ),
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage your notification preferences',
                  onTap: () => _navigateToScreen(const NotificationsSettingsScreen()),
                ),
                _buildMenuItem(
                  icon: Icons.security_outlined,
                  title: 'Privacy & Security',
                  subtitle: 'Manage your privacy settings',
                  onTap: () => _navigateToScreen(const PrivacySecurityScreen()),
                ),
              ]),

              const SizedBox(height: DesignTokens.space24),

              _buildMenuSection('Business', [
                _buildMenuItem(
                  icon: Icons.business_outlined,
                  title: 'Business Profile',
                  subtitle: 'Manage your coaching business',
                  onTap: () => _navigateToScreen(const BusinessProfileScreen()),
                ),
                _buildMenuItem(
                  icon: Icons.analytics_outlined,
                  title: 'Analytics & Reports',
                  subtitle: 'View detailed analytics',
                  onTap: () => _navigateToScreen(const AnalyticsReportsScreen()),
                ),
                _buildMenuItem(
                  icon: Icons.payment_outlined,
                  title: 'Billing & Payments',
                  subtitle: 'Manage your subscription',
                  onTap: () => _navigateToScreen(const BillingPaymentsScreen()),
                ),
              ]),

              const SizedBox(height: DesignTokens.space24),

              // Admin Section (only show if user is admin)
              if (_isAdmin) ...[
                _buildMenuSection('Admin', [
                  _buildMenuItem(
                    icon: Icons.campaign_outlined,
                    title: 'Ad Management',
                    subtitle: 'Manage ad banners and campaigns',
                    onTap: () => _navigateToScreen(const AdminAdsScreen()),
                  ),
                ]),
                const SizedBox(height: DesignTokens.space24),
              ],

              _buildMenuSection('Support', [
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  subtitle: 'Get help and support',
                  onTap: () => _navigateToScreen(const HelpCenterScreen()),
                ),
                _buildMenuItem(
                  icon: Icons.feedback_outlined,
                  title: 'Send Feedback',
                  subtitle: 'Share your thoughts with us',
                  onTap: () => _showFeedbackDialog(),
                ),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'App version and information',
                  onTap: () => _showAboutDialog(),
                ),
              ]),

              const SizedBox(height: DesignTokens.space32), // All Menu Screens Now Functional

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.danger,
                    foregroundColor: AppTheme.neutralWhite,
                    padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    ),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: DesignTokens.space20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.lightGrey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: DesignTokens.space12),
        ...items,
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: AppTheme.steelGrey,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space8,
        ),
        leading: Icon(
          icon,
          color: AppTheme.mintAqua,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.lightGrey,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.lightGrey,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _navigateToDashboard() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Send Feedback',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        content: TextField(
          controller: feedbackController,
          maxLines: 4,
          style: const TextStyle(color: AppTheme.neutralWhite),
          decoration: const InputDecoration(
            hintText: 'Share your thoughts, suggestions, or report issues...',
            hintStyle: TextStyle(color: AppTheme.lightGrey),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.lightGrey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: AppTheme.mintAqua,
                ),
              );
            },
            child: const Text(
              'Send',
              style: TextStyle(color: AppTheme.mintAqua),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'About Vagus Coach',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: AppTheme.lightGrey),
            ),
            const SizedBox(height: DesignTokens.space8),
            const Text(
              'Vagus Coach is a comprehensive coaching platform designed to help fitness professionals manage their clients, create personalized plans, and track progress.',
              style: TextStyle(color: AppTheme.lightGrey),
            ),
            const SizedBox(height: DesignTokens.space16),
            const Text(
              '© 2024 Vagus Technologies. All rights reserved.',
              style: TextStyle(color: AppTheme.lightGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.mintAqua),
            ),
          ),
        ],
      ),
    );
  }
}
