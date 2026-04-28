# SHEETIFY status: READY-FOR-REVIEW

**Started:** 2026-04-28 00:00 UTC
**Last update:** 2026-04-28 00:00 UTC
**Branch:** agent/sheetify
**Mission:** Bidirectional Google Sheets sync for coaches — auto-create 3-tab sheet per client, push app data to sheet, poll for sheet edits, flag conflicts for coach review.

## Current state
READY-FOR-REVIEW: PR is open. All code is complete. Blocked on E-003 (Google OAuth client ID) for live OAuth to work — but this does not block the PR merge or CI.

## PRs
- 🟡 **Open — agent/sheetify → main** — `[SHEETIFY] Bidirectional Google Sheets sync`

## Progress
- [x] Read .oxbar files — VAULT live, TIER/DRIFTKIT/CONDUIT PENDING
- [x] DB migration: `coach_google_credentials`, `client_sheets`, `sheets_sync_queue`, `sheets_sync_conflicts` with full RLS
- [x] Edge function `sheetify-oauth`: OAuth consent URL + callback (exchange code, encrypt tokens, store)
- [x] Edge function `sheetify-sync`: create_sheet, push_data, flush_queue, poll_changes, resolve_conflict, revoke, status
- [x] Dart models: `sheet_sync_models.dart`
- [x] Dart service: `sheetify_service.dart` (singleton, polling, push helpers, conflict management)
- [x] Flutter screen: `sheetify_connect_screen.dart` (connect/disconnect, sheet list, conflict banner)
- [x] Flutter screen: `sheetify_conflicts_screen.dart` (review + resolve conflicts)
- [x] Escalation E-003 filed (Google OAuth client ID + SHEETIFY_ENCRYPT_KEY)
- [x] Decisions documented in .oxbar/decisions.md

## Files touched
- `supabase/migrations/20260428000000_sheetify_tables.sql`
- `supabase/functions/sheetify-oauth/index.ts`
- `supabase/functions/sheetify-sync/index.ts`
- `lib/models/sheetify/sheet_sync_models.dart`
- `lib/services/sheetify/sheetify_service.dart`
- `lib/screens/settings/sheetify_connect_screen.dart`
- `lib/screens/settings/sheetify_conflicts_screen.dart`
- `.oxbar/agent-status/SHEETIFY.md`
- `.oxbar/decisions.md`
- `.oxbar/escalations.md`

## Dependency deferrals

| Dep | Status | SHEETIFY approach |
|-----|--------|------------------|
| TIER | PENDING | No gate — all tiers get sync per spec |
| DRIFTKIT | PENDING | Own `sheets_sync_queue` table; swap when DRIFTKIT ships |
| CONDUIT | PENDING | Not needed — sync is edge-function-driven |
| VAULT `vault_encrypt_text` | GUC broken | AES-256-GCM in edge function via `SHEETIFY_ENCRYPT_KEY` |

## Validation checklist (manual, requires E-003 resolved)
- [ ] Coach connects Google → sheets appear in Drive
- [ ] Coach logs workout in app → row appears in sheet within 30s
- [ ] Coach edits sheet → change appears as conflict in app within 90s
- [ ] Coach resolves conflict → conflict row disappears
- [ ] Disconnect → tokens revoked (Google returns success on revoke endpoint)
- [ ] VAULT CI passes (no plaintext secrets, RLS on all tables)

## Blockers
- **E-003** (escalations.md): Google OAuth client ID + `SHEETIFY_ENCRYPT_KEY` + `GOOGLE_CLIENT_SECRET` must be set in Supabase edge secrets before the live OAuth flow works. PR can merge without this.

## Questions for OXBAR
1. **Deep link `vagus://sheetify/connected`** — confirm `vagus://` custom URI scheme is registered in `AndroidManifest.xml` and `Info.plist`. The `app_links` package is in pubspec but SHEETIFY couldn't verify platform configuration in the worktree.
2. **`sheetify/conflicts` route** — `SheetifyConnectScreen` pushes to `/sheetify/conflicts` for the conflict review screen. Ensure this route is registered in the app's router (wherever routes are defined).

## Next steps after merge
- Alhassan resolves E-003 → live OAuth tested end-to-end
- Call `SheetifyService.instance.onClientAdded(...)` from wherever `coach_clients` rows are created
- Call `pushCheckin` / `pushWorkout` / `pushNutrition` from the respective write paths
- Start polling via `startPolling(coachId)` from the coach dashboard's `initState`
