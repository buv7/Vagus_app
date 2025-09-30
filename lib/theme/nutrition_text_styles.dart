import 'package:flutter/material.dart';

import 'nutrition_colors.dart';

/// Typography system for Nutrition Platform 2.0.
///
/// Provides consistent text styles across all nutrition features.
/// All styles respect the user's accessibility font scaling preferences.
///
/// Usage:
/// ```dart
/// Text(
///   '150g',
///   style: NutritionTextStyles.macroValue(context),
/// )
/// ```
class NutritionTextStyles {
  // Prevent instantiation
  NutritionTextStyles._();

  // ============================================================
  // MACRO DISPLAY STYLES
  // ============================================================

  /// Large numeric value for displaying macro amounts
  ///
  /// Features:
  /// - Tabular figures for alignment
  /// - Bold weight for emphasis
  /// - Large size for readability
  static TextStyle macroValue(BuildContext context) {
    return const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontFeatures: [FontFeature.tabularFigures()], // Monospace numbers
      height: 1.2,
    );
  }

  /// Small label for macro types (Protein, Carbs, Fat)
  static TextStyle macroLabel(BuildContext context) {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: NutritionColors.textSecondary,
      letterSpacing: 0.5,
      height: 1.3,
    );
  }

  /// Compact macro value for chips and badges
  static TextStyle macroChip(BuildContext context) {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFeatures: [FontFeature.tabularFigures()],
      height: 1.2,
    );
  }

  // ============================================================
  // HEADING STYLES
  // ============================================================

  /// Extra large heading (h1) - Screen titles
  static TextStyle h1(BuildContext context) {
    return const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }

  /// Large heading (h2) - Section titles
  static TextStyle h2(BuildContext context) {
    return const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      height: 1.3,
      letterSpacing: -0.3,
    );
  }

  /// Medium heading (h3) - Subsection titles
  static TextStyle h3(BuildContext context) {
    return const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.3,
    );
  }

  /// Small heading (h4) - Card titles
  static TextStyle h4(BuildContext context) {
    return const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.4,
    );
  }

  /// Extra small heading (h5) - Minor titles
  static TextStyle h5(BuildContext context) {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.4,
    );
  }

  // ============================================================
  // BODY TEXT STYLES
  // ============================================================

  /// Large body text
  static TextStyle bodyLarge(BuildContext context) {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: NutritionColors.textPrimary,
      height: 1.5,
    );
  }

  /// Medium body text (default)
  static TextStyle bodyMedium(BuildContext context) {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: NutritionColors.textPrimary,
      height: 1.5,
    );
  }

  /// Small body text
  static TextStyle bodySmall(BuildContext context) {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: NutritionColors.textSecondary,
      height: 1.4,
    );
  }

  // ============================================================
  // BUTTON TEXT STYLES
  // ============================================================

  /// Button text large
  static TextStyle buttonLarge(BuildContext context) {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.3,
      height: 1.2,
    );
  }

  /// Button text medium (default)
  static TextStyle buttonMedium(BuildContext context) {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.3,
      height: 1.2,
    );
  }

  /// Button text small
  static TextStyle buttonSmall(BuildContext context) {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.3,
      height: 1.2,
    );
  }

  // ============================================================
  // CAPTION & LABEL STYLES
  // ============================================================

  /// Caption text for hints and descriptions
  static TextStyle caption(BuildContext context) {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: NutritionColors.textTertiary,
      height: 1.3,
    );
  }

  /// Label text for form fields and inputs
  static TextStyle label(BuildContext context) {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: NutritionColors.textSecondary,
      height: 1.3,
    );
  }

  /// Overline text for categories and tags
  static TextStyle overline(BuildContext context) {
    return const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: NutritionColors.textSecondary,
      letterSpacing: 1.0,
      height: 1.2,
    );
  }

  // ============================================================
  // SPECIAL STYLES
  // ============================================================

  /// Time display (e.g., "2:30 PM")
  static TextStyle time(BuildContext context) {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: NutritionColors.textSecondary,
      fontFeatures: [FontFeature.tabularFigures()],
      height: 1.2,
    );
  }

  /// Badge text for chips and pills
  static TextStyle badge(BuildContext context) {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.2,
    );
  }

  /// Error message text
  static TextStyle error(BuildContext context) {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: NutritionColors.error,
      height: 1.4,
    );
  }

  /// Success message text
  static TextStyle success(BuildContext context) {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: NutritionColors.success,
      height: 1.4,
    );
  }

  /// Warning message text
  static TextStyle warning(BuildContext context) {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: NutritionColors.warning,
      height: 1.4,
    );
  }

  /// Info message text
  static TextStyle info(BuildContext context) {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: NutritionColors.info,
      height: 1.4,
    );
  }

  // ============================================================
  // LINK STYLES
  // ============================================================

  /// Hyperlink text
  static TextStyle link(BuildContext context) {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: NutritionColors.info,
      decoration: TextDecoration.underline,
      height: 1.4,
    );
  }

  // ============================================================
  // PLACEHOLDER STYLES
  // ============================================================

  /// Placeholder text for empty states
  static TextStyle placeholder(BuildContext context) {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: NutritionColors.textDisabled,
      fontStyle: FontStyle.italic,
      height: 1.5,
    );
  }

  // ============================================================
  // NUMERIC DISPLAY STYLES
  // ============================================================

  /// Large numeric display (e.g., total calories)
  static TextStyle numericLarge(BuildContext context) {
    return const TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontFeatures: [FontFeature.tabularFigures()],
      height: 1.1,
    );
  }

  /// Medium numeric display
  static TextStyle numericMedium(BuildContext context) {
    return const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontFeatures: [FontFeature.tabularFigures()],
      height: 1.2,
    );
  }

  /// Small numeric display
  static TextStyle numericSmall(BuildContext context) {
    return const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFeatures: [FontFeature.tabularFigures()],
      height: 1.2,
    );
  }
}