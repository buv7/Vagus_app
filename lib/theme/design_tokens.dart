import 'package:flutter/material.dart';
import 'dart:ui';

/// Design tokens for NFT Marketplace UI/UX v2
/// Centralized constants for colors, typography, spacing, shadows, and glassmorphic effects
class DesignTokens {
  // Private constructor to prevent instantiation
  DesignTokens._();

  // ===== PREMIUM NEURAL FITNESS COLORS =====

  /// Primary Background Colors - Pure black theme
  static const Color primaryDark = Color(0xFF000000);      // Black base
  static const Color darkBackground = Color(0xFF0A0A14);   // Black soft
  static const Color secondaryDark = Color(0xFF0A0A14);    // Black soft (compatibility)
  static const Color cardBackground = Color(0xF20A0A14);   // Black soft with 95% opacity

  /// Cyan/Blue Spectrum Colors
  static const Color accentGreen = Color(0xFF00C8FF);      // Cyan primary (renamed from green for compatibility)
  static const Color accentBlue = Color(0xFF0080FF);       // Blue deep
  static const Color primaryBlue = Color(0xFF0099FF);      // Blue medium
  static const Color darkBlue = Color(0xFF0064C8);         // Blue dark

  /// Accent Colors
  static const Color accentTeal = Color(0xFF00FFC8);       // Teal
  static const Color accentPink = Color(0xFFFF6B9D);       // Pink (kept)
  static const Color accentPurple = Color(0xFF9D6BFF);     // Purple (kept)
  static const Color accentOrange = Color(0xFFFF9D6B);     // Orange (kept)

  /// Text Colors - Pure white spectrum
  static const Color neutralWhite = Color(0xFFFFFFFF);     // Pure white text
  static const Color textPrimary = Color(0xFFFFFFFF);      // Primary text (white)
  static const Color textSecondary = Color(0x99FFFFFF);    // Secondary text (60% white)
  static const Color textTertiary = Color(0x66FFFFFF);     // Tertiary text (40% white)
  static const Color textDisabled = Color(0x4DFFFFFF);     // Disabled text (30% white)
  static const Color lightGrey = Color(0xFF2A2433);        // Darker grey for dark theme (legacy)
  static const Color mediumGrey = Color(0xFF6A7385);       // Medium text (legacy)
  static const Color darkGrey = Color(0xFF1C1C1C);         // Dark card backgrounds (legacy)

  /// Gradient Definitions - Premium neural style
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00C8FF), Color(0xFF0080FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient textGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xCC00C8FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient backgroundGradient = RadialGradient(
    colors: [
      Color(0x1A00C8FF), // Subtle cyan hint
      Color(0x0D0080FF), // Subtle blue hint
      Color(0xFF000000), // Black base
    ],
    stops: [0.0, 0.5, 1.0],
    center: Alignment.center,
    radius: 1.5,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0x40FFFFFF), Color(0x10FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF0A0A14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy gradient for compatibility
  static const LinearGradient vibrantGradient = primaryGradient;

  /// State Colors (updated for premium theme)
  static const Color success = Color(0xFF00C8FF); // Use cyan primary
  static const Color info = Color(0xFF0080FF);    // Use blue deep
  static const Color warn = Color(0xFFFF9D6B);    // Use accent orange (kept)
  static const Color danger = Color(0xFFFF6B9D);  // Use accent pink (kept)

  /// State Background Colors (dark theme variants)
  static const Color successBg = Color(0x2000C8FF); // 12% cyan
  static const Color infoBg = Color(0x200080FF);    // 12% blue
  static const Color warnBg = Color(0x20FF9D6B);    // 12% orange
  static const Color dangerBg = Color(0x20FF6B9D);  // 12% pink

  // ===== BACKWARD COMPATIBILITY COLORS =====

  /// Legacy brand colors (mapped to new NFT colors for compatibility)
  static const Color blue600 = accentBlue;    // Primary brand -> Blue accent
  static const Color blue500 = accentBlue;    // Secondary brand -> Blue accent
  static const Color blue200 = Color(0xFFC7D2FE); // Light brand border (kept)
  static const Color blue100 = Color(0xFFDBEAFE); // Very light brand tint (kept)
  static const Color blue50 = Color(0xFFF2F5FF);  // Light brand tint (kept)
  static const Color blue700 = accentBlue;    // Darker brand -> Blue accent
  static const Color blue900 = primaryDark;   // Dark brand -> Primary dark

  /// Legacy accent colors
  static const Color purple500 = accentPurple; // Primary accent -> Purple accent
  static const Color purple50 = Color(0xFFF6F0FF);  // Light accent tint (kept)

  /// Legacy neutral colors (mapped to new dark theme colors)
  static const Color ink900 = primaryDark;    // Darkest text -> Primary dark
  static const Color ink700 = secondaryDark;  // Dark text -> Secondary dark
  static const Color ink600 = lightGrey;      // Medium-dark text -> Light grey
  static const Color ink500 = mediumGrey;     // Medium text -> Medium grey
  static const Color ink400 = textSecondary;  // Medium-light text -> Text secondary
  static const Color ink300 = glassBorder;    // Light borders -> Glass border
  static const Color ink200 = glassBorder;    // Lighter borders -> Glass border
  static const Color ink100 = Color(0xFFE7EAF2); // Light borders (kept for light theme)
  static const Color ink50 = Color(0xFFF7F8FC);  // Lightest surface (kept for light theme)

  // ===== TYPOGRAPHY =====

  /// Display Text (ultra-light for premium feel)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w100,
    letterSpacing: -2,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w100,
    letterSpacing: -1,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w200,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Title Text (light to regular)
  static const TextStyle titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  /// Body Text (regular with increased line height)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.8,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Label Text (semibold for buttons)
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.4,
  );

  // ===== SPACING =====
  
  /// 8-pt grid spacing system
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // ===== RADIUS =====

  /// Border radius values
  static const double radius4 = 4.0;
  static const double radius6 = 6.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius28 = 28.0;
  static const double radiusFull = 999.0;

  // ===== SHADOWS & GLASSMORPHIC EFFECTS =====

  /// Glassmorphic shadows with premium glow effects
  static const List<BoxShadow> glowSm = [
    BoxShadow(
      color: Color(0x4000C8FF), // Cyan primary @ 25%
      blurRadius: 20,
      offset: Offset(0, 0),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> glowMd = [
    BoxShadow(
      color: Color(0x400080FF), // Blue deep @ 25%
      blurRadius: 30,
      offset: Offset(0, 0),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> glowLg = [
    BoxShadow(
      color: Color(0x4000C8FF), // Cyan primary @ 25%
      blurRadius: 40,
      offset: Offset(0, 0),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> glowPurple = [
    BoxShadow(
      color: Color(0x4000FFC8), // Teal @ 25%
      blurRadius: 30,
      offset: Offset(0, 0),
      spreadRadius: 0,
    ),
  ];

  /// Card shadows with subtle elevation
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x20000000), // Black @ 12%
      blurRadius: 16,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  /// Dark mode shadows (minimal, elevation-based)
  static const List<BoxShadow> shadowDark = [
    BoxShadow(
      color: Color(0x10000000), // Black @ 6%
      blurRadius: 12,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  /// Glassmorphic border colors
  static const Color glassBorder = Color(0x14FFFFFF); // 8% white
  static const Color glassBorderAccent = Color(0x4000C8FF); // 25% cyan

  /// Backdrop filter blur values
  static const double blurSm = 10.0;
  static const double blurMd = 15.0;
  static const double blurLg = 20.0;

  // ===== ANIMATION DURATIONS =====
  
  /// Motion durations (160-220ms for micro-interactions)
  static const Duration durationFast = Duration(milliseconds: 160);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 220);

  // ===== CATEGORY COLORS =====

  /// Category color mapping for consistent visual hierarchy (updated for premium theme)
  static const Map<String, Color> categoryColors = {
    'workout': primaryBlue,    // Blue medium for workouts
    'nutrition': accentGreen,  // Cyan primary for nutrition
    'calling': accentPink,     // Pink for calling/sessions (kept)
    'coach': accentPurple,     // Purple for coaching (kept)
    'other': mediumGrey,       // Grey for other (kept)
  };

  /// Category background colors (dark theme variants)
  static const Map<String, Color> categoryBgColors = {
    'workout': Color(0x200099FF),   // Blue medium @ 12%
    'nutrition': Color(0x2000C8FF), // Cyan primary @ 12%
    'calling': Color(0x20FF6B9D),   // Pink @ 12%
    'coach': Color(0x209D6BFF),     // Purple @ 12%
    'other': Color(0x206A7385),     // Grey @ 12%
  };

  // ===== NAVIGATION =====

  /// Navigation active state colors (updated for premium theme)
  static const Color navActive = accentGreen; // Cyan primary
  static const Color navInactive = textSecondary; // 60% white

  /// Navigation active state styles
  static const TextStyle navActiveLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: accentGreen,
  );

  static const TextStyle navInactiveLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary, // 60% white
  );

  // ===== BADGES =====

  /// Badge sizes and styles
  static const double badgeSize = 16.0;
  static const double badgeSizeSmall = 12.0;

  /// Badge colors (updated for premium theme)
  static const Color badgeDefault = accentBlue; // Blue deep
  static const Color badgeSuccess = accentGreen; // Cyan primary
  static const Color badgeWarning = accentOrange; // Orange (kept)
  static const Color badgeDanger = accentPink; // Pink (kept)

  // ===== GLASSMORPHIC HELPER METHODS =====

  /// Create a glassmorphic decoration
  static BoxDecoration glassmorphicDecoration({
    Color? backgroundColor,
    double borderRadius = 20.0,
    Color? borderColor,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? glassBorder,
        width: 1.0,
      ),
      boxShadow: boxShadow ?? cardShadow,
    );
  }

  /// Create backdrop filter for glassmorphic effect
  static Widget createBackdropFilter({
    required Widget child,
    double sigmaX = 15.0,
    double sigmaY = 15.0,
  }) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: child,
      ),
    );
  }

  // ===== THEME-AWARE HELPER METHODS =====
  // Use these instead of static colors when you need theme support
  
  /// Get theme-aware card background
  /// Usage: DesignTokens.cardBg(context)
  static Color cardBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? cardBackground : const Color(0xFFFFFFFF);
  }

  /// Get theme-aware primary text color
  /// Usage: DesignTokens.textColor(context)
  static Color textColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? neutralWhite : const Color(0xFF0B1220);
  }

  /// Get theme-aware secondary text color
  static Color textColorSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? textSecondary : const Color(0xFF4B5563);
  }

  /// Get theme-aware icon color
  static Color iconColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? neutralWhite : const Color(0xFF0B1220);
  }

  /// Get theme-aware border color
  static Color borderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? glassBorder : const Color(0xFFE5E7EB);
  }

  /// Get theme-aware scaffold background
  static Color scaffoldBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? primaryDark : const Color(0xFFF7F8FA);
  }

  /// Create theme-aware glassmorphic decoration
  static BoxDecoration adaptiveGlassmorphicDecoration(
    BuildContext context, {
    double borderRadius = 20.0,
    List<BoxShadow>? boxShadow,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? cardBackground : const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark ? glassBorder : const Color(0xFFE5E7EB),
        width: 1.0,
      ),
      boxShadow: boxShadow ?? (isDark 
          ? cardShadow 
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ]),
    );
  }
}
