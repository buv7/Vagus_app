// ignore_for_file: deprecated_member_use_from_same_package
import 'tokens.dart';

/// Consistent spacing system for Nutrition Platform 2.0.
///
/// Core spacing values are @Deprecated aliases for [VagusTokens].
/// Nutrition-domain-specific sizing (avatar, meal images, charts) remains here.
///
/// Provides a standardized set of spacing values to ensure visual consistency
/// across all nutrition screens and components.
///
/// Usage:
/// ```dart
/// Padding(
///   padding: EdgeInsets.all(NutritionSpacing.md),
///   child: Column(
///     children: [
///       Text('Meal Name'),
///       SizedBox(height: NutritionSpacing.sm),
///       Text('Macros'),
///     ],
///   ),
/// )
/// ```
class NutritionSpacing {
  // Prevent instantiation
  NutritionSpacing._();

  // ============================================================
  // SPACING SCALE
  // ============================================================

  @Deprecated('Use VagusTokens.spaceXs (4 px)')
  static const double xxs = VagusTokens.spaceXs;    // 4 px

  @Deprecated('Use VagusTokens.spaceSm (8 px)')
  static const double xs = VagusTokens.spaceSm;     // 8 px

  /// 12 px — no direct VagusTokens alias; use VagusTokens.space12
  static const double sm = VagusTokens.space12;     // 12 px

  @Deprecated('Use VagusTokens.spaceMd (16 px)')
  static const double md = VagusTokens.spaceMd;     // 16 px

  @Deprecated('Use VagusTokens.spaceLg (24 px)')
  static const double lg = VagusTokens.spaceLg;     // 24 px

  @Deprecated('Use VagusTokens.spaceXl (32 px)')
  static const double xl = VagusTokens.spaceXl;     // 32 px

  @Deprecated('Use VagusTokens.spaceXxl (48 px)')
  static const double xxl = VagusTokens.spaceXxl;   // 48 px

  // ============================================================
  // SEMANTIC SPACING
  // ============================================================

  /// Standard screen horizontal padding
  static const double screenHorizontal = md;

  /// Standard screen vertical padding
  static const double screenVertical = md;

  /// Card internal padding
  static const double cardPadding = md;

  /// Card external margin
  static const double cardMargin = sm;

  /// List item vertical spacing
  static const double listItemVertical = sm;

  /// List item horizontal spacing
  static const double listItemHorizontal = md;

  /// Section header bottom margin
  static const double sectionHeaderBottom = lg;

  /// Bottom sheet padding
  static const double bottomSheetPadding = lg;

  /// Modal dialog padding
  static const double modalPadding = lg;

  /// FAB bottom margin
  static const double fabBottom = xl;

  /// AppBar bottom padding
  static const double appBarBottom = md;

  // ============================================================
  // BORDER RADIUS
  // ============================================================

  @Deprecated('Use VagusTokens.radiusSm')
  static const double radiusSm = VagusTokens.radiusSm;

  @Deprecated('Use VagusTokens.radiusMd')
  static const double radiusMd = VagusTokens.radiusMd;

  @Deprecated('Use VagusTokens.radiusLg')
  static const double radiusLg = VagusTokens.radiusLg;

  @Deprecated('Use VagusTokens.radiusXl')
  static const double radiusXl = VagusTokens.radiusXl;

  @Deprecated('Use VagusTokens.radiusPill')
  static const double radiusCircular = VagusTokens.radiusPill;

  // ============================================================
  // ICON SIZES
  // ============================================================

  /// Small icon size
  static const double iconSm = 16.0;

  /// Medium icon size (default)
  static const double iconMd = 24.0;

  /// Large icon size
  static const double iconLg = 32.0;

  /// Extra large icon size (for hero icons)
  static const double iconXl = 48.0;

  // ============================================================
  // AVATAR/IMAGE SIZES
  // ============================================================

  /// Small avatar size
  static const double avatarSm = 32.0;

  /// Medium avatar size
  static const double avatarMd = 48.0;

  /// Large avatar size
  static const double avatarLg = 64.0;

  /// Extra large avatar size
  static const double avatarXl = 96.0;

  /// Meal image thumbnail size (square)
  static const double mealImageSm = 80.0;

  /// Meal image medium size (square)
  static const double mealImageMd = 120.0;

  /// Meal image large size (square)
  static const double mealImageLg = 200.0;

  // ============================================================
  // BUTTON SIZES
  // ============================================================

  /// Button height small
  static const double buttonHeightSm = 36.0;

  /// Button height medium (default)
  static const double buttonHeightMd = 48.0;

  /// Button height large
  static const double buttonHeightLg = 56.0;

  /// Button horizontal padding
  static const double buttonPaddingHorizontal = lg;

  /// Button vertical padding
  static const double buttonPaddingVertical = sm;

  // ============================================================
  // INPUT FIELD SIZES
  // ============================================================

  /// Input field height
  static const double inputHeight = 48.0;

  /// Input field horizontal padding
  static const double inputPaddingHorizontal = md;

  /// Input field vertical padding
  static const double inputPaddingVertical = sm;

  // ============================================================
  // CHART SIZES
  // ============================================================

  /// Macro ring chart small size
  static const double macroRingChartSm = 120.0;

  /// Macro ring chart medium size
  static const double macroRingChartMd = 200.0;

  /// Macro ring chart large size
  static const double macroRingChartLg = 280.0;

  // ============================================================
  // DIVIDER SIZES
  // ============================================================

  /// Divider thickness thin
  static const double dividerThin = 1.0;

  /// Divider thickness medium
  static const double dividerMedium = 2.0;

  /// Divider thickness thick
  static const double dividerThick = 4.0;

}