import 'package:flutter/material.dart';

/// Design tokens for Soft Aurora UI/UX v1
/// Centralized constants for colors, typography, spacing, and shadows
class DesignTokens {
  // Private constructor to prevent instantiation
  DesignTokens._();

  // ===== COLORS =====
  
  /// Brand Colors (soft blue focus + purple accent)
  static const Color blue600 = Color(0xFF6C83F7); // Primary brand
  static const Color blue500 = Color(0xFF7D90F8); // Secondary brand
  static const Color blue200 = Color(0xFFC7D2FE); // Light brand border
  static const Color blue100 = Color(0xFFDBEAFE); // Very light brand tint
  static const Color blue50 = Color(0xFFF2F5FF);  // Light brand tint
  static const Color blue700 = Color(0xFF5B6BF9); // Darker brand
  static const Color blue900 = Color(0xFF101426); // Dark brand
  
  /// Accent Colors
  static const Color purple500 = Color(0xFFA26BFA); // Primary accent
  static const Color purple50 = Color(0xFFF6F0FF);  // Light accent tint
  
  /// Neutral Colors
  static const Color ink900 = Color(0xFF0E1016); // Darkest text
  static const Color ink700 = Color(0xFF2A2F3A); // Dark text
  static const Color ink600 = Color(0xFF4A5568); // Medium-dark text
  static const Color ink500 = Color(0xFF6A7385); // Medium text
  static const Color ink400 = Color(0xFF9CA3AF); // Medium-light text
  static const Color ink300 = Color(0xFFD1D5DB); // Light borders
  static const Color ink200 = Color(0xFFE5E7EB); // Lighter borders
  static const Color ink100 = Color(0xFFE7EAF2); // Light borders
  static const Color ink50 = Color(0xFFF7F8FC);  // Lightest surface
  
  /// State Colors (muted, accessible)
  static const Color success = Color(0xFF2BB673); // Success green
  static const Color info = Color(0xFF3AA0FF);    // Info blue
  static const Color warn = Color(0xFFFFB74D);    // Warning orange
  static const Color danger = Color(0xFFFF6B6B);  // Danger red
  
  /// State Background Colors (70-80% tints)
  static const Color successBg = Color(0xFFE8F5E8);
  static const Color infoBg = Color(0xFFE3F2FD);
  static const Color warnBg = Color(0xFFFFF3E0);
  static const Color dangerBg = Color(0xFFFFEBEE);

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
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // ===== RADIUS =====
  
  /// Border radius values
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius28 = 28.0;
  static const double radiusFull = 999.0;

  // ===== SHADOWS =====
  
  /// Light mode shadows (soft, tinted with brand colors)
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x1A6C83F7), // Blue600 @ 10%
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: -2,
    ),
  ];
  
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A6C83F7), // Blue600 @ 10%
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
  ];
  
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1F6C83F7), // Blue600 @ 12%
      blurRadius: 24,
      offset: Offset(0, 12),
      spreadRadius: -6,
    ),
  ];
  
  /// Dark mode shadows (minimal, elevation-based)
  static const List<BoxShadow> shadowDark = [
    BoxShadow(
      color: Color(0x0A000000), // Black @ 4%
      blurRadius: 8,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // ===== ANIMATION DURATIONS =====
  
  /// Motion durations (160-220ms for micro-interactions)
  static const Duration durationFast = Duration(milliseconds: 160);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 220);

  // ===== CATEGORY COLORS =====
  
  /// Category color mapping for consistent visual hierarchy
  static const Map<String, Color> categoryColors = {
    'workout': blue600,
    'nutrition': purple500,
    'session': success,
    'other': ink500,
  };
  
  /// Category background colors (light tints)
  static const Map<String, Color> categoryBgColors = {
    'workout': blue50,
    'nutrition': purple50,
    'session': successBg,
    'other': ink50,
  };

  // ===== NAVIGATION =====
  
  /// Navigation active state colors
  static const Color navActive = blue600;
  static const Color navInactive = Color(0x996A7385); // Ink500 @ 60%
  
  /// Navigation active state styles
  static const TextStyle navActiveLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: blue600,
  );
  
  static const TextStyle navInactiveLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0x996A7385), // Ink500 @ 60%
  );

  // ===== BADGES =====
  
  /// Badge sizes and styles
  static const double badgeSize = 16.0;
  static const double badgeSizeSmall = 12.0;
  
  /// Badge colors
  static const Color badgeDefault = blue600;
  static const Color badgeSuccess = success;
  static const Color badgeWarning = warn;
  static const Color badgeDanger = danger;
}
