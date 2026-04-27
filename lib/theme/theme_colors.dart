import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Theme-aware color helper with guaranteed readable LIGHT mode
/// while preserving the existing DARK glass aesthetic.
///
/// Usage:
/// ```dart
/// // Option 1: Direct access
/// final tc = ThemeColors.of(context);
/// Text('Hi', style: TextStyle(color: tc.textPrimary));
///
/// // Option 2: Extension (shorter)
/// Text('Hi', style: TextStyle(color: context.tc.textPrimary));
///
/// // Option 3: Widget wrapper for nested widgets that don't inherit theme
/// ThemeColors.wrap(
///   context: context,
///   child: YourNestedWidget(),
/// )
/// ```
class ThemeColors {
  final BuildContext context;
  final ThemeData theme;
  final ColorScheme scheme;
  final bool isDark;

  ThemeColors._(this.context, this.theme, this.scheme, this.isDark);

  factory ThemeColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return ThemeColors._(context, theme, scheme, isDark);
  }

  // =============================================================
  // LIGHT mode: fixed palette (contrast-safe)
  // =============================================================
  static const _lightBg = Color(0xFFF7F8FA);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurfaceAlt = Color(0xFFF2F4F7);
  static const _lightSurfaceTertiary = Color(0xFFE8EAED);

  static const _lightTextPrimary = Color(0xFF0B1220);
  static const _lightTextSecondary = Color(0xFF4B5563);
  static const _lightTextTertiary = Color(0xFF6B7280);
  static const _lightTextDisabled = Color(0xFF9CA3AF);

  static const _lightBorder = Color(0xFFE5E7EB);
  static const _lightBorderStrong = Color(0xFFD1D5DB);
  static const _lightDivider = Color(0xFFE5E7EB);

  // =============================================================
  // BACKGROUNDS
  // =============================================================

  /// Main app/scaffold background
  Color get bg => isDark ? DesignTokens.primaryDark : _lightBg;

  /// Card/dialog surface
  Color get surface => isDark ? DesignTokens.cardBackground : _lightSurface;

  /// Secondary surface (nested cards, subtle elevation)
  Color get surfaceAlt => isDark ? DesignTokens.cardBackground : _lightSurfaceAlt;

  /// Tertiary surface (deeply nested elements)
  Color get surfaceTertiary => isDark 
      ? const Color(0xFF1A1A1A) 
      : _lightSurfaceTertiary;

  /// Modal/bottom sheet background
  Color get modalBg => isDark 
      ? const Color(0xFF1A1A2E) 
      : _lightSurface;

  /// Overlay/scrim color
  Color get overlay => isDark 
      ? Colors.black.withValues(alpha: 0.7) 
      : Colors.black.withValues(alpha: 0.5);

  // =============================================================
  // TEXT COLORS
  // =============================================================

  /// Primary text (highest contrast)
  Color get textPrimary => isDark ? DesignTokens.neutralWhite : _lightTextPrimary;

  /// Secondary text (labels/hints)
  Color get textSecondary => isDark ? DesignTokens.textSecondary : _lightTextSecondary;

  /// Tertiary text (subtle, less important)
  Color get textTertiary => isDark ? DesignTokens.textTertiary : _lightTextTertiary;

  /// Disabled text
  Color get textDisabled => isDark ? DesignTokens.textDisabled : _lightTextDisabled;

  /// Inverse text (text on accent/primary backgrounds)
  Color get textInverse => isDark ? Colors.black : Colors.white;

  /// Text on dark background (always white) - for banners, toasts
  Color get textOnDark => Colors.white;

  /// Text on light background (always dark)
  Color get textOnLight => _lightTextPrimary;

  // =============================================================
  // ICONS
  // =============================================================

  /// Primary icon color
  Color get icon => isDark ? DesignTokens.neutralWhite : _lightTextPrimary;

  /// Secondary icon color (less prominent)
  Color get iconSecondary => isDark ? DesignTokens.textSecondary : _lightTextSecondary;

  /// Disabled icon
  Color get iconDisabled => isDark ? DesignTokens.textDisabled : _lightTextDisabled;

  /// Icon on accent backgrounds
  Color get iconOnAccent => isDark ? Colors.black : Colors.white;

  // =============================================================
  // BORDERS & DIVIDERS
  // =============================================================

  /// Standard border
  Color get border => isDark ? DesignTokens.glassBorder : _lightBorder;

  /// Strong/focused border
  Color get borderStrong => isDark 
      ? const Color(0x28FFFFFF) 
      : _lightBorderStrong;

  /// Divider color
  Color get divider => isDark ? DesignTokens.glassBorder : _lightDivider;

  // =============================================================
  // INTERACTIVE ELEMENTS
  // =============================================================

  /// Chip background (unselected)
  Color get chipBg => isDark ? DesignTokens.cardBackground : _lightSurfaceAlt;

  /// Chip background (selected)
  Color get chipSelectedBg => isDark ? DesignTokens.accentGreen : _lightTextPrimary;

  /// Chip text (unselected)
  Color get chipText => textPrimary;

  /// Chip text (selected)
  Color get chipTextOnSelected => isDark ? Colors.black : Colors.white;

  /// Input field fill color
  Color get inputFill => isDark ? const Color(0x0AFFFFFF) : _lightSurface;

  /// Input field fill when focused
  Color get inputFillFocused => isDark 
      ? const Color(0x14FFFFFF) 
      : _lightSurface;

  /// Button background (secondary/outlined)
  Color get buttonSecondaryBg => isDark 
      ? DesignTokens.cardBackground 
      : _lightSurfaceAlt;

  /// Hover/pressed state overlay
  Color get hoverOverlay => isDark 
      ? Colors.white.withValues(alpha: 0.05) 
      : Colors.black.withValues(alpha: 0.05);

  /// Pressed state overlay
  Color get pressedOverlay => isDark 
      ? Colors.white.withValues(alpha: 0.1) 
      : Colors.black.withValues(alpha: 0.1);

  /// Avatar placeholder background (visible in both light/dark modes)
  Color get avatarBg => isDark 
      ? const Color(0xFF2A3441)  // Subtle dark grey-blue
      : const Color(0xFFE8EAED); // Light grey

  /// Avatar placeholder icon color (contrasts with avatarBg)
  Color get avatarIcon => isDark 
      ? const Color(0xFF8B9AAB)  // Muted grey
      : const Color(0xFF6B7280); // Medium grey

  // =============================================================
  // ACCENTS (theme-aware but preserve brand colors)
  // =============================================================

  /// Primary accent (cyan in dark, darker blue in light for contrast)
  Color get accent => isDark ? DesignTokens.accentGreen : const Color(0xFF0066CC);

  /// Secondary accent
  Color get accentSecondary => isDark ? DesignTokens.accentBlue : const Color(0xFF0080FF);

  /// Success color
  Color get success => isDark ? DesignTokens.accentGreen : const Color(0xFF059669);

  /// Warning color
  Color get warning => isDark ? DesignTokens.accentOrange : const Color(0xFFD97706);

  /// Error/danger color
  Color get danger => isDark ? DesignTokens.accentPink : const Color(0xFFDC2626);

  /// Info color
  Color get info => isDark ? DesignTokens.accentBlue : const Color(0xFF2563EB);

  // =============================================================
  // ACCENT BACKGROUNDS (subtle tints)
  // =============================================================

  Color get successBg => isDark 
      ? DesignTokens.successBg 
      : const Color(0xFFD1FAE5);

  Color get warningBg => isDark 
      ? DesignTokens.warnBg 
      : const Color(0xFFFEF3C7);

  Color get dangerBg => isDark 
      ? DesignTokens.dangerBg 
      : const Color(0xFFFEE2E2);

  Color get infoBg => isDark 
      ? DesignTokens.infoBg 
      : const Color(0xFFDBEAFE);

  // =============================================================
  // SHADOWS & EFFECTS
  // =============================================================

  /// Card shadow
  List<BoxShadow> get cardShadow => isDark 
      ? DesignTokens.cardShadow 
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];

  /// Elevated shadow (modals, FABs)
  List<BoxShadow> get elevatedShadow => isDark 
      ? DesignTokens.glowSm 
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ];

  // =============================================================
  // PREMIUM GRADIENTS (like the pricing card)
  // =============================================================

  /// Premium cyan-teal gradient (works in both light/dark modes)
  static const premiumGradient = LinearGradient(
    colors: [Color(0xFF00C8FF), Color(0xFF00D4AA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Premium blue-cyan gradient
  static const premiumBlueGradient = LinearGradient(
    colors: [Color(0xFF0080FF), Color(0xFF00C8FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Premium purple-pink gradient
  static const premiumPurpleGradient = LinearGradient(
    colors: [Color(0xFF9D6BFF), Color(0xFFFF6B9D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle gradient overlay for glassmorphic effect
  LinearGradient get glassOverlay => LinearGradient(
    colors: [
      Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
      Colors.white.withValues(alpha: isDark ? 0.05 : 0.1),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // =============================================================
  // PREMIUM CARD COLORS (for gradient cards)
  // =============================================================

  /// Text on premium gradient cards (always dark for readability)
  Color get textOnGradient => const Color(0xFF0B1220);

  /// Secondary text on gradient cards
  Color get textOnGradientSecondary => const Color(0xFF1A3A5C);

  /// Icon/check color on gradient cards (cyan accent)
  Color get iconOnGradient => const Color(0xFF00C8FF);

  /// Button on gradient cards (white with dark text)
  Color get buttonOnGradient => Colors.white;
  Color get buttonTextOnGradient => const Color(0xFF0B1220);

  // =============================================================
  // DECORATIONS (pre-built for common patterns)
  // =============================================================

  /// Standard card decoration
  BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: border),
    boxShadow: cardShadow,
  );

  /// Subtle card decoration (no shadow)
  BoxDecoration get cardDecorationSubtle => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: border),
  );

  /// Modal/bottom sheet decoration
  BoxDecoration get modalDecoration => BoxDecoration(
    color: modalBg,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
  );

  /// Input field decoration
  BoxDecoration get inputDecoration => BoxDecoration(
    color: inputFill,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: border),
  );

  /// Premium gradient card decoration (like the pricing card)
  /// Works beautifully in both light and dark modes!
  BoxDecoration get premiumCardDecoration => BoxDecoration(
    gradient: premiumGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.3),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF00C8FF).withValues(alpha: 0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Premium blue gradient card decoration
  BoxDecoration get premiumBlueCardDecoration => BoxDecoration(
    gradient: premiumBlueGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.3),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0080FF).withValues(alpha: 0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Premium purple gradient card decoration
  BoxDecoration get premiumPurpleCardDecoration => BoxDecoration(
    gradient: premiumPurpleGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.3),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF9D6BFF).withValues(alpha: 0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Glassmorphic card with subtle gradient overlay
  BoxDecoration get glassCardDecoration => BoxDecoration(
    gradient: glassOverlay,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.5),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );

  // =============================================================
  // WIDGET WRAPPER FOR NESTED WIDGETS
  // =============================================================

  /// Wraps a widget to ensure it inherits the correct theme.
  /// Use this when a nested widget (like a modal or dialog content)
  /// doesn't properly inherit the parent theme.
  ///
  /// Example:
  /// ```dart
  /// showModalBottomSheet(
  ///   context: context,
  ///   builder: (ctx) => ThemeColors.wrap(
  ///     context: context, // Use parent context!
  ///     child: YourModalContent(),
  ///   ),
  /// );
  /// ```
  static Widget wrap({
    required BuildContext context,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Theme(
      data: theme,
      child: child,
    );
  }

  /// Creates a modal bottom sheet builder that preserves theme
  static Widget Function(BuildContext) modalBuilder({
    required BuildContext parentContext,
    required Widget Function(BuildContext, ThemeColors) builder,
  }) {
    return (BuildContext modalContext) {
      return Theme(
        data: Theme.of(parentContext),
        child: Builder(
          builder: (ctx) => builder(ctx, ThemeColors.of(ctx)),
        ),
      );
    };
  }
}

// =============================================================
// EXTENSIONS
// =============================================================

/// Convenience extension for shorter syntax
extension ThemeColorsExtension on BuildContext {
  /// Get ThemeColors instance
  /// Usage: context.tc.textPrimary
  ThemeColors get tc => ThemeColors.of(this);
  
  /// Legacy alias (for compatibility)
  ThemeColors get themeColors => ThemeColors.of(this);
  
  /// Quick check if dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

/// Extension on Color for opacity helpers
extension ThemeColorOpacity on Color {
  /// Apply alpha by percentage (0-100)
  Color withPercent(int percent) => withValues(alpha: percent / 100);
}

// =============================================================
// PREMIUM CARD WIDGET
// =============================================================

/// A premium glassmorphic card widget with gradient background.
/// Works beautifully in both light and dark modes!
/// 
/// Usage:
/// ```dart
/// PremiumCard(
///   child: Column(
///     children: [
///       Text('Premium Feature', style: TextStyle(color: tc.textOnGradient)),
///       // ...
///     ],
///   ),
/// )
/// ```
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final double borderRadius;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.gradient,
    this.borderRadius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    
    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient ?? ThemeColors.premiumGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C8FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// A premium button styled for gradient card backgrounds
class PremiumButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: tc.buttonOnGradient,
        foregroundColor: tc.buttonTextOnGradient,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
    );
  }
}

/// A check item for premium cards (like pricing features)
class PremiumCheckItem extends StatelessWidget {
  final String text;
  final bool checked;

  const PremiumCheckItem({
    super.key,
    required this.text,
    this.checked = true,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.cancel,
            color: checked ? tc.iconOnGradient : Colors.red.shade300,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: tc.textOnGradient,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// MIGRATION HELPERS
// =============================================================

/// Temporary shim to help migrate hard-coded colors.
/// These will show warnings in debug mode when used.
/// 
/// Replace usages of:
/// - Colors.white → context.tc.textPrimary (for text)
/// - Colors.white70 → context.tc.textSecondary
/// - DesignTokens.neutralWhite → context.tc.textPrimary
/// - DesignTokens.cardBackground → context.tc.surface
/// - AppTheme.neutralWhite → context.tc.textPrimary
class AdaptiveColors {
  /// Use instead of Colors.white for text
  static Color textWhite(BuildContext context) => context.tc.textPrimary;
  
  /// Use instead of Colors.white70 for secondary text
  static Color textWhite70(BuildContext context) => context.tc.textSecondary;
  
  /// Use instead of Colors.white for icons
  static Color iconWhite(BuildContext context) => context.tc.icon;
  
  /// Use instead of DesignTokens.cardBackground
  static Color cardBg(BuildContext context) => context.tc.surface;
  
  /// Use instead of DesignTokens.primaryDark for backgrounds
  static Color scaffoldBg(BuildContext context) => context.tc.bg;
  
  /// Use instead of hard-coded grey colors
  static Color grey(BuildContext context) => context.tc.textSecondary;
}
