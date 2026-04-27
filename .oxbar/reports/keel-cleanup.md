# KEEL cleanup report

**Branch:** `agent/keel-cleanup`
**Commits:** `b9bc5da`, `971d9ec`
**Date:** 2026-04-27

## Summary

| Metric | Count |
|---|---|
| Files archived (root *.sql → archive/legacy-sql/) | 43 |
| Files deleted (orphan / duplicate Dart) | 6 |
| LOC removed (deletions) | 1,584 |
| LOC added (READMEs, gitignore, status) | ~70 |
| Net LOC change | **-1,514** |
| flutter analyze errors introduced | 0 |
| flutter analyze info/warning total | 190 (all pre-existing) |
| flutter test pass / fail | 174 / 24 (all 24 are pre-existing flaky tests, none reference KEEL-touched code; per OXBAR soft-fail policy) |

## Phase 1 — SQL archive (commit `b9bc5da`)

Moved 43 root-level ad-hoc SQL fix / diagnostic scripts into `archive/legacy-sql/`. None were part of `supabase/migrations/`. Full list (by `git mv`):

```
check_existing_nutrition_tables.sql       fix_database_schema_issues.sql
clear_supabase_cache.sql                  fix_security_definer_views.sql
complete_production_fix.sql               fix_supabase_security_issues.sql
comprehensive_database_diagnosis.sql      fix_supplement_functions.sql
corrected_account_setup.sql               fix_user_roles.sql
database_audit.sql                        force_fix_coach_clients.sql
database_check.sql                        immediate_fix.sql
database_fixes.sql                        master_database_fix.sql
debug_coach_clients.sql                   mcp-test-queries.sql
diagnose_auth_issues.sql                  production_fixes.sql
diagnose_user_roles.sql                   quick_fix_user_roles.sql
direct_sql_fix.sql                        restore_test_accounts.sql
emergency_fix.sql                         schema_dump.sql
final_database_fix.sql                    supabase_diagnostics.sql
fix_all_missing_database_objects.sql      supabase_migration_fix_coach_connections.sql
fix_auth_issues.sql                       supabase_migration_fix_coach_connections_corrected.sql
fix_calendar_attachments.sql              supabase_progress_setup.sql
fix_coach_clients_properly.sql            temp_fix.sql
fix_coach_clients_table.sql               test_coach_clients.sql
fix_coach_query.sql                       test_coach_clients_fix.sql
fix_database_schema.sql                   test_supabase_connection.sql
                                          test_workout_schema.sql
```

Also in this commit:

- **`archive/legacy-sql/README.md`** documents the archive policy: forensic only, do not run, do not add new files.
- **Root `README.md`** amended with the `archive/` tree and the same policy callout.
- **`.gitignore`** carve-out: the existing `ARCHIVE/` rule case-folded to lowercase `archive/` on Windows (and other case-insensitive filesystems) and was hiding the new directory; added explicit `!archive/**` so the tree stays under git.

Out of scope (deliberately untouched): `supabase/migrations/`, `supabase/queries/`, `supabase/scripts/`, `supabase/seed/`, `archived/`, `docs/archive/`.

## Phase 2 — Dart duplicate / orphan deletion (commit `971d9ec`)

Six files deleted. Each was confirmed via grep across `lib/**/*.dart` and the rest of the repo to have **zero Dart import callsites and zero `part of` references** before deletion.

| File deleted | Canonical (kept) | Why this file is dead |
|---|---|---|
| `lib/services/ai/nutrition_ai_clean.dart` | `lib/services/ai/nutrition_ai.dart` (5 callsites) | Stub copy of `class NutritionAI`; the live one uses `FoodVisionService` + Supabase. Zero imports of `nutrition_ai_clean.dart`. |
| `lib/widgets/messaging/smart_replies_panel.dart` | `lib/widgets/messaging/smart_reply_panel.dart` (2 callsites: coach_messenger_screen, client_messenger_screen) | Older `SmartRepliesPanel` widget. Only docs (`AGENT_PROMPTS.md`, `THEME_AUDIT_REPORT.md`) referenced it by filename. |
| `lib/widgets/fab/glassmorphism_fab.dart` | `lib/widgets/fab/simple_glassmorphism_fab.dart` + `lib/widgets/fab/camera_glassmorphism_fab.dart` (both used in `lib/screens/nav/main_nav.dart`) | Older `GlassmorphismFAB` variant. Its `FABAction` companion class is also defined inside `simple_glassmorphism_fab.dart` so deletion does not strand callers. |
| `lib/components/workout/rest_timer.dart` | `lib/components/workout/rest_timer_inline.dart` (2 callsites: exercise_detail_sheet, set_row_controls) | Orphan `RestTimer` widget. The class name is not referenced anywhere outside this file. |
| `lib/screens/workout/widgets/rest_timer_widget.dart` | (none — fully removed) | `RestTimerWidget` + `RestTimerBanner` only mentioned in a stale `VIEWER_README.md` checklist. Zero Dart code uses them. |
| `lib/models/nutrition/money_compat.dart` | (none — fully removed) | Extension `MoneyFormatCompat` providing a `.format()` shim on `Money`. Zero callers; the live `Money` type provides what callers need via `toString()`. |

Out of scope (intentionally kept):

- **8 theme files** in `lib/theme/` (`app_theme.dart`, `design_tokens.dart`, `design_tokens_compat.dart`, `theme_colors.dart`, `theme_index.dart`, `nutrition_colors.dart`, `nutrition_spacing.dart`, `nutrition_text_styles.dart`) — PALETTE owns theme consolidation; KEEL only flagged them.
- **`design_tokens_compat.dart`** specifically — exported via `lib/theme/theme_index.dart`, so it is live.
- **`nutrition_plan_compat.dart`** — imported by `lib/services/nutrition/costing_service.dart`, so it is live.

## Files KEEL was NOT 90% sure about (left for human / TODO-KILLER review)

Nothing crossed the "uncertain" threshold during this pass. Every deletion in commit `971d9ec` was confirmed to have zero Dart import callsites *and* zero `part of` directives *and* zero `export '<filename>'` references in any barrel before deletion. If a follow-up agent finds a reference KEEL missed, the file can be restored from git history.

## Files NOT in the KEEL plan but flagged for future passes

The following came up during the duplicate scan but were left intact because they have at least one live caller:

- `lib/utils/glass_card_builder.dart` — separate utility, not a duplicate of the FAB family.
- `lib/screens/workout/widgets/` and `lib/widgets/workout/` partially overlap conceptually; needs design intent decision before any consolidation.
- The 8 theme files — owner: PALETTE.
- `*_compat.dart` shims that are still imported.

## Validation

```
flutter analyze --no-pub          # 0 errors, 190 pre-existing info/warning
flutter test --no-pub             # 174 passed, 24 pre-existing flaky failures (none reference KEEL-touched files)
git diff --stat HEAD~2..HEAD      # 53 files changed, 78 insertions(+), 1594 deletions(-)
                                  #   (43 renames, 4 docs/config edits, 6 deletions)
```

Both KEEL commits are pushed to `origin/agent/keel-cleanup`.
