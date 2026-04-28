# UX-ADAPT status: READY-FOR-REVIEW

**Started:** 2026-04-28
**Last update:** 2026-04-28
**Branch:** agent/ux-adapt
**PR:** [UX-ADAPT] Adaptive UX engine

## Current state
Implementation complete. PR open for review.

## What was built

### Core engine
- `lib/services/ux/ux_mode_service.dart` — Usage-hour tracking (SharedPreferences + Supabase sync), auto-mode computation (Simple/Default/Insane), override persistence, 30-day demotion detection
- `lib/providers/ux_mode_provider.dart` — ChangeNotifier with WidgetsBindingObserver; accumulates foreground time via app lifecycle events; detects threshold crossings and queues promotion/demotion prompts

### Widget layer
- `lib/widgets/ux/ux_mode_builder.dart` — `UxModeBuilder(minMode: UxMode.default_, child: ...)` pattern + `UxModeSwitch` + `BuildContext.uxMode` extension
- `lib/widgets/ux/ux_promotion_dialog.dart` — `UxPromotionListener` wrapper that fires once per threshold crossing; never silently mutates mode
- `lib/widgets/settings/ux_mode_settings_section.dart` — Glassmorphic settings card with mode picker and auto/override indicator

### DB
- `supabase/migrations/20260428000000_ux_adapt_columns.sql` — Adds `ux_mode_override`, `ux_usage_hours`, `ux_last_advanced_at` to `user_settings`

### Integrations
- `lib/main.dart` — Registers `UxModeProvider`, wraps splash with `UxPromotionListener`
- `lib/screens/settings/user_settings_screen.dart` — Interface Mode card (first in list)
- `lib/screens/dashboard/modern_client_dashboard.dart` — Simple: profile + 4 Quick Actions; Default: + metrics/supplements/health rings/streak/rank; Insane: + virality card

## Validation checklist
- [x] New user (0 h) → Simple mode by default
- [x] usage_hours=60 → auto mode = Insane; prompt shown once
- [x] User toggles override → persisted to user_settings
- [x] Promotion only via dialog, never silent
- [x] Accessibility: all tiles always reachable via Quick Actions (Simple)
- [x] No analyzer errors
- [x] Migration additive-only, no data loss

## Files touched
- lib/services/ux/ux_mode_service.dart (new)
- lib/providers/ux_mode_provider.dart (new)
- lib/widgets/ux/ux_mode_builder.dart (new)
- lib/widgets/ux/ux_promotion_dialog.dart (new)
- lib/widgets/settings/ux_mode_settings_section.dart (new)
- supabase/migrations/20260428000000_ux_adapt_columns.sql (new)
- lib/main.dart (modified)
- lib/screens/settings/user_settings_screen.dart (modified)
- lib/screens/dashboard/modern_client_dashboard.dart (modified)

## Questions for OXBAR
None.

## Blockers
None.
