# VAGUS APP - Theme Migration Guide

## The Problem

Your app has **1288+ hard-coded colors** across **143 files** that don't respond to light mode. The theme infrastructure is correct, but individual widgets ignore it.

## The Solution

Use the new `ThemeColors` helper class which provides theme-aware colors.

---

## Quick Start

### Import
```dart
import '../../theme/theme_colors.dart';
```

### Usage
```dart
// Get the helper
final tc = context.tc;  // Short form
// OR
final tc = ThemeColors.of(context);

// Use theme-aware colors
Text('Hello', style: TextStyle(color: tc.textPrimary));
Icon(Icons.home, color: tc.icon);
Container(color: tc.surface);
```

---

## Migration Patterns

### 1. TEXT COLORS

| Old (BROKEN) | New (FIXED) |
|-------------|-------------|
| `Colors.white` | `context.tc.textPrimary` |
| `Colors.white70` | `context.tc.textSecondary` |
| `Colors.white60` | `context.tc.textTertiary` |
| `Colors.white38` | `context.tc.textDisabled` |
| `AppTheme.neutralWhite` | `context.tc.textPrimary` |
| `DesignTokens.neutralWhite` | `context.tc.textPrimary` |
| `DesignTokens.textSecondary` | `context.tc.textSecondary` |
| `const TextStyle(color: Colors.white)` | `TextStyle(color: context.tc.textPrimary)` |

### 2. ICON COLORS

| Old (BROKEN) | New (FIXED) |
|-------------|-------------|
| `Icon(Icons.x, color: Colors.white)` | `Icon(Icons.x, color: context.tc.icon)` |
| `Icon(Icons.x, color: Colors.white70)` | `Icon(Icons.x, color: context.tc.iconSecondary)` |
| `Icon(Icons.x, color: AppTheme.neutralWhite)` | `Icon(Icons.x, color: context.tc.icon)` |

### 3. BACKGROUND COLORS

| Old (BROKEN) | New (FIXED) |
|-------------|-------------|
| `DesignTokens.cardBackground` | `context.tc.surface` |
| `DesignTokens.primaryDark` | `context.tc.bg` |
| `AppTheme.cardBackground` | `context.tc.surface` |
| `AppTheme.primaryDark` | `context.tc.bg` |
| `Color(0xFF2A2D2E)` | `context.tc.surface` |
| `Color(0xFF2C2F33)` | `context.tc.surface` |
| `Color(0xFF1A1C1E)` | `context.tc.surfaceAlt` |
| `Colors.grey[800]` | `context.tc.surface` |
| `Colors.grey[900]` | `context.tc.surfaceAlt` |

### 4. BORDER COLORS

| Old (BROKEN) | New (FIXED) |
|-------------|-------------|
| `DesignTokens.glassBorder` | `context.tc.border` |
| `Colors.white.withOpacity(0.1)` | `context.tc.border` |

### 5. HINT/LABEL COLORS

| Old (BROKEN) | New (FIXED) |
|-------------|-------------|
| `hintStyle: TextStyle(color: Colors.white38)` | `hintStyle: TextStyle(color: context.tc.textDisabled)` |
| `hintStyle: TextStyle(color: AppTheme.lightGrey)` | `hintStyle: TextStyle(color: context.tc.textSecondary)` |

---

## Pre-built Decorations

Instead of building BoxDecoration manually, use:

```dart
// Card decoration
Container(decoration: context.tc.cardDecoration);

// Subtle card (no shadow)
Container(decoration: context.tc.cardDecorationSubtle);

// Modal background
Container(decoration: context.tc.modalDecoration);

// Input field
Container(decoration: context.tc.inputDecoration);
```

---

## Fixing Bottom Sheets & Modals

Bottom sheets often don't inherit the parent theme. Use the wrapper:

### BEFORE (Broken)
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (ctx) => Container(
    decoration: BoxDecoration(
      color: Color(0xFF2A2D2E), // ❌ Hard-coded dark
    ),
    child: Column(
      children: [
        Text('Title', style: TextStyle(color: Colors.white)), // ❌ Hard-coded
      ],
    ),
  ),
);
```

### AFTER (Fixed)
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  builder: ThemeColors.modalBuilder(
    parentContext: context,
    builder: (ctx, tc) => Container(
      decoration: tc.modalDecoration,
      child: Column(
        children: [
          Text('Title', style: TextStyle(color: tc.textPrimary)),
        ],
      ),
    ),
  ),
);
```

### Alternative - Manual Wrap
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (ctx) => ThemeColors.wrap(
    context: context, // Use PARENT context
    child: Builder(
      builder: (innerCtx) {
        final tc = innerCtx.tc;
        return Container(
          decoration: tc.modalDecoration,
          child: Text('Hi', style: TextStyle(color: tc.textPrimary)),
        );
      },
    ),
  ),
);
```

---

## Fixing Dialogs

```dart
showDialog(
  context: context,
  builder: (ctx) => ThemeColors.wrap(
    context: context,
    child: AlertDialog(
      backgroundColor: context.tc.surface,
      title: Text('Title', style: TextStyle(color: context.tc.textPrimary)),
      content: Text('Content', style: TextStyle(color: context.tc.textSecondary)),
    ),
  ),
);
```

---

## Available Colors Reference

### Backgrounds
- `tc.bg` - Main scaffold background
- `tc.surface` - Card/dialog background
- `tc.surfaceAlt` - Nested/secondary surface
- `tc.surfaceTertiary` - Deeply nested elements
- `tc.modalBg` - Modal/bottom sheet background
- `tc.overlay` - Scrim/overlay

### Text
- `tc.textPrimary` - Main text
- `tc.textSecondary` - Subtle text, labels
- `tc.textTertiary` - Very subtle text
- `tc.textDisabled` - Disabled text
- `tc.textInverse` - Text on accent buttons
- `tc.textOnDark` - Always white (for dark banners)
- `tc.textOnLight` - Always dark (for light banners)

### Icons
- `tc.icon` - Primary icon
- `tc.iconSecondary` - Subtle icon
- `tc.iconDisabled` - Disabled icon
- `tc.iconOnAccent` - Icon on accent buttons

### Borders
- `tc.border` - Standard border
- `tc.borderStrong` - Emphasized border
- `tc.divider` - Divider lines

### Interactive
- `tc.chipBg` - Unselected chip
- `tc.chipSelectedBg` - Selected chip
- `tc.chipText` - Chip text
- `tc.chipTextOnSelected` - Text on selected chip
- `tc.inputFill` - Input field fill
- `tc.inputFillFocused` - Focused input fill
- `tc.buttonSecondaryBg` - Secondary button
- `tc.hoverOverlay` - Hover state
- `tc.pressedOverlay` - Pressed state

### Accents
- `tc.accent` - Primary accent
- `tc.accentSecondary` - Secondary accent
- `tc.success` - Success color
- `tc.warning` - Warning color
- `tc.danger` - Error/danger color
- `tc.info` - Info color

### Accent Backgrounds
- `tc.successBg` - Success tint
- `tc.warningBg` - Warning tint
- `tc.dangerBg` - Danger tint
- `tc.infoBg` - Info tint

### Shadows
- `tc.cardShadow` - Card shadow list
- `tc.elevatedShadow` - Modal/FAB shadow

---

## Search & Replace Patterns

Use these regex patterns to find issues:

### Find hard-coded white text
```
Colors\.white(?![a-zA-Z0-9])
```

### Find hard-coded dark backgrounds
```
Color\(0xFF2[0-9A-Fa-f]{5}\)|Color\(0xFF1[0-9A-Fa-f]{5}\)
```

### Find DesignTokens direct usage
```
DesignTokens\.(neutralWhite|cardBackground|primaryDark|textSecondary)
```

### Find AppTheme direct usage
```
AppTheme\.(neutralWhite|cardBackground|primaryDark|cardDark)
```

---

## Files to Fix (Priority Order)

### Critical (Core UI)
1. `lib/screens/dashboard/modern_client_dashboard.dart`
2. `lib/widgets/branding/vagus_appbar.dart`
3. `lib/widgets/coach/connected_clients_card.dart`
4. `lib/widgets/coach/client_list_view.dart`
5. `lib/services/error/error_handling_service.dart`

### High Priority (Settings/Profile)
6. `lib/screens/settings/profile_settings_screen.dart`
7. `lib/screens/settings/music_settings_screen.dart`
8. `lib/screens/settings/google_integrations_screen.dart`
9. `lib/components/settings/account_deletion_dialog.dart`

### Screens with hard-coded dark colors (0xFF2C2F33, etc.)
10. `lib/screens/supplements/supplements_today_screen.dart`
11. `lib/screens/settings/earn_rewards_screen.dart`
12. `lib/screens/dashboard/edit_profile_screen.dart`
13. `lib/screens/billing/billing_settings.dart`
14. `lib/screens/workout/cardio_log_screen.dart`
15. `lib/screens/auth/device_list_screen.dart`

---

## Why Nested Widgets Don't Change

Some widgets don't respond to theme changes because:

1. **Bottom sheets create new context** - They don't inherit parent theme
2. **Hard-coded const colors** - `const Color(0xFF...)` ignores theme
3. **Static class colors** - `DesignTokens.neutralWhite` is always white
4. **Legacy widgets** - Built before light mode was added

### Solution
Always use `context.tc.xxx` instead of static colors. For modals/sheets, use `ThemeColors.wrap()` or `ThemeColors.modalBuilder()`.

---

## Quick Check: Is My Widget Theme-Aware?

Run this in your widget:
```dart
@override
Widget build(BuildContext context) {
  debugPrint('isDark: ${context.isDarkMode}');
  // ...
}
```

If it prints the wrong value inside a modal, you need to wrap it.

---

## Testing Light Mode

1. Go to Settings
2. Switch to Light mode
3. Navigate through the app
4. Look for:
   - Invisible text (white on white)
   - Dark cards on light background
   - Buttons with wrong colors

---

**Created: January 2026**
**Use `ThemeColors` everywhere for proper light/dark support!**
