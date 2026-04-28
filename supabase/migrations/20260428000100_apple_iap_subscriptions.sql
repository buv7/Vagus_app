-- Apple IAP: additive-only columns on the existing subscriptions table.
-- The table and entitlements_v view were created by the baseline schema;
-- 20260428000000_trial_flow.sql extended them.  We only ADD columns here.

-- Apple-specific audit columns (safe no-ops if already present).
alter table public.subscriptions
  add column if not exists apple_original_transaction_id text,
  add column if not exists apple_expires_at              timestamptz,
  add column if not exists is_trial                      boolean not null default false,
  add column if not exists platform                      text;

-- Extend entitlements_v to expose max_clients for PlanAccessManager.
-- Replaces TRIAL's version; fully backwards-compatible — same columns plus max_clients.
create or replace view public.entitlements_v as
select
  p.id as user_id,
  case
    when s.status = 'trialing' then coalesce(s.plan_code, 'free')
    when s.status = 'active'   then coalesce(s.plan_code, 'free')
    else 'free'
  end as plan_code,
  case
    when s.status in ('trialing', 'active') then
      case coalesce(s.plan_code, 'free')
        when 'ultimate' then -1
        when 'pro'      then 20
        else 3
      end
    else 3
  end as max_clients,
  case
    when s.status = 'trialing' then coalesce(bp.ai_monthly_limit, 2000)
    when s.status = 'active'   then coalesce(bp.ai_monthly_limit, 200)
    else 200
  end as ai_monthly_limit,
  coalesce(s.status, 'active') as status,
  s.period_end,
  s.is_trial
from public.profiles p
left join lateral (
  select s1.* from public.subscriptions s1
  where s1.user_id = p.id
  order by s1.updated_at desc nulls last
  limit 1
) s on true
left join public.billing_plans bp
  on bp.code = s.plan_code and bp.is_active = true;

select 'apple iap columns ready' as status;
