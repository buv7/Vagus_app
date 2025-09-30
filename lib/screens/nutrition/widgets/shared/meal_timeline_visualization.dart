import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../models/nutrition/nutrition_plan.dart';
import '../../../../services/haptics.dart';
import '../../../../services/nutrition/locale_helper.dart';
import 'nutrition_card.dart';

/// Stunning vertical timeline with drag-and-drop meal reordering
/// Features: Time markers, meal cards with photos, swipe actions
class MealTimelineVisualization extends StatefulWidget {
  final List<Meal> meals;
  final Function(List<Meal>)? onMealsReordered;
  final Function(int)? onMealTapped;
  final Function(int)? onMealEdit;
  final Function(int)? onMealDuplicate;
  final Function(int)? onMealDelete;
  final VoidCallback? onAddMeal;
  final bool isReadOnly;

  const MealTimelineVisualization({
    super.key,
    required this.meals,
    this.onMealsReordered,
    this.onMealTapped,
    this.onMealEdit,
    this.onMealDuplicate,
    this.onMealDelete,
    this.onAddMeal,
    this.isReadOnly = false,
  });

  @override
  State<MealTimelineVisualization> createState() =>
      _MealTimelineVisualizationState();
}

class _MealTimelineVisualizationState extends State<MealTimelineVisualization>
    with TickerProviderStateMixin {
  late List<Meal> _meals;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  int? _draggedIndex;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _meals = List.from(widget.meals);
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(MealTimelineVisualization oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meals.length != widget.meals.length) {
      _meals = List.from(widget.meals);
      _initializeAnimations();
    }
  }

  void _initializeAnimations() {
    // Dispose old controllers
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers = [];
    _animations = [];

    // Create new controllers
    for (int i = 0; i < _meals.length; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 300 + (i * 100)),
        vsync: this,
      );

      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
      );

      _controllers.add(controller);
      _animations.add(animation);

      // Stagger animations
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              LocaleHelper.t('meal_timeline', locale),
              style: const TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (!widget.isReadOnly)
              Text(
                LocaleHelper.t('drag_to_reorder', locale),
                style: TextStyle(
                  color: AppTheme.lightGrey.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
          ],
        ),

        const SizedBox(height: DesignTokens.space20),

        // Timeline
        if (_meals.isEmpty)
          _buildEmptyTimeline(locale)
        else
          _buildTimeline(),

        // Add meal button
        if (!widget.isReadOnly) ...[
          const SizedBox(height: DesignTokens.space20),
          _buildAddMealButton(locale),
        ],
      ],
    );
  }

  Widget _buildEmptyTimeline(String locale) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: AppTheme.mediumGrey.withOpacity(0.3),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 48,
              color: AppTheme.lightGrey.withOpacity(0.5),
            ),
            const SizedBox(height: DesignTokens.space12),
            Text(
              LocaleHelper.t('no_meals_scheduled', locale),
              style: TextStyle(
                color: AppTheme.lightGrey.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              LocaleHelper.t('add_first_meal', locale),
              style: TextStyle(
                color: AppTheme.lightGrey.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      constraints: BoxConstraints(
        minHeight: (_meals.length * 120.0) + 100,
      ),
      child: Stack(
        children: [
          // Timeline line
          Positioned(
            left: 40,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.accentGreen.withOpacity(0.8),
                    AppTheme.accentGreen.withOpacity(0.3),
                    AppTheme.accentGreen.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),

          // Time markers and meals
          Column(
            children: [
              for (int i = 0; i < _meals.length; i++) ...[
                _buildTimeMarker(i),
                const SizedBox(height: DesignTokens.space8),
                _buildMealCard(i),
                if (i < _meals.length - 1)
                  const SizedBox(height: DesignTokens.space20),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeMarker(int index) {
    final time = _getMealTime(index);

    return Row(
      children: [
        // Time badge
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space8,
            vertical: DesignTokens.space4,
          ),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: Border.all(
              color: AppTheme.accentGreen.withOpacity(0.3),
            ),
          ),
          child: Text(
            time,
            style: const TextStyle(
              color: AppTheme.accentGreen,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(width: DesignTokens.space12),

        // Timeline dot
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.accentGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGreen.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),

        // Connecting line to card
        Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentGreen.withOpacity(0.5),
                  AppTheme.accentGreen.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(int index) {
    if (index >= _animations.length) {
      return _buildStaticMealCard(index);
    }

    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(100 * (1 - _animations[index].value), 0),
          child: Opacity(
            opacity: _animations[index].value,
            child: _buildInteractiveMealCard(index),
          ),
        );
      },
    );
  }

  Widget _buildInteractiveMealCard(int index) {
    final meal = _meals[index];
    final isDragged = _draggedIndex == index;
    final isHovered = _hoveredIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()
        ..scale(isDragged ? 1.05 : (isHovered ? 1.02 : 1.0)),
      child: widget.isReadOnly
        ? _buildMealCardContent(meal, index)
        : LongPressDraggable<int>(
            data: index,
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(DesignTokens.radius16),
              child: Container(
                width: MediaQuery.of(context).size.width - 150,
                child: _buildMealCardContent(meal, index, isDragging: true),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: _buildMealCardContent(meal, index),
            ),
            onDragStarted: () {
              setState(() => _draggedIndex = index);
              Haptics.impact();
            },
            onDragEnd: (_) {
              setState(() => _draggedIndex = null);
            },
            child: DragTarget<int>(
              onWillAccept: (data) => data != index,
              onAccept: (fromIndex) {
                _reorderMeals(fromIndex, index);
              },
              onMove: (_) {
                if (_hoveredIndex != index) {
                  setState(() => _hoveredIndex = index);
                }
              },
              onLeave: (_) {
                setState(() => _hoveredIndex = null);
              },
              builder: (context, candidateData, rejectedData) {
                return _buildMealCardContent(meal, index);
              },
            ),
          ),
    );
  }

  Widget _buildStaticMealCard(int index) {
    return _buildMealCardContent(_meals[index], index);
  }

  Widget _buildMealCardContent(Meal meal, int index, {bool isDragging = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 92),
      child: Dismissible(
        key: Key('meal_$index'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: DesignTokens.space16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.8),
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 24,
          ),
        ),
        confirmDismiss: widget.isReadOnly
          ? (_) async => false
          : (direction) async => await _showDeleteConfirmation(meal.label),
        onDismissed: (direction) {
          widget.onMealDelete?.call(index);
        },
        child: GestureDetector(
          onTap: () {
            Haptics.tap();
            widget.onMealTapped?.call(index);
          },
          child: NutritionCard(
            highlighted: isDragging,
            child: Row(
              children: [
                // Food photo or icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getMealTypeColor(meal.label).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    child: meal.attachments.isNotEmpty
                      ? Image.network(
                          meal.attachments.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildMealIcon(meal.label),
                        )
                      : _buildMealIcon(meal.label),
                  ),
                ),

                const SizedBox(width: DesignTokens.space12),

                // Meal info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meal name
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              meal.label,
                              style: const TextStyle(
                                color: AppTheme.neutralWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (meal.clientComment.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.space6,
                                vertical: DesignTokens.space2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(DesignTokens.radius8),
                              ),
                              child: const Icon(
                                Icons.comment,
                                size: 12,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: DesignTokens.space4),

                      // Time and completion
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.lightGrey,
                          ),
                          const SizedBox(width: DesignTokens.space4),
                          Text(
                            _getMealTime(index),
                            style: const TextStyle(
                              color: AppTheme.lightGrey,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          _buildCompletionBadge(),
                        ],
                      ),

                      const SizedBox(height: DesignTokens.space8),

                      // Macro chips
                      Row(
                        children: [
                          _buildMacroChip(
                            '🔥',
                            '${meal.mealSummary.totalKcal.toStringAsFixed(0)}',
                            'kcal',
                            Colors.red,
                          ),
                          const SizedBox(width: DesignTokens.space6),
                          _buildMacroChip(
                            '💪',
                            '${meal.mealSummary.totalProtein.toStringAsFixed(0)}g',
                            'P',
                            const Color(0xFF00D9A3),
                          ),
                          const SizedBox(width: DesignTokens.space6),
                          _buildMacroChip(
                            '🍞',
                            '${meal.mealSummary.totalCarbs.toStringAsFixed(0)}g',
                            'C',
                            const Color(0xFFFF9A3C),
                          ),
                          const SizedBox(width: DesignTokens.space6),
                          _buildMacroChip(
                            '🥑',
                            '${meal.mealSummary.totalFat.toStringAsFixed(0)}g',
                            'F',
                            const Color(0xFFFFD93C),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                if (!widget.isReadOnly)
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppTheme.lightGrey,
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case 'edit':
                          widget.onMealEdit?.call(index);
                          break;
                        case 'duplicate':
                          widget.onMealDuplicate?.call(index);
                          break;
                        case 'delete':
                          widget.onMealDelete?.call(index);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 16),
                            SizedBox(width: 8),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealIcon(String mealLabel) {
    final color = _getMealTypeColor(mealLabel);
    final icon = _getMealTypeIcon(mealLabel);

    return Icon(
      icon,
      color: color,
      size: 28,
    );
  }

  Widget _buildMacroChip(String emoji, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space6,
        vertical: DesignTokens.space2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: DesignTokens.space2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBadge() {
    // This would be dynamic based on actual completion status
    final isCompleted = false; // Placeholder

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: isCompleted ? AppTheme.accentGreen : AppTheme.mediumGrey.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted ? AppTheme.accentGreen : AppTheme.mediumGrey,
          width: 2,
        ),
      ),
      child: isCompleted
        ? const Icon(
            Icons.check,
            size: 10,
            color: Colors.white,
          )
        : null,
    );
  }

  Widget _buildAddMealButton(String locale) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onAddMeal,
        icon: const Icon(Icons.add_circle_outline),
        label: Text(LocaleHelper.t('add_meal', locale)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentGreen.withOpacity(0.1),
          foregroundColor: AppTheme.accentGreen,
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            side: BorderSide(
              color: AppTheme.accentGreen.withOpacity(0.3),
            ),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _reorderMeals(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;

    setState(() {
      final meal = _meals.removeAt(fromIndex);
      _meals.insert(toIndex, meal);
    });

    widget.onMealsReordered?.call(_meals);
    Haptics.success();
  }

  Future<bool> _showDeleteConfirmation(String mealName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to delete "$mealName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  String _getMealTime(int index) {
    final times = ['7:00 AM', '10:00 AM', '12:30 PM', '3:00 PM', '7:00 PM', '9:00 PM'];
    return index < times.length ? times[index] : 'Anytime';
  }

  Color _getMealTypeColor(String mealLabel) {
    final name = mealLabel.toLowerCase();
    if (name.contains('breakfast')) return Colors.orange;
    if (name.contains('lunch')) return Colors.green;
    if (name.contains('dinner')) return Colors.purple;
    if (name.contains('snack')) return Colors.blue;
    return AppTheme.accentGreen;
  }

  IconData _getMealTypeIcon(String mealLabel) {
    final name = mealLabel.toLowerCase();
    if (name.contains('breakfast')) return Icons.wb_sunny;
    if (name.contains('lunch')) return Icons.wb_sunny_outlined;
    if (name.contains('dinner')) return Icons.nightlight_round;
    if (name.contains('snack')) return Icons.cookie;
    return Icons.restaurant_menu;
  }
}