# KEEL status: RUNNING

**Started:** 2026-04-27 21:10 UTC
**Last update:** 2026-04-27 21:35 UTC
**Branch:** agent/keel-cleanup
**Mission:** Archive root-level *.sql fix scripts; remove duplicate Dart files; retire dead code paths.

## Current state
RUNNING: phase-1 committed and pushed. 43 root-level *.sql moved into `archive/legacy-sql/` with a policy README; root README amended; `.gitignore` carve-out added so the new archive tree is tracked (the existing `ARCHIVE/` rule case-folded on Windows). Phase-2 (Dart duplicate cleanup) starts next, in its own commit.

## Sign-off note
KEEL touches: 43 root *.sql → `archive/legacy-sql/`, plus Dart duplicates by callsite count. KEEL does NOT touch: `supabase/migrations|queries|scripts|seed/`, `archived/`, the 8 theme files (PALETTE owns), and the pre-existing dirty WIP per OXBAR's 20:49 decision.

## Note on working-tree contention
The shared working tree is being branch-swapped under KEEL by other agents. KEEL commits each phase in its own commit and pushes to origin so the work survives.

## Progress
- [x] Phase 1: SQL archive + READMEs + gitignore (committed, pushed)
- [ ] Phase 2: Dart duplicate cleanup
- [ ] flutter analyze clean
- [ ] Report at `.oxbar/reports/keel-cleanup.md`
- [ ] PR opened

## Phase-2 plan (zero-Dart-import orphans, all confirmed)
- delete `lib/services/ai/nutrition_ai_clean.dart` (canonical: `nutrition_ai.dart`)
- delete `lib/widgets/messaging/smart_replies_panel.dart` (canonical: `smart_reply_panel.dart`)
- delete `lib/widgets/fab/glassmorphism_fab.dart` (orphan; live: `simple_glassmorphism_fab.dart`, `camera_glassmorphism_fab.dart`)
- delete `lib/components/workout/rest_timer.dart` (orphan; canonical: `rest_timer_inline.dart`)
- delete `lib/screens/workout/widgets/rest_timer_widget.dart` (orphan; only README mentions)
- delete `lib/models/nutrition/money_compat.dart` (orphan)

Kept (have callsites): `design_tokens_compat.dart` (exported via theme_index), `nutrition_plan_compat.dart` (imported by costing_service).
8 theme files — left for PALETTE per prompt.

## Questions for OXBAR
(none)

## Blockers
(none)

## Next step
Phase-2 commit + push, then flutter analyze, then report and PR.
