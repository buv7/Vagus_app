import 'package:flutter/material.dart';
import 'tokens.dart';

/// App theme configuration — builds ThemeData from [VagusTokens].
///
/// Dark theme: glassmorphic dark purple/navy (primary canonical theme).
/// Light theme: monochrome skeleton (future-ready; not the primary mode).
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Backward-compat shims for callers that import AppTheme directly.
  // Prefer VagusTokens.xxx in new code.
  // ---------------------------------------------------------------------------

  @Deprecated('Use VagusTokens.bgBase')
  static const Color primaryDark = VagusTokens.bgBase;

  @Deprecated('Use VagusTokens.textPrimary')
  static const Color neutralWhite = VagusTokens.textPrimary;

  @Deprecated('Use VagusTokens.textSecondary or a ThemeColors accessor')
  static const Color mediumGrey = Color(0xFF6A7385);

  static const Color lightGrey    = Color(0xFFE0E0E0);
  static const Color charcoalGrey = Color(0xFF1C1C1C);

  @Deprecated('Use VagusTokens.primary')
  static const Color accentGreen = VagusTokens.primary;

  @Deprecated('Use VagusTokens.accentOrange')
  static const Color accentOrange = VagusTokens.accentOrange;

  @Deprecated('Use VagusTokens.surfaceGlass')
  static const Color cardBackground = VagusTokens.surfaceGlass;

  @Deprecated('Use VagusTokens.bgBase')
  static const Color backgroundDark = VagusTokens.bgBase;

  @Deprecated('Use VagusTokens.surfaceGlass')
  static const Color cardDark = VagusTokens.surfaceGlass;

  @Deprecated('Use VagusTokens.primaryDark')
  static const Color lightBlue = VagusTokens.primaryDark;

  @Deprecated('Use VagusTokens.accentOrange')
  static const Color lightOrange = VagusTokens.accentOrange;

  static const Color lightYellow = Color(0xFFFFEB3B);

  // ---------------------------------------------------------------------------
  // LIGHT THEME  (monochrome skeleton — reserved for future parity work)
  // ---------------------------------------------------------------------------

  static ThemeData light() {
    return ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF000000),
        secondary: Color(0xFF6A7385),
        surface: Color(0xFFFFFFFF),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFF000000),
        outline: Color(0xFFE0E0E0),
        surfaceContainerHighest: Color(0xFFFFFFFF),
        onSurfaceVariant: Color(0xFF6A7385),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF000000),
        elevation: 0,
        shadowColor: Color(0xFF000000),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VagusTokens.radiusLg),
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
          borderRadius: BorderRadius.circular(VagusTokens.radiusMd),
        ),
        side: const BorderSide(color: Color(0xFF6A7385)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF000000),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VagusTokens.radiusSm),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: VagusTokens.spaceLg,
            vertical: VagusTokens.space12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF000000),
          side: const BorderSide(color: Color(0xFF000000)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VagusTokens.radiusSm),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: VagusTokens.spaceLg,
            vertical: VagusTokens.space12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VagusTokens.radiusSm),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: VagusTokens.spaceMd,
            vertical: VagusTokens.spaceSm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VagusTokens.radiusMd),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VagusTokens.radiusMd),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VagusTokens.radiusMd),
          borderSide: const BorderSide(color: Color(0xFF000000), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(VagusTokens.spaceMd),
      ),
      dividerColor: const Color(0xFFE0E0E0),
      textTheme: _buildTextTheme(const Color(0xFF000000)).copyWith(
        bodyLarge:  const TextStyle(color: Color(0xFF000000)),
        bodyMedium: const TextStyle(color: Color(0xFF6A7385)),
        titleLarge: const TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DARK THEME  (glassmorphic dark purple/navy — primary canonical theme)
  // ---------------------------------------------------------------------------

  static ThemeData dark() {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: VagusTokens.primary,
        secondary: VagusTokens.primaryDark,
        tertiary: VagusTokens.primaryLight,
        surface: VagusTokens.bgBase,
        onPrimary: Colors.black,
        onSecondary: VagusTokens.textPrimary,
        onSurface: VagusTokens.textPrimary,
        outline: VagusTokens.glassBorder,
        surfaceContainerHighest: VagusTokens.surfaceGlass,
        onSurfaceVariant: VagusTokens.textSecondary,
      ),
      scaffoldBackgroundColor: VagusTokens.bgBase,
      appBarTheme: const AppBarTheme(
        backgroundColor: VagusTokens.surfaceGlass,
        foregroundColor: VagusTokens.textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VagusTokens.radiusMd),
        ),
        color: VagusTokens.surfaceGlass,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: VagusTokens.surfaceGlass,
        selectedColor: VagusTokens.primary,
        labelStyle: const TextStyle(color: VagusTokens.textPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VagusTokens.radiusMd),
        ),
        side: const BorderSide(color: VagusTokens.glassBorder),
        shadowColor: Colors.transparent,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VagusTokens.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VagusTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: VagusTokens.spaceLg,
            vertical: VagusTokens.space12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VagusTokens.textPrimary,
          side: const BorderSide(color: VagusTokens.glassBorder),
          backgroundColor: VagusTokens.surfaceGlass,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VagusTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: VagusTokens.spaceLg,
            vertical: VagusTokens.space12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VagusTokens.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VagusTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: VagusTokens.spaceMd,
            vertical: VagusTokens.spaceSm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VagusTokens.radiusMd),
          borderSide: const BorderSide(color: VagusTokens.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VagusTokens.radiusMd),
          borderSide: const BorderSide(color: VagusTokens.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VagusTokens.radiusMd),
          borderSide: const BorderSide(color: VagusTokens.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VagusTokens.radiusMd),
          borderSide: const BorderSide(color: VagusTokens.accentPink, width: 2),
        ),
        filled: true,
        fillColor: const Color(0x0AFFFFFF),
        contentPadding: const EdgeInsets.all(VagusTokens.spaceMd),
        hintStyle: const TextStyle(color: VagusTokens.textSecondary),
        labelStyle: const TextStyle(color: VagusTokens.textSecondary),
      ),
      dividerColor: VagusTokens.divider,
      textTheme: _buildTextTheme(VagusTokens.textPrimary).copyWith(
        bodyLarge:  const TextStyle(color: VagusTokens.textPrimary),
        bodyMedium: const TextStyle(color: VagusTokens.textSecondary),
        titleLarge: const TextStyle(
          color: VagusTokens.textPrimary,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: const TextStyle(
          color: VagusTokens.textPrimary,
          fontWeight: FontWeight.w100,
          fontSize: 24,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS (kept for call-site compat)
  // ---------------------------------------------------------------------------

  static TextTheme _buildTextTheme(Color onSurface) {
    return TextTheme(
      displayLarge:  VagusTokens.displayLg.copyWith(color: onSurface),
      displayMedium: VagusTokens.displayMd.copyWith(color: onSurface),
      displaySmall:  VagusTokens.displaySm.copyWith(color: onSurface),
      titleLarge:    VagusTokens.titleLg.copyWith(color: onSurface),
      titleMedium:   VagusTokens.titleMd.copyWith(color: onSurface),
      titleSmall:    VagusTokens.titleSm.copyWith(color: onSurface),
      bodyLarge:     VagusTokens.bodyLg.copyWith(color: onSurface),
      bodyMedium:    VagusTokens.bodyMd.copyWith(color: onSurface),
      bodySmall:     VagusTokens.bodySm.copyWith(color: onSurface),
      labelLarge:    VagusTokens.labelMd.copyWith(color: onSurface),
      labelMedium:   VagusTokens.labelMd.copyWith(color: onSurface),
      labelSmall:    VagusTokens.labelSm.copyWith(color: onSurface),
    );
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'workout':   return VagusTokens.primaryDark;
      case 'nutrition': return VagusTokens.primary;
      case 'calling':   return VagusTokens.accentPink;
      case 'coach':     return VagusTokens.secondary;
      default:          return const Color(0xFF6A7385);
    }
  }

  static Color getCategoryBgColor(String category) {
    switch (category.toLowerCase()) {
      case 'workout':   return const Color(0x200099FF);
      case 'nutrition': return const Color(0x2000C8FF);
      case 'calling':   return const Color(0x20FF6B9D);
      case 'coach':     return const Color(0x209D6BFF);
      default:          return const Color(0x206A7385);
    }
  }

  static List<BoxShadow> getGlowShadow({String type = 'sm'}) {
    switch (type) {
      case 'sm':     return VagusTokens.shadowSm;
      case 'md':     return VagusTokens.shadowMd;
      case 'lg':     return VagusTokens.shadowLg;
      case 'purple': return VagusTokens.shadowPurple;
      default:       return VagusTokens.shadowSm;
    }
  }

  static List<BoxShadow> getShadow(ThemeMode themeMode, {String type = 'card'}) {
    return (themeMode == ThemeMode.dark && type != 'card')
        ? VagusTokens.shadowSubtle
        : VagusTokens.shadowCard;
  }

  static BoxDecoration createGlassmorphicDecoration({
    Color? backgroundColor,
    double borderRadius = 20.0,
    Color? borderColor,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? VagusTokens.surfaceGlass,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? VagusTokens.glassBorder),
      boxShadow: boxShadow ?? VagusTokens.shadowCard,
    );
  }
}
