/// Consistent spacing system for Nutrition Platform 2.0.
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

  /// Extra extra small spacing (4.0 logical pixels)
  ///
  /// Use for: Tight spacing between related elements, icon padding
  static const double xxs = 4.0;

  /// Extra small spacing (8.0 logical pixels)
  ///
  /// Use for: Small gaps, chip spacing, badge padding
  static const double xs = 8.0;

  /// Small spacing (12.0 logical pixels)
  ///
  /// Use for: Vertical spacing between related items, small margins
  static const double sm = 12.0;

  /// Medium spacing (16.0 logical pixels) - DEFAULT
  ///
  /// Use for: Standard padding, default margins, card padding
  static const double md = 16.0;

  /// Large spacing (24.0 logical pixels)
  ///
  /// Use for: Section separation, large margins
  static const double lg = 24.0;

  /// Extra large spacing (32.0 logical pixels)
  ///
  /// Use for: Major section breaks, screen padding
  static const double xl = 32.0;

  /// Extra extra large spacing (48.0 logical pixels)
  ///
  /// Use for: Major visual breaks, hero section spacing
  static const double xxl = 48.0;

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

  /// Small border radius for chips and badges
  static const double radiusSm = 8.0;

  /// Medium border radius for cards and buttons
  static const double radiusMd = 12.0;

  /// Large border radius for major containers
  static const double radiusLg = 16.0;

  /// Extra large border radius for sheets and modals
  static const double radiusXl = 24.0;

  /// Circular border radius (50% of size)
  static const double radiusCircular = 9999.0;

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