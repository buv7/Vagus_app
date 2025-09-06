import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// App theme configuration with VAGUS monochrome design system
class AppTheme {
  // New monochrome color constants
  static const Color primaryBlack = Color(0xFF000000);
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color steelGrey = Color(0xFF555555);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color charcoalGrey = Color(0xFF1C1C1C);

  /// Light theme with VAGUS monochrome palette
  static ThemeData light() {
    return ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF000000),    // Black
        secondary: Color(0xFF555555),  // Steel Grey
        surface: Color(0xFFFFFFFF),    // White
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFF000000),
        outline: Color(0xFFE0E0E0),
        surfaceContainerHighest: Color(0xFFFFFFFF),
        onSurfaceVariant: Color(0xFF555555),
      ),
      scaffoldBackgroundColor: Color(0xFFFFFFFF), // White
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF), // White
        foregroundColor: Color(0xFF000000), // Black
        elevation: 0,
        shadowColor: Color(0xFF000000),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
        ),
        color: Colors.white,
        surfaceTintColor: Color(0xFFE0E0E0),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFFE0E0E0),
        selectedColor: Color(0xFF000000),
        labelStyle: const TextStyle(color: Color(0xFF000000)),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
        side: BorderSide(color: Color(0xFF555555)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF000000),
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
          foregroundColor: Color(0xFF000000),
          side: const BorderSide(color: Color(0xFF000000)),
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
          foregroundColor: Color(0xFF000000),
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
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: Color(0xFF000000), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(DesignTokens.space16),
      ),
      dividerColor: const Color(0xFFE0E0E0),
      textTheme: _buildTextTheme(const Color(0xFF000000)).copyWith(
        bodyLarge: const TextStyle(color: Color(0xFF000000)),
        bodyMedium: const TextStyle(color: Color(0xFF555555)),
        titleLarge: const TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Dark theme with VAGUS monochrome palette
  static ThemeData dark() {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFFFFF),    // White
        secondary: Color(0xFF555555),  // Steel Grey
        surface: Color(0xFF000000),    // Black
        onPrimary: Color(0xFF000000),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFFFFFFFF),
        outline: Color(0xFF555555),
        surfaceContainerHighest: Color(0xFF1C1C1C),
        onSurfaceVariant: Color(0xFFE0E0E0),
      ),
      scaffoldBackgroundColor: Color(0xFF000000), // Black
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C1C1C), // Charcoal Grey
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
        ),
        color: const Color(0xFF1C1C1C), // Charcoal Grey
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFF555555).withValues(alpha: 0.2),
        selectedColor: Color(0xFFFFFFFF),
        labelStyle: const TextStyle(color: Color(0xFFFFFFFF)),
        secondaryLabelStyle: const TextStyle(color: Color(0xFF000000)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
        side: BorderSide(color: Color(0xFF555555)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFFFFFF),
          foregroundColor: Color(0xFF000000),
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
          foregroundColor: Color(0xFFFFFFFF),
          side: const BorderSide(color: Color(0xFFFFFFFF)),
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
          foregroundColor: Color(0xFFFFFFFF),
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
          borderSide: const BorderSide(color: Color(0xFF555555)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: Color(0xFF555555)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: Color(0xFFFFFFFF), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF1C1C1C), // Charcoal Grey
        contentPadding: const EdgeInsets.all(DesignTokens.space16),
      ),
      dividerColor: const Color(0xFF555555),
      textTheme: _buildTextTheme(const Color(0xFFFFFFFF)).copyWith(
        bodyLarge: const TextStyle(color: Color(0xFFFFFFFF)),
        bodyMedium: const TextStyle(color: Color(0xFFE0E0E0)),
        titleLarge: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
      ),
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
