import 'package:flutter/material.dart';
import '../../../models/coach/coach_profile.dart';
import '../../../models/coach/coach_profile_stats.dart';
import '../../../theme/design_tokens.dart';

class ProfileHeroSectionWidget extends StatefulWidget {
  final CoachProfile? profile;
  final CoachProfileStats? stats;
  final bool isEditMode;
  final bool isOwner;
  final TextEditingController headlineController;
  final VoidCallback onFieldChanged;

  const ProfileHeroSectionWidget({
    super.key,
    required this.profile,
    required this.stats,
    required this.isEditMode,
    required this.isOwner,
    required this.headlineController,
    required this.onFieldChanged,
  });

  @override
  State<ProfileHeroSectionWidget> createState() => _ProfileHeroSectionWidgetState();
}

class _ProfileHeroSectionWidgetState extends State<ProfileHeroSectionWidget>
    with TickerProviderStateMixin {
  late AnimationController _statsController;
  late AnimationController _ctaController;
  late List<Animation<double>> _statAnimations;
  late Animation<double> _ctaAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _ctaController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Stagger stat animations
    _statAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _statsController,
          curve: Interval(
            index * 0.2,
            0.6 + (index * 0.2),
            curve: Curves.elasticOut,
          ),
        ),
      );
    });

    _ctaAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctaController, curve: Curves.bounceOut),
    );

    // Start animations
    _statsController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctaController.forward();
    });
  }

  @override
  void dispose() {
    _statsController.dispose();
    _ctaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(DesignTokens.space16),
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.cardBackground,
            DesignTokens.cardBackground.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
        boxShadow: DesignTokens.cardShadow,
        border: Border.all(
          color: DesignTokens.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline section
          _buildHeadlineSection(),

          const SizedBox(height: DesignTokens.space20),

          // Stats section
          _buildStatsSection(),

          if (!widget.isEditMode) ...[
            const SizedBox(height: DesignTokens.space24),

            // CTA buttons
            _buildCTASection(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeadlineSection() {
    if (widget.isEditMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Headline',
            style: DesignTokens.titleSmall.copyWith(
              color: DesignTokens.neutralWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          TextField(
            controller: widget.headlineController,
            onChanged: (_) => widget.onFieldChanged(),
            style: DesignTokens.titleMedium.copyWith(color: DesignTokens.neutralWhite),
            decoration: InputDecoration(
              hintText: 'Write a compelling headline that describes your expertise...',
              hintStyle: DesignTokens.bodyMedium.copyWith(color: DesignTokens.textSecondary),
              filled: true,
              fillColor: DesignTokens.primaryDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                borderSide: BorderSide.none,
              ),
              counterText: '${widget.headlineController.text.length}/120',
              counterStyle: DesignTokens.bodySmall.copyWith(color: DesignTokens.textSecondary),
            ),
            maxLength: 120,
            maxLines: 3,
          ),
        ],
      );
    }

    final headline = widget.profile?.headline;
    if (headline == null || headline.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.space16),
        decoration: BoxDecoration(
          color: DesignTokens.primaryDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: Center(
          child: Text(
            widget.isOwner ? 'Add a compelling headline to attract clients' : 'No headline yet',
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Text(
      headline,
      style: DesignTokens.titleMedium.copyWith(
        color: DesignTokens.neutralWhite,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatsSection() {
    final stats = widget.stats;
    if (stats == null) {
      return _buildLoadingStats();
    }

    return Row(
      children: [
        Expanded(
          child: ScaleTransition(
            scale: _statAnimations[0],
            child: _buildStatCard(
              icon: Icons.star,
              value: stats.ratingText,
              label: 'Rating',
              color: DesignTokens.accentOrange,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.space12),
        Expanded(
          child: ScaleTransition(
            scale: _statAnimations[1],
            child: _buildStatCard(
              icon: Icons.people,
              value: '${stats.clientCount}',
              label: 'Clients',
              color: DesignTokens.accentGreen,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.space12),
        Expanded(
          child: ScaleTransition(
            scale: _statAnimations[2],
            child: _buildStatCard(
              icon: Icons.trending_up,
              value: stats.yearsExperience > 0 ? '${stats.yearsExperience}y' : 'New',
              label: 'Experience',
              color: DesignTokens.accentBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: DesignTokens.primaryDark,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(color: DesignTokens.glassBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            value,
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.neutralWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            label,
            style: DesignTokens.bodySmall.copyWith(
              color: DesignTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Row(
      children: [
        Expanded(child: _buildLoadingStatCard()),
        const SizedBox(width: DesignTokens.space12),
        Expanded(child: _buildLoadingStatCard()),
        const SizedBox(width: DesignTokens.space12),
        Expanded(child: _buildLoadingStatCard()),
      ],
    );
  }

  Widget _buildLoadingStatCard() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: DesignTokens.primaryDark,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: DesignTokens.accentGreen,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildCTASection() {
    if (widget.isOwner) return const SizedBox.shrink();

    return ScaleTransition(
      scale: _ctaAnimation,
      child: Row(
        children: [
          // Primary CTA - Connect/Message
          Expanded(
            flex: 2,
            child: _buildCTAButton(
              onPressed: _onConnectPressed,
              backgroundColor: DesignTokens.accentGreen,
              foregroundColor: DesignTokens.primaryDark,
              icon: Icons.person_add,
              text: 'Connect',
              isPrimary: true,
            ),
          ),

          const SizedBox(width: DesignTokens.space12),

          // Secondary CTA - Book Session
          Expanded(
            child: _buildCTAButton(
              onPressed: _onBookSessionPressed,
              backgroundColor: Colors.transparent,
              foregroundColor: DesignTokens.accentGreen,
              icon: Icons.calendar_today,
              text: 'Book',
              isPrimary: false,
            ),
          ),

          const SizedBox(width: DesignTokens.space12),

          // Tertiary CTA - Message
          _buildIconCTAButton(
            onPressed: _onMessagePressed,
            icon: Icons.message,
            color: DesignTokens.accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    required IconData icon,
    required String text,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.space12,
            horizontal: DesignTokens.space16,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: isPrimary
                ? null
                : Border.all(color: DesignTokens.accentGreen),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: DesignTokens.space8),
              Text(
                text,
                style: DesignTokens.labelMedium.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconCTAButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }

  void _onConnectPressed() {
    // Implement connect functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connect functionality coming soon'),
        backgroundColor: DesignTokens.accentGreen,
      ),
    );
  }

  void _onBookSessionPressed() {
    // Implement booking functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking functionality coming soon'),
        backgroundColor: DesignTokens.accentBlue,
      ),
    );
  }

  void _onMessagePressed() {
    // Implement messaging functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Messaging functionality coming soon'),
        backgroundColor: DesignTokens.accentBlue,
      ),
    );
  }
}