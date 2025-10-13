import 'package:flutter/material.dart';
import '../../../models/coach_profile.dart';
import '../../../theme/design_tokens.dart';

class BioSectionWidget extends StatefulWidget {
  final CoachProfile? profile;
  final bool isEditMode;
  final TextEditingController bioController;
  final VoidCallback onFieldChanged;

  const BioSectionWidget({
    super.key,
    required this.profile,
    required this.isEditMode,
    required this.bioController,
    required this.onFieldChanged,
  });

  @override
  State<BioSectionWidget> createState() => _BioSectionWidgetState();
}

class _BioSectionWidgetState extends State<BioSectionWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const int _maxCollapsedLength = 200;
  static const int _maxBioLength = 1000;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );


    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
        padding: const EdgeInsets.all(DesignTokens.space20),
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          boxShadow: DesignTokens.cardShadow,
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            _buildSectionHeader(),

            const SizedBox(height: DesignTokens.space16),

            // Bio content
            widget.isEditMode ? _buildEditMode() : _buildViewMode(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.space8),
          decoration: BoxDecoration(
            color: DesignTokens.accentBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: const Icon(
            Icons.person,
            size: 20,
            color: DesignTokens.accentBlue,
          ),
        ),
        const SizedBox(width: DesignTokens.space12),
        Text(
          'About',
          style: DesignTokens.titleMedium.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.bioController,
          onChanged: (_) => widget.onFieldChanged(),
          style: DesignTokens.bodyMedium.copyWith(color: DesignTokens.neutralWhite),
          decoration: InputDecoration(
            hintText: 'Tell potential clients about your background, experience, and coaching philosophy...',
            hintStyle: DesignTokens.bodyMedium.copyWith(color: DesignTokens.textSecondary),
            filled: true,
            fillColor: DesignTokens.primaryDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(DesignTokens.space16),
            counterText: '${widget.bioController.text.length}/$_maxBioLength',
            counterStyle: DesignTokens.bodySmall.copyWith(
              color: widget.bioController.text.length > _maxBioLength
                  ? DesignTokens.accentPink
                  : DesignTokens.textSecondary,
            ),
          ),
          maxLength: _maxBioLength,
          maxLines: 8,
          minLines: 4,
        ),

        const SizedBox(height: DesignTokens.space12),

        // Tips for writing a good bio
        _buildBioTips(),
      ],
    );
  }

  Widget _buildViewMode() {
    final bio = widget.profile?.bio;

    if (bio == null || bio.isEmpty) {
      return _buildEmptyState();
    }

    final shouldTruncate = bio.length > _maxCollapsedLength;
    final displayText = _isExpanded || !shouldTruncate
        ? bio
        : '${bio.substring(0, _maxCollapsedLength)}...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Text(
            displayText,
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.neutralWhite,
              height: 1.6,
            ),
          ),
        ),

        if (shouldTruncate) ...[
          const SizedBox(height: DesignTokens.space12),
          GestureDetector(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.space8,
                horizontal: DesignTokens.space12,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radius20),
                border: Border.all(color: DesignTokens.accentBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? 'Show less' : 'Read more',
                    style: DesignTokens.labelMedium.copyWith(
                      color: DesignTokens.accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space4),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: DesignTokens.accentBlue,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space24),
      decoration: BoxDecoration(
        color: DesignTokens.primaryDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.description_outlined,
              size: 32,
              color: DesignTokens.textSecondary,
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              'No bio added yet',
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              'A compelling bio helps clients understand your background and expertise',
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioTips() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: DesignTokens.accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: DesignTokens.accentGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates,
                size: 18,
                color: DesignTokens.accentGreen,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                'Tips for a great bio:',
                style: DesignTokens.labelMedium.copyWith(
                  color: DesignTokens.accentGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space8),
          ..._buildTipsList(),
        ],
      ),
    );
  }

  List<Widget> _buildTipsList() {
    final tips = [
      'Share your professional background and certifications',
      'Describe your coaching philosophy and approach',
      'Highlight your specialties and areas of expertise',
      'Include success stories or transformation results',
      'Keep it personal but professional',
    ];

    return tips.map((tip) => Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: DesignTokens.accentGreen,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.neutralWhite,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }
}