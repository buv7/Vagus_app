import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../auth/device_list_screen.dart';
import '../auth/become_coach_screen.dart';
import '../billing/billing_settings.dart';
import '../settings/user_settings_screen.dart';
import '../../theme/design_tokens.dart';
import '../../theme/theme_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final supabase = Supabase.instance.client;
  final picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _avatarUrl = '';
  String _role = 'client';
  bool _isAdmin = false;
  bool _loading = true;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    _nameController.text = response['name'] ?? '';
    _avatarUrl = response['avatar_url'] ?? '';
    _bioController.text = response['bio'] ?? '';
    _locationController.text = response['location'] ?? '';
    _role = response['role'] ?? 'client';
    _isAdmin = _role == 'admin';
  
    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<String?> _uploadAvatar(File file) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final filename = '${userId}_${const Uuid().v4()}.jpg';
    final bytes = await file.readAsBytes();

    // 🗑 Step 1: delete old file if exists
    if (_avatarUrl.isNotEmpty) {
      final uri = Uri.parse(_avatarUrl);
      final segments = uri.pathSegments;
      final index = segments.indexOf('avatars');
      if (index != -1 && index + 1 < segments.length) {
        final path = segments.sublist(index + 1).join('/');
        await supabase.storage.from('avatars').remove([path]);
      }
    }

    // 💾 Step 2: upload new avatar
    await supabase.storage
        .from('avatars')
        .uploadBinary(
      filename,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        metadata: {'owner': userId},
      ),
    );

    final publicUrl =
    supabase.storage.from('avatars').getPublicUrl(filename);
    return publicUrl;
  }


  Future<void> _saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    String finalAvatarUrl = _avatarUrl;

    if (_pickedImage != null) {
      final uploaded = await _uploadAvatar(_pickedImage!);
      if (uploaded != null) {
        finalAvatarUrl = uploaded;
      }
    }

    final updates = {
      'name': _nameController.text.trim(),
      'avatar_url': finalAvatarUrl,
      'bio': _bioController.text.trim(),
      'location': _locationController.text.trim(),
    };

    if (_isAdmin) {
      updates['role'] = _role;
    }

    await supabase.from('profiles').update(updates).eq('id', user.id);
    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Widget _avatarPreview(ThemeColors tc) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: DesignTokens.accentBlue.withValues(alpha: 0.4),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: tc.avatarBg,
        backgroundImage: _pickedImage != null 
          ? FileImage(_pickedImage!) 
          : (_avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null),
        child: (_pickedImage == null && _avatarUrl.isEmpty) 
          ? Icon(
              Icons.person,
              size: 50,
              color: tc.avatarIcon,
            )
          : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tc = context.tc;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: tc.textPrimary,
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: tc.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tc.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: DesignTokens.accentBlue,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Avatar Section
                  _buildAvatarSection(tc),
                  const SizedBox(height: 16),
                  
                  // Profile Information Card
                  _buildProfileInfoCard(tc),
                  const SizedBox(height: 12),
                  
                  // Security Settings Card
                  _buildSecuritySettingsCard(tc),
                  const SizedBox(height: 12),
                  
                  // Save Button
                  _buildSaveButton(tc),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarSection(ThemeColors tc) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: _avatarPreview(tc),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap image to change avatar',
          style: TextStyle(
            color: tc.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfoCard(ThemeColors tc) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2.0,
              colors: [
                DesignTokens.accentBlue.withValues(alpha: 0.2),
                DesignTokens.accentBlue.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DesignTokens.accentBlue.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentBlue.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline, color: Colors.white.withValues(alpha: 0.9), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Profile Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Name Field
              _buildCompactTextField(
                controller: _nameController,
                label: 'Your Name',
                icon: Icons.person,
                tc: tc,
              ),
              const SizedBox(height: 12),
              
              // Bio Field
              _buildCompactTextField(
                controller: _bioController,
                label: 'Bio',
                icon: Icons.description,
                maxLines: 2,
                tc: tc,
              ),
              const SizedBox(height: 12),
              
              // Location Field
              _buildCompactTextField(
                controller: _locationController,
                label: 'Location',
                icon: Icons.location_on,
                tc: tc,
              ),
              const SizedBox(height: 12),
              
              // Role Dropdown
              _buildCompactRoleDropdown(tc),
              if (!_isAdmin)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Only admins can change roles.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeColors tc,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: DesignTokens.accentBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.accentBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 18),
              border: InputBorder.none,
              fillColor: Colors.transparent,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildCompactRoleDropdown(ThemeColors tc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: DesignTokens.accentBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.accentBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _role,
            dropdownColor: DesignTokens.accentBlue.withValues(alpha: 0.9),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.white.withValues(alpha: 0.7), size: 18),
            decoration: InputDecoration(
              border: InputBorder.none,
              fillColor: Colors.transparent,
              filled: true,
              prefixIcon: Icon(Icons.admin_panel_settings, color: Colors.white.withValues(alpha: 0.7), size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(value: 'client', child: Text('Client')),
              DropdownMenuItem(value: 'coach', child: Text('Coach')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: _isAdmin
                ? (val) => setState(() => _role = val!)
                : null,
          ),
        ),
      ],
    );
  }


  Widget _buildSecuritySettingsCard(ThemeColors tc) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2.0,
              colors: [
                DesignTokens.accentBlue.withValues(alpha: 0.2),
                DesignTokens.accentBlue.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DesignTokens.accentBlue.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentBlue.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security, color: Colors.white.withValues(alpha: 0.9), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Security Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Device Management
              _buildSettingsTile(
                icon: Icons.devices_other,
                title: 'Manage devices',
                subtitle: 'View and manage your signed-in devices',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DeviceListScreen(),
                    ),
                  );
                },
              ),
              
              // Billing & Upgrade
              _buildSettingsTile(
                icon: Icons.credit_card,
                title: 'Billing & Upgrade',
                subtitle: 'Manage your subscription and billing',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BillingSettings(),
                    ),
                  );
                },
              ),
              
              // Settings
              _buildSettingsTile(
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'Theme, language, and reminder preferences',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserSettingsScreen(),
                    ),
                  );
                },
              ),
              
              // Coach Application (only for clients)
              if (_role == 'client')
                _buildSettingsTile(
                  icon: Icons.sports_gymnastics,
                  title: 'Apply to become a Coach',
                  subtitle: 'Submit your coaching application',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BecomeCoachScreen(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: DesignTokens.accentBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DesignTokens.accentBlue.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white.withValues(alpha: 0.5),
          size: 14,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSaveButton(ThemeColors tc) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 2.0,
              colors: [
                DesignTokens.accentBlue.withValues(alpha: 0.4),
                DesignTokens.accentBlue.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.accentBlue.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _saveProfile,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
