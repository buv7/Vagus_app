// Compatibility layer for legacy token names
// Maps old token names to current canonical DesignTokens
// DO NOT modify DesignTokens.dart - only add aliases here

import 'package:flutter/material.dart';
import 'design_tokens.dart' show DesignTokens;

// ===== COLOR ALIASES =====

/// Legacy color names mapped to current DesignTokens
const Color mintAqua = DesignTokens.accentGreen;        // #00E5A0 legacy → accentGreen
const Color errorRed = DesignTokens.danger;             // Error color → danger
const Color softYellow = DesignTokens.warn;             // Warning → warn
const Color steelGrey = DesignTokens.mediumGrey;        // Medium grey
const Color lightGrey = DesignTokens.lightGrey;         // Light grey
const Color primaryBlack = DesignTokens.primaryDark;    // Black → primaryDark
const Color neutralWhite = DesignTokens.neutralWhite;   // White (already correct)
const Color textPrimary = DesignTokens.neutralWhite;    // Primary text
const Color textSecondary = DesignTokens.textSecondary; // Secondary text (already correct)
const Color primaryAccent = DesignTokens.accentGreen;   // Primary accent

// ===== SPACING ALIASES =====

/// Legacy spacing names mapped to 8pt grid system
const double spacing1 = DesignTokens.space4;   // 4px
const double spacing2 = DesignTokens.space8;   // 8px
const double spacing3 = DesignTokens.space12;  // 12px
const double spacing4 = DesignTokens.space16;  // 16px
const double spacing5 = DesignTokens.space20;  // 20px
const double spacing6 = DesignTokens.space24;  // 24px

// ===== RADIUS ALIASES =====

/// Legacy radius names mapped to current system
const double radiusS = DesignTokens.radius6;   // Small radius
const double radiusM = DesignTokens.radius12;  // Medium radius
const double radiusL = DesignTokens.radius16;  // Large radius
const double radiusXL = DesignTokens.radius20; // Extra large radius

// ===== TYPOGRAPHY ALIASES =====

/// Legacy typography sizes
const double h1 = 32.0;
const double h2 = 28.0;
const double h3 = 24.0;
const double body = 16.0;
const double caption = 12.0;

// ===== SHADOW ALIASES =====

/// Legacy shadow definitions
final List<BoxShadow> glassShadow = [
  BoxShadow(
    color: DesignTokens.primaryDark.withValues(alpha: 0.08),
    blurRadius: 24,
    offset: const Offset(0, 12),
  )
];

// ===== HELPER GETTERS =====

/// Legacy brand color getters
Color get brandMint => DesignTokens.accentGreen;
Color get brandYellow => DesignTokens.warn;
Color get brandGreen => DesignTokens.success;

