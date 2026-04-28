import 'package:flutter/material.dart';

/// Canonical design tokens for the Vagus glassmorphic dark purple/navy theme.
///
/// All values are sourced from the existing theme files — nothing invented.
/// This is the single source of truth; all other theme files are deprecated
/// shims that re-export from here.
///
/// Usage:
/// ```dart
/// import 'package:vagus_app/theme/tokens.dart';
///
/// Container(
///   color: VagusTokens.bgSurface,
///   padding: const EdgeInsets.all(VagusTokens.spaceMd),
///   child: Text('Hello', style: VagusTokens.bodyMd),
/// )
/// ```
class VagusTokens {
  VagusTokens._();

  // ═══════════════════════════════════════════════════
  // BACKGROUNDS
  // Dark purple/navy glassmorphic aesthetic
  // ═══════════════════════════════════════════════════

  /// Pure black — scaffold / deepest layer
  static const Color bgBase = Color(0xFF000000);

  /// Dark navy — card / surface background
  static const Color bgSurface = Color(0xFF0A0A14);

  /// Dark navy at 95 % opacity — glass card background
  static const Color surfaceGlass = Color(0xF20A0A14);

  /// Deep purple-navy — modals / bottom sheets
  static const Color bgModal = Color(0xFF1A1A2E);

  // ═══════════════════════════════════════════════════
  // PRIMARY  (Cyan interactive accent)
  // ═══════════════════════════════════════════════════

  /// Cyan — primary interactive accent
  static const Color primary = Color(0xFF00C8FF);

  /// Blue deep — primary variant / pressed state
  static const Color primaryDark = Color(0xFF0080FF);

  /// Teal — primary light / hover
  static const Color primaryLight = Color(0xFF00FFC8);

  // ═══════════════════════════════════════════════════
  // SECONDARY  (Purple accent)
  // ═══════════════════════════════════════════════════

  /// Purple — secondary accent (coach, rank, AI features)
  static const Color secondary = Color(0xFF9D6BFF);

  // ═══════════════════════════════════════════════════
  // ADDITIONAL ACCENTS
  // ═══════════════════════════════════════════════════

  /// Pink — calling, error highlights, premium gradient end
  static const Color accentPink = Color(0xFFFF6B9D);

  /// Orange — nutrition warmth, warning highlights
  static const Color accentOrange = Color(0xFFFF9D6B);

  // ═══════════════════════════════════════════════════
  // SEMANTIC STATES
  // ═══════════════════════════════════════════════════

  static const Color success = Color(0xFF00D9A3);   // Teal-green
  static const Color warning = Color(0xFFFFBF47);   // Amber
  static const Color error   = Color(0xFFFF6B6B);   // Red
  static const Color info    = Color(0xFF4A90E2);   // Blue

  /// 12 % tint backgrounds for state chips / banners
  static const Color successBg = Color(0x2000D9A3);
  static const Color warningBg = Color(0x20FFBF47);
  static const Color errorBg   = Color(0x20FF6B6B);
  static const Color infoBg    = Color(0x204A90E2);

  // ═══════════════════════════════════════════════════
  // TEXT
  // ═══════════════════════════════════════════════════

  static const Color textPrimary   = Color(0xFFFFFFFF);         // 100 %
  static const Color textSecondary = Color(0x99FFFFFF);         //  60 %
  static const Color textTertiary  = Color(0x66FFFFFF);         //  40 %
  static const Color textDisabled  = Color(0x4DFFFFFF);         //  30 %
  static const Color textInverse   = Color(0xFF0B1220);         // dark text on light/accent bg

  // ═══════════════════════════════════════════════════
  // DIVIDERS / GLASS BORDERS
  // ═══════════════════════════════════════════════════

  static const Color divider           = Color(0x14FFFFFF);     //  8 % white
  static const Color glassBorder       = Color(0x14FFFFFF);     //  8 % white (alias)
  static const Color glassBorderStrong = Color(0x28FFFFFF);     // 16 % white
  static const Color glassBorderAccent = Color(0x4000C8FF);     // 25 % cyan

  // ═══════════════════════════════════════════════════
  // NUTRITION MACRO COLORS
  // ═══════════════════════════════════════════════════

  static const Color macroProtein  = Color(0xFF00D9A3);   // Teal-green
  static const Color macroCarbs    = Color(0xFFFF9A3C);   // Orange
  static const Color macroFat      = Color(0xFFFFD93C);   // Yellow
  static const Color macroCalories = Color(0xFFFF6B6B);   // Red

  // ═══════════════════════════════════════════════════
  // GRADIENTS
  // ═══════════════════════════════════════════════════

  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF00C8FF), Color(0xFF0080FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientPurple = LinearGradient(
    colors: [Color(0xFF9D6BFF), Color(0xFFFF6B9D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientPremium = LinearGradient(
    colors: [Color(0xFF00C8FF), Color(0xFF00D4AA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientCard = LinearGradient(
    colors: [Color(0x40FFFFFF), Color(0x10FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient gradientBackground = RadialGradient(
    colors: [
      Color(0x1A00C8FF),
      Color(0x0D0080FF),
      Color(0xFF000000),
    ],
    stops: [0.0, 0.5, 1.0],
    center: Alignment.center,
    radius: 1.5,
  );

  // ═══════════════════════════════════════════════════
  // TYPOGRAPHY
  // ═══════════════════════════════════════════════════

  // Display — ultra-light for premium feel
  static const TextStyle displayLg = TextStyle(
    fontSize: 72, fontWeight: FontWeight.w100, letterSpacing: -2, height: 1.1,
  );
  static const TextStyle displayMd = TextStyle(
    fontSize: 48, fontWeight: FontWeight.w100, letterSpacing: -1, height: 1.2,
  );
  static const TextStyle displaySm = TextStyle(
    fontSize: 34, fontWeight: FontWeight.w200, letterSpacing: -0.5, height: 1.2,
  );

  // Headline — bold, for screen / section titles
  static const TextStyle headlineLg = TextStyle(
    fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, height: 1.2,
  );
  static const TextStyle headlineMd = TextStyle(
    fontSize: 28, fontWeight: FontWeight.bold, height: 1.3,
  );
  static const TextStyle headlineSm = TextStyle(
    fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.3, height: 1.3,
  );

  // Title — regular weight
  static const TextStyle titleLg = TextStyle(fontSize: 24, fontWeight: FontWeight.w400, height: 1.3);
  static const TextStyle titleMd = TextStyle(fontSize: 20, fontWeight: FontWeight.w400, height: 1.3);
  static const TextStyle titleSm = TextStyle(fontSize: 18, fontWeight: FontWeight.w400, height: 1.3);

  // Body
  static const TextStyle bodyLg = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.8);
  static const TextStyle bodyMd = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6);
  static const TextStyle bodySm = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);

  // Label — semibold, for buttons / chips
  static const TextStyle labelLg = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);
  static const TextStyle labelMd = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4);
  static const TextStyle labelSm = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.5, height: 1.4,
  );

  // ═══════════════════════════════════════════════════
  // SPACING  (8-pt grid)
  // ═══════════════════════════════════════════════════

  static const double spaceXs  =  4.0;
  static const double spaceSm  =  8.0;
  static const double spaceMd  = 16.0;
  static const double spaceLg  = 24.0;
  static const double spaceXl  = 32.0;
  static const double spaceXxl = 48.0;

  // Fine-grained helpers
  static const double space2  =  2.0;
  static const double space4  =  4.0;
  static const double space6  =  6.0;
  static const double space8  =  8.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // ═══════════════════════════════════════════════════
  // RADIUS
  // ═══════════════════════════════════════════════════

  static const double radiusSm   =   8.0;
  static const double radiusMd   =  12.0;
  static const double radiusLg   =  16.0;
  static const double radiusXl   =  24.0;
  static const double radiusPill = 999.0;

  // ═══════════════════════════════════════════════════
  // ELEVATION / SHADOWS
  // ═══════════════════════════════════════════════════

  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x4000C8FF), blurRadius: 20, spreadRadius: 0),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x400080FF), blurRadius: 30, spreadRadius: 0),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x4000C8FF), blurRadius: 40, spreadRadius: 0),
  ];
  static const List<BoxShadow> shadowPurple = [
    BoxShadow(color: Color(0x4000FFC8), blurRadius: 30, spreadRadius: 0),
  ];
  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color(0x20000000), blurRadius: 16, offset: Offset(0, 8), spreadRadius: -4,
    ),
  ];
  static const List<BoxShadow> shadowSubtle = [
    BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 6)),
  ];

  // ═══════════════════════════════════════════════════
  // GLASS TOKENS
  // ═══════════════════════════════════════════════════

  static const double glassBlurSm = 10.0;
  static const double glassBlurMd = 15.0;
  static const double glassBlurLg = 20.0;

  /// Fractional opacity of a glass panel fill  (8 %)
  static const double glassOpacity = 0.08;

  /// Gradient colours / stops for a glass shimmer overlay
  static const List<Color>  glassGradientColors = [Color(0x40FFFFFF), Color(0x10FFFFFF)];
  static const List<double> glassGradientStops  = [0.0, 1.0];

  // ═══════════════════════════════════════════════════
  // ANIMATION
  // ═══════════════════════════════════════════════════

  static const Duration animFast   = Duration(milliseconds: 160);
  static const Duration animNormal = Duration(milliseconds: 200);
  static const Duration animSlow   = Duration(milliseconds: 220);
}
