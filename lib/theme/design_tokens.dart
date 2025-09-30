import 'package:flutter/material.dart';
import 'dart:ui';

/// Design tokens for NFT Marketplace UI/UX v2
/// Centralized constants for colors, typography, spacing, shadows, and glassmorphic effects
class DesignTokens {
  // Private constructor to prevent instantiation
  DesignTokens._();

  // ===== NFT MARKETPLACE COLORS =====

  /// Primary Background Colors - Dark purple/navy theme
  static const Color primaryDark = Color(0xFF0F0B1F);      // Deep navy background
  static const Color secondaryDark = Color(0xFF1A1525);    // Dark purple
  static const Color cardBackground = Color(0x991E172D);   // Semi-transparent dark with blur

  /// Accent Colors - Vibrant NFT marketplace colors
  static const Color accentGreen = Color(0xFF00E5A0);      // Bright green (replaces mintAqua)
  static const Color accentPink = Color(0xFFFF6B9D);       // Pink
  static const Color accentBlue = Color(0xFF6B8AFF);       // Blue
  static const Color accentPurple = Color(0xFF9D6BFF);     // Purple gradient
  static const Color accentOrange = Color(0xFFFF9D6B);     // Orange (optional)

  /// Neutral Colors - Updated for dark theme
  static const Color neutralWhite = Color(0xFFFFFFFF);     // Pure white text
  static const Color textSecondary = Color(0x99FFFFFF);    // 60% opacity white
  static const Color lightGrey = Color(0xFF2A2433);        // Darker grey for dark theme
  static const Color mediumGrey = Color(0xFF6A7385);       // Medium text
  static const Color darkGrey = Color(0xFF1C1C1C);         // Dark card backgrounds

  /// Gradient Definitions
  static const LinearGradient vibrantGradient = LinearGradient(
    colors: [Color(0xFF6B8AFF), Color(0xFF9D6BFF), Color(0xFFFF6B9D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0x40FFFFFF), Color(0x10FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F0B1F), Color(0xFF1A1525)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// State Colors (updated for NFT theme)
  static const Color success = Color(0xFF00E5A0); // Use accent green
  static const Color info = Color(0xFF6B8AFF);    // Use accent blue
  static const Color warn = Color(0xFFFF9D6B);    // Use accent orange
  static const Color danger = Color(0xFFFF6B9D);  // Use accent pink

  /// State Background Colors (dark theme variants)
  static const Color successBg = Color(0x2000E5A0); // 12% opacity
  static const Color infoBg = Color(0x206B8AFF);
  static const Color warnBg = Color(0x20FF9D6B);
  static const Color dangerBg = Color(0x20FF6B9D);

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
  
  /// Display Text (semibold)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  /// Title Text (semibold)
  static const TextStyle titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  /// Body Text (regular)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  /// Meta/Label Text (medium)
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
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

  /// Glassmorphic shadows with NFT glow effects
  static const List<BoxShadow> glowSm = [
    BoxShadow(
      color: Color(0x4000E5A0), // Accent green @ 25%
      blurRadius: 20,
      offset: Offset(0, 0),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> glowMd = [
    BoxShadow(
      color: Color(0x406B8AFF), // Accent blue @ 25%
      blurRadius: 30,
      offset: Offset(0, 0),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> glowLg = [
    BoxShadow(
      color: Color(0x40FF6B9D), // Accent pink @ 25%
      blurRadius: 40,
      offset: Offset(0, 0),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> glowPurple = [
    BoxShadow(
      color: Color(0x409D6BFF), // Accent purple @ 25%
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
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white
  static const Color glassBorderAccent = Color(0x4000E5A0); // 25% green

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

  /// Category color mapping for consistent visual hierarchy (updated for NFT theme)
  static const Map<String, Color> categoryColors = {
    'workout': accentBlue,     // Blue for workouts
    'nutrition': accentGreen,  // Green for nutrition
    'calling': accentPink,     // Pink for calling/sessions
    'coach': accentPurple,     // Purple for coaching
    'other': mediumGrey,       // Grey for other
  };

  /// Category background colors (dark theme variants)
  static const Map<String, Color> categoryBgColors = {
    'workout': Color(0x206B8AFF),   // Blue @ 12%
    'nutrition': Color(0x2000E5A0), // Green @ 12%
    'calling': Color(0x20FF6B9D),   // Pink @ 12%
    'coach': Color(0x209D6BFF),     // Purple @ 12%
    'other': Color(0x206A7385),     // Grey @ 12%
  };

  // ===== NAVIGATION =====

  /// Navigation active state colors (updated for NFT theme)
  static const Color navActive = accentGreen;
  static const Color navInactive = textSecondary; // 60% white

  /// Navigation active state styles
  static const TextStyle navActiveLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700, // Increased weight
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

  /// Badge colors (updated for NFT theme)
  static const Color badgeDefault = accentBlue;
  static const Color badgeSuccess = accentGreen;
  static const Color badgeWarning = accentOrange;
  static const Color badgeDanger = accentPink;

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
}
