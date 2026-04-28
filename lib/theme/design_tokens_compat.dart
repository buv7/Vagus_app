// Compatibility layer for legacy token names.
// All aliases here are @Deprecated — migrate to VagusTokens directly.

import 'package:flutter/material.dart';
import 'tokens.dart';

// ===== COLOR ALIASES =====

@Deprecated('Use VagusTokens.primary')
const Color mintAqua = VagusTokens.primary;

@Deprecated('Use VagusTokens.error')
const Color errorRed = VagusTokens.error;

@Deprecated('Use VagusTokens.warning')
const Color softYellow = VagusTokens.warning;

@Deprecated('Use VagusTokens.textSecondary or a theme-aware accessor')
const Color steelGrey = Color(0xFF6A7385);

@Deprecated('Use VagusTokens.textSecondary or a theme-aware accessor')
const Color lightGrey = Color(0xFF2A2433);

@Deprecated('Use VagusTokens.bgBase')
const Color primaryBlack = VagusTokens.bgBase;

@Deprecated('Use VagusTokens.textPrimary')
const Color neutralWhite = VagusTokens.textPrimary;

@Deprecated('Use VagusTokens.textPrimary')
const Color textPrimary = VagusTokens.textPrimary;

@Deprecated('Use VagusTokens.textSecondary')
const Color textSecondary = VagusTokens.textSecondary;

@Deprecated('Use VagusTokens.primary')
const Color primaryAccent = VagusTokens.primary;

// ===== SPACING ALIASES =====

@Deprecated('Use VagusTokens.spaceXs')
const double spacing1 = VagusTokens.spaceXs;

@Deprecated('Use VagusTokens.spaceSm')
const double spacing2 = VagusTokens.spaceSm;

@Deprecated('Use VagusTokens.space12')
const double spacing3 = VagusTokens.space12;

@Deprecated('Use VagusTokens.spaceMd')
const double spacing4 = VagusTokens.spaceMd;

@Deprecated('Use VagusTokens.space20')
const double spacing5 = VagusTokens.space20;

@Deprecated('Use VagusTokens.spaceLg')
const double spacing6 = VagusTokens.spaceLg;

// ===== RADIUS ALIASES =====

@Deprecated('Use VagusTokens.radiusSm')
const double radiusM = VagusTokens.radiusMd;

@Deprecated('Use VagusTokens.radiusMd')
const double radiusS = VagusTokens.radiusMd;

@Deprecated('Use VagusTokens.radiusLg')
const double radiusL = VagusTokens.radiusLg;

@Deprecated('Use VagusTokens.radiusXl')
const double radiusXL = VagusTokens.radiusXl;

// ===== TYPOGRAPHY ALIASES =====

const double h1      = 32.0;
const double h2      = 28.0;
const double h3      = 24.0;
const double body    = 16.0;
const double caption = 12.0;

// ===== SHADOW ALIASES =====

@Deprecated('Use VagusTokens.shadowCard')
final List<BoxShadow> glassShadow = [
  BoxShadow(
    color: VagusTokens.bgBase.withValues(alpha: 0.08),
    blurRadius: 24,
    offset: const Offset(0, 12),
  ),
];

// ===== HELPER GETTERS =====

@Deprecated('Use VagusTokens.primary')
Color get brandMint => VagusTokens.primary;

@Deprecated('Use VagusTokens.warning')
Color get brandYellow => VagusTokens.warning;

@Deprecated('Use VagusTokens.success')
Color get brandGreen => VagusTokens.success;
