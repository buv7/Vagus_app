# VAGUS APP - THEME AUDIT REPORT
**Generated:** Comprehensive scan of theme implementation  
**Purpose:** Identify all theme sources and hard-coded colors that break light mode

---

## A) ENTRY POINTS

### MaterialApp Configuration
**File:** `lib/main.dart`  
**Lines:** 105-110

```dart
return MaterialApp(
  title: 'VAGUS',
  navigatorKey: navigatorKey,
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: widget.settings.themeMode,
  // ... rest of config
);
```

**Key Details:**
- Uses `AppTheme.light()` for light theme
- Uses `AppTheme.dark()` for dark theme
- Theme mode comes from `SettingsController` (wrapped in `AnimatedBuilder` for reactivity)
- No `useMaterial3` flag found (defaults to Material 3)

---

## B) THEME MODE STATE

### State Management
**File:** `lib/services/settings/settings_controller.dart`

**Storage:**
- **State:** `ThemeMode _themeMode = ThemeMode.system` (default)
- **Provider:** `SettingsController` extends `ChangeNotifier`
- **Persistence:** `SettingsService.instance.saveThemeMode()` → Supabase `user_settings` table
- **Key:** `'theme_mode'` (stored as string: 'system', 'light', 'dark')

**Update Flow:**
1. User toggles theme in `ThemeToggle` widget (`lib/components/settings/theme_toggle.dart`)
2. Calls `settingsController.setThemeMode(ThemeMode.light/dark/system)`
3. Controller updates `_themeMode` and calls `notifyListeners()`
4. Persists to Supabase via `SettingsService.saveThemeMode()`

**Default Behavior:**
- First install: `ThemeMode.system` (follows device setting)
- Falls back to `'system'` if database value is invalid/missing

**Persistence Service:**
**File:** `lib/services/settings/settings_service.dart`
- Stores in Supabase `user_settings` table
- Merges with admin defaults from `admin_settings` table
- Key: `'theme_mode'` (string value)

---

## C) THEME DEFINITIONS

### Light Theme
**File:** `lib/theme/app_theme.dart`  
**Lines:** 26-128

**Method:** `AppTheme.light()`

**ColorScheme:**
```dart
ColorScheme.light(
  primary: Color(0xFF000000),              // Black
  secondary: DesignTokens.mediumGrey,      // #6A7385
  surface: Color(0xFFFFFFFF),              // White
  onPrimary: Color(0xFFFFFFFF),           // White
  onSecondary: Color(0xFFFFFFFF),         // White
  onSurface: Color(0xFF000000),           // Black
  outline: Color(0xFFE0E0E0),              // Light grey
  surfaceContainerHighest: Color(0xFFFFFFFF), // White
  onSurfaceVariant: DesignTokens.mediumGrey, // #6A7385
)
```

**Key Colors:**
- `scaffoldBackgroundColor`: `Color(0xFFFFFFFF)` (White)
- `appBarTheme.backgroundColor`: `Color(0xFFFFFFFF)` (White)
- `appBarTheme.foregroundColor`: `Color(0xFF000000)` (Black)
- `cardTheme.color`: `Colors.white`
- `chipTheme.backgroundColor`: `Color(0xFFE0E0E0)` (Light grey)
- `chipTheme.selectedColor`: `Color(0xFF000000)` (Black)
- `chipTheme.labelStyle.color`: `Color(0xFF000000)` (Black)

**Text Theme:**
- Base color: `Color(0xFF000000)` (Black)
- `bodyLarge`: Black
- `bodyMedium`: `DesignTokens.mediumGrey` (#6A7385)
- `titleLarge`: Black, bold

**Button Themes:**
- `elevatedButtonTheme`: Black background, white text
- `outlinedButtonTheme`: Black foreground, black border
- `textButtonTheme`: Black foreground

**Input Theme:**
- `fillColor`: `Colors.white`
- `border`: `Color(0xFFE0E0E0)` (Light grey)
- `focusedBorder`: `Color(0xFF000000)` (Black, width 2)

---

### Dark Theme
**File:** `lib/theme/app_theme.dart`  
**Lines:** 132-254

**Method:** `AppTheme.dark()`

**ColorScheme:**
```dart
ColorScheme.dark(
  primary: DesignTokens.accentGreen,           // #00C8FF (Cyan)
  secondary: DesignTokens.accentBlue,         // #0080FF
  tertiary: DesignTokens.accentTeal,           // #00FFC8
  surface: DesignTokens.primaryDark,            // #000000 (Black)
  onPrimary: Colors.black,                     // Black text on cyan
  onSecondary: DesignTokens.neutralWhite,      // White
  onSurface: DesignTokens.neutralWhite,        // White
  outline: DesignTokens.glassBorder,           // #14FFFFFF (8% white)
  surfaceContainerHighest: DesignTokens.cardBackground, // #F20A0A14 (95% opacity black)
  onSurfaceVariant: DesignTokens.textSecondary, // #99FFFFFF (60% white)
)
```

**Key Colors:**
- `scaffoldBackgroundColor`: `DesignTokens.primaryDark` (#000000 - Pure black)
- `appBarTheme.backgroundColor`: `DesignTokens.cardBackground` (#F20A0A14 - 95% opacity)
- `appBarTheme.foregroundColor`: `DesignTokens.neutralWhite` (#FFFFFF)
- `cardTheme.color`: `DesignTokens.cardBackground` (95% opacity black)
- `chipTheme.backgroundColor`: `DesignTokens.cardBackground`
- `chipTheme.selectedColor`: `DesignTokens.accentGreen` (Cyan)
- `chipTheme.labelStyle.color`: `DesignTokens.neutralWhite` (White)

**Text Theme:**
- Base color: `DesignTokens.neutralWhite` (#FFFFFF - White)
- `bodyLarge`: White
- `bodyMedium`: `DesignTokens.textSecondary` (#99FFFFFF - 60% white)
- `titleLarge`: White, weight 400

**Button Themes:**
- `elevatedButtonTheme`: Cyan background, black text
- `outlinedButtonTheme`: White foreground, glass border, card background
- `textButtonTheme`: Cyan foreground

**Input Theme:**
- `fillColor`: `Color(0x0AFFFFFF)` (4% white)
- `border`: `DesignTokens.glassBorder` (8% white)
- `focusedBorder`: `DesignTokens.accentGreen` (Cyan, width 2)
- `hintStyle`: `DesignTokens.textSecondary` (60% white)
- `labelStyle`: `DesignTokens.textSecondary` (60% white)

---

### Design Tokens
**File:** `lib/theme/design_tokens.dart`

**Dark-Mode-Specific Colors (PROBLEM):**
- `neutralWhite = Color(0xFFFFFFFF)` - Pure white (breaks on light backgrounds)
- `cardBackground = Color(0xF20A0A14)` - 95% opacity black (breaks on light theme)
- `primaryDark = Color(0xFF000000)` - Pure black (breaks on light theme)
- `textPrimary = Color(0xFFFFFFFF)` - White text (breaks on light theme)
- `textSecondary = Color(0x99FFFFFF)` - 60% white (breaks on light theme)

**These are used directly in widgets, causing light mode breakage.**

---

## D) OVERRIDES THAT CAN BREAK LIGHT MODE

### Widgets with Hard-Coded Dark Colors

#### 1. Text Colors (White Text - Breaks Light Mode)
**Files with `TextStyle(color: AppTheme.neutralWhite)` or `DesignTokens.neutralWhite`:**

- `lib/widgets/coach/connected_clients_card.dart` (Lines 61, 79, 173, 191, 203, 211, 265, 271)
- `lib/widgets/workout/plan_search_filter_bar.dart` (Lines 30, 33, 67, 73)
- `lib/widgets/coach/client_list_view.dart` (Lines 61, 72, 88, 265, 283, 295, 326, 360, 374, 381, 402, 414, 420, 425, 441, 447)
- `lib/services/error/error_handling_service.dart` (Lines 115, 119, 126, 373)
- `lib/screens/business/business_profile_screen.dart` (Line 473)
- `lib/screens/admin/admin_ads_screen.dart` (Lines 352, 617, 703, 730)
- `lib/screens/coach/program_ingest_upload_sheet.dart` (Lines 344, 557, 563)
- `lib/screens/auth/set_new_password_screen.dart` (Line 305)
- `lib/screens/messaging/modern_coach_messenger_screen.dart` (Lines 262, 265)
- `lib/screens/settings/profile_settings_screen.dart` (Lines 382, 385)
- `lib/widgets/messaging/schedule_session_modal.dart` (Lines 189, 192)
- `lib/screens/settings/privacy_security_screen.dart` (Lines 466, 469)
- `lib/screens/nutrition/widgets/shared/custom_foods_tab.dart` (Line 339)
- `lib/screens/nutrition/components/meal_detail/food_list_panel.dart` (Lines 214, 217, 233)
- `lib/screens/nutrition/widgets/shared/smart_barcode_scanner.dart` (Line 586)
- `lib/screens/nutrition/widgets/shared/barcode_scanner_tab.dart` (Lines 692, 753)
- `lib/screens/nutrition/components/plan_viewer/viewer_view.dart` (Line 457)
- `lib/screens/messaging/modern_client_messages_screen.dart` (Lines 190, 848)
- `lib/widgets/coach/client_search_filter_bar.dart` (Lines 37, 40, 103, 126)
- `lib/screens/menu/modern_coach_menu_screen.dart` (Line 353)

#### 2. Icon Colors (White Icons - Breaks Light Mode)
**Files with `Icon(color: AppTheme.neutralWhite)` or `DesignTokens.neutralWhite`:**

- `lib/screens/menu/modern_coach_menu_screen.dart` (Lines 83, 92)
- `lib/screens/settings/privacy_security_screen.dart` (Line 235)
- `lib/screens/coach/program_ingest_preview_screen.dart` (Line 140)
- `lib/screens/billing/billing_payments_screen.dart` (Lines 135, 144)
- `lib/screens/settings/notifications_settings_screen.dart` (Line 137)
- `lib/screens/business/business_profile_screen.dart` (Line 176)
- `lib/screens/messaging/modern_coach_messenger_screen.dart` (Lines 178, 186, 194, 210)
- `lib/screens/settings/profile_settings_screen.dart` (Line 129)
- `lib/screens/analytics/analytics_reports_screen.dart` (Lines 128, 136)
- `lib/screens/admin/admin_ads_screen.dart` (Lines 72, 95)
- `lib/screens/nutrition/nutrition_hub_screen.dart` (Line 280)

#### 3. Container/Background Colors (Dark Backgrounds - Breaks Light Mode)
**Files with `Container(color: AppTheme.cardBackground)` or `DesignTokens.cardBackground`:**

- `lib/widgets/coach/connected_clients_card.dart` (Line 26, 133)
- `lib/widgets/workout/plan_search_filter_bar.dart` (Lines 25, 43, 58)
- `lib/widgets/calling/call_chat.dart` (Line 74)
- `lib/widgets/coach/quick_action_sheets.dart` (Lines 229, 243, 340, 389)
- `lib/widgets/branding/vagus_appbar.dart` (Line 42, 61, 68)
- `lib/widgets/calling/connection_quality_indicator.dart` (Line 18)
- `lib/widgets/coach/weekly_summary_card.dart` (Lines 16, 67)
- `lib/widgets/coach/recent_checkins_card.dart` (Line 22)
- `lib/components/nutrition/recipe_card.dart` (Line 44)
- `lib/widgets/calling/call_controls.dart` (Line 38)
- `lib/widgets/admin/user_inspector_sheet.dart` (Line 19)
- `lib/widgets/coach/coach_inbox_card.dart` (Lines 26, 118)
- `lib/widgets/coach/connected_clients_card.dart` (Line 26)
- `lib/widgets/coach/pending_requests_card.dart` (Line 24)
- `lib/widgets/coach/client_metrics_cards.dart` (Line 73)
- `lib/widgets/coach/performance_analytics_card.dart` (Line 20)
- `lib/widgets/coach/client_management_header.dart` (Line 18)
- `lib/components/messaging/attachment_preview.dart` (Lines 69, 128, 175)
- `lib/components/messaging/smart_reply_buttons.dart` (Line 91)
- `lib/components/messaging/typing_indicator.dart` (Lines 57, 141)
- `lib/components/settings/account_deletion_dialog.dart` (Line 84)
- `lib/components/billing/free_trial_countdown_card.dart` (Line 109)
- `lib/screens/learn/learn_client_screen.dart` (Lines 183, 255)

#### 4. AppTheme Static Colors (Dark-Mode-Forced)
**Files using `AppTheme.primaryDark`, `AppTheme.cardBackground`, `AppTheme.cardDark`:**

- `lib/widgets/coach/connected_clients_card.dart` (Line 133 - primaryDark background)
- `lib/services/error/error_handling_service.dart` (Lines 112, 360 - cardDark backgrounds)
- `lib/widgets/coach/client_list_view.dart` (Multiple - primaryDark, cardBackground)
- `lib/screens/rank/rank_hub_screen.dart` (Multiple - primaryDark)
- `lib/components/periods/period_progress_bar.dart` (Multiple - primaryDark)
- `lib/screens/learn/learn_coach_screen.dart` (Multiple - primaryDark)
- `lib/components/checkins/compare_checkins_modal.dart` (Multiple - primaryDark)

#### 5. DesignTokens Direct Usage (Dark-Mode-Forced)
**Files using `DesignTokens.neutralWhite`, `DesignTokens.cardBackground`, `DesignTokens.primaryDark` directly:**

- `lib/widgets/branding/vagus_appbar.dart` (Lines 42, 61, 68)
- `lib/widgets/coach/weekly_summary_card.dart` (Lines 16, 42, 53, 67, 102)
- `lib/widgets/coaches/coach_glass_card.dart` (Lines 52, 67, 92)
- `lib/components/settings/account_deletion_dialog.dart` (Lines 84, 99, 136, 190, 202, 204, 211, 236, 243, 252)
- `lib/components/nutrition/recipe_card.dart` (Line 44, 202, 362, 388)
- `lib/screens/learn/learn_client_screen.dart` (Lines 33, 43, 183, 201, 208, 241, 255, 270, 277, 294)
- `lib/widgets/coach/performance_analytics_card.dart` (Lines 20, 50)
- `lib/screens/coaches/qr_scanner_screen.dart` (Lines 135, 140, 191)
- `lib/widgets/coach/quick_actions_grid.dart` (Lines 63, 367, 368, 426, 427, 437, 438)
- `lib/components/billing/free_trial_countdown_card.dart` (Lines 81, 93, 109, 125)
- `lib/widgets/messaging/voice_recorder.dart` (Multiple)
- `lib/widgets/workout/exercise_history_card.dart` (Multiple)
- `lib/widgets/messaging/smart_replies_panel.dart` (Multiple)
- `lib/widgets/workout/auto_progression_tip.dart` (Multiple)

---

## E) TOP 30 WORST OFFENDERS (Hard-Coded Color List)

### Ranked by Impact (Most Likely to Break Light Mode First)

1. **`lib/widgets/coach/connected_clients_card.dart`**
   - **Lines 26, 61, 79, 133, 173, 191, 203, 211, 265, 271, 276**
   - **Issues:**
     - `color: DesignTokens.cardBackground` (dark background)
     - `TextStyle(color: AppTheme.neutralWhite)` (white text on light bg = invisible)
     - `color: AppTheme.primaryDark` (black container on light theme)
   - **Why it breaks:** Entire card uses dark-mode colors, text becomes invisible in light mode

2. **`lib/widgets/workout/plan_search_filter_bar.dart`**
   - **Lines 25, 30, 33, 36, 43, 58, 67, 73, 78**
   - **Issues:**
     - `color: AppTheme.cardBackground` (dark background)
     - `TextStyle(color: AppTheme.neutralWhite)` (white text)
     - `hintStyle: TextStyle(color: AppTheme.lightGrey)` (grey hint on light bg = low contrast)
   - **Why it breaks:** Search bar has dark background and white text, invisible in light mode

3. **`lib/widgets/coach/client_list_view.dart`**
   - **Lines 54, 61, 72, 88, 217, 238, 265, 283, 295, 320, 326, 344, 360, 374, 381, 402, 414, 420, 425, 441, 447, 481, 503, 507**
   - **Issues:**
     - Multiple `TextStyle(color: AppTheme.neutralWhite)` (white text)
     - `color: AppTheme.cardBackground` (dark backgrounds)
     - `color: AppTheme.primaryDark` (black containers)
   - **Why it breaks:** Entire client list uses dark-mode colors throughout

4. **`lib/widgets/branding/vagus_appbar.dart`**
   - **Lines 42, 61, 68**
   - **Issues:**
     - `color: DesignTokens.cardBackground` (dark background)
     - `foregroundColor: DesignTokens.neutralWhite` (white icons/text)
   - **Why it breaks:** AppBar becomes dark with white text, invisible in light mode

5. **`lib/services/error/error_handling_service.dart`**
   - **Lines 112, 115, 119, 126, 360, 367, 373, 387**
   - **Issues:**
     - `backgroundColor: AppTheme.cardDark` (dark background)
     - `TextStyle(color: AppTheme.neutralWhite)` (white text)
     - `TextStyle(color: AppTheme.lightGrey)` (grey text on light bg)
   - **Why it breaks:** Error dialogs have dark backgrounds with white text

6. **`lib/components/settings/account_deletion_dialog.dart`**
   - **Lines 84, 99, 136, 190, 202, 204, 211, 236, 243, 252**
   - **Issues:**
     - `backgroundColor: DesignTokens.cardBackground` (dark background)
     - `TextStyle(color: DesignTokens.neutralWhite)` (white text)
     - `fillColor: DesignTokens.primaryDark` (black input background)
   - **Why it breaks:** Critical dialog uses dark-mode colors, unreadable in light mode

7. **`lib/screens/messaging/modern_coach_messenger_screen.dart`**
   - **Lines 178, 186, 194, 210, 262, 265**
   - **Issues:**
     - `Icon(color: AppTheme.neutralWhite)` (white icons)
     - `TextStyle(color: AppTheme.neutralWhite)` (white text)
     - `hintStyle: TextStyle(color: AppTheme.lightGrey)` (grey hint)
   - **Why it breaks:** Messenger UI uses white text/icons on light backgrounds

8. **`lib/screens/settings/profile_settings_screen.dart`**
   - **Lines 129, 382, 385**
   - **Issues:**
     - `Icon(color: AppTheme.neutralWhite)` (white back icon)
     - `TextStyle(color: AppTheme.neutralWhite)` (white text)
     - `hintStyle: TextStyle(color: AppTheme.lightGrey)` (grey hint)
   - **Why it breaks:** Settings screen has white text/icons on light background

9. **`lib/widgets/coach/weekly_summary_card.dart`**
   - **Lines 16, 42, 53, 67, 102**
   - **Issues:**
     - `color: DesignTokens.cardBackground` (dark background)
     - `color: DesignTokens.textSecondary` (60% white text)
     - `color: DesignTokens.neutralWhite` (white text)
   - **Why it breaks:** Card uses dark background with white text

10. **`lib/screens/nutrition/widgets/shared/smart_barcode_scanner.dart`**
    - **Line 586**
    - **Issues:**
      - `TextStyle(color: AppTheme.neutralWhite)` (white text)
    - **Why it breaks:** Scanner UI has white text on light background

11. **`lib/screens/business/business_profile_screen.dart`**
    - **Lines 176, 473, 476**
    - **Issues:**
      - `Icon(color: AppTheme.neutralWhite)` (white back icon)
      - `TextStyle(color: AppTheme.neutralWhite)` (white text)
      - `hintStyle: TextStyle(color: AppTheme.lightGrey)` (grey hint)
    - **Why it breaks:** Profile screen uses white text/icons

12. **`lib/screens/admin/admin_ads_screen.dart`**
    - **Lines 72, 95, 352, 617, 703, 730**
    - **Issues:**
      - `Icon(color: AppTheme.neutralWhite)` (white icons)
      - `TextStyle(color: AppTheme.lightGrey)` (grey text)
      - `TextStyle(color: AppTheme.neutralWhite)` (white text)
    - **Why it breaks:** Admin screen has white/grey text on light backgrounds

13. **`lib/widgets/messaging/schedule_session_modal.dart`**
    - **Lines 189, 192, 218, 242**
    - **Issues:**
      - `TextStyle(color: AppTheme.neutralWhite)` (white text)
      - `hintStyle: TextStyle(color: AppTheme.lightGrey)` (grey hint)
      - `colorScheme: ColorScheme.dark()` (forced dark theme)
    - **Why it breaks:** Modal uses dark theme colors and white text

14. **`lib/screens/coach/program_ingest_upload_sheet.dart`**
    - **Lines 344, 557, 563**
    - **Issues:**
      - `TextStyle(color: AppTheme.neutralWhite)` (white text)
    - **Why it breaks:** Upload sheet has white text on light background

15. **`lib/screens/auth/set_new_password_screen.dart`**
    - **Line 305**
    - **Issues:**
      - `TextStyle(color: AppTheme.neutralWhite)` (white text)
    - **Why it breaks:** Auth screen has white text on light background

16. **`lib/screens/settings/privacy_security_screen.dart`**
    - **Lines 235, 466, 469**
    - **Issues:**
      - `Icon(color: AppTheme.neutralWhite)` (white back icon)
      - `TextStyle(color: AppTheme.neutralWhite)` (white text)
      - `hintStyle: TextStyle(color: AppTheme.lightGrey)` (grey hint)
    - **Why it breaks:** Privacy screen uses white text/icons

17. **`lib/screens/nutrition/components/meal_detail/food_list_panel.dart`**
    - **Lines 214, 217, 233**
    - **Issues:**
      - `TextStyle(color: AppTheme.neutralWhite)` (white text)
      - `hintStyle: TextStyle(color: AppTheme.lightGrey)` (grey hint)
    - **Why it breaks:** Food panel has white text on light background

18. **`lib/screens/nutrition/widgets/shared/barcode_scanner_tab.dart`**
    - **Lines 692, 753**
    - **Issues:**
      - `TextStyle(color: AppTheme.lightGrey)` (grey text)
      - `TextStyle(color: AppTheme.neutralWhite)` (white text)
    - **Why it breaks:** Scanner tab uses white/grey text on light background

19. **`lib/screens/nutrition/components/plan_viewer/viewer_view.dart`**
    - **Line 457**
    - **Issues:**
      - `TextStyle(color: AppTheme.neutralWhite)` (white text)
    - **Why it breaks:** Plan viewer has white text on light background

20. **`lib/screens/messaging/modern_client_messages_screen.dart`**
    - **Lines 190, 848**
    - **Issues:**
      - `TextStyle(color: AppTheme.neutralWhite)` (white text)
    - **Why it breaks:** Client messages screen has white text

21. **`lib/widgets/coach/client_search_filter_bar.dart`**
    - **Lines 37, 40, 103, 126**
    - **Issues:**
      - `TextStyle(color: AppTheme.neutralWhite)` (white text)
      - `hintStyle: TextStyle(color: AppTheme.lightGrey)` (grey hint)
    - **Why it breaks:** Search bar has white text on light background

22. **`lib/screens/menu/modern_coach_menu_screen.dart`**
    - **Lines 83, 92, 353**
    - **Issues:**
      - `Icon(color: AppTheme.neutralWhite)` (white icons)
      - `TextStyle(color: AppTheme.neutralWhite)` (white text)
    - **Why it breaks:** Menu screen uses white icons/text

23. **`lib/screens/nutrition/widgets/shared/custom_foods_tab.dart`**
    - **Line 339**
    - **Issues:**
      - `TextStyle(color: AppTheme.lightGrey)` (grey text)
    - **Why it breaks:** Custom foods tab has grey text on light background

24. **`lib/screens/analytics/analytics_reports_screen.dart`**
    - **Lines 128, 136**
    - **Issues:**
      - `Icon(color: AppTheme.neutralWhite)` (white icons)
    - **Why it breaks:** Analytics screen has white icons on light background

25. **`lib/screens/billing/billing_payments_screen.dart`**
    - **Lines 135, 144**
    - **Issues:**
      - `Icon(color: AppTheme.neutralWhite)` (white icons)
    - **Why it breaks:** Billing screen has white icons on light background

26. **`lib/screens/settings/notifications_settings_screen.dart`**
    - **Line 137**
    - **Issues:**
      - `Icon(color: AppTheme.neutralWhite)` (white back icon)
    - **Why it breaks:** Notifications screen has white icon on light background

27. **`lib/screens/coach/program_ingest_preview_screen.dart`**
    - **Lines 140, 206, 251**
    - **Issues:**
      - `Icon(color: AppTheme.neutralWhite)` (white back icon)
      - `TextStyle(color: AppTheme.lightGrey)` (grey text)
    - **Why it breaks:** Preview screen has white icon and grey text

28. **`lib/screens/nutrition/nutrition_hub_screen.dart`**
    - **Line 280**
    - **Issues:**
      - `Icon(color: AppTheme.neutralWhite)` (white icon)
    - **Why it breaks:** Nutrition hub has white icon on light background

29. **`lib/components/nutrition/recipe_card.dart`**
    - **Lines 44, 202, 362, 388**
    - **Issues:**
      - `color: DesignTokens.cardBackground` (dark background)
      - `DesignTokens.textSecondary` (60% white text)
    - **Why it breaks:** Recipe card uses dark background with white text

30. **`lib/widgets/coach/coach_inbox_card.dart`**
    - **Lines 26, 61, 79, 118**
    - **Issues:**
      - `color: DesignTokens.cardBackground` (dark background)
      - `color: DesignTokens.neutralWhite` (white text)
    - **Why it breaks:** Inbox card uses dark background with white text

---

## F) ROUTE/SPECIFIC SCREEN NOTES

### Screens with Custom Theme Wrappers

1. **`lib/screens/coach_profile/coach_profile_screen.dart`** (Lines 183-208)
   - Uses `Theme` widget wrapper to override `chipTheme`
   - Fixes dark theme chip issues but may not handle light theme properly

2. **`lib/screens/workout/revolutionary_plan_builder_screen.dart`** (Lines 2897-2898)
   - Forces `ThemeData.dark()` with `ColorScheme.dark()` in a dialog
   - This will break when system/light theme is active

3. **`lib/widgets/messaging/schedule_session_modal.dart`** (Lines 218, 242)
   - Uses `ThemeData.dark()` with `ColorScheme.dark()` in modal
   - Forces dark theme regardless of app theme mode

### Screens Using `scaffoldBackgroundColor` (Generally Safe)
Most screens use `theme.scaffoldBackgroundColor` which is theme-aware:
- `lib/screens/dashboard/modern_client_dashboard.dart`
- `lib/screens/dashboard/modern_coach_dashboard.dart`
- `lib/screens/messaging/modern_messenger_screen.dart`
- `lib/screens/workout/revolutionary_plan_builder_screen.dart`
- And many others...

**These are generally safe** as they use the theme's scaffold color.

---

## G) SYSTEM THEME DETECTION

### Brightness Detection
**Pattern Found:** `Theme.of(context).brightness == Brightness.dark`

**Files using this pattern:**
- `lib/widgets/coach/analytics/analytics_header.dart` (Line 21)
- `lib/screens/coach_profile/widgets/profile_content.dart` (Lines 14, 186, 228)
- `lib/widgets/coach/energy_balance_card.dart` (Lines 10, 37)
- `lib/widgets/workout/exercise_history_card.dart` (Line 69)
- `lib/widgets/workout/load_suggestion_bar.dart` (Lines 138, 277)
- `lib/widgets/messaging/smart_reply_panel.dart` (Line 21)
- `lib/screens/messaging/modern_messenger_screen.dart` (Line 320)
- `lib/components/nutrition/recipe_card.dart` (Line 36)
- And 30+ more files...

**Good Practice:** These files detect brightness and conditionally apply colors. However, many still use hard-coded `AppTheme.neutralWhite` or `DesignTokens.neutralWhite` even when `isDark == false`.

---

## H) THEME FIXES UTILITY

**File:** `lib/utils/theme_fixes.dart`

**Purpose:** Contains `ThemeFixes.fixDarkTheme()` and `ThemeFixes.fixLightTheme()` methods.

**Status:** **NOT USED** - These methods exist but are never called in the codebase. They appear to be legacy/unused code.

**Note:** The fixes in this file use hard-coded `Colors.white`, `Colors.black`, `Colors.grey` which would work, but the methods are not integrated into the app.

---

## I) SUMMARY - WHAT'S WRONG

### Primary Issues:

1. **Hard-Coded Dark-Mode Colors Everywhere**
   - Widgets directly use `AppTheme.neutralWhite` (white) for text/icons
   - Widgets use `AppTheme.cardBackground` / `DesignTokens.cardBackground` (dark backgrounds)
   - Widgets use `AppTheme.primaryDark` / `DesignTokens.primaryDark` (black containers)
   - These colors are **dark-mode-specific** and break light mode

2. **Design Tokens Are Dark-Theme-Only**
   - `DesignTokens.neutralWhite` = white (breaks on light backgrounds)
   - `DesignTokens.cardBackground` = 95% opacity black (breaks on light theme)
   - `DesignTokens.textSecondary` = 60% white (breaks on light backgrounds)
   - These tokens don't adapt to theme mode

3. **AppTheme Static Colors Are Not Theme-Aware**
   - `AppTheme.neutralWhite` is always white
   - `AppTheme.cardBackground` is always dark
   - `AppTheme.primaryDark` is always black
   - These should use `Theme.of(context).colorScheme` instead

4. **Forced Dark Themes in Modals/Dialogs**
   - Some modals force `ThemeData.dark()` regardless of app theme
   - Example: `revolutionary_plan_builder_screen.dart`, `schedule_session_modal.dart`

5. **No Theme-Aware Color Helpers**
   - No utility functions to get theme-appropriate colors
   - Widgets must manually check `brightness` or use hard-coded colors

### Root Cause:
The app was designed primarily for dark mode. When light theme was added, widgets continued using dark-mode-specific color constants (`AppTheme.neutralWhite`, `DesignTokens.cardBackground`, etc.) instead of theme-aware colors from `Theme.of(context).colorScheme`.

### Expected Behavior vs. Actual:
- **Expected:** Text/icons should use `theme.colorScheme.onSurface` (black in light, white in dark)
- **Actual:** Text/icons use `AppTheme.neutralWhite` (always white, invisible on light backgrounds)
- **Expected:** Backgrounds should use `theme.colorScheme.surface` (white in light, dark in dark)
- **Actual:** Backgrounds use `DesignTokens.cardBackground` (always dark, breaks light mode)

---

## J) FILES TO FIX (Priority Order)

### Critical (Breaks Core Functionality):
1. `lib/widgets/coach/connected_clients_card.dart`
2. `lib/widgets/workout/plan_search_filter_bar.dart`
3. `lib/widgets/coach/client_list_view.dart`
4. `lib/widgets/branding/vagus_appbar.dart`
5. `lib/services/error/error_handling_service.dart`

### High Priority (User-Facing Screens):
6. `lib/components/settings/account_deletion_dialog.dart`
7. `lib/screens/messaging/modern_coach_messenger_screen.dart`
8. `lib/screens/settings/profile_settings_screen.dart`
9. `lib/screens/business/business_profile_screen.dart`
10. `lib/screens/admin/admin_ads_screen.dart`

### Medium Priority (Feature Screens):
11-30. All other files listed in Section E

---

**END OF REPORT**
