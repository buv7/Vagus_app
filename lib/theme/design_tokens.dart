import 'package:flutter/material.dart';
import 'dart:ui';
import 'tokens.dart';

/// Legacy design-token namespace — retained for backward compatibility.
///
/// All constants below are @Deprecated aliases for [VagusTokens].
/// Migrate call-sites to `VagusTokens.xxx` and remove this file in a future PR.
// ignore_for_file: deprecated_member_use_from_same_package
class DesignTokens {
  DesignTokens._();

  // ===== BACKGROUNDS =====

  @Deprecated('Use VagusTokens.bgBase')
  static const Color primaryDark = VagusTokens.bgBase;

  @Deprecated('Use VagusTokens.bgSurface')
  static const Color darkBackground = VagusTokens.bgSurface;

  @Deprecated('Use VagusTokens.bgSurface')
  static const Color secondaryDark = VagusTokens.bgSurface;

  @Deprecated('Use VagusTokens.surfaceGlass')
  static const Color cardBackground = VagusTokens.surfaceGlass;

  // ===== CYAN / BLUE SPECTRUM =====

  @Deprecated('Use VagusTokens.primary')
  static const Color accentGreen = VagusTokens.primary;

  @Deprecated('Use VagusTokens.primaryDark')
  static const Color accentBlue = VagusTokens.primaryDark;

  @Deprecated('Use VagusTokens.primaryDark')
  static const Color primaryBlue = Color(0xFF0099FF);

  static const Color darkBlue = Color(0xFF0064C8);

  // ===== ACCENT COLORS =====

  @Deprecated('Use VagusTokens.primaryLight')
  static const Color accentTeal = VagusTokens.primaryLight;

  @Deprecated('Use VagusTokens.accentPink')
  static const Color accentPink = VagusTokens.accentPink;

  @Deprecated('Use VagusTokens.secondary')
  static const Color accentPurple = VagusTokens.secondary;

  @Deprecated('Use VagusTokens.accentOrange')
  static const Color accentOrange = VagusTokens.accentOrange;

  // ===== TEXT =====

  @Deprecated('Use VagusTokens.textPrimary')
  static const Color neutralWhite = VagusTokens.textPrimary;

  @Deprecated('Use VagusTokens.textPrimary')
  static const Color textPrimary = VagusTokens.textPrimary;

  @Deprecated('Use VagusTokens.textSecondary')
  static const Color textSecondary = VagusTokens.textSecondary;

  @Deprecated('Use VagusTokens.textTertiary')
  static const Color textTertiary = VagusTokens.textTertiary;

  @Deprecated('Use VagusTokens.textDisabled')
  static const Color textDisabled = VagusTokens.textDisabled;

  static const Color lightGrey  = Color(0xFF2A2433);
  static const Color mediumGrey = Color(0xFF6A7385);
  static const Color darkGrey   = Color(0xFF1C1C1C);

  // ===== GRADIENTS =====

  @Deprecated('Use VagusTokens.gradientPrimary')
  static const LinearGradient primaryGradient = VagusTokens.gradientPrimary;

  static const LinearGradient textGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xCC00C8FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @Deprecated('Use VagusTokens.gradientBackground')
  static const RadialGradient backgroundGradient = VagusTokens.gradientBackground;

  @Deprecated('Use VagusTokens.gradientCard')
  static const LinearGradient cardGradient = VagusTokens.gradientCard;

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF000000), VagusTokens.bgSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @Deprecated('Use VagusTokens.gradientPrimary')
  static const LinearGradient vibrantGradient = VagusTokens.gradientPrimary;

  // ===== SEMANTIC STATES =====

  @Deprecated('Use VagusTokens.success')
  static const Color success = VagusTokens.success;

  @Deprecated('Use VagusTokens.info')
  static const Color info = VagusTokens.info;

  @Deprecated('Use VagusTokens.warning')
  static const Color warn = VagusTokens.warning;

  @Deprecated('Use VagusTokens.error')
  static const Color danger = VagusTokens.error;

  @Deprecated('Use VagusTokens.successBg')
  static const Color successBg = VagusTokens.successBg;

  @Deprecated('Use VagusTokens.infoBg')
  static const Color infoBg = VagusTokens.infoBg;

  @Deprecated('Use VagusTokens.warningBg')
  static const Color warnBg = VagusTokens.warningBg;

  @Deprecated('Use VagusTokens.errorBg')
  static const Color dangerBg = VagusTokens.errorBg;

  // ===== LEGACY BRAND COLORS =====

  static const Color blue600 = VagusTokens.primaryDark;
  static const Color blue500 = VagusTokens.primaryDark;
  static const Color blue200 = Color(0xFFC7D2FE);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue50  = Color(0xFFF2F5FF);
  static const Color blue700 = VagusTokens.primaryDark;
  static const Color blue900 = VagusTokens.bgBase;

  static const Color purple500 = VagusTokens.secondary;
  static const Color purple50  = Color(0xFFF6F0FF);

  static const Color ink900 = VagusTokens.bgBase;
  static const Color ink700 = VagusTokens.bgSurface;
  static const Color ink600 = Color(0xFF2A2433);
  static const Color ink500 = Color(0xFF6A7385);
  static const Color ink400 = VagusTokens.textSecondary;
  static const Color ink300 = VagusTokens.glassBorder;
  static const Color ink200 = VagusTokens.glassBorder;
  static const Color ink100 = Color(0xFFE7EAF2);
  static const Color ink50  = Color(0xFFF7F8FC);

  // ===== TYPOGRAPHY =====

  @Deprecated('Use VagusTokens.displayLg')
  static const TextStyle displayLarge = VagusTokens.displayLg;

  @Deprecated('Use VagusTokens.displayMd')
  static const TextStyle displayMedium = VagusTokens.displayMd;

  @Deprecated('Use VagusTokens.displaySm')
  static const TextStyle displaySmall = VagusTokens.displaySm;

  @Deprecated('Use VagusTokens.titleLg')
  static const TextStyle titleLarge = VagusTokens.titleLg;

  @Deprecated('Use VagusTokens.titleMd')
  static const TextStyle titleMedium = VagusTokens.titleMd;

  @Deprecated('Use VagusTokens.titleSm')
  static const TextStyle titleSmall = VagusTokens.titleSm;

  @Deprecated('Use VagusTokens.bodyLg')
  static const TextStyle bodyLarge = VagusTokens.bodyLg;

  @Deprecated('Use VagusTokens.bodyMd')
  static const TextStyle bodyMedium = VagusTokens.bodyMd;

  @Deprecated('Use VagusTokens.bodySm')
  static const TextStyle bodySmall = VagusTokens.bodySm;

  @Deprecated('Use VagusTokens.labelMd')
  static const TextStyle labelMedium = VagusTokens.labelMd;

  @Deprecated('Use VagusTokens.labelSm')
  static const TextStyle labelSmall = VagusTokens.labelSm;

  // ===== SPACING =====

  @Deprecated('Use VagusTokens.space2')
  static const double space2 = VagusTokens.space2;
  @Deprecated('Use VagusTokens.spaceXs or VagusTokens.space4')
  static const double space4 = VagusTokens.space4;
  @Deprecated('Use VagusTokens.space6')
  static const double space6 = VagusTokens.space6;
  @Deprecated('Use VagusTokens.spaceSm or VagusTokens.space8')
  static const double space8 = VagusTokens.space8;
  @Deprecated('Use VagusTokens.space12')
  static const double space12 = VagusTokens.space12;
  @Deprecated('Use VagusTokens.space14')
  static const double space14 = VagusTokens.space14;
  @Deprecated('Use VagusTokens.spaceMd or VagusTokens.space16')
  static const double space16 = VagusTokens.space16;
  @Deprecated('Use VagusTokens.space20')
  static const double space20 = VagusTokens.space20;
  @Deprecated('Use VagusTokens.spaceLg or VagusTokens.space24')
  static const double space24 = VagusTokens.space24;
  @Deprecated('Use VagusTokens.spaceXl or VagusTokens.space32')
  static const double space32 = VagusTokens.space32;
  @Deprecated('Use VagusTokens.spaceXxl or VagusTokens.space48')
  static const double space48 = VagusTokens.space48;

  // ===== RADIUS =====

  static const double radius4  = 4.0;
  static const double radius6  = 6.0;

  @Deprecated('Use VagusTokens.radiusSm')
  static const double radius8 = VagusTokens.radiusSm;

  @Deprecated('Use VagusTokens.radiusMd')
  static const double radius12 = VagusTokens.radiusMd;

  @Deprecated('Use VagusTokens.radiusLg')
  static const double radius16 = VagusTokens.radiusLg;

  static const double radius20 = 20.0;

  @Deprecated('Use VagusTokens.radiusXl')
  static const double radius24 = VagusTokens.radiusXl;

  static const double radius28 = 28.0;

  @Deprecated('Use VagusTokens.radiusPill')
  static const double radiusFull = VagusTokens.radiusPill;

  // ===== SHADOWS / GLASSMORPHIC =====

  @Deprecated('Use VagusTokens.shadowSm')
  static const List<BoxShadow> glowSm = VagusTokens.shadowSm;

  @Deprecated('Use VagusTokens.shadowMd')
  static const List<BoxShadow> glowMd = VagusTokens.shadowMd;

  @Deprecated('Use VagusTokens.shadowLg')
  static const List<BoxShadow> glowLg = VagusTokens.shadowLg;

  @Deprecated('Use VagusTokens.shadowPurple')
  static const List<BoxShadow> glowPurple = VagusTokens.shadowPurple;

  @Deprecated('Use VagusTokens.shadowCard')
  static const List<BoxShadow> cardShadow = VagusTokens.shadowCard;

  @Deprecated('Use VagusTokens.shadowSubtle')
  static const List<BoxShadow> shadowDark = VagusTokens.shadowSubtle;

  @Deprecated('Use VagusTokens.glassBorder')
  static const Color glassBorder = VagusTokens.glassBorder;

  @Deprecated('Use VagusTokens.glassBorderAccent')
  static const Color glassBorderAccent = VagusTokens.glassBorderAccent;

  @Deprecated('Use VagusTokens.glassBlurSm')
  static const double blurSm = VagusTokens.glassBlurSm;

  @Deprecated('Use VagusTokens.glassBlurMd')
  static const double blurMd = VagusTokens.glassBlurMd;

  @Deprecated('Use VagusTokens.glassBlurLg')
  static const double blurLg = VagusTokens.glassBlurLg;

  // ===== ANIMATION =====

  @Deprecated('Use VagusTokens.animFast')
  static const Duration durationFast = VagusTokens.animFast;

  @Deprecated('Use VagusTokens.animNormal')
  static const Duration durationNormal = VagusTokens.animNormal;

  @Deprecated('Use VagusTokens.animSlow')
  static const Duration durationSlow = VagusTokens.animSlow;

  // ===== CATEGORY COLORS =====

  static const Map<String, Color> categoryColors = {
    'workout':   Color(0xFF0099FF),
    'nutrition': VagusTokens.primary,
    'calling':   VagusTokens.accentPink,
    'coach':     VagusTokens.secondary,
    'other':     Color(0xFF6A7385),
  };

  static const Map<String, Color> categoryBgColors = {
    'workout':   Color(0x200099FF),
    'nutrition': Color(0x2000C8FF),
    'calling':   Color(0x20FF6B9D),
    'coach':     Color(0x209D6BFF),
    'other':     Color(0x206A7385),
  };

  // ===== NAVIGATION =====

  static const Color navActive   = VagusTokens.primary;
  static const Color navInactive = VagusTokens.textSecondary;

  static const TextStyle navActiveLabel = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600, color: VagusTokens.primary,
  );
  static const TextStyle navInactiveLabel = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: VagusTokens.textSecondary,
  );

  // ===== BADGES =====

  static const double badgeSize      = 16.0;
  static const double badgeSizeSmall = 12.0;

  static const Color badgeDefault = VagusTokens.primaryDark;
  static const Color badgeSuccess = VagusTokens.primary;
  static const Color badgeWarning = VagusTokens.accentOrange;
  static const Color badgeDanger  = VagusTokens.accentPink;

  // ===== GLASSMORPHIC HELPER METHODS =====

  static BoxDecoration glassmorphicDecoration({
    Color? backgroundColor,
    double borderRadius = 20.0,
    Color? borderColor,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? VagusTokens.surfaceGlass,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? VagusTokens.glassBorder,
        width: 1.0,
      ),
      boxShadow: boxShadow ?? VagusTokens.shadowCard,
    );
  }

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

  // ===== THEME-AWARE HELPERS =====

  static Color cardBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? VagusTokens.surfaceGlass : const Color(0xFFFFFFFF);
  }

  static Color textColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? VagusTokens.textPrimary : VagusTokens.textInverse;
  }

  static Color textColorSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? VagusTokens.textSecondary : const Color(0xFF4B5563);
  }

  static Color iconColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? VagusTokens.textPrimary : VagusTokens.textInverse;
  }

  static Color borderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? VagusTokens.glassBorder : const Color(0xFFE5E7EB);
  }

  static Color scaffoldBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? VagusTokens.bgBase : const Color(0xFFF7F8FA);
  }

  static BoxDecoration adaptiveGlassmorphicDecoration(
    BuildContext context, {
    double borderRadius = 20.0,
    List<BoxShadow>? boxShadow,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? VagusTokens.surfaceGlass : const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark ? VagusTokens.glassBorder : const Color(0xFFE5E7EB),
        width: 1.0,
      ),
      boxShadow: boxShadow ?? (isDark
          ? VagusTokens.shadowCard
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
