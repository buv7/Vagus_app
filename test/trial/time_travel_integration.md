# Time-travel integration test

## Purpose

Verify that `expire-trials` Edge Function correctly downgrades a coach when
`period_end` is set to the past.

## Steps (run against a Supabase branch, not prod)

```sql
-- 1. Create a test coach subscription with period_end in the past
insert into public.subscriptions (user_id, plan_code, status, period_start, period_end)
values ('<test_coach_uid>', 'pro', 'trialing', now() - interval '31 days', now() - interval '1 hour');

-- 2. Ensure coach has ≤ 2 clients (auto-downgrade path)
-- (or add > 2 clients to test the pending_client_review path)

-- 3. Invoke the Edge Function (or run manually via curl)
-- curl -X POST https://<project>.supabase.co/functions/v1/expire-trials \
--   -H "Authorization: Bearer $CRON_SECRET"

-- 4. Verify result
select plan_code, status from public.subscriptions where user_id = '<test_coach_uid>';
-- Expected: plan_code = 'free', status = 'canceled'

-- 5. Verify entitlements view reflects free tier
select plan_code from public.entitlements_v where user_id = '<test_coach_uid>';
-- Expected: 'free'
```

## Expected notifications

| Event | Push sent |
|---|---|
| Trial start | "Your 30-day Pro trial has started!" |
| Day 23 (7 days left) | "Your trial ends in 7 days" |
| Day 28 (2 days left) | "Your trial ends in 2 days!" |
| Post-downgrade | "Your trial has ended" |

Max 4 trial-related comms in 30 days — enforced by `trial_notified_stages`.
