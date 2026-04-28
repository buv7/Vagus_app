# DANGERZONE status: READY-FOR-REVIEW

**Started:** 2026-04-28 UTC
**Last update:** 2026-04-28 UTC
**Branch:** agent/dangerzone
**Mission:** Right-to-be-forgotten + soft-delete with grace periods. Compliant by design.

## Current state
Implementation complete. PR open.

## Progress
- [x] `account_lifecycle` + `account_lifecycle_audit` migration (20260428000000)
- [x] RPCs: `request_account_deactivation`, `request_account_deletion`, `restore_account`, `get_account_lifecycle_status`
- [x] RLS: users read own rows only; cron uses service role
- [x] `active_profiles` view — excludes deactivated users from coach lists
- [x] Edge Function `lifecycle-purge` — daily batch purge + SIGNAL notifications
- [x] `AccountLifecycleService` Dart service
- [x] `DeactivateAccountDialog` — password confirm, 30-day grace
- [x] `AccountDeletionDialog` — password + typed "DELETE", 7-day grace (replaces stub)
- [x] `AccountGraceCountdownBanner` — shown on sign-in during grace
- [x] `AccountSettingsScreen` — Settings → Account with deactivate/delete/restore/export
- [x] `UserSettingsScreen` — Account card added

## Files touched
- `supabase/migrations/20260428000000_dangerzone_account_lifecycle.sql` (new)
- `supabase/functions/lifecycle-purge/index.ts` (new)
- `lib/services/account_lifecycle_service.dart` (new)
- `lib/components/settings/account_deletion_dialog.dart` (rewritten: adds DeactivateAccountDialog, AccountGraceCountdownBanner, password confirm, DELETE phrase)
- `lib/screens/settings/account_settings_screen.dart` (new)
- `lib/screens/settings/user_settings_screen.dart` (Account card added)

## Notification schedule implemented
| Event                   | Channel |
|-------------------------|---------|
| Deactivate requested    | Push (client-side) |
| Day-25 warning (5 left) | Push (cron) |
| Day-30 final / purge    | Push (cron, before purge) |
| Delete requested        | Push (client-side) |
| Day-1 (6 days left)     | Push (cron) |
| Day-6 (1 day left)      | Push (cron) |
| Day-7 purged            | Push (cron, before purge) |

## Validation checklist
- [ ] Deactivate → user absent from `active_profiles` view (coach lists)
- [ ] Deactivate → user can still sign in to restore within 30 days
- [ ] Restore during grace → status='restored', user visible again
- [ ] Delete → 7-day grace enforced by partial unique index
- [ ] Day 7 → lifecycle-purge deletes auth.users row → CASCADE cleans all tables
- [ ] `account_lifecycle_audit` populated at every state change
- [ ] RLS: user can only SELECT own rows; no direct INSERT/UPDATE/DELETE
- [ ] VAULT CI: audit log present, RLS strict

## Questions for OXBAR
- SIGNAL agent: email notifications referenced in spec — current impl is push-only (OneSignal). Does SIGNAL expose an email RPC we should call from lifecycle-purge?
- pg_cron schedule for lifecycle-purge: recommend `0 3 * * *` (03:00 UTC daily). OXBAR to register via Supabase dashboard or `cron.schedule`.

## Blockers
None.

## Next step
Review open PR. Connect SIGNAL for email leg if available.
