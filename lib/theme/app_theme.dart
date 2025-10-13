import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// App theme configuration with NFT Marketplace design system
class AppTheme {
  // Legacy colors (kept for compatibility)
  static const Color primaryDark = DesignTokens.primaryDark;
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color mediumGrey = DesignTokens.mediumGrey;
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color charcoalGrey = Color(0xFF1C1C1C);

  // Updated to use NFT marketplace colors from DesignTokens
  static const Color accentGreen = DesignTokens.accentGreen;
  static const Color accentOrange = DesignTokens.accentOrange;
  static const Color cardBackground = DesignTokens.secondaryDark;

  // Additional color getters for nutrition platform compatibility
  static const Color backgroundDark = DesignTokens.primaryDark;
  static const Color cardDark = DesignTokens.cardBackground;
  static const Color lightBlue = DesignTokens.accentBlue;
  static const Color lightOrange = DesignTokens.accentOrange;
  static const Color lightYellow = Color(0xFFFFEB3B); // Material yellow

  /// Light theme with VAGUS monochrome palette
  static ThemeData light() {
    return ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF000000),    // Black
        secondary: DesignTokens.mediumGrey,  // Medium Grey
        surface: Color(0xFFFFFFFF),    // White
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFF000000),
        outline: Color(0xFFE0E0E0),
        surfaceContainerHighest: Color(0xFFFFFFFF),
        onSurfaceVariant: DesignTokens.mediumGrey,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF), // White
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
        surfaceTintColor: const Color(0xFFE0E0E0),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE0E0E0),
        selectedColor: const Color(0xFF000000),
        labelStyle: const TextStyle(color: Color(0xFF000000)),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
        side: const BorderSide(color: DesignTokens.mediumGrey),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF000000),
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
          foregroundColor: const Color(0xFF000000),
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
          foregroundColor: const Color(0xFF000000),
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
        bodyMedium: const TextStyle(color: DesignTokens.mediumGrey),
        titleLarge: const TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Dark theme with Premium Neural Fitness design palette
  static ThemeData dark() {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: DesignTokens.accentGreen,           // Cyan primary
        secondary: DesignTokens.accentBlue,          // Blue deep
        tertiary: DesignTokens.accentTeal,           // Teal
        surface: DesignTokens.primaryDark,           // Pure black
        onPrimary: Colors.black,                     // Black text on cyan
        onSecondary: DesignTokens.neutralWhite,      // White text on blue
        onSurface: DesignTokens.neutralWhite,        // White text
        outline: DesignTokens.glassBorder,           // 8% white borders
        surfaceContainerHighest: DesignTokens.cardBackground, // Black soft 95%
        onSurfaceVariant: DesignTokens.textSecondary,         // 60% white text
      ),
      scaffoldBackgroundColor: DesignTokens.primaryDark, // Pure black
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.cardBackground, // Black soft with 95% opacity
        foregroundColor: DesignTokens.neutralWhite,
        elevation: 0,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
        color: DesignTokens.cardBackground, // Black soft with 95% opacity
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DesignTokens.cardBackground,
        selectedColor: DesignTokens.accentGreen,
        labelStyle: const TextStyle(color: DesignTokens.neutralWhite),
        secondaryLabelStyle: const TextStyle(color: Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
        side: const BorderSide(color: DesignTokens.glassBorder),
        shadowColor: Colors.transparent,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.accentGreen, // Cyan primary (gradient applied via decoration)
          foregroundColor: Colors.black, // Black text
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space24,
            vertical: DesignTokens.space12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.neutralWhite,
          side: const BorderSide(color: DesignTokens.glassBorder),
          backgroundColor: DesignTokens.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space24,
            vertical: DesignTokens.space12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.accentGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
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
          borderSide: const BorderSide(color: DesignTokens.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: DesignTokens.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: DesignTokens.accentGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: DesignTokens.accentPink, width: 2),
        ),
        filled: true,
        fillColor: const Color(0x0AFFFFFF), // 4% white
        contentPadding: const EdgeInsets.all(DesignTokens.space16),
        hintStyle: const TextStyle(color: DesignTokens.textSecondary),
        labelStyle: const TextStyle(color: DesignTokens.textSecondary),
      ),
      dividerColor: DesignTokens.glassBorder,
      textTheme: _buildTextTheme(DesignTokens.neutralWhite).copyWith(
        bodyLarge: const TextStyle(color: DesignTokens.neutralWhite),
        bodyMedium: const TextStyle(color: DesignTokens.textSecondary),
        titleLarge: const TextStyle(
          color: DesignTokens.neutralWhite,
          fontWeight: FontWeight.w400, // Light for premium feel
        ),
        headlineMedium: const TextStyle(
          color: DesignTokens.neutralWhite,
          fontWeight: FontWeight.w100, // Ultra-light headings
          fontSize: 24,
        ),
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
    return DesignTokens.categoryColors[category.toLowerCase()] ?? DesignTokens.mediumGrey;
  }

  /// Get category background color
  static Color getCategoryBgColor(String category) {
    return DesignTokens.categoryBgColors[category.toLowerCase()] ?? DesignTokens.cardBackground;
  }

  /// Get glow shadow based on category or color type
  static List<BoxShadow> getGlowShadow({String type = 'sm'}) {
    switch (type) {
      case 'sm':
        return DesignTokens.glowSm;
      case 'md':
        return DesignTokens.glowMd;
      case 'lg':
        return DesignTokens.glowLg;
      case 'purple':
        return DesignTokens.glowPurple;
      default:
        return DesignTokens.glowSm;
    }
  }

  /// Get shadow based on theme mode (updated for NFT theme)
  static List<BoxShadow> getShadow(ThemeMode themeMode, {String type = 'card'}) {
    if (themeMode == ThemeMode.dark) {
      return type == 'card' ? DesignTokens.cardShadow : DesignTokens.shadowDark;
    }

    // For light mode, use card shadows as well
    return DesignTokens.cardShadow;
  }

  /// Create glassmorphic container decoration
  static BoxDecoration createGlassmorphicDecoration({
    Color? backgroundColor,
    double borderRadius = 20.0,
    Color? borderColor,
    List<BoxShadow>? boxShadow,
  }) {
    return DesignTokens.glassmorphicDecoration(
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      borderColor: borderColor,
      boxShadow: boxShadow,
    );
  }
}
