import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/nutrition/nutrition_plan.dart';
import '../../theme/nutrition_colors.dart';
import '../../theme/nutrition_spacing.dart';

/// A beautiful glassmorphic card displaying a meal in timeline format.
///
/// Supports both coach and client modes with different interactions:
/// - Coach mode: Swipe actions for duplicate/delete
/// - Client mode: Checkbox for meal completion tracking
///
/// Features:
/// - Meal photo or type icon
/// - Time and meal type badges
/// - Macro chips with emoji indicators
/// - Smooth glassmorphism effect
/// - Dismissible swipe actions
///
/// Example:
/// ```dart
/// MealTimelineCard(
///   meal: myMeal,
///   isCoachMode: false,
///   onTap: () => viewMealDetails(),
///   onCheckIn: (checked) => logMealCompletion(checked),
/// )
/// ```
class MealTimelineCard extends StatelessWidget {
  /// The meal to display
  final Meal meal;

  /// Whether to show coach-specific features (swipe actions)
  final bool isCoachMode;

  /// Callback when card is tapped
  final VoidCallback onTap;

  /// Callback when edit is triggered (coach mode)
  final VoidCallback? onEdit;

  /// Callback when delete is triggered (coach mode)
  final VoidCallback? onDelete;

  /// Callback when duplicate is triggered (coach mode)
  final VoidCallback? onDuplicate;

  /// Callback when meal is checked in/out (client mode)
  final Function(bool)? onCheckIn;

  const MealTimelineCard({
    super.key,
    required this.meal,
    required this.isCoachMode,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(meal.label), // TODO: Use meal.id when added to Meal model
      direction: isCoachMode
          ? DismissDirection.horizontal
          : DismissDirection.none,
      background: _buildSwipeBackground(
        Colors.blue,
        Icons.copy,
        Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        Colors.red,
        Icons.delete,
        Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onDuplicate?.call();
        } else {
          onDelete?.call();
        }
        return false; // Don't actually dismiss
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: NutritionSpacing.sm,
            horizontal: NutritionSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NutritionColors.cardGradientStart.withValues(alpha: 0.8),
                NutritionColors.cardGradientEnd.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: NutritionColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(NutritionSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meal photo or icon
                    _buildMealImage(),
                    const SizedBox(width: NutritionSpacing.md),
                    // Meal details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  meal.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isCoachMode)
                                Checkbox(
                                  value: false, // TODO: Add checkedInAt to Meal model
                                  onChanged: (value) {
                                    if (value != null) {
                                      onCheckIn?.call(value);
                                    }
                                  },
                                  activeColor: NutritionColors.success,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildBadge(
                                Icons.access_time,
                                _formatTime(DateTime.now()), // TODO: Use meal.createdAt
                              ),
                              const SizedBox(width: NutritionSpacing.sm),
                              _buildBadge(
                                _getMealTypeIcon('meal'), // TODO: Use meal.mealType
                                meal.label,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Macro chips
                          Wrap(
                            spacing: NutritionSpacing.sm,
                            runSpacing: 4,
                            children: [
                              _buildMacroChip(
                                '🔥',
                                '${_calculateTotalCalories()} kcal',
                                NutritionColors.calories,
                              ),
                              _buildMacroChip(
                                '💪',
                                '${_calculateTotalProtein()}g P',
                                NutritionColors.protein,
                              ),
                              _buildMacroChip(
                                '🍞',
                                '${_calculateTotalCarbs()}g C',
                                NutritionColors.carbs,
                              ),
                              _buildMacroChip(
                                '🥑',
                                '${_calculateTotalFat()}g F',
                                NutritionColors.fat,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealImage() {
    // TODO: Add photo_url field to Meal model when implementing meal photos
    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getMealTypeIcon('meal'), // TODO: Use meal.mealType when added
        color: Colors.white.withValues(alpha: 0.6),
        size: 40,
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$emoji $text',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white, size: 32),
    );
  }

  IconData _getMealTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.fastfood;
      default:
        return Icons.restaurant;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  int _calculateTotalCalories() {
    // TODO: Implement when Meal model includes items with macros
    return 0;
  }

  int _calculateTotalProtein() {
    // TODO: Implement when Meal model includes items with macros
    return 0;
  }

  int _calculateTotalCarbs() {
    // TODO: Implement when Meal model includes items with macros
    return 0;
  }

  int _calculateTotalFat() {
    // TODO: Implement when Meal model includes items with macros
    return 0;
  }
}