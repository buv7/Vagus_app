# TRIAL status: READY-FOR-REVIEW

**Started:** 2026-04-28
**Last update:** 2026-04-28
**Branch:** agent/trial-flow
**Mission:** 30-day free trial flow + downgrade UX for coach onboarding

## Current state

Implementation complete. TIER and IAP-APPLE/IAP-GOOGLE are still PENDING,
but the trial flow is built against the existing `subscriptions` / `billing_plans`
schema which already defines the contracts we need. The upgrade path delegates
to `UpgradeScreen` (IAP agents' responsibility); TRIAL only owns the non-subscriber
downgrade path.

## Progress

- [x] Migration: `supabase/migrations/20260428000000_trial_flow.sql`
  - Updates `pro` plan to 30-day trial
  - Adds `trial_notified_stages text[]` to subscriptions (dedup guard)
  - Creates `trial_survey_responses` table (anonymous, admin-read only)
  - Creates `activate_coach_trial(uuid)` RPC (called on coach approval)
  - Updates `entitlements_v` to handle trial/canceled states correctly
- [x] `lib/services/subscription/trial_service.dart` — state machine
  - `activateTrial()` — sets tier=pro, status=trialing, period_end=+30d
  - `getStatus()` → `TrialStatus` with phase + days remaining
  - `getClientsExceedingFreeLimit()` — returns clients if > 2
  - `downgradeToFree({clientIdsToRemove})` — never auto-deletes
  - `submitExitSurvey()` — anonymous, 3-question survey
- [x] `lib/widgets/trial/trial_banner.dart` — slim persistent banner (day 23+)
- [x] `lib/widgets/trial/trial_downgrade_sheet.dart` — graceful downgrade UX
  - Path A: "Choose a plan" → UpgradeScreen
  - Path B: "Move to Free" → client selection (if > 2) → exit survey → downgrade
- [x] `lib/widgets/trial/trial_exit_survey_sheet.dart` — 3 optional questions
- [x] `supabase/functions/expire-trials/index.ts` — cron-triggered Edge Function
  - Day 23 notification (156–180 h window, deduped via trial_notified_stages)
  - Day 28 notification (42–54 h window, deduped)
  - Expiry: auto-downgrade if ≤ 2 clients; notify + leave pending if > 2
  - Max 4 comms total (start + day23 + day28 + post-downgrade)
- [x] `test/trial/trial_service_test.dart` — unit tests for state machine logic
- [x] `test/trial/time_travel_integration.md` — manual time-travel test steps

## Files touched

- `supabase/migrations/20260428000000_trial_flow.sql` (new)
- `lib/services/subscription/trial_service.dart` (new)
- `lib/widgets/trial/trial_banner.dart` (new)
- `lib/widgets/trial/trial_downgrade_sheet.dart` (new)
- `lib/widgets/trial/trial_exit_survey_sheet.dart` (new)
- `supabase/functions/expire-trials/index.ts` (new)
- `test/trial/trial_service_test.dart` (new)
- `test/trial/time_travel_integration.md` (new)

## Handoff notes for TIER / IAP agents

- On coach approval, call `TrialService.instance.activateTrial()` (or invoke
  the `activate_coach_trial` RPC directly from server-side code).
- When IAP subscription is confirmed active, update the `subscriptions` row:
  `status = 'active'`, keep `plan_code = 'pro'`. The `TrialService.getStatus()`
  will then return `notInTrial`, hiding the banner automatically.
- The Free plan's `features` jsonb now carries `"max_clients": 2` for any
  gating logic TIER wants to implement.

## Blockers

None — built against existing schema. TIER/IAP can integrate without blocking TRIAL.

## Questions for OXBAR

- Should the `expire-trials` cron be registered in `pg_cron` or via an external
  scheduler? The function comment includes the `pg_cron` setup SQL.
- SIGNAL is PENDING — current push notifications go directly via `send-notification`
  Edge Function (OneSignal). When SIGNAL ships, it should replace `_sendPush` calls
  in `TrialService` and `expire-trials/index.ts`.

## Next step

Open PR: `[TRIAL] 30-day trial flow + downgrade UX`
