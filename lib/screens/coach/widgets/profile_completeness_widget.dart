import 'package:flutter/material.dart';
import '../../../models/coach_profile_stats.dart';
import '../../../theme/design_tokens.dart';

class ProfileCompletenessWidget extends StatefulWidget {
  final CoachProfileCompleteness completeness;
  final Function(String) onSectionTap;

  const ProfileCompletenessWidget({
    super.key,
    required this.completeness,
    required this.onSectionTap,
  });

  @override
  State<ProfileCompletenessWidget> createState() => _ProfileCompletenessWidgetState();
}

class _ProfileCompletenessWidgetState extends State<ProfileCompletenessWidget>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _progressController;
  late AnimationController _expandController;
  late Animation<double> _progressAnimation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.completeness.completionPercentage / 100,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );

    // Start progress animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.completeness.isComplete) {
      return _buildCompleteState();
    }

    return Container(
      margin: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.accentGreen.withValues(alpha: 0.1),
            DesignTokens.accentBlue.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: DesignTokens.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _buildMainCard(),
          if (_isExpanded) _buildExpandedContent(),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.space8),
                    decoration: BoxDecoration(
                      color: DesignTokens.accentGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                    child: const Icon(
                      Icons.checklist,
                      size: 20,
                      color: DesignTokens.accentGreen,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Completeness',
                          style: DesignTokens.titleMedium.copyWith(
                            color: DesignTokens.neutralWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.completeness.completedSteps} of ${widget.completeness.totalSteps} completed',
                          style: DesignTokens.bodySmall.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Percentage badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space8,
                      vertical: DesignTokens.space4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCompletionColor().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      border: Border.all(color: _getCompletionColor()),
                    ),
                    child: Text(
                      '${widget.completeness.completionPercentage.toInt()}%',
                      style: DesignTokens.labelSmall.copyWith(
                        color: _getCompletionColor(),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: DesignTokens.space16),

              // Progress bar
              _buildProgressBar(),

              const SizedBox(height: DesignTokens.space12),

              // Next step
              _buildNextStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: DesignTokens.labelMedium.copyWith(
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${widget.completeness.completionPercentage.toInt()}%',
              style: DesignTokens.labelMedium.copyWith(
                color: _getCompletionColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: DesignTokens.primaryDark,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: DesignTokens.glassBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            DesignTokens.accentGreen,
                            DesignTokens.accentBlue,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextStep() {
    final nextStep = widget.completeness.nextStepTitle;
    if (nextStep.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: DesignTokens.accentOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: DesignTokens.space8),
          Expanded(
            child: Text(
              'Next: $nextStep',
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.neutralWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: DesignTokens.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.space20,
          0,
          DesignTokens.space20,
          DesignTokens.space20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: DesignTokens.glassBorder),
            const SizedBox(height: DesignTokens.space16),

            Text(
              'Missing Items',
              style: DesignTokens.titleSmall.copyWith(
                color: DesignTokens.neutralWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space12),

            // Missing items list
            ...widget.completeness.missingItems.map((item) => _buildMissingItem(item)),

            if (widget.completeness.missingItems.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(DesignTokens.space16),
                decoration: BoxDecoration(
                  color: DesignTokens.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: DesignTokens.accentGreen),
                    SizedBox(width: DesignTokens.space12),
                    Expanded(
                      child: Text(
                        'Your profile is complete! Great job!',
                        style: TextStyle(
                          color: DesignTokens.accentGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMissingItem(ProfileCompletionItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onSectionTap(item.title),
          borderRadius: BorderRadius.circular(DesignTokens.radius8),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space12),
            decoration: BoxDecoration(
              color: DesignTokens.primaryDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
              border: Border.all(color: _getPriorityColor(item.priority)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(item.priority),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: DesignTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: DesignTokens.bodyMedium.copyWith(
                          color: DesignTokens.neutralWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space2),
                      Text(
                        item.description,
                        style: DesignTokens.bodySmall.copyWith(
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space6,
                    vertical: DesignTokens.space2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(item.priority).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignTokens.radius4),
                  ),
                  child: Text(
                    _getPriorityText(item.priority),
                    style: DesignTokens.labelSmall.copyWith(
                      color: _getPriorityColor(item.priority),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.space8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: DesignTokens.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteState() {
    return Container(
      margin: const EdgeInsets.all(DesignTokens.space16),
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.accentGreen.withValues(alpha: 0.2),
            DesignTokens.accentBlue.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(color: DesignTokens.accentGreen),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space8),
            decoration: BoxDecoration(
              color: DesignTokens.accentGreen.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 24,
              color: DesignTokens.accentGreen,
            ),
          ),
          const SizedBox(width: DesignTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Complete!',
                  style: DesignTokens.titleMedium.copyWith(
                    color: DesignTokens.neutralWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  'Your profile is fully optimized and ready to attract clients',
                  style: DesignTokens.bodySmall.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCompletionColor() {
    final percentage = widget.completeness.completionPercentage;
    if (percentage >= 80) return DesignTokens.accentGreen;
    if (percentage >= 50) return DesignTokens.accentOrange;
    return DesignTokens.accentPink;
  }

  Color _getPriorityColor(ProfileCompletionPriority priority) {
    switch (priority) {
      case ProfileCompletionPriority.high:
        return DesignTokens.accentPink;
      case ProfileCompletionPriority.medium:
        return DesignTokens.accentOrange;
      case ProfileCompletionPriority.low:
        return DesignTokens.accentBlue;
    }
  }

  String _getPriorityText(ProfileCompletionPriority priority) {
    switch (priority) {
      case ProfileCompletionPriority.high:
        return 'HIGH';
      case ProfileCompletionPriority.medium:
        return 'MED';
      case ProfileCompletionPriority.low:
        return 'LOW';
    }
  }
}