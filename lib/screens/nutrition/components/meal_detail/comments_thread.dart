import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../models/nutrition/nutrition_plan.dart';
import '../../../../services/nutrition/locale_helper.dart';
import '../../../../services/haptics.dart';
import '../../widgets/shared/nutrition_card.dart';
import '../../widgets/shared/empty_state_widget.dart';

/// Thread for coach-client comments and notes on meals
class CommentsThread extends StatefulWidget {
  final Meal meal;
  final String userRole;
  final bool isReadOnly;
  final Function(Meal)? onMealUpdated;

  const CommentsThread({
    super.key,
    required this.meal,
    required this.userRole,
    this.isReadOnly = false,
    this.onMealUpdated,
  });

  @override
  State<CommentsThread> createState() => _CommentsThreadState();
}

class _CommentsThreadState extends State<CommentsThread>
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  late AnimationController _inputAnimationController;
  late Animation<double> _inputSlideAnimation;
  late Animation<double> _inputFadeAnimation;

  bool _isTyping = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _commentController.text = widget.meal.clientComment;

    _inputAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _inputSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _inputAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _inputFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _inputAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _commentController.addListener(_onCommentChanged);
    _commentFocus.addListener(_onFocusChanged);

    _inputAnimationController.forward();
  }

  @override
  void didUpdateWidget(CommentsThread oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meal.clientComment != widget.meal.clientComment) {
      _commentController.text = widget.meal.clientComment;
      _hasUnsavedChanges = false;
    }
  }

  @override
  void dispose() {
    _commentController.removeListener(_onCommentChanged);
    _commentFocus.removeListener(_onFocusChanged);
    _commentController.dispose();
    _commentFocus.dispose();
    _inputAnimationController.dispose();
    super.dispose();
  }

  void _onCommentChanged() {
    final hasChanges = _commentController.text != widget.meal.clientComment;
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  void _onFocusChanged() {
    setState(() {
      _isTyping = _commentFocus.hasFocus;
    });
  }

  void _saveComment() {
    if (_commentController.text == widget.meal.clientComment) return;

    final updatedMeal = widget.meal.copyWith(
      clientComment: _commentController.text,
    );

    widget.onMealUpdated?.call(updatedMeal);
    Haptics.success();

    setState(() {
      _hasUnsavedChanges = false;
    });

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Comment saved'),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius8),
        ),
      ),
    );
  }

  void _discardChanges() {
    _commentController.text = widget.meal.clientComment;
    _commentFocus.unfocus();
    setState(() {
      _hasUnsavedChanges = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return Column(
      children: [
        // Coach notes section (if any exist)
        if (widget.userRole == 'client')
          Expanded(child: _buildCoachNotesSection(locale))
        else
          Expanded(child: _buildCommentsList(locale)),

        // Comment input section
        AnimatedBuilder(
          animation: _inputAnimationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 100 * (1 - _inputSlideAnimation.value)),
              child: Opacity(
                opacity: _inputFadeAnimation.value,
                child: _buildCommentInput(locale),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCoachNotesSection(String locale) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coach instructions/notes placeholder
          NutritionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: AppTheme.accentOrange,
                      size: 20,
                    ),
                    const SizedBox(width: DesignTokens.space8),
                    Text(
                      LocaleHelper.t('coach_notes', locale),
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DesignTokens.space12),

                Text(
                  'No specific notes from your coach for this meal. Follow the portions as planned and feel free to add your own notes below.',
                  style: const TextStyle(
                    color: AppTheme.lightGrey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.space16),

          // Tips section
          NutritionCard(
            customBackgroundColor: AppTheme.accentGreen.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.accentGreen,
                      size: 20,
                    ),
                    const SizedBox(width: DesignTokens.space8),
                    Text(
                      LocaleHelper.t('meal_tips', locale),
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DesignTokens.space12),

                ..._getMealTips().map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.space8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: const BoxDecoration(
                          color: AppTheme.accentGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.space8),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            color: AppTheme.lightGrey,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(String locale) {
    // For coaches, show a more structured view of client feedback
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client feedback section
          NutritionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.feedback_outlined,
                      color: AppTheme.accentOrange,
                      size: 20,
                    ),
                    const SizedBox(width: DesignTokens.space8),
                    Text(
                      LocaleHelper.t('client_feedback', locale),
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DesignTokens.space12),

                if (widget.meal.clientComment.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DesignTokens.space12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                      border: Border.all(
                        color: AppTheme.mediumGrey.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.meal.clientComment,
                      style: const TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DesignTokens.space16),
                    decoration: BoxDecoration(
                      color: AppTheme.mediumGrey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                      border: Border.all(
                        color: AppTheme.mediumGrey.withOpacity(0.2),
                      ),
                    ),
                    child: const Text(
                      'No feedback from client yet',
                      style: TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.space16),

          // Coach notes section (for adding instructions)
          NutritionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.note_add,
                      color: AppTheme.accentGreen,
                      size: 20,
                    ),
                    const SizedBox(width: DesignTokens.space8),
                    Text(
                      LocaleHelper.t('add_instructions', locale),
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DesignTokens.space12),

                const Text(
                  'Add specific instructions or notes for this meal that will be visible to your client.',
                  style: TextStyle(
                    color: AppTheme.lightGrey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: DesignTokens.space16),

                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement coach notes functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coach notes feature coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Coach Notes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(String locale) {
    if (widget.isReadOnly) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(
            color: AppTheme.mediumGrey.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          // Input field
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              border: Border.all(
                color: _isTyping
                  ? AppTheme.accentGreen
                  : AppTheme.mediumGrey.withOpacity(0.3),
                width: _isTyping ? 2 : 1,
              ),
            ),
            child: TextFormField(
              controller: _commentController,
              focusNode: _commentFocus,
              maxLines: null,
              minLines: 1,
              style: const TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: widget.userRole == 'client'
                  ? LocaleHelper.t('add_your_notes', locale)
                  : LocaleHelper.t('add_instructions', locale),
                hintStyle: const TextStyle(
                  color: AppTheme.lightGrey,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(DesignTokens.space16),
              ),
            ),
          ),

          // Action buttons
          if (_hasUnsavedChanges) ...[
            const SizedBox(height: DesignTokens.space12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _discardChanges,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.lightGrey,
                    ),
                    child: Text(LocaleHelper.t('discard', locale)),
                  ),
                ),
                const SizedBox(width: DesignTokens.space8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _saveComment,
                    icon: const Icon(Icons.save),
                    label: Text(LocaleHelper.t('save', locale)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: AppTheme.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Character counter (if typing)
          if (_isTyping) ...[
            const SizedBox(height: DesignTokens.space8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_commentController.text.length}/500',
                style: TextStyle(
                  color: _commentController.text.length > 500
                    ? Colors.red
                    : AppTheme.lightGrey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _getMealTips() {
    // Return contextual tips based on meal type
    final mealName = widget.meal.label.toLowerCase();

    if (mealName.contains('breakfast')) {
      return [
        'Start your day with protein to stabilize blood sugar',
        'Include healthy fats for sustained energy',
        'Consider drinking water before eating',
      ];
    } else if (mealName.contains('lunch')) {
      return [
        'Balance your plate with protein, carbs, and vegetables',
        'Eat mindfully and chew slowly',
        'Stay hydrated throughout the day',
      ];
    } else if (mealName.contains('dinner')) {
      return [
        'Eat dinner 2-3 hours before bedtime',
        'Focus on lighter proteins in the evening',
        'Include plenty of vegetables',
      ];
    } else {
      return [
        'Choose nutrient-dense snacks',
        'Consider the timing around workouts',
        'Stay within your daily calorie goals',
      ];
    }
  }
}