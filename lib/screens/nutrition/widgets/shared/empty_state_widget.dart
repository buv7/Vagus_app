import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../widgets/supplements/pill_icon.dart';

/// Delightful empty state widgets for various nutrition contexts
class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final String? customTitle;
  final String? customSubtitle;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final bool showAnimation;

  const EmptyStateWidget({
    super.key,
    required this.type,
    this.customTitle,
    this.customSubtitle,
    this.onActionPressed,
    this.actionLabel,
    this.showAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final config = _getConfigForType(type, context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: showAnimation ? value : 1.0,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: config.backgroundColor,
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(
                        color: config.borderColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: config.iconColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: type == EmptyStateType.noSupplements
                        ? const PillIcon(size: 48)
                        : Icon(
                            config.icon,
                            size: 48,
                            color: config.iconColor,
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: DesignTokens.space24),

            // Title
            Text(
              customTitle ?? config.title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: DesignTokens.space12),

            // Subtitle
            Text(
              customSubtitle ?? config.subtitle,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: DesignTokens.space32),

            // Action button
            if (onActionPressed != null)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 280),
                child: ElevatedButton.icon(
                  onPressed: onActionPressed,
                  icon: Icon(config.actionIcon),
                  label: Text(actionLabel ?? config.actionLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: config.actionColor,
                    foregroundColor: isDark ? AppTheme.primaryDark : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space16,
                      horizontal: DesignTokens.space24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    ),
                    elevation: 8,
                    shadowColor: config.actionColor.withValues(alpha: 0.3),
                  ),
                ),
              ),

            // Additional hints
            if (config.hints.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.space24),
              Container(
                padding: const EdgeInsets.all(DesignTokens.space16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? AppTheme.cardBackground.withValues(alpha: 0.5)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: config.hints.map((hint) => Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.space8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: DesignTokens.space8),
                        Expanded(
                          child: Text(
                            hint,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _EmptyStateConfig _getConfigForType(EmptyStateType type, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.cardBackground : theme.colorScheme.surfaceContainerHighest;
    final primaryColor = theme.colorScheme.primary;
    
    switch (type) {
      case EmptyStateType.noMeals:
        return _EmptyStateConfig(
          icon: Icons.restaurant_menu,
          iconColor: primaryColor,
          backgroundColor: cardBg,
          borderColor: primaryColor.withValues(alpha: 0.3),
          title: 'No Meals Added',
          subtitle: 'Start building your nutrition plan by adding meals',
          actionLabel: 'Add First Meal',
          actionIcon: Icons.add_circle_outline,
          actionColor: primaryColor,
          hints: [
            'Use AI to generate a complete day',
            'Browse the recipe library',
            'Add individual food items',
          ],
        );

      case EmptyStateType.noFoodItems:
        return _EmptyStateConfig(
          icon: Icons.fastfood,
          iconColor: AppTheme.accentOrange,
          backgroundColor: cardBg,
          borderColor: AppTheme.accentOrange.withValues(alpha: 0.3),
          title: 'Empty Meal',
          subtitle: 'Add food items to complete this meal',
          actionLabel: 'Add Food Items',
          actionIcon: Icons.add,
          actionColor: AppTheme.accentOrange,
          hints: [
            'Search from our food database',
            'Scan barcodes for quick entry',
            'Create custom food items',
          ],
        );

      case EmptyStateType.noRecipes:
        return _EmptyStateConfig(
          icon: Icons.menu_book,
          iconColor: Colors.blue,
          backgroundColor: cardBg,
          borderColor: Colors.blue.withValues(alpha: 0.3),
          title: 'No Recipes Found',
          subtitle: 'Discover delicious recipes that match your goals',
          actionLabel: 'Browse Recipes',
          actionIcon: Icons.search,
          actionColor: Colors.blue,
          hints: [
            'Filter by dietary preferences',
            'Search by ingredients',
            'Save favorites for quick access',
          ],
        );

      case EmptyStateType.noSupplements:
        return _EmptyStateConfig(
          icon: Icons.medication,
          iconColor: Colors.purple,
          backgroundColor: cardBg,
          borderColor: Colors.purple.withValues(alpha: 0.3),
          title: 'No Supplements',
          subtitle: 'Track supplements to optimize your nutrition',
          actionLabel: 'Add Supplement',
          actionIcon: Icons.add_box,
          actionColor: Colors.purple,
          hints: [
            'Set dosage and timing',
            'Add reminders',
            'Track adherence',
          ],
        );

      case EmptyStateType.noPantryItems:
        return _EmptyStateConfig(
          icon: Icons.kitchen,
          iconColor: Colors.brown,
          backgroundColor: cardBg,
          borderColor: Colors.brown.withValues(alpha: 0.3),
          title: 'Empty Pantry',
          subtitle: 'Add items to your pantry for smart meal planning',
          actionLabel: 'Stock Pantry',
          actionIcon: Icons.add_shopping_cart,
          actionColor: Colors.brown,
          hints: [
            'Track expiration dates',
            'Get recipe suggestions',
            'Generate shopping lists',
          ],
        );

      case EmptyStateType.noPlans:
        return _EmptyStateConfig(
          icon: Icons.assignment,
          iconColor: primaryColor,
          backgroundColor: cardBg,
          borderColor: primaryColor.withValues(alpha: 0.3),
          title: 'No Nutrition Plans',
          subtitle: 'Create your first nutrition plan to get started',
          actionLabel: 'Create Plan',
          actionIcon: Icons.add_circle,
          actionColor: primaryColor,
          hints: [
            'Set macro targets',
            'Plan multiple days',
            'Share with clients',
          ],
        );

      case EmptyStateType.searchResults:
        return _EmptyStateConfig(
          icon: Icons.search_off,
          iconColor: theme.colorScheme.onSurfaceVariant,
          backgroundColor: cardBg,
          borderColor: theme.colorScheme.outline.withValues(alpha: 0.3),
          title: 'No Results Found',
          subtitle: 'Try adjusting your search terms or filters',
          actionLabel: 'Clear Search',
          actionIcon: Icons.clear,
          actionColor: theme.colorScheme.onSurfaceVariant,
          hints: [
            'Check spelling',
            'Use fewer filters',
            'Try broader terms',
          ],
        );

      case EmptyStateType.offline:
        return _EmptyStateConfig(
          icon: Icons.cloud_off,
          iconColor: Colors.orange,
          backgroundColor: cardBg,
          borderColor: Colors.orange.withValues(alpha: 0.3),
          title: 'Offline Mode',
          subtitle: 'Some features are limited without internet connection',
          actionLabel: 'Retry Connection',
          actionIcon: Icons.refresh,
          actionColor: Colors.orange,
          hints: [
            'Check your internet connection',
            'Previously loaded data is still available',
            'Changes will sync when online',
          ],
        );
    }
  }
}

enum EmptyStateType {
  noMeals,
  noFoodItems,
  noRecipes,
  noSupplements,
  noPantryItems,
  noPlans,
  searchResults,
  offline,
}

class _EmptyStateConfig {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData actionIcon;
  final Color actionColor;
  final List<String> hints;

  _EmptyStateConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionIcon,
    required this.actionColor,
    this.hints = const [],
  });
}

/// Animated loading state for nutrition content
class NutritionLoadingWidget extends StatefulWidget {
  final String? message;
  final bool showProgress;
  final double? progress;

  const NutritionLoadingWidget({
    super.key,
    this.message,
    this.showProgress = false,
    this.progress,
  });

  @override
  State<NutritionLoadingWidget> createState() => _NutritionLoadingWidgetState();
}

class _NutritionLoadingWidgetState extends State<NutritionLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animation.value * 2 * 3.14159,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.3),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: theme.colorScheme.onPrimary,
                    size: 32,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: DesignTokens.space24),

          if (widget.message != null)
            Text(
              widget.message!,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

          if (widget.showProgress && widget.progress != null) ...[
            const SizedBox(height: DesignTokens.space16),
            Container(
              width: 200,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widget.progress!.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              '${(widget.progress! * 100).round()}%',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}