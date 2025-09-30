import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/nutrition/nutrition_plan.dart';

/// Compact, tappable card for displaying a food item in a list
/// Replaces the cramped horizontal scrolling row with a clean glassmorphism design
class FoodItemCard extends StatelessWidget {
  final FoodItem foodItem;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool showTargetMacros;

  const FoodItemCard({
    super.key,
    required this.foodItem,
    required this.onTap,
    required this.onDelete,
    this.showTargetMacros = false,
  });

  @override
  Widget build(BuildContext context) {
    final calories = _calculateCalories(
      foodItem.protein,
      foodItem.carbs,
      foodItem.fat,
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A3A3A).withValues(alpha: 0.6),
            const Color(0xFF0D2626).withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Food name + Delete button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        foodItem.name,
                        style: const TextStyle(
                          color: AppTheme.neutralWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onDelete();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Macro chips in Wrap layout (no horizontal scrolling)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMacroChip(
                      emoji: '💪',
                      label: 'Protein',
                      value: '${foodItem.protein.toStringAsFixed(1)}g',
                      color: const Color(0xFF00D9A3),
                    ),
                    _buildMacroChip(
                      emoji: '🍞',
                      label: 'Carbs',
                      value: '${foodItem.carbs.toStringAsFixed(1)}g',
                      color: const Color(0xFFFF9A3C),
                    ),
                    _buildMacroChip(
                      emoji: '🥑',
                      label: 'Fat',
                      value: '${foodItem.fat.toStringAsFixed(1)}g',
                      color: const Color(0xFFFFD93C),
                    ),
                    _buildMacroChip(
                      emoji: '🔥',
                      label: 'Calories',
                      value: '${calories.toInt()} kcal',
                      color: Colors.white.withValues(alpha: 0.54),
                    ),
                    // Show sodium if it exists and has a value
                    if (foodItem.sodium > 0)
                      _buildMacroChip(
                        emoji: '🧂',
                        label: 'Sodium',
                        value: '${(foodItem.sodium * 1000).toInt()}mg',
                        color: Colors.blueGrey,
                      ),
                    // Show potassium if it exists and has a value
                    if (foodItem.potassium > 0)
                      _buildMacroChip(
                        emoji: '🍌',
                        label: 'Potassium',
                        value: '${(foodItem.potassium * 1000).toInt()}mg',
                        color: Colors.orange.shade300,
                      ),
                  ],
                ),

                // Show amount if available
                if (foodItem.amount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.scale,
                          color: Colors.white38,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${foodItem.amount.toStringAsFixed(0)}g serving',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Optional target macros display (removed - field not in model)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroChip({
    required String emoji,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateCalories(double protein, double carbs, double fat) {
    return (protein * 4) + (carbs * 4) + (fat * 9);
  }
}