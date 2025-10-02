import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../models/nutrition/nutrition_plan.dart';
import '../../../../services/haptics.dart';
import '../../widgets/shared/nutrition_card.dart';

/// Beautiful timeline card for displaying meals in sequence
class MealTimelineCard extends StatefulWidget {
  final Meal meal;
  final int index;
  final VoidCallback? onTap;
  final bool isCompleted;

  const MealTimelineCard({
    super.key,
    required this.meal,
    required this.index,
    this.onTap,
    this.isCompleted = false,
  });

  @override
  State<MealTimelineCard> createState() => _MealTimelineCardState();
}

class _MealTimelineCardState extends State<MealTimelineCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: AppTheme.accentGreen.withValues(alpha: 0.1),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      Haptics.tap();
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: _handleTap,
            child: Container(
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
              ),
              child: Row(
                children: [
                  // Timeline indicator
                  _buildTimelineIndicator(),

                  const SizedBox(width: DesignTokens.space16),

                  // Meal card
                  Expanded(
                    child: NutritionCard(
                      highlighted: widget.isCompleted,
                      child: _buildMealContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineIndicator() {
    return Column(
      children: [
        // Timeline line (top)
        if (widget.index > 0)
          Container(
            width: 2,
            height: 20,
            color: AppTheme.mediumGrey.withValues(alpha: 0.3),
          ),

        // Meal number circle
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _getMealTypeColor().withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: _getMealTypeColor(),
              width: 2,
            ),
          ),
          child: Center(
            child: widget.isCompleted
              ? Icon(
                  Icons.check,
                  color: _getMealTypeColor(),
                  size: 16,
                )
              : Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    color: _getMealTypeColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),

        // Timeline line (bottom)
        Container(
          width: 2,
          height: 20,
          color: AppTheme.mediumGrey.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildMealContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meal header
        Row(
          children: [
            // Meal type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getMealTypeColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: Icon(
                _getMealTypeIcon(),
                color: _getMealTypeColor(),
                size: 20,
              ),
            ),

            const SizedBox(width: DesignTokens.space12),

            // Meal info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.meal.label,
                          style: const TextStyle(
                            color: AppTheme.neutralWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space6,
                            vertical: DesignTokens.space2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen,
                            borderRadius: BorderRadius.circular(DesignTokens.radius8),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: AppTheme.primaryDark,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  Text(
                    _getMealTime(),
                    style: const TextStyle(
                      color: AppTheme.lightGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Calories badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space8,
                vertical: DesignTokens.space4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: Text(
                widget.meal.mealSummary.totalKcal.toStringAsFixed(0),
                style: const TextStyle(
                  color: AppTheme.accentGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.space12),

        // Macro breakdown
        Row(
          children: [
            Expanded(
              child: _buildMacroItem(
                'P',
                widget.meal.mealSummary.totalProtein,
                Colors.red,
              ),
            ),
            Expanded(
              child: _buildMacroItem(
                'C',
                widget.meal.mealSummary.totalCarbs,
                Colors.orange,
              ),
            ),
            Expanded(
              child: _buildMacroItem(
                'F',
                widget.meal.mealSummary.totalFat,
                Colors.yellow.shade700,
              ),
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.space12),

        // Food items summary
        Row(
          children: [
            const Icon(
              Icons.restaurant_menu,
              size: 14,
              color: AppTheme.lightGrey,
            ),
            const SizedBox(width: DesignTokens.space4),
            Text(
              '${widget.meal.items.length} items',
              style: const TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 12,
              ),
            ),
            if (widget.meal.attachments.isNotEmpty) ...[
              const SizedBox(width: DesignTokens.space12),
              const Icon(
                Icons.photo_camera,
                size: 14,
                color: AppTheme.lightGrey,
              ),
              const SizedBox(width: DesignTokens.space4),
              Text(
                '${widget.meal.attachments.length}',
                style: const TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 12,
                ),
              ),
            ],
            if (widget.meal.clientComment.isNotEmpty) ...[
              const SizedBox(width: DesignTokens.space12),
              const Icon(
                Icons.comment,
                size: 14,
                color: AppTheme.lightGrey,
              ),
            ],
            const Spacer(),
            if (widget.onTap != null)
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: AppTheme.lightGrey,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroItem(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space8,
        vertical: DesignTokens.space6,
      ),
      margin: const EdgeInsets.only(right: DesignTokens.space4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius6),
      ),
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(0)}g',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMealTypeColor() {
    final name = widget.meal.label.toLowerCase();
    if (name.contains('breakfast')) return Colors.orange;
    if (name.contains('lunch')) return Colors.green;
    if (name.contains('dinner')) return Colors.purple;
    if (name.contains('snack')) return Colors.blue;
    return AppTheme.accentGreen;
  }

  IconData _getMealTypeIcon() {
    final name = widget.meal.label.toLowerCase();
    if (name.contains('breakfast')) return Icons.wb_sunny;
    if (name.contains('lunch')) return Icons.wb_sunny_outlined;
    if (name.contains('dinner')) return Icons.nightlight_round;
    if (name.contains('snack')) return Icons.cookie;
    return Icons.restaurant_menu;
  }

  String _getMealTime() {
    final name = widget.meal.label.toLowerCase();
    if (name.contains('breakfast')) return '7:00 AM';
    if (name.contains('lunch')) return '12:30 PM';
    if (name.contains('dinner')) return '7:00 PM';
    if (name.contains('snack')) {
      // Different times for different snacks
      if (widget.index == 1) return '10:00 AM';
      if (widget.index == 3) return '3:00 PM';
      return '9:00 PM';
    }
    return 'Anytime';
  }
}