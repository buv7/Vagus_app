-- Monetization v1 (idempotent, additive-only)
create extension if not exists pgcrypto;

-- helper: is_admin
create or replace function public.is_admin(uid uuid)
returns boolean language sql stable as $$
  select exists (select 1 from public.profiles p where p.id = uid and p.role = 'admin');
$$;

-- profiles add-on: stripe_customer_id (nullable)
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='profiles' and column_name='stripe_customer_id'
  ) then
    alter table public.profiles add column stripe_customer_id text;
  end if;
end $$;

-- billing_plans
create table if not exists public.billing_plans (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  price_monthly_cents integer not null default 0,
  currency text not null default 'USD',
  features jsonb not null default '{}'::jsonb,
  ai_monthly_limit integer not null default 200,
  trial_days integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- subscriptions
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_code text not null,
  status text not null default 'trialing', -- trialing|active|past_due|canceled
  period_start timestamptz,
  period_end timestamptz,
  cancel_at_period_end boolean default false,
  coupon_code text,
  external_customer_id text,
  external_subscription_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists subscriptions_user_idx on public.subscriptions(user_id);
create index if not exists subscriptions_status_idx on public.subscriptions(status);

-- coupons
create table if not exists public.coupons (
  code text primary key,
  percent_off integer,
  amount_off_cents integer,
  max_redemptions integer,
  redeem_by timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- coupon_redemptions
create table if not exists public.coupon_redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  coupon_code text not null references public.coupons(code) on delete cascade,
  redeemed_at timestamptz not null default now(),
  unique (user_id, coupon_code)
);
create index if not exists coupon_redemptions_user_idx on public.coupon_redemptions(user_id);

-- invoices (read-only viewer in-app)
create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_code text,
  amount_cents integer not null default 0,
  currency text not null default 'USD',
  status text not null default 'open', -- open|paid|void|uncollectible
  due_at timestamptz,
  external_invoice_id text,
  created_at timestamptz not null default now()
);
create index if not exists invoices_user_idx on public.invoices(user_id);

-- RLS
alter table public.billing_plans enable row level security;
alter table public.subscriptions enable row level security;
alter table public.coupons enable row level security;
alter table public.coupon_redemptions enable row level security;
alter table public.invoices enable row level security;

do $$
begin
  -- billing_plans: public read; admin write
  if not exists (select 1 from pg_policies where policyname='billing_plans_read_all') then
    create policy billing_plans_read_all on public.billing_plans
    for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname='billing_plans_rw_admins') then
    create policy billing_plans_rw_admins on public.billing_plans
    for all to authenticated
    using (public.is_admin(auth.uid()))
    with check (public.is_admin(auth.uid()));
  end if;

  -- subscriptions: owner read/write; admins all
  if not exists (select 1 from pg_policies where policyname='subscriptions_owner_rw') then
    create policy subscriptions_owner_rw on public.subscriptions
    for all to authenticated
    using (user_id = auth.uid())
    with check (user_id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where policyname='subscriptions_admin_all') then
    create policy subscriptions_admin_all on public.subscriptions
    for all to authenticated
    using (public.is_admin(auth.uid()))
    with check (public.is_admin(auth.uid()));
  end if;

  -- coupons: public read; admin write
  if not exists (select 1 from pg_policies where policyname='coupons_read_all') then
    create policy coupons_read_all on public.coupons
    for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname='coupons_rw_admins') then
    create policy coupons_rw_admins on public.coupons
    for all to authenticated
    using (public.is_admin(auth.uid()))
    with check (public.is_admin(auth.uid()));
  end if;

  -- coupon_redemptions: owner rw; admin all
  if not exists (select 1 from pg_policies where policyname='coupon_redemptions_owner_rw') then
    create policy coupon_redemptions_owner_rw on public.coupon_redemptions
    for all to authenticated
    using (user_id = auth.uid())
    with check (user_id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where policyname='coupon_redemptions_admin_all') then
    create policy coupon_redemptions_admin_all on public.coupon_redemptions
    for all to authenticated
    using (public.is_admin(auth.uid()))
    with check (public.is_admin(auth.uid()));
  end if;

  -- invoices: owner read; admin all
  if not exists (select 1 from pg_policies where policyname='invoices_owner_ro') then
    create policy invoices_owner_ro on public.invoices
    for select to authenticated using (user_id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where policyname='invoices_admin_all') then
    create policy invoices_admin_all on public.invoices
    for all to authenticated
    using (public.is_admin(auth.uid()))
    with check (public.is_admin(auth.uid()));
  end if;
end $$;

-- Entitlements view
create or replace view public.entitlements_v as
select
  p.id as user_id,
  coalesce(s.plan_code, 'free') as plan_code,
  coalesce(bp.ai_monthly_limit, 200) as ai_monthly_limit,
  coalesce(s.status, 'active') as status,
  s.period_end
from public.profiles p
left join lateral (
  select s1.* from public.subscriptions s1
  where s1.user_id = p.id
  order by s1.updated_at desc nulls last
  limit 1
) s on true
left join public.billing_plans bp on bp.code = s.plan_code and bp.is_active = true;

-- seeds (safe)
insert into public.billing_plans (code, name, price_monthly_cents, currency, features, ai_monthly_limit, trial_days, is_active)
select * from (values
  ('free','Free',0,'USD','{"notes":"Basic access"}'::jsonb,200,0,true),
  ('pro','Pro',1500,'USD','{"notes":"Higher AI limits"}'::jsonb,2000,7,true)
) as v(code,name,price_monthly_cents,currency,features,ai_monthly_limit,trial_days,is_active)
on conflict (code) do nothing;

insert into public.coupons (code, percent_off, is_active)
values ('WELCOME20', 20, true)
on conflict (code) do nothing;

select 'monetization v1 ready' as status;
