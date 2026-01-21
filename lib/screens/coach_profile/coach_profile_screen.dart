// Create the new unified coach profile screen at lib/screens/coach_profile/coach_profile_screen.dart
// This single screen replaces all the previous screens (portfolio, marketplace, edit, public view)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/coach_profile_service.dart';
import '../../models/coach_profile.dart';
import '../../theme/theme_colors.dart';
import 'widgets/profile_content.dart';
import 'widgets/media_gallery.dart';
import 'widgets/marketplace_status.dart';

class CoachProfileScreen extends StatefulWidget {
  final String? coachId;
  final bool isPublicView;

  const CoachProfileScreen({
    super.key,
    this.coachId,
    this.isPublicView = false,
  });

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen>
    with SingleTickerProviderStateMixin {
  final _profileService = CoachProfileService();
  late TabController _tabController;

  CoachProfile? _profile;
  bool _loading = true;
  bool _isEditMode = false;

  // Controllers for edit mode
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _headlineController = TextEditingController();
  final _bioController = TextEditingController();
  List<String> _selectedSpecialties = [];

  final List<String> _tabs = ['Profile', 'Media', 'Marketplace'];

  final List<String> _availableSpecialties = [
    'Weight Loss', 'Muscle Building', 'Strength Training',
    'Cardio Fitness', 'HIIT', 'Yoga', 'Pilates',
    'Nutrition Coaching', 'Sports Performance', 'Rehabilitation',
    'Flexibility', 'Endurance Training', 'Powerlifting',
    'CrossFit', 'Bodybuilding', 'Functional Training',
    'Senior Fitness', 'Pre/Postnatal', 'Athletic Training',
    'Mental Wellness'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _displayNameController.dispose();
    _usernameController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  String get _targetCoachId =>
      widget.coachId ?? Supabase.instance.client.auth.currentUser?.id ?? '';

  bool get _isOwnProfile =>
      widget.coachId == null ||
      widget.coachId == Supabase.instance.client.auth.currentUser?.id;

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    try {
      final profile = await _profileService.getFullProfile(_targetCoachId);
      setState(() {
        _profile = profile['profile'];
        _loading = false;

        // Initialize controllers with profile data
        _displayNameController.text = _profile?.displayName ?? '';
        _usernameController.text = _profile?.username ?? '';
        _headlineController.text = _profile?.headline ?? '';
        _bioController.text = _profile?.bio ?? '';
        _selectedSpecialties = List<String>.from(_profile?.specialties ?? []);
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    // Validate username format
    final username = _usernameController.text.trim();
    if (username.isNotEmpty) {
      if (username.length < 3 || username.length > 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username must be 3-20 characters'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if starts with letter
      if (!RegExp(r'^[a-zA-Z]').hasMatch(username)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username must start with a letter'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if contains only letters, numbers, and underscores
      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(username)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username can only contain letters, numbers, and underscores'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final updates = {
      'display_name': _displayNameController.text.trim(),
      'username': username,
      'headline': _headlineController.text.trim(),
      'bio': _bioController.text.trim(),
      'specialties': _selectedSpecialties,
    };

    try {
      await _profileService.updateProfile(_targetCoachId, updates);
      await _loadProfile();
      setState(() => _isEditMode = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _displayNameController.text = _profile?.displayName ?? '';
      _usernameController.text = _profile?.username ?? '';
      _headlineController.text = _profile?.headline ?? '';
      _bioController.text = _profile?.bio ?? '';
      _selectedSpecialties = List<String>.from(_profile?.specialties ?? []);
      _isEditMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: Theme.of(context).copyWith(
        // Fix for dark theme issues
        chipTheme: ChipThemeData(
          backgroundColor: isDarkMode
              ? Colors.grey[800]
              : Colors.grey[200],
          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          disabledColor: Colors.grey[600],
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDarkMode
                  ? Colors.grey[600]!
                  : Colors.grey[400]!,
            ),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Profile' : 'Coach Profile'),
          actions: _isOwnProfile ? [
            if (_isEditMode) ...[
              TextButton(
                onPressed: _cancelEdit,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              TextButton(
                onPressed: _saveProfile,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _isEditMode = true),
                tooltip: 'Edit Profile',
              ),
          ] : null,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _isEditMode
                ? _buildEditMode()
                : _buildViewMode(),
      ),
    );
  }

  Widget _buildEditMode() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Section
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: ThemeColors.of(context).avatarBg,
                      backgroundImage: _profile?.avatarUrl != null
                          ? NetworkImage(_profile!.avatarUrl!)
                          : null,
                      child: _profile?.avatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: ThemeColors.of(context).avatarIcon,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // TODO: Implement image picker
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('Change Photo'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Display Name Field
          _buildEditField(
            label: 'Display Name',
            controller: _displayNameController,
            icon: Icons.person_outline,
            hint: 'Enter your professional name',
          ),

          const SizedBox(height: 20),

          // Username Field
          _buildEditField(
            label: '@username',
            controller: _usernameController,
            icon: Icons.alternate_email,
            hint: 'Choose a unique username',
            prefix: '@',
          ),

          const SizedBox(height: 20),

          // Headline Field
          _buildEditField(
            label: 'Headline',
            controller: _headlineController,
            icon: Icons.short_text,
            hint: 'Your professional tagline',
            maxLength: 100,
          ),

          const SizedBox(height: 20),

          // Bio Field
          _buildEditField(
            label: 'Bio',
            controller: _bioController,
            icon: Icons.description_outlined,
            hint: 'Tell clients about yourself, your experience, and approach',
            maxLines: 6,
            maxLength: 500,
          ),

          const SizedBox(height: 20),

          // Specialties Section with HIGH CONTRAST
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Specialties',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF1E1E2E) // Lighter background in dark mode
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableSpecialties.map((specialty) {
                    final isSelected = _selectedSpecialties.contains(specialty);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedSpecialties.remove(specialty);
                          } else if (_selectedSpecialties.length < 5) {
                            _selectedSpecialties.add(specialty);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You can select up to 5 specialties'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : (isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : (isDarkMode
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.grey.shade400),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            Text(
                              specialty,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDarkMode
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : Colors.black87),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedSpecialties.length == 5
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedSpecialties.length == 5
                            ? Colors.orange.withValues(alpha: 0.3)
                            : Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${_selectedSpecialties.length}/5 specialties selected',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _selectedSpecialties.length == 5
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    String? prefix,
    int maxLines = 1,
    int? maxLength,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white38 : Colors.black38,
            ),
            prefixText: prefix,
            prefixStyle: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
            filled: true,
            fillColor: isDarkMode
                ? Colors.grey[900]
                : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            counterStyle: TextStyle(
              color: isDarkMode ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewMode() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Profile Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: _profile?.avatarUrl != null
                    ? NetworkImage(_profile!.avatarUrl!)
                    : null,
                child: _profile?.avatarUrl == null
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile?.displayName ?? 'Coach Name',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_profile?.username != null)
                      Text(
                        '@${_profile!.username}',
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    if (_profile?.headline != null)
                      Text(
                        _profile!.headline!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab Bar with proper theming
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _tabController,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
            indicatorColor: Theme.of(context).primaryColor,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              ProfileContent(profile: _profile),
              MediaGallery(
                coachId: _targetCoachId,
                isOwnProfile: _isOwnProfile,
                onMediaUpdated: _loadProfile,
              ),
              if (_isOwnProfile)
                MarketplaceStatus(
                  profile: _profile,
                  onNavigate: (section) {
                    if (section == 'profile') {
                      _tabController.index = 0;
                      setState(() => _isEditMode = true);
                    } else if (section == 'media') {
                      _tabController.index = 1;
                    }
                  },
                )
              else
                const Center(child: Text('Marketplace info not available')),
            ],
          ),
        ),
      ],
    );
  }
}
