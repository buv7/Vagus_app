import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Theme-aware color helper with guaranteed readable LIGHT mode
/// while preserving the existing DARK glass aesthetic.
///
/// Usage:
/// final tc = ThemeColors.of(context);
/// Text('Hi', style: TextStyle(color: tc.textPrimary));
class ThemeColors {
  final BuildContext context;
  final ThemeData theme;
  final ColorScheme scheme;
  final bool isDark;

  ThemeColors._(this.context, this.theme, this.scheme, this.isDark);

  factory ThemeColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return ThemeColors._(context, theme, scheme, isDark);
  }

  // -----------------------------
  // LIGHT mode: fixed palette (contrast-safe)
  // -----------------------------
  static const _lightBg = Color(0xFFF7F8FA);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurfaceAlt = Color(0xFFF2F4F7);

  static const _lightTextPrimary = Color(0xFF0B1220);
  static const _lightTextSecondary = Color(0xFF4B5563);

  static const _lightBorder = Color(0xFFE5E7EB);

  // -----------------------------
  // DARK mode: keep your current look
  // -----------------------------

  /// Main app background
  Color get bg => isDark ? DesignTokens.primaryDark : _lightBg;

  /// Card/dialog surface
  Color get surface => isDark ? DesignTokens.cardBackground : _lightSurface;

  /// Secondary surface (nested cards, subtle elevation)
  Color get surfaceAlt => isDark
      ? DesignTokens.cardBackground
      : _lightSurfaceAlt;

  /// Primary text
  Color get textPrimary => isDark ? DesignTokens.neutralWhite : _lightTextPrimary;

  /// Secondary text (labels/hints)
  Color get textSecondary => isDark ? DesignTokens.textSecondary : _lightTextSecondary;

  /// Icons
  Color get icon => isDark ? DesignTokens.neutralWhite : _lightTextPrimary;

  /// Borders / outlines
  Color get border => isDark ? DesignTokens.glassBorder : _lightBorder;

  /// Chip background (unselected)
  Color get chipBg => isDark ? DesignTokens.cardBackground : _lightSurfaceAlt;

  /// Chip background (selected)
  Color get chipSelectedBg => isDark ? DesignTokens.accentGreen : _lightTextPrimary;

  /// Chip text (use this to avoid wrong onSecondary)
  Color get chipTextOnSelected => isDark ? Colors.black : Colors.white;

  /// Input fill
  Color get inputFill => isDark ? const Color(0x0AFFFFFF) : _lightSurface;

  /// Error/danger
  Color get danger => isDark ? DesignTokens.accentPink : scheme.error;
}

/// Convenience extension
extension ThemeColorsExtension on BuildContext {
  ThemeColors get themeColors => ThemeColors.of(this);
}
