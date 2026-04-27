import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';

/// Consistent card design for all nutrition components
/// Provides glassmorphism effect with high contrast for the dark theme
class NutritionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool highlighted;
  final Color? customBackgroundColor;
  final double? customBorderRadius;
  final List<BoxShadow>? customShadows;

  const NutritionCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.highlighted = false,
    this.customBackgroundColor,
    this.customBorderRadius,
    this.customShadows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final defaultBackground = isDark 
        ? AppTheme.cardBackground 
        : theme.colorScheme.surfaceContainerHighest;
    final highlightedBackground = isDark
        ? AppTheme.accentGreen.withValues(alpha: 0.1)
        : theme.colorScheme.primary.withValues(alpha: 0.1);
    final borderColor = highlighted
        ? (isDark ? AppTheme.accentGreen : theme.colorScheme.primary).withValues(alpha: 0.3)
        : theme.colorScheme.outline.withValues(alpha: 0.2);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(DesignTokens.space16),
        decoration: BoxDecoration(
          color: customBackgroundColor ?? (highlighted
            ? highlightedBackground
            : defaultBackground),
          borderRadius: BorderRadius.circular(
            customBorderRadius ?? DesignTokens.radius16,
          ),
          border: Border.all(
            color: borderColor,
            width: highlighted ? 2 : 1,
          ),
          boxShadow: customShadows ?? [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            if (highlighted)
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Specialized card for meal items
class MealCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isCompleted;
  final bool hasAttachments;
  final bool hasComments;
  final int itemCount;

  const MealCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.isCompleted = false,
    this.hasAttachments = false,
    this.hasComments = false,
    this.itemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return NutritionCard(
      onTap: onTap,
      highlighted: isCompleted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Meal type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getMealTypeColor(title).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Icon(
                  _getMealTypeIcon(title),
                  color: _getMealTypeColor(title),
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
                            title,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.space8,
                              vertical: DesignTokens.space4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(DesignTokens.radius12),
                            ),
                            child: Text(
                              'Completed',
                              style: TextStyle(
                                color: isDark ? AppTheme.primaryDark : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              if (trailing != null) trailing!,
            ],
          ),

          // Meal metadata
          if (itemCount > 0 || hasAttachments || hasComments) ...[
            const SizedBox(height: DesignTokens.space12),
            Row(
              children: [
                if (itemCount > 0) ...[
                  _buildMetadataChip(
                    Icons.restaurant_menu,
                    '$itemCount items',
                    AppTheme.accentOrange,
                  ),
                  const SizedBox(width: DesignTokens.space8),
                ],
                if (hasAttachments) ...[
                  _buildMetadataChip(
                    Icons.attach_file,
                    'Photos',
                    Colors.blue,
                  ),
                  const SizedBox(width: DesignTokens.space8),
                ],
                if (hasComments) ...[
                  _buildMetadataChip(
                    Icons.comment,
                    'Notes',
                    Colors.purple,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space8,
        vertical: DesignTokens.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: DesignTokens.space4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMealTypeColor(String mealName) {
    final name = mealName.toLowerCase();
    if (name.contains('breakfast')) return Colors.orange;
    if (name.contains('lunch')) return Colors.green;
    if (name.contains('dinner')) return Colors.purple;
    if (name.contains('snack')) return Colors.blue;
    return AppTheme.accentGreen;
  }

  IconData _getMealTypeIcon(String mealName) {
    final name = mealName.toLowerCase();
    if (name.contains('breakfast')) return Icons.wb_sunny;
    if (name.contains('lunch')) return Icons.wb_sunny_outlined;
    if (name.contains('dinner')) return Icons.nightlight_round;
    if (name.contains('snack')) return Icons.cookie;
    return Icons.restaurant_menu;
  }
}

/// Interactive card for food items with macro visualization
class FoodItemCard extends StatelessWidget {
  final String name;
  final double amount;
  final String unit;
  final double protein;
  final double carbs;
  final double fat;
  final double kcal;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool isSelected;
  final bool isRecipe;
  final String? photoUrl;

  const FoodItemCard({
    super.key,
    required this.name,
    required this.amount,
    required this.unit,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.kcal,
    this.onTap,
    this.onRemove,
    this.isSelected = false,
    this.isRecipe = false,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return NutritionCard(
      onTap: onTap,
      highlighted: isSelected,
      padding: const EdgeInsets.all(DesignTokens.space12),
      child: Row(
        children: [
          // Food photo or icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
              border: Border.all(
                color: isRecipe
                  ? Colors.blue.withValues(alpha: 0.5)
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
              child: photoUrl != null && photoUrl!.isNotEmpty
                ? Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFoodIcon(context),
                  )
                : _buildFoodIcon(context),
            ),
          ),

          const SizedBox(width: DesignTokens.space12),

          // Food info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isRecipe)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.space6,
                          vertical: DesignTokens.space2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(DesignTokens.radius4),
                        ),
                        child: const Text(
                          'Recipe',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: DesignTokens.space4),

                // Amount and macros
                Text(
                  '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)}$unit • ${kcal.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: DesignTokens.space4),

                // Macro bars
                Row(
                  children: [
                    _buildMacroBar('P', protein, Colors.red),
                    const SizedBox(width: DesignTokens.space4),
                    _buildMacroBar('C', carbs, Colors.orange),
                    const SizedBox(width: DesignTokens.space4),
                    _buildMacroBar('F', fat, Colors.yellow),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodIcon(BuildContext context) {
    final theme = Theme.of(context);
    return Icon(
      isRecipe ? Icons.restaurant_menu : Icons.fastfood,
      color: isRecipe ? Colors.blue : theme.colorScheme.primary,
      size: 24,
    );
  }

  Widget _buildMacroBar(String label, double value, Color color) {
    return Expanded(
      child: Container(
        height: 16,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(DesignTokens.radius8),
        ),
        child: Center(
          child: Text(
            '$label ${value.toStringAsFixed(0)}g',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Summary card for displaying totals and insights
class SummaryCard extends StatelessWidget {
  final String title;
  final List<SummaryItem> items;
  final Widget? chart;
  final VoidCallback? onViewDetails;

  const SummaryCard({
    super.key,
    required this.title,
    required this.items,
    this.chart,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return NutritionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (onViewDetails != null)
                TextButton(
                  onPressed: onViewDetails,
                  child: Text(
                    'View Details',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
            ],
          ),

          const SizedBox(height: DesignTokens.space16),

          if (chart != null) ...[
            Center(child: chart!),
            const SizedBox(height: DesignTokens.space16),
          ],

          // Summary items
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: DesignTokens.space8),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  item.value,
                  style: TextStyle(
                    color: item.color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class SummaryItem {
  final String label;
  final String value;
  final Color color;

  SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });
}