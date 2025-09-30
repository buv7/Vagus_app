import 'package:flutter/material.dart';

/// Color palette specifically for the Nutrition Platform 2.0.
///
/// Defines all colors used in nutrition features including:
/// - Macro colors (protein, carbs, fat, calories)
/// - Status colors (success, warning, error, info)
/// - Background gradients for glassmorphic cards
/// - Border colors for UI elements
///
/// Usage:
/// ```dart
/// Container(
///   color: NutritionColors.protein,
///   child: Text('Protein', style: TextStyle(color: Colors.white)),
/// )
/// ```
class NutritionColors {
  // Prevent instantiation
  NutritionColors._();

  // ============================================================
  // MACRO COLORS
  // ============================================================

  /// Protein indicator color (Teal/Aqua)
  static const Color protein = Color(0xFF00D9A3);

  /// Carbohydrates indicator color (Orange)
  static const Color carbs = Color(0xFFFF9A3C);

  /// Fat indicator color (Yellow)
  static const Color fat = Color(0xFFFFD93C);

  /// Calories indicator color (Red)
  static const Color calories = Color(0xFFFF6B6B);

  // ============================================================
  // STATUS COLORS
  // ============================================================

  /// Success state color (Green/Teal)
  static const Color success = Color(0xFF00D9A3);

  /// Warning state color (Amber)
  static const Color warning = Color(0xFFFFBF47);

  /// Error state color (Red)
  static const Color error = Color(0xFFFF6B6B);

  /// Info state color (Blue)
  static const Color info = Color(0xFF4A90E2);

  // ============================================================
  // BACKGROUND COLORS (Glassmorphism)
  // ============================================================

  /// Card gradient start color (Dark teal)
  static const Color cardGradientStart = Color(0xFF1A3A3A);

  /// Card gradient end color (Darker teal)
  static const Color cardGradientEnd = Color(0xFF0D2626);

  /// Dark overlay for modals and dialogs
  static const Color overlayDark = Color(0x88000000);

  /// Dark background for screens
  static const Color backgroundDark = Color(0xFF0A1F1F);

  /// Secondary background for nested cards
  static const Color backgroundSecondary = Color(0xFF0D2626);

  // ============================================================
  // BORDER COLORS
  // ============================================================

  /// Light border (10% white opacity)
  static const Color borderLight = Color(0x1AFFFFFF);

  /// Medium border (20% white opacity)
  static const Color borderMedium = Color(0x33FFFFFF);

  /// Strong border (40% white opacity)
  static const Color borderStrong = Color(0x66FFFFFF);

  // ============================================================
  // TEXT COLORS
  // ============================================================

  /// Primary text color (white)
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text color (70% white)
  static const Color textSecondary = Color(0xB3FFFFFF);

  /// Tertiary text color (50% white)
  static const Color textTertiary = Color(0x80FFFFFF);

  /// Disabled text color (30% white)
  static const Color textDisabled = Color(0x4DFFFFFF);

  // ============================================================
  // SPECIAL COLORS
  // ============================================================

  /// Premium feature indicator (Gold)
  static const Color premium = Color(0xFFFFD700);

  /// AI-generated content indicator (Purple)
  static const Color aiGenerated = Color(0xFF9B59B6);

  /// Verified content indicator (Blue check)
  static const Color verified = Color(0xFF1DA1F2);

  /// Sustainability indicator (Green)
  static const Color sustainability = Color(0xFF27AE60);

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Returns the appropriate macro color based on macro type.
  ///
  /// Example:
  /// ```dart
  /// final color = NutritionColors.getMacroColor('protein'); // Returns teal
  /// ```
  static Color getMacroColor(String macroType) {
    switch (macroType.toLowerCase()) {
      case 'protein':
        return protein;
      case 'carbs':
      case 'carbohydrates':
        return carbs;
      case 'fat':
      case 'fats':
        return fat;
      case 'calories':
      case 'kcal':
        return calories;
      default:
        return textSecondary;
    }
  }

  /// Returns the appropriate status color based on progress percentage.
  ///
  /// - Green: 80-120% of target
  /// - Yellow: 120-150% or 50-80% of target
  /// - Red: <50% or >150% of target
  ///
  /// Example:
  /// ```dart
  /// final color = NutritionColors.getProgressColor(0.95); // Returns green
  /// ```
  static Color getProgressColor(double progressPercent) {
    if (progressPercent >= 0.8 && progressPercent <= 1.2) {
      return success;
    } else if ((progressPercent >= 0.5 && progressPercent < 0.8) ||
        (progressPercent > 1.2 && progressPercent <= 1.5)) {
      return warning;
    } else {
      return error;
    }
  }

  /// Returns a glassmorphic gradient for cards and containers.
  ///
  /// Example:
  /// ```dart
  /// Container(
  ///   decoration: BoxDecoration(
  ///     gradient: NutritionColors.glassGradient,
  ///   ),
  /// )
  /// ```
  static LinearGradient get glassGradient => LinearGradient(
        colors: [
          cardGradientStart.withValues(alpha: 0.8),
          cardGradientEnd.withValues(alpha: 0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}