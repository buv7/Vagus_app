import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/coach/coach_profile.dart';
import '../../models/coach/coach_profile_stats.dart';
import '../../services/coach_portfolio_service.dart';
import '../../services/qr_service.dart';
import '../../theme/design_tokens.dart';
import 'widgets/profile_header_widget.dart';
import 'widgets/profile_hero_section_widget.dart';
import 'widgets/bio_section_widget.dart';
import 'widgets/specialties_section_widget.dart';
import 'widgets/media_gallery_widget.dart';
import 'widgets/profile_completeness_widget.dart';

class UnifiedCoachProfileScreen extends StatefulWidget {
  final String coachId;
  final String? username; // Alternative entry point
  final bool initialEditMode;

  const UnifiedCoachProfileScreen({
    super.key,
    required this.coachId,
    this.username,
    this.initialEditMode = false,
  });

  @override
  State<UnifiedCoachProfileScreen> createState() => _UnifiedCoachProfileScreenState();
}

class _UnifiedCoachProfileScreenState extends State<UnifiedCoachProfileScreen>
    with TickerProviderStateMixin {
  final CoachPortfolioService _portfolioService = CoachPortfolioService();
  final QRService _qrService = QRService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

  // Data state
  CoachProfile? _profile;
  CoachProfileStats? _stats;
  CoachProfileCompleteness? _completeness;
  List<CoachMedia> _media = [];
  bool _isOwner = false;
  bool _canEdit = false;

  // UI state
  bool _isLoading = true;
  bool _isEditMode = false;
  bool _hasUnsavedChanges = false;
  String? _error;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Edit form controllers
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _headlineController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _introVideoController = TextEditingController();

  // Form validation
  String? _usernameError;
  bool _isCheckingUsername = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _isEditMode = widget.initialEditMode;
    _loadProfileData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      // Track profile view if not self-view
      if (currentUserId != null) {
        unawaited(_portfolioService.incrementProfileView(widget.coachId, viewerId: currentUserId));
      }

      final data = await _portfolioService.getFullCoachProfile(
        widget.coachId,
        viewerId: currentUserId,
      );

      if (mounted) {
        setState(() {
          _profile = data['profile'] as CoachProfile?;
          _stats = data['stats'] as CoachProfileStats;
          _completeness = data['completeness'] as CoachProfileCompleteness;
          _media = data['media'] as List<CoachMedia>;
          _isOwner = data['is_owner'] as bool;
          _canEdit = data['can_edit'] as bool;
          _isLoading = false;
        });

        _populateEditControllers();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _populateEditControllers() {
    if (_profile != null) {
      _displayNameController.text = _profile!.displayName ?? '';
      _usernameController.text = _profile!.username ?? '';
      _headlineController.text = _profile!.headline ?? '';
      _bioController.text = _profile!.bio ?? '';
      _introVideoController.text = _profile!.introVideoUrl ?? '';
    }
  }

  void _toggleEditMode() {
    if (_isEditMode && _hasUnsavedChanges) {
      _showUnsavedChangesDialog();
    } else {
      setState(() {
        _isEditMode = !_isEditMode;
        _hasUnsavedChanges = false;
      });

      if (_isEditMode) {
        _populateEditControllers();
      }
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
        ),
        title: Text(
          'Unsaved Changes',
          style: DesignTokens.titleMedium.copyWith(color: DesignTokens.neutralWhite),
        ),
        content: Text(
          'You have unsaved changes. Would you like to save them before exiting edit mode?',
          style: DesignTokens.bodyMedium.copyWith(color: DesignTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isEditMode = false;
                _hasUnsavedChanges = false;
              });
              _populateEditControllers(); // Reset to original values
            },
            child: const Text('Discard', style: TextStyle(color: DesignTokens.accentPink)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.accentGreen,
              foregroundColor: DesignTokens.primaryDark,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;

    // Validate form
    if (_displayNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Display name is required');
      return;
    }

    if (_usernameController.text.trim().isEmpty) {
      _showErrorSnackBar('Username is required');
      return;
    }

    // Show loading
    setState(() => _isLoading = true);

    try {
      final updatedProfile = CoachProfile(
        coachId: _profile!.coachId,
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim().toLowerCase(),
        headline: _headlineController.text.trim(),
        bio: _bioController.text.trim(),
        specialties: _profile!.specialties, // Will be updated by specialties widget
        introVideoUrl: _introVideoController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _portfolioService.createOrUpdateProfile(updatedProfile);

      if (mounted) {
        setState(() {
          _profile = updatedProfile;
          _isEditMode = false;
          _hasUnsavedChanges = false;
          _isLoading = false;
        });

        _showSuccessSnackBar('Profile updated successfully!');

        // Refresh completeness data
        unawaited(_refreshCompleteness());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to save profile: ${e.toString()}');
      }
    }
  }

  Future<void> _refreshCompleteness() async {
    try {
      final completeness = await _portfolioService.getProfileCompleteness(widget.coachId);
      if (mounted) {
        setState(() => _completeness = completeness);
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty || username == _profile?.username) {
      setState(() {
        _usernameError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    try {
      final isAvailable = await _portfolioService.isUsernameAvailable(
        username,
        excludeCoachId: widget.coachId,
      );

      if (mounted) {
        setState(() {
          _usernameError = isAvailable ? null : 'Username already taken';
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usernameError = 'Unable to check username availability';
          _isCheckingUsername = false;
        });
      }
    }
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _shareProfile() {
    if (_profile?.username == null) return;

    _qrService.showQRBottomSheet(
      context,
      coachId: widget.coachId,
      coachName: _profile!.displayName ?? 'Coach',
      username: _profile!.username!,
    );
  }

  Future<void> _refreshProfile() async {
    await _loadProfileData();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.accentPink,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.accentGreen,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    _displayNameController.dispose();
    _usernameController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    _introVideoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !(_isEditMode && _hasUnsavedChanges),
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _isEditMode && _hasUnsavedChanges) {
          _showUnsavedChangesDialog();
        }
      },
      child: Scaffold(
        backgroundColor: DesignTokens.primaryDark,
        appBar: AppBar(
          backgroundColor: DesignTokens.primaryDark,
          foregroundColor: DesignTokens.neutralWhite,
          elevation: 0,
          title: Text(_isEditMode ? 'Edit Profile' : (_profile?.displayName ?? 'Coach Profile')),
          actions: [
            if (_canEdit && !_isLoading) ...[
              if (_isEditMode)
                TextButton.icon(
                  onPressed: _hasUnsavedChanges ? _saveProfile : null,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save'),
                  style: TextButton.styleFrom(
                    foregroundColor: _hasUnsavedChanges
                        ? DesignTokens.accentGreen
                        : DesignTokens.textSecondary,
                  ),
                )
              else
                IconButton(
                  onPressed: _toggleEditMode,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Profile',
                ),
            ],
            if (!_isEditMode && !_canEdit && _profile?.username != null)
              IconButton(
                onPressed: _shareProfile,
                icon: const Icon(Icons.qr_code),
                tooltip: 'Share Profile',
              ),
            if (_isEditMode)
              IconButton(
                onPressed: _toggleEditMode,
                icon: const Icon(Icons.close),
                tooltip: 'Cancel',
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _profile == null) {
      return const Center(
        child: CircularProgressIndicator(color: DesignTokens.accentGreen),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: DesignTokens.accentPink,
            ),
            const SizedBox(height: DesignTokens.space16),
            Text(
              'Failed to load profile',
              style: DesignTokens.titleMedium.copyWith(color: DesignTokens.neutralWhite),
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              _error!,
              style: DesignTokens.bodySmall.copyWith(color: DesignTokens.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space24),
            ElevatedButton(
              onPressed: _loadProfileData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          key: _refreshKey,
          onRefresh: _refreshProfile,
          color: DesignTokens.accentGreen,
          backgroundColor: DesignTokens.cardBackground,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Profile completeness indicator (edit mode only)
                if (_isEditMode && _completeness != null && !_completeness!.isComplete)
                  ProfileCompletenessWidget(
                    completeness: _completeness!,
                    onSectionTap: _scrollToSection,
                  ),

                // Profile header
                ProfileHeaderWidget(
                  profile: _profile,
                  stats: _stats,
                  isEditMode: _isEditMode,
                  isOwner: _isOwner,
                  displayNameController: _displayNameController,
                  usernameController: _usernameController,
                  usernameError: _usernameError,
                  isCheckingUsername: _isCheckingUsername,
                  onFieldChanged: _onFieldChanged,
                  onUsernameChanged: _checkUsernameAvailability,
                  onShareProfile: _shareProfile,
                ),

                // Hero section with stats and CTAs
                ProfileHeroSectionWidget(
                  profile: _profile,
                  stats: _stats,
                  isEditMode: _isEditMode,
                  isOwner: _isOwner,
                  headlineController: _headlineController,
                  onFieldChanged: _onFieldChanged,
                ),

                // Bio section
                BioSectionWidget(
                  profile: _profile,
                  isEditMode: _isEditMode,
                  bioController: _bioController,
                  onFieldChanged: _onFieldChanged,
                ),

                // Specialties section
                SpecialtiesSectionWidget(
                  profile: _profile,
                  isEditMode: _isEditMode,
                  onSpecialtiesChanged: (specialties) {
                    if (_profile != null) {
                      setState(() {
                        _profile = CoachProfile(
                          coachId: _profile!.coachId,
                          displayName: _profile!.displayName,
                          username: _profile!.username,
                          headline: _profile!.headline,
                          bio: _profile!.bio,
                          specialties: specialties,
                          introVideoUrl: _profile!.introVideoUrl,
                          updatedAt: _profile!.updatedAt,
                        );
                      });
                      _onFieldChanged();
                    }
                  },
                ),

                // Introduction video section
                if (_isEditMode || (_profile?.introVideoUrl?.isNotEmpty ?? false))
                  _buildIntroVideoSection(),

                // Media portfolio gallery
                MediaGalleryWidget(
                  media: _media,
                  isEditMode: _isEditMode,
                  isOwner: _isOwner,
                  coachId: widget.coachId,
                  onMediaUpdated: _refreshProfile,
                ),

                const SizedBox(height: DesignTokens.space32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroVideoSection() {
    return Container(
      margin: const EdgeInsets.all(DesignTokens.space16),
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        boxShadow: DesignTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Introduction Video',
            style: DesignTokens.titleMedium.copyWith(color: DesignTokens.neutralWhite),
          ),
          const SizedBox(height: DesignTokens.space12),
          if (_isEditMode)
            TextField(
              controller: _introVideoController,
              onChanged: (_) => _onFieldChanged(),
              style: DesignTokens.bodyMedium.copyWith(color: DesignTokens.neutralWhite),
              decoration: InputDecoration(
                hintText: 'Enter video URL (YouTube, Vimeo, etc.)',
                hintStyle: DesignTokens.bodyMedium.copyWith(color: DesignTokens.textSecondary),
                filled: true,
                fillColor: DesignTokens.primaryDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.video_library, color: DesignTokens.accentGreen),
              ),
              maxLines: 2,
            )
          else if (_profile?.introVideoUrl?.isNotEmpty ?? false)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: DesignTokens.primaryDark,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_outline, size: 48, color: DesignTokens.accentGreen),
                    SizedBox(height: DesignTokens.space8),
                    Text(
                      'Introduction Video',
                      style: TextStyle(color: DesignTokens.neutralWhite),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: DesignTokens.primaryDark,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(color: DesignTokens.glassBorder),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_library_outlined, size: 32, color: DesignTokens.textSecondary),
                    SizedBox(height: DesignTokens.space8),
                    Text(
                      'No introduction video',
                      style: TextStyle(color: DesignTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _scrollToSection(String section) {
    // Implementation for scrolling to specific sections
    // This would be expanded based on section keys
  }
}