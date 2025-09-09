import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final supabase = Supabase.instance.client;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _loading = true;
  bool _changingPassword = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // Privacy settings
  bool _profileVisibility = true;
  bool _showOnlineStatus = true;
  bool _allowDirectMessages = true;
  bool _dataSharing = false;
  bool _analyticsTracking = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadPrivacySettings() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      // Load privacy settings from profiles table
      final response = await supabase
          .from('profiles')
          .select('profile_visibility, show_online_status, allow_direct_messages, data_sharing, analytics_tracking')
          .eq('id', user.id)
          .single();

      setState(() {
        _profileVisibility = response['profile_visibility'] ?? true;
        _showOnlineStatus = response['show_online_status'] ?? true;
        _allowDirectMessages = response['allow_direct_messages'] ?? true;
        _dataSharing = response['data_sharing'] ?? false;
        _analyticsTracking = response['analytics_tracking'] ?? true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match'),
          backgroundColor: DesignTokens.danger,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: DesignTokens.danger,
        ),
      );
      return;
    }

    setState(() {
      _changingPassword = true;
    });

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: DesignTokens.success,
          ),
        );
        
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _changingPassword = false;
        });
      }
    }
  }

  Future<void> _savePrivacySettings() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('profiles').update({
        'profile_visibility': _profileVisibility,
        'show_online_status': _showOnlineStatus,
        'allow_direct_messages': _allowDirectMessages,
        'data_sharing': _dataSharing,
        'analytics_tracking': _analyticsTracking,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy settings saved successfully'),
            backgroundColor: DesignTokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(color: AppTheme.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.lightGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: DesignTokens.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete user account
        await supabase.auth.admin.deleteUser(supabase.auth.currentUser!.id);
        
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: DesignTokens.danger,
            ),
          );
        }
      }
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
          'Privacy & Security',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.mintAqua),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Change Password Section
                  _buildSectionTitle('Change Password'),
                  const SizedBox(height: DesignTokens.space16),

                  _buildPasswordField(
                    controller: _currentPasswordController,
                    label: 'Current Password',
                    hint: 'Enter your current password',
                    showPassword: _showCurrentPassword,
                    onToggleVisibility: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                  ),

                  const SizedBox(height: DesignTokens.space16),

                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: 'New Password',
                    hint: 'Enter your new password',
                    showPassword: _showNewPassword,
                    onToggleVisibility: () => setState(() => _showNewPassword = !_showNewPassword),
                  ),

                  const SizedBox(height: DesignTokens.space16),

                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm New Password',
                    hint: 'Confirm your new password',
                    showPassword: _showConfirmPassword,
                    onToggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  ),

                  const SizedBox(height: DesignTokens.space16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _changingPassword ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mintAqua,
                        foregroundColor: AppTheme.primaryBlack,
                        padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radius12),
                        ),
                      ),
                      child: _changingPassword
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlack),
                              ),
                            )
                          : const Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: DesignTokens.space32),

                  // Privacy Settings
                  _buildSectionTitle('Privacy Settings'),
                  const SizedBox(height: DesignTokens.space16),

                  _buildPrivacyTile(
                    title: 'Profile Visibility',
                    subtitle: 'Make your profile visible to other users',
                    icon: Icons.visibility,
                    value: _profileVisibility,
                    onChanged: (value) => setState(() => _profileVisibility = value),
                  ),

                  _buildPrivacyTile(
                    title: 'Show Online Status',
                    subtitle: 'Show when you are online',
                    icon: Icons.circle,
                    value: _showOnlineStatus,
                    onChanged: (value) => setState(() => _showOnlineStatus = value),
                  ),

                  _buildPrivacyTile(
                    title: 'Allow Direct Messages',
                    subtitle: 'Allow other users to send you direct messages',
                    icon: Icons.message,
                    value: _allowDirectMessages,
                    onChanged: (value) => setState(() => _allowDirectMessages = value),
                  ),

                  _buildPrivacyTile(
                    title: 'Data Sharing',
                    subtitle: 'Allow sharing of anonymized data for research',
                    icon: Icons.share,
                    value: _dataSharing,
                    onChanged: (value) => setState(() => _dataSharing = value),
                  ),

                  _buildPrivacyTile(
                    title: 'Analytics Tracking',
                    subtitle: 'Allow tracking for app improvement',
                    icon: Icons.analytics,
                    value: _analyticsTracking,
                    onChanged: (value) => setState(() => _analyticsTracking = value),
                  ),

                  const SizedBox(height: DesignTokens.space16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePrivacySettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mintAqua,
                        foregroundColor: AppTheme.primaryBlack,
                        padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radius12),
                        ),
                      ),
                      child: const Text(
                        'Save Privacy Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: DesignTokens.space32),

                  // Account Actions
                  _buildSectionTitle('Account Actions'),
                  const SizedBox(height: DesignTokens.space16),

                  _buildActionTile(
                    title: 'Download My Data',
                    subtitle: 'Download a copy of your data',
                    icon: Icons.download,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data download initiated'),
                          backgroundColor: AppTheme.mintAqua,
                        ),
                      );
                    },
                  ),

                  _buildActionTile(
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    icon: Icons.delete_forever,
                    isDestructive: true,
                    onTap: _deleteAccount,
                  ),

                  const SizedBox(height: DesignTokens.space20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.lightGrey,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: DesignTokens.space8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: Border.all(
              color: AppTheme.steelGrey,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: !showPassword,
            style: const TextStyle(color: AppTheme.neutralWhite),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.lightGrey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(DesignTokens.space16),
              prefixIcon: const Icon(
                Icons.lock,
                color: AppTheme.mintAqua,
                size: 20,
              ),
              suffixIcon: IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.lightGrey,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
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
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.mintAqua,
          activeTrackColor: AppTheme.mintAqua.withOpacity(0.3),
          inactiveThumbColor: AppTheme.lightGrey,
          inactiveTrackColor: AppTheme.steelGrey,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
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
          color: isDestructive ? DesignTokens.danger : AppTheme.mintAqua,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? DesignTokens.danger : AppTheme.neutralWhite,
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
}
