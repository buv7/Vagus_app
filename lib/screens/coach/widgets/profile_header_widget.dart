import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/coach_profile.dart';
import '../../../models/coach_profile_stats.dart';
import '../../../theme/design_tokens.dart';

class ProfileHeaderWidget extends StatefulWidget {
  final CoachProfile? profile;
  final CoachProfileStats? stats;
  final bool isEditMode;
  final bool isOwner;
  final TextEditingController displayNameController;
  final TextEditingController usernameController;
  final String? usernameError;
  final bool isCheckingUsername;
  final VoidCallback onFieldChanged;
  final Function(String) onUsernameChanged;
  final VoidCallback? onShareProfile;

  const ProfileHeaderWidget({
    super.key,
    required this.profile,
    required this.stats,
    required this.isEditMode,
    required this.isOwner,
    required this.displayNameController,
    required this.usernameController,
    this.usernameError,
    this.isCheckingUsername = false,
    required this.onFieldChanged,
    required this.onUsernameChanged,
    this.onShareProfile,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget>
    with TickerProviderStateMixin {
  String? _avatarUrl;
  bool _isLoadingAvatar = false;
  late AnimationController _avatarController;
  late Animation<double> _avatarScale;

  @override
  void initState() {
    super.initState();
    _avatarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _avatarScale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _avatarController, curve: Curves.elasticOut));

    _loadAvatarUrl();
    _avatarController.forward();
  }

  Future<void> _loadAvatarUrl() async {
    if (widget.profile == null) return;

    setState(() => _isLoadingAvatar = true);

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', widget.profile!.coachId)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _avatarUrl = response['avatar_url']?.toString();
          _isLoadingAvatar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAvatar = false);
      }
    }
  }

  Future<void> _updateAvatar() async {
    // This would integrate with image picker and upload to Supabase storage
    // Implementation would be similar to existing avatar update logic in the app
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avatar update feature coming soon'),
        backgroundColor: DesignTokens.accentBlue,
      ),
    );
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Column(
        children: [
          // Avatar section
          _buildAvatarSection(),

          const SizedBox(height: DesignTokens.space16),

          // Display name
          _buildDisplayNameSection(),

          const SizedBox(height: DesignTokens.space8),

          // Username
          _buildUsernameSection(),

          const SizedBox(height: DesignTokens.space12),

          // Role badge and QR share
          _buildRoleAndActions(),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return ScaleTransition(
      scale: _avatarScale,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: DesignTokens.accentGreen,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.accentGreen.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _isLoadingAvatar
                ? const CircularProgressIndicator(color: DesignTokens.accentGreen)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? Image.network(
                            _avatarUrl!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                          )
                        : _buildDefaultAvatar(),
                  ),
          ),

          // Edit overlay for avatar in edit mode
          if (widget.isEditMode && widget.isOwner)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _updateAvatar,
                    borderRadius: BorderRadius.circular(60),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.white, size: 24),
                          SizedBox(height: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    final initials = _getInitials();
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            DesignTokens.accentGreen,
            DesignTokens.accentBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: DesignTokens.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    final displayName = widget.isEditMode
        ? widget.displayNameController.text.trim()
        : widget.profile?.displayName;

    if (displayName == null || displayName.isEmpty) return 'C';

    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  Widget _buildDisplayNameSection() {
    if (widget.isEditMode) {
      return TextField(
        controller: widget.displayNameController,
        onChanged: (_) => widget.onFieldChanged(),
        style: DesignTokens.titleLarge.copyWith(color: DesignTokens.neutralWhite),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: 'Enter display name',
          hintStyle: DesignTokens.titleLarge.copyWith(color: DesignTokens.textSecondary),
          filled: true,
          fillColor: DesignTokens.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space12,
          ),
        ),
      );
    }

    return Text(
      widget.profile?.displayName ?? 'Unnamed Coach',
      style: DesignTokens.titleLarge.copyWith(
        color: DesignTokens.neutralWhite,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildUsernameSection() {
    if (widget.isEditMode) {
      return Column(
        children: [
          TextField(
            controller: widget.usernameController,
            onChanged: (value) {
              widget.onFieldChanged();
              // Debounce username checking
              Future.delayed(const Duration(milliseconds: 500), () {
                if (widget.usernameController.text == value) {
                  widget.onUsernameChanged(value.trim().toLowerCase());
                }
              });
            },
            style: DesignTokens.bodyLarge.copyWith(color: DesignTokens.accentGreen),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixText: '@',
              prefixStyle: DesignTokens.bodyLarge.copyWith(color: DesignTokens.accentGreen),
              hintText: 'username',
              hintStyle: DesignTokens.bodyLarge.copyWith(color: DesignTokens.textSecondary),
              filled: true,
              fillColor: DesignTokens.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                borderSide: BorderSide.none,
              ),
              errorText: widget.usernameError,
              errorStyle: const TextStyle(color: DesignTokens.accentPink),
              suffixIcon: widget.isCheckingUsername
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DesignTokens.accentGreen,
                      ),
                    )
                  : widget.usernameError == null && widget.usernameController.text.isNotEmpty
                      ? const Icon(Icons.check_circle, color: DesignTokens.accentGreen, size: 20)
                      : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space16,
                vertical: DesignTokens.space12,
              ),
            ),
          ),
        ],
      );
    }

    if (widget.profile?.username != null && widget.profile!.username!.isNotEmpty) {
      return Text(
        '@${widget.profile!.username}',
        style: DesignTokens.bodyLarge.copyWith(
          color: DesignTokens.accentGreen,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRoleAndActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space12,
            vertical: DesignTokens.space4,
          ),
          decoration: BoxDecoration(
            color: DesignTokens.accentGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(DesignTokens.radius20),
            border: Border.all(color: DesignTokens.accentGreen),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, size: 16, color: DesignTokens.accentGreen),
              const SizedBox(width: DesignTokens.space4),
              Text(
                _getRoleBadgeText(),
                style: DesignTokens.labelSmall.copyWith(
                  color: DesignTokens.accentGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // QR share button (view mode only)
        if (!widget.isEditMode && widget.onShareProfile != null &&
            widget.profile?.username != null) ...[
          const SizedBox(width: DesignTokens.space12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onShareProfile,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.space8),
                decoration: BoxDecoration(
                  color: DesignTokens.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DesignTokens.glassBorder),
                ),
                child: const Icon(
                  Icons.qr_code,
                  size: 20,
                  color: DesignTokens.neutralWhite,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getRoleBadgeText() {
    // This could be expanded based on coach tier/status
    final stats = widget.stats;
    if (stats == null) return 'Coach';

    if (stats.rating >= 4.8 && stats.clientCount >= 50) {
      return 'Elite Coach';
    } else if (stats.rating >= 4.5 && stats.clientCount >= 20) {
      return 'Premium Coach';
    } else if (stats.clientCount >= 5) {
      return 'Verified Coach';
    }

    return 'Coach';
  }
}