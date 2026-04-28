# PALETTE → PRISM Handoff

**From:** PALETTE agent  
**To:** PRISM agent  
**Date:** 2026-04-28  
**Branch merged:** `agent/palette-tokens`

---

## What PALETTE did

Unified 8 fragmented theme files into a single `lib/theme/tokens.dart` system (VagusTokens class). Migrated 33 screen/widget/component files to use VagusTokens. All deprecated shims preserved for backward compatibility.

---

## Token Reference: VagusTokens

All tokens live in `lib/theme/tokens.dart`. Import:
```dart
import 'package:vagus_app/theme/tokens.dart';
```

### Color Tokens

| Token | Hex | Description |
|-------|-----|-------------|
| `VagusTokens.bgBase` | `#000000` | Pure black scaffold |
| `VagusTokens.bgSurface` | `#0A0A14` | Dark navy card bg |
| `VagusTokens.surfaceGlass` | `#F20A0A14` | Dark navy 95% — glass cards |
| `VagusTokens.bgModal` | `#1A1A2E` | Deep purple-navy modals |
| `VagusTokens.primary` | `#00C8FF` | Cyan — primary interactive |
| `VagusTokens.primaryDark` | `#0080FF` | Blue deep — pressed/variant |
| `VagusTokens.primaryLight` | `#00FFC8` | Teal — hover |
| `VagusTokens.secondary` | `#9D6BFF` | Purple — coach/rank/AI |
| `VagusTokens.accentPink` | `#FF6B9D` | Pink — calling/error hl |
| `VagusTokens.accentOrange` | `#FF9D6B` | Orange — nutrition warmth |
| `VagusTokens.success` | `#00D9A3` | Teal-green |
| `VagusTokens.warning` | `#FFBF47` | Amber |
| `VagusTokens.error` | `#FF6B6B` | Red |
| `VagusTokens.info` | `#4A90E2` | Blue |
| `VagusTokens.successBg` | `#2000D9A3` | 12% teal-green tint |
| `VagusTokens.warningBg` | `#20FFBF47` | 12% amber tint |
| `VagusTokens.errorBg` | `#20FF6B6B` | 12% red tint |
| `VagusTokens.infoBg` | `#204A90E2` | 12% blue tint |
| `VagusTokens.textPrimary` | `#FFFFFF` | 100% white |
| `VagusTokens.textSecondary` | `#99FFFFFF` | 60% white |
| `VagusTokens.textTertiary` | `#66FFFFFF` | 40% white |
| `VagusTokens.textDisabled` | `#4DFFFFFF` | 30% white |
| `VagusTokens.textInverse` | `#0B1220` | Dark text on light/accent |
| `VagusTokens.divider` | `#14FFFFFF` | 8% white glass border |
| `VagusTokens.glassBorder` | `#14FFFFFF` | 8% white (alias) |
| `VagusTokens.glassBorderStrong` | `#28FFFFFF` | 16% white |
| `VagusTokens.glassBorderAccent` | `#4000C8FF` | 25% cyan |

### Nutrition Macro Colors

| Token | Hex | Macro |
|-------|-----|-------|
| `VagusTokens.macroProtein` | `#00D9A3` | Teal-green |
| `VagusTokens.macroCarbs` | `#FF9A3C` | Orange |
| `VagusTokens.macroFat` | `#FFD93C` | Yellow |
| `VagusTokens.macroCalories` | `#FF6B6B` | Red |

### Typography

| Token | Size | Weight | Use |
|-------|------|--------|-----|
| `VagusTokens.displayLg` | 72 | w100 | Hero display |
| `VagusTokens.displayMd` | 48 | w100 | Large display |
| `VagusTokens.displaySm` | 34 | w200 | Small display |
| `VagusTokens.headlineLg` | 32 | bold | Screen titles |
| `VagusTokens.headlineMd` | 28 | bold | Section titles |
| `VagusTokens.headlineSm` | 24 | bold | Card titles |
| `VagusTokens.titleLg` | 24 | w400 | Title large |
| `VagusTokens.titleMd` | 20 | w400 | Title medium |
| `VagusTokens.titleSm` | 18 | w400 | Title small |
| `VagusTokens.bodyLg` | 16 | w400 | Body large |
| `VagusTokens.bodyMd` | 14 | w400 | Body medium |
| `VagusTokens.bodySm` | 12 | w400 | Body small |
| `VagusTokens.labelLg` | 16 | w600 | Label large |
| `VagusTokens.labelMd` | 14 | w600 | Label medium / buttons |
| `VagusTokens.labelSm` | 12 | w500 | Overline / caps |

### Spacing

| Token | px | Alias |
|-------|-----|-------|
| `VagusTokens.spaceXs` | 4 | `space4` |
| `VagusTokens.spaceSm` | 8 | `space8` |
| `VagusTokens.spaceMd` | 16 | `space16` |
| `VagusTokens.spaceLg` | 24 | `space24` |
| `VagusTokens.spaceXl` | 32 | `space32` |
| `VagusTokens.spaceXxl` | 48 | `space48` |

Fine-grained helpers: `space2`, `space4`, `space6`, `space8`, `space12`, `space14`, `space16`, `space20`, `space24`, `space32`, `space48`.

### Radius

| Token | px | Use |
|-------|----|-----|
| `VagusTokens.radiusSm` | 8 | Chips, inputs |
| `VagusTokens.radiusMd` | 12 | Cards, buttons |
| `VagusTokens.radiusLg` | 16 | Major containers |
| `VagusTokens.radiusXl` | 24 | Sheets, modals |
| `VagusTokens.radiusPill` | 999 | Pill buttons |

### Elevation / Shadows

| Token | Description |
|-------|-------------|
| `VagusTokens.shadowSm` | Cyan glow 20px blur |
| `VagusTokens.shadowMd` | Blue glow 30px blur |
| `VagusTokens.shadowLg` | Cyan glow 40px blur |
| `VagusTokens.shadowPurple` | Teal glow 30px blur |
| `VagusTokens.shadowCard` | Elevation card shadow |
| `VagusTokens.shadowSubtle` | Subtle elevation |

### Glass Tokens

| Token | Value | Description |
|-------|-------|-------------|
| `VagusTokens.glassBlurSm` | 10 | Small backdrop blur |
| `VagusTokens.glassBlurMd` | 15 | Medium backdrop blur |
| `VagusTokens.glassBlurLg` | 20 | Large backdrop blur |
| `VagusTokens.glassOpacity` | 0.08 | Glass panel fill opacity |
| `VagusTokens.glassGradientColors` | [0x40FFFFFF, 0x10FFFFFF] | Shimmer overlay |
| `VagusTokens.glassGradientStops` | [0.0, 1.0] | Shimmer stops |

### Gradients

| Token | Colors | Use |
|-------|--------|-----|
| `VagusTokens.gradientPrimary` | Cyan → Blue | Main CTA gradient |
| `VagusTokens.gradientPurple` | Purple → Pink | Premium/coach gradient |
| `VagusTokens.gradientPremium` | Cyan → Teal | Premium card gradient |
| `VagusTokens.gradientCard` | 25%→6% white | Glass card shimmer |
| `VagusTokens.gradientBackground` | Radial cyan-blue-black | Scaffold bg |

### Animation

| Token | Duration |
|-------|----------|
| `VagusTokens.animFast` | 160ms |
| `VagusTokens.animNormal` | 200ms |
| `VagusTokens.animSlow` | 220ms |

---

## Deprecated Shims

These files remain for backward compatibility but all tokens point to VagusTokens:

| File | Status |
|------|--------|
| `lib/theme/design_tokens.dart` | Fully deprecated, re-exports VagusTokens |
| `lib/theme/design_tokens_compat.dart` | Fully deprecated, re-exports VagusTokens |
| `lib/theme/nutrition_colors.dart` | Status colors deprecated; macro colors kept canonical |
| `lib/theme/nutrition_spacing.dart` | Core spacing deprecated; domain sizes kept |
| `lib/theme/nutrition_text_styles.dart` | Uses deprecated NutritionColors — migrate to VagusTokens |
| `lib/theme/theme_colors.dart` | Context-aware accessor kept; uses VagusTokens internally |

---

## Files Migrated to VagusTokens

Screens:
- `lib/screens/account_switch_screen.dart`
- `lib/screens/auth/become_coach_screen.dart`
- `lib/screens/auth/premium_login_screen.dart`
- `lib/screens/auth/signup_screen.dart`
- `lib/screens/billing/billing_settings.dart`
- `lib/screens/calendar/event_editor.dart`
- `lib/screens/learn/learn_client_screen.dart`
- `lib/screens/nav/main_nav.dart`
- `lib/screens/nutrition/widgets/shared/animated_circular_progress_rings.dart`
- `lib/screens/nutrition/widgets/shared/daily_nutrition_dashboard.dart`
- `lib/screens/nutrition/widgets/shared/enhanced_food_card.dart`
- `lib/screens/nutrition/widgets/shared/food_search_result_card.dart`
- `lib/screens/nutrition/widgets/shared/macro_balance_bar_chart.dart`
- `lib/screens/nutrition/widgets/shared/meal_timeline_visualization.dart`
- `lib/screens/progress/export_progress_screen.dart`
- `lib/screens/progress/modern_progress_tracker.dart`
- `lib/screens/settings/ai_usage_screen.dart`
- `lib/screens/settings/user_settings_screen.dart`

Widgets:
- `lib/widgets/auth/animated_gradient_background.dart`
- `lib/widgets/auth/floating_particles.dart`
- `lib/widgets/auth/premium_glass_card.dart`
- `lib/widgets/auth/premium_gradient_button.dart`
- `lib/widgets/auth/stats_display.dart`
- `lib/widgets/nutrition/animated_food_item_edit_modal.dart`
- `lib/widgets/nutrition/food_item_card.dart`
- `lib/widgets/nutrition/food_item_edit_modal.dart`
- `lib/widgets/nutrition/macro_ring_chart.dart`
- `lib/widgets/nutrition/animated/animated_glass_text_field.dart`
- `lib/widgets/nutrition/animated/animated_save_button.dart`

---

## Remaining Work for PRISM

1. **Migrate the remaining ~17 screen files** that still use hardcoded colors not in VagusTokens:
   - `screens/settings/music_settings_screen.dart` — `0xFF2C2F33`, `0xFF1A1C1E` (dark charcoal variant, confirm if these should map to bgSurface or bgModal)
   - `screens/settings/earn_rewards_screen.dart` — same pattern
   - `screens/supplements/supplements_today_screen.dart` — same pattern
   - `screens/settings/google_integrations_screen.dart` — same
   - `screens/auth/device_list_screen.dart` — uses `0xFF00C8FF` ✓ already mapped by PALETTE? (verify)
   - `screens/nutrition/meal_editor.dart` — check specific values
   - `screens/coach_profile/*.dart` — check specific values

2. **Add custom_lint plugin** (`vagus_lints`) to enforce the lint rules documented in `analysis_options.yaml`.

3. **Migrate `lib/theme/nutrition_text_styles.dart`** — currently uses deprecated NutritionColors constants.

4. **Migrate `lib/utils/theme_fixes.dart`** — uses raw `Colors.grey[...]` which should use VagusTokens if this file is still in use.

5. **Verify dark mode visual parity** end-to-end on a physical device or emulator.

---

## ThemeData wiring

`main.dart` uses:
```dart
theme: AppTheme.light(),
darkTheme: AppTheme.dark(),
themeMode: widget.settings.themeMode,
```

Both `AppTheme.light()` and `AppTheme.dark()` now use VagusTokens throughout.

---

## Notes for PRISM

- The glassmorphic `surfaceGlass` token (`0xF20A0A14`) is the most used card background — it's the `DesignTokens.cardBackground` equivalent.
- `bgModal` (`0xFF1A1A2E`) is the deep purple/navy that defines the "dark purple" part of the aesthetic — use it for bottom sheets, dialogs, drawers.
- The primary cyan (`0xFF00C8FF`) is the *interactive* accent, not a background color.
- Purple (`VagusTokens.secondary`) is used for coach/rank/AI features specifically.
- The `ThemeColors` class (`lib/theme/theme_colors.dart`) provides context-aware (light/dark) accessors — recommend PRISM keeps it and migrates its internals to VagusTokens fully.
