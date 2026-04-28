# KEEL Cleanup Report — v2

**Date:** 2026-04-28
**Branch:** agent/keel-cleanup-v2
**Agent:** KEEL

---

## Summary

| Category | Count | Notes |
|---|---|---|
| SQL files archived | 43 | Root `*.sql` → `archived/legacy-sql/` |
| Dart files deleted | 5 | Confirmed-dead duplicates, 0 import callsites each |
| LOC removed | ~1,119 | Dart deletions only (SQL is archived, not deleted) |
| Files kept (compat) | 2 | `design_tokens_compat.dart`, `nutrition_plan_compat.dart` |

---

## SQL Archive

**Moved 43 root-level `.sql` files** to `archived/legacy-sql/`.

These were one-shot fix scripts, diagnostic queries, and ad-hoc schema dumps accumulated during early development. None of them are referenced by app code or CI. Canonical schema is in `supabase/migrations/` (untouched).

---

## Duplicate File Deletions

### nutrition_ai_clean.dart (109 LOC) — DELETED
- Path: `lib/services/ai/nutrition_ai.dart` (canonical, 271 LOC, 5 import callsites)
- Deleted: `lib/services/ai/nutrition_ai_clean.dart` (0 import callsites)
- Decision: `_clean` suffix is the old scratchpad; canonical has all current callers.

### smart_replies_panel.dart (112 LOC) — DELETED
- Path: `lib/widgets/messaging/smart_reply_panel.dart` (canonical, 139 LOC, 2 import callsites)
- Deleted: `lib/widgets/messaging/smart_replies_panel.dart` (0 import callsites)
- Decision: Plural `smart_replies_panel` was the old draft; `smart_reply_panel` is used by both messenger screens.

### glassmorphism_fab.dart (756 LOC) — DELETED
- Path: `lib/widgets/fab/simple_glassmorphism_fab.dart` + `camera_glassmorphism_fab.dart` (both in main_nav.dart)
- Deleted: `lib/widgets/fab/glassmorphism_fab.dart` (0 import callsites, `GlassmorphismFAB` class never instantiated)
- Decision: `GlassmorphismFAB` predates the split into Simple/Camera variants. 756 LOC, zero users.

### money_compat.dart (7 LOC) — DELETED
- Path: `lib/models/nutrition/money_compat.dart` (0 import callsites)
- Decision: Adds `.format()` to `Money`, but no code calls `.format()` on Money objects.

### rest_timer.dart (135 LOC) — DELETED
- Path: `lib/components/workout/rest_timer.dart` (0 import callsites, `RestTimer` class never instantiated)
- Active alternatives: `rest_timer_inline.dart` (2 callers), `rest_timer_widget.dart` (RestTimerController used by workout_session_manager)
- Decision: `RestTimer` class is the old standalone widget replaced by the inline and full-screen variants.

---

## Files Kept (Conservative)

### design_tokens_compat.dart — KEPT
- Exported via `lib/theme/theme_index.dart`
- `mintAqua`, `radiusM`, `spacing2-4`, etc. actively used in `coupon_input.dart` and other billing/UI files.
- Removing it would require a broad token rename across the codebase — out of KEEL scope.

### nutrition_plan_compat.dart — KEPT
- Imported by `lib/services/nutrition/costing_service.dart`.
- Single active caller — safe to leave.

---

## LOC Reduction Detail

| File | LOC |
|---|---|
| nutrition_ai_clean.dart | 109 |
| smart_replies_panel.dart | 112 |
| glassmorphism_fab.dart | 756 |
| money_compat.dart | 7 |
| rest_timer.dart | 135 |
| **Total** | **1,119** |

SQL files are archived (not deleted) — no LOC reduction counted for them.

---

## Uncertainty / Deferred

| Item | Reason deferred |
|---|---|
| `design_tokens_compat.dart` | Actively used. Renaming tokens is a separate refactor ticket. |
| `nutrition_plan_compat.dart` | One active caller. Leave for the caller's owner to migrate. |
| `rest_timer_widget.dart` vs `rest_timer_inline.dart` | Both active with different contracts. Consolidation needs design input. |
| `camera_glassmorphism_fab.dart` vs `simple_glassmorphism_fab.dart` | Both used in main_nav with distinct APIs — consolidation needs product decision on FAB behavior. |
| `smart_reply_buttons.dart` (components/messaging/) | Different file/class from the deleted panel. Left untouched — import path differs and usage not confirmed zero. |

---

## Validation

- `flutter analyze` — run post-commit (see PR CI)
- `flutter test` — run post-commit (see PR CI)
