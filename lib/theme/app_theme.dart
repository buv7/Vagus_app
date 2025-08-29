import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// App theme configuration with Soft Aurora design system
class AppTheme {
  // Legacy color constants for backward compatibility
  static const Color primaryBlue = DesignTokens.blue600;
  static const Color secondaryPurple = DesignTokens.purple500;
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonMagenta = Color(0xFFFF00FF);

  /// Light theme with soft blue tint and tinted shadows
  static ThemeData light() {
    return ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: DesignTokens.blue600,
        secondary: DesignTokens.purple500,
        surface: DesignTokens.ink50,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DesignTokens.ink900,
        outline: DesignTokens.ink100,
        surfaceContainerHighest: DesignTokens.blue50,
        onSurfaceVariant: DesignTokens.ink700,
      ),
      scaffoldBackgroundColor: DesignTokens.ink50,
      appBarTheme: AppBarTheme(
        backgroundColor: DesignTokens.blue600,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: DesignTokens.blue600.withValues(alpha: 0.1),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
        ),
        color: Colors.white,
        surfaceTintColor: DesignTokens.blue50,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DesignTokens.blue50,
        selectedColor: DesignTokens.blue600,
        labelStyle: const TextStyle(color: DesignTokens.blue600),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
        side: BorderSide(color: DesignTokens.blue600.withValues(alpha: 0.2)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.blue600,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space24,
            vertical: DesignTokens.space12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.blue600,
          side: const BorderSide(color: DesignTokens.blue600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space24,
            vertical: DesignTokens.space12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.blue600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space8,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: DesignTokens.ink100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: DesignTokens.ink100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: DesignTokens.blue600, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(DesignTokens.space16),
      ),
      textTheme: _buildTextTheme(DesignTokens.ink900),
    );
  }

  /// Dark theme with deep neutral and elevation overlays
  static ThemeData dark() {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: DesignTokens.blue600,
        secondary: DesignTokens.purple500,
        surface: DesignTokens.ink900,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        outline: DesignTokens.ink700,
        surfaceContainerHighest: Color(0xFF1A1D26), // Ink900 + 8% elevation
        onSurfaceVariant: DesignTokens.ink100,
      ),
      scaffoldBackgroundColor: DesignTokens.ink900,
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.ink900,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
        ),
        color: const Color(0xFF1A1D26), // Ink900 + 8% elevation
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DesignTokens.blue600.withValues(alpha: 0.2),
        selectedColor: DesignTokens.blue600,
        labelStyle: const TextStyle(color: DesignTokens.blue600),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
        side: BorderSide(color: DesignTokens.blue600.withValues(alpha: 0.3)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.blue600,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space24,
            vertical: DesignTokens.space12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.blue600,
          side: const BorderSide(color: DesignTokens.blue600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space24,
            vertical: DesignTokens.space12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.blue600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space8,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: DesignTokens.ink700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: DesignTokens.ink700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: DesignTokens.blue600, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF1A1D26), // Ink900 + 8% elevation
        contentPadding: const EdgeInsets.all(DesignTokens.space16),
      ),
      textTheme: _buildTextTheme(Colors.white),
    );
  }

  /// Build text theme with design tokens
  static TextTheme _buildTextTheme(Color onSurface) {
    return TextTheme(
      displayLarge: DesignTokens.displayLarge.copyWith(color: onSurface),
      displayMedium: DesignTokens.displayMedium.copyWith(color: onSurface),
      displaySmall: DesignTokens.displaySmall.copyWith(color: onSurface),
      titleLarge: DesignTokens.titleLarge.copyWith(color: onSurface),
      titleMedium: DesignTokens.titleMedium.copyWith(color: onSurface),
      titleSmall: DesignTokens.titleSmall.copyWith(color: onSurface),
      bodyLarge: DesignTokens.bodyLarge.copyWith(color: onSurface),
      bodyMedium: DesignTokens.bodyMedium.copyWith(color: onSurface),
      bodySmall: DesignTokens.bodySmall.copyWith(color: onSurface),
      labelLarge: DesignTokens.labelMedium.copyWith(color: onSurface),
      labelMedium: DesignTokens.labelMedium.copyWith(color: onSurface),
      labelSmall: DesignTokens.labelSmall.copyWith(color: onSurface),
    );
  }

  /// Get category color for consistent visual hierarchy
  static Color getCategoryColor(String category) {
    return DesignTokens.categoryColors[category.toLowerCase()] ?? DesignTokens.ink500;
  }

  /// Get category background color
  static Color getCategoryBgColor(String category) {
    return DesignTokens.categoryBgColors[category.toLowerCase()] ?? DesignTokens.ink50;
  }

  /// Get shadow based on theme mode
  static List<BoxShadow> getShadow(ThemeMode themeMode, {String type = 'sm'}) {
    if (themeMode == ThemeMode.dark) {
      return DesignTokens.shadowDark;
    }
    
    switch (type) {
      case 'sm':
        return DesignTokens.shadowSm;
      case 'md':
        return DesignTokens.shadowMd;
      case 'lg':
        return DesignTokens.shadowLg;
      default:
        return DesignTokens.shadowSm;
    }
  }
}
