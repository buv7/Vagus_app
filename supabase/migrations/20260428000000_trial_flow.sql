-- Trial flow v1 (idempotent, additive-only)
-- Adds: trial notification stage tracking, anonymous exit survey, activate_coach_trial() RPC

-- ── 1. Update 'pro' plan to 30-day trial (was 7) ──────────────────────────────
update public.billing_plans
  set trial_days = 30,
      features   = features || '{"max_clients": 999}'::jsonb,
      updated_at = now()
  where code = 'pro';

update public.billing_plans
  set features = features || '{"max_clients": 2}'::jsonb,
      updated_at = now()
  where code = 'free';

-- ── 2. Add notification stage tracking to subscriptions ───────────────────────
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'subscriptions'
      and column_name = 'trial_notified_stages'
  ) then
    alter table public.subscriptions
      add column trial_notified_stages text[] not null default '{}';
  end if;
end $$;

-- ── 3. Anonymous exit-survey table ────────────────────────────────────────────
create table if not exists public.trial_survey_responses (
  id           uuid primary key default gen_random_uuid(),
  reason       text not null, -- 'price' | 'features_missing' | 'didnt_fit' | 'other'
  what_missing text,
  other_text   text,
  created_at   timestamptz not null default now()
);

alter table public.trial_survey_responses enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'trial_survey_insert_auth') then
    create policy trial_survey_insert_auth on public.trial_survey_responses
    for insert to authenticated with check (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'trial_survey_admin_select') then
    create policy trial_survey_admin_select on public.trial_survey_responses
    for select to authenticated using (public.is_admin(auth.uid()));
  end if;
end $$;

-- ── 4. activate_coach_trial() ─────────────────────────────────────────────────
-- Called on coach approval. No-op if a subscription row already exists.
create or replace function public.activate_coach_trial(p_user_id uuid)
returns void
language plpgsql security definer as $$
begin
  if not exists (
    select 1 from public.subscriptions where user_id = p_user_id
  ) then
    insert into public.subscriptions (
      user_id, plan_code, status, period_start, period_end
    ) values (
      p_user_id, 'pro', 'trialing', now(), now() + interval '30 days'
    );
  end if;
end;
$$;

-- ── 5. Update entitlements view to treat 'trial_expired' as free ─────────────
-- 2026-04-28 KEEL fixup: CREATE OR REPLACE VIEW cannot remove columns.
-- DROP+CREATE used because no objects depend on entitlements_v
-- (verified phase 5 inspection: 0 SQL consumers, 1 Dart consumer
--  reads only plan_code + ai_monthly_limit which are retained).
drop view if exists public.entitlements_v cascade;
create view public.entitlements_v as
select
  p.id as user_id,
  case
    when s.status = 'trialing' then coalesce(s.plan_code, 'free')
    when s.status in ('active') then coalesce(s.plan_code, 'free')
    else 'free'
  end as plan_code,
  case
    when s.status = 'trialing' then coalesce(bp.ai_monthly_limit, 2000)
    when s.status = 'active'   then coalesce(bp.ai_monthly_limit, 200)
    else 200
  end as ai_monthly_limit,
  coalesce(s.status, 'active') as status,
  s.period_end
from public.profiles p
left join lateral (
  select s1.* from public.subscriptions s1
  where s1.user_id = p.id
  order by s1.updated_at desc nulls last
  limit 1
) s on true
left join public.billing_plans bp
  on bp.code = s.plan_code and bp.is_active = true;

select 'trial flow v1 ready' as status;

-- ROLLBACK NOTE (KEEL fixup 2026-04-28):
-- To revert: drop view if exists public.entitlements_v cascade;
--            then re-create from _archive/20250115130000_fix_schema_issues.sql
--            (9-column version with plan_name, price_monthly_cents, currency, features).
