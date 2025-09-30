import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/nutrition_colors.dart';
import '../theme/nutrition_spacing.dart';

/// Utility for building glassmorphic cards with consistent styling.
///
/// Provides helper methods to create beautiful frosted glass effect cards
/// used throughout the Nutrition Platform 2.0.
///
/// Example:
/// ```dart
/// GlassCardBuilder.build(
///   child: Text('Content'),
///   onTap: () => handleTap(),
/// )
/// ```
class GlassCardBuilder {
  // Prevent instantiation
  GlassCardBuilder._();

  // ============================================================
  // MAIN BUILDER METHOD
  // ============================================================

  /// Builds a glassmorphic card with default styling.
  ///
  /// Parameters:
  /// - [child]: The content widget to display inside the card
  /// - [padding]: Internal padding (defaults to standard card padding)
  /// - [margin]: External margin (defaults to standard card margin)
  /// - [onTap]: Optional tap callback
  /// - [borderRadius]: Corner radius (defaults to 16.0)
  /// - [opacity]: Glass effect opacity (0.0 to 1.0)
  /// - [blur]: Backdrop blur strength (sigmaX and sigmaY)
  /// - [gradient]: Custom gradient (overrides default)
  /// - [border]: Border color and width
  /// - [shadow]: Shadow configuration
  ///
  /// Example:
  /// ```dart
  /// GlassCardBuilder.build(
  ///   child: Column(
  ///     children: [
  ///       Text('Title'),
  ///       Text('Description'),
  ///     ],
  ///   ),
  ///   onTap: () => print('Tapped'),
  /// )
  /// ```
  static Widget build({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double borderRadius = NutritionSpacing.radiusLg,
    double opacity = 0.8,
    double blur = 10.0,
    Gradient? gradient,
    Border? border,
    List<BoxShadow>? shadow,
  }) {
    final content = Container(
      margin: margin ??
          const EdgeInsets.symmetric(
            vertical: NutritionSpacing.cardMargin,
            horizontal: NutritionSpacing.cardMargin,
          ),
      decoration: BoxDecoration(
        gradient: gradient ?? _defaultGradient(opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: NutritionColors.borderLight,
              width: 1,
            ),
        boxShadow: shadow ?? _defaultShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(NutritionSpacing.cardPadding),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }

  // ============================================================
  // PRESET BUILDERS
  // ============================================================

  /// Builds a compact glass card with reduced padding
  static Widget compact({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return build(
      child: child,
      padding: const EdgeInsets.all(NutritionSpacing.sm),
      margin: const EdgeInsets.symmetric(
        vertical: NutritionSpacing.xs,
        horizontal: NutritionSpacing.sm,
      ),
      onTap: onTap,
    );
  }

  /// Builds a full-width glass card (no horizontal margin)
  static Widget fullWidth({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return build(
      child: child,
      margin: const EdgeInsets.symmetric(
        vertical: NutritionSpacing.cardMargin,
      ),
      onTap: onTap,
    );
  }

  /// Builds a prominent glass card with stronger shadow
  static Widget prominent({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return build(
      child: child,
      shadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      onTap: onTap,
    );
  }

  /// Builds a subtle glass card with lighter appearance
  static Widget subtle({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return build(
      child: child,
      opacity: 0.6,
      blur: 5.0,
      shadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
      onTap: onTap,
    );
  }

  /// Builds a glass card with colored tint
  static Widget tinted({
    required Widget child,
    required Color tintColor,
    VoidCallback? onTap,
  }) {
    return build(
      child: child,
      gradient: LinearGradient(
        colors: [
          tintColor.withValues(alpha: 0.3),
          tintColor.withValues(alpha: 0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: onTap,
    );
  }

  // ============================================================
  // SPECIAL BUILDERS
  // ============================================================

  /// Builds a glass card for success states (green tint)
  static Widget success({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return tinted(
      child: child,
      tintColor: NutritionColors.success,
      onTap: onTap,
    );
  }

  /// Builds a glass card for warning states (yellow tint)
  static Widget warning({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return tinted(
      child: child,
      tintColor: NutritionColors.warning,
      onTap: onTap,
    );
  }

  /// Builds a glass card for error states (red tint)
  static Widget error({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return tinted(
      child: child,
      tintColor: NutritionColors.error,
      onTap: onTap,
    );
  }

  /// Builds a glass card for info states (blue tint)
  static Widget info({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return tinted(
      child: child,
      tintColor: NutritionColors.info,
      onTap: onTap,
    );
  }

  // ============================================================
  // CONTAINER BUILDERS
  // ============================================================

  /// Builds a glass card specifically for list items
  static Widget listItem({
    required Widget child,
    VoidCallback? onTap,
    bool showDivider = false,
  }) {
    return build(
      child: Column(
        children: [
          child,
          if (showDivider) ...[
            const SizedBox(height: NutritionSpacing.sm),
            Container(
              height: 1,
              color: NutritionColors.borderLight,
            ),
          ],
        ],
      ),
      padding: const EdgeInsets.all(NutritionSpacing.md),
      margin: const EdgeInsets.symmetric(
        vertical: NutritionSpacing.xs,
        horizontal: NutritionSpacing.md,
      ),
      onTap: onTap,
    );
  }

  /// Builds a glass card for modal dialogs
  static Widget modal({
    required Widget child,
    double maxWidth = 400,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: build(
          child: child,
          padding: const EdgeInsets.all(NutritionSpacing.lg),
          margin: const EdgeInsets.all(NutritionSpacing.lg),
          borderRadius: NutritionSpacing.radiusXl,
        ),
      ),
    );
  }

  /// Builds a glass card for bottom sheets
  static Widget bottomSheet({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: _defaultGradient(0.95),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(NutritionSpacing.radiusXl),
        ),
        border: const Border(
          top: BorderSide(
            color: NutritionColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(NutritionSpacing.radiusXl),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Padding(
            padding: const EdgeInsets.all(NutritionSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  static Gradient _defaultGradient(double opacity) {
    return LinearGradient(
      colors: [
        NutritionColors.cardGradientStart.withValues(alpha: opacity),
        NutritionColors.cardGradientEnd.withValues(alpha: opacity * 0.75),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static List<BoxShadow> _defaultShadow() {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }
}