import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/nutrition/recipe.dart';
import '../../models/nutrition/money.dart';
import '../../theme/design_tokens.dart';
import 'pantry_match_chip.dart';
import 'cost_chip.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final bool isSelected;
  final bool showSelectionIndicator;
  final bool isCompact;
  final double? pantryCoverage; // 0.0 to 1.0
  final Money? costPerServing;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.isSelected = false,
    this.showSelectionIndicator = false,
    this.isCompact = false,
    this.pantryCoverage,
    this.costPerServing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radius20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DesignTokens.blurMd, sigmaY: DesignTokens.blurMd),
        child: Container(
          decoration: BoxDecoration(
            color: DesignTokens.cardBackground,
            borderRadius: BorderRadius.circular(DesignTokens.radius20),
            border: Border.all(
              color: isSelected ? DesignTokens.accentGreen : DesignTokens.glassBorder,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? DesignTokens.glowSm
                : DesignTokens.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(DesignTokens.radius20),
              child: isCompact ? _buildCompactCard(context, theme, isDark) : _buildFullCard(context, theme, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullCard(BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Image
        _buildHeroImage(context, theme, isDark),
        
        // Content
        Padding(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Favorite
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onFavorite != null)
                    IconButton(
                      onPressed: onFavorite,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              
              const SizedBox(height: DesignTokens.space8),
              
              // Summary
              if (recipe.summary != null && recipe.summary!.isNotEmpty)
                Text(
                  recipe.summary!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const SizedBox(height: DesignTokens.space12),
              
              // Nutrition and Time Chips
              _buildNutritionAndTimeChips(theme),
              
              const SizedBox(height: DesignTokens.space12),
              
              // Tags
              if (recipe.cuisineTags.isNotEmpty || recipe.dietTags.isNotEmpty)
                _buildTags(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCard(BuildContext context, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space12),
      child: Row(
        children: [
          // Compact Image
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
            child: _buildImageWidget(context, 60, 60),
          ),
          
          const SizedBox(width: DesignTokens.space12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: DesignTokens.space4),
                
                _buildCompactNutritionChips(theme),
              ],
            ),
          ),
          
          // Selection indicator
          if (showSelectionIndicator)
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, ThemeData theme, bool isDark) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(DesignTokens.radius16),
        topRight: Radius.circular(DesignTokens.radius16),
      ),
      child: Stack(
        children: [
          _buildImageWidget(context, double.infinity, 200),
          
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    DesignTokens.primaryDark.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          
          // Halal indicator
          if (recipe.halal)
            Positioned(
              top: DesignTokens.space8,
              right: DesignTokens.space8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space8,
                  vertical: DesignTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.accentGreen,
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.accentGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Text(
                  'HALAL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          // Quick recipe indicator
          if (recipe.totalMinutes < 20)
            Positioned(
              top: DesignTokens.space8,
              left: DesignTokens.space8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space8,
                  vertical: DesignTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.accentOrange,
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.accentOrange.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.flash_on,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: DesignTokens.space4),
                    Text(
                      '${recipe.totalMinutes}m',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context, double width, double height) {
    if (recipe.photoUrl != null && recipe.photoUrl!.isNotEmpty) {
      return Image.network(
        recipe.photoUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(context, width, height),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingImage(context, width, height);
        },
      );
    }
    return _buildPlaceholderImage(context, width, height);
  }

  Widget _buildPlaceholderImage(BuildContext context, double width, double height) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.restaurant,
        size: width * 0.3,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildLoadingImage(BuildContext context, double width, double height) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionAndTimeChips(ThemeData theme) {
    return Wrap(
      spacing: DesignTokens.space8,
      runSpacing: DesignTokens.space4,
      children: [
        // Calories chip
        _buildChip(
          theme,
          '${recipe.calories.round()} kcal',
          Icons.local_fire_department,
          DesignTokens.accentOrange,
        ),

        // Protein chip
        _buildChip(
          theme,
          '${recipe.protein.toStringAsFixed(1)}g protein',
          Icons.fitness_center,
          DesignTokens.accentBlue,
        ),

        // Time chip
        _buildChip(
          theme,
          '${recipe.totalMinutes}m',
          Icons.access_time,
          DesignTokens.textSecondary,
        ),
        
        // Pantry coverage chip
        if (pantryCoverage != null)
          PantryMatchChip(ratio: pantryCoverage!),
        
        // Cost chip
        if (costPerServing != null)
          CostChip(costPerServing: costPerServing!, compact: isCompact),
      ],
    );
  }

  Widget _buildCompactNutritionChips(ThemeData theme) {
    return Wrap(
      spacing: DesignTokens.space4,
      children: [
        _buildCompactChip(
          theme,
          '${recipe.calories.round()} kcal',
          DesignTokens.accentOrange,
        ),
        _buildCompactChip(
          theme,
          '${recipe.totalMinutes}m',
          DesignTokens.textSecondary,
        ),
        // Pantry coverage badge (compact)
        if (pantryCoverage != null)
          PantryMatchBadge(ratio: pantryCoverage!),
      ],
    );
  }

  Widget _buildChip(ThemeData theme, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space8,
        vertical: DesignTokens.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: DesignTokens.space4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactChip(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space6,
        vertical: DesignTokens.space2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTags(ThemeData theme) {
    final allTags = [...recipe.cuisineTags, ...recipe.dietTags];
    if (allTags.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: DesignTokens.space4,
      runSpacing: DesignTokens.space4,
      children: allTags.take(3).map((tag) => _buildTag(theme, tag)).toList(),
    );
  }

  Widget _buildTag(ThemeData theme, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space8,
        vertical: DesignTokens.space4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
      ),
      child: Text(
        tag,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
