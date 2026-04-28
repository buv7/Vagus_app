-- IAP: add store-discriminator and Google Play-specific columns to subscriptions.
-- Also seeds vagus_pro_monthly and vagus_ultimate_monthly billing plans.
-- No new table created; existing RLS on `subscriptions` and `billing_plans` covers all new data.

-- ── Column additions ──────────────────────────────────────────────────────────

do $$ begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='subscriptions' and column_name='store'
  ) then
    alter table public.subscriptions add column store text;
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='subscriptions' and column_name='purchase_token'
  ) then
    alter table public.subscriptions add column purchase_token text;
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='subscriptions' and column_name='google_order_id'
  ) then
    alter table public.subscriptions add column google_order_id text;
  end if;
end $$;

-- Index for fast lookup of active Google subscription per user
create index if not exists subscriptions_user_store_idx
  on public.subscriptions (user_id, store);

-- ── Billing plan seeds ────────────────────────────────────────────────────────
-- Prices are placeholders; adjust to match Play Console product pricing.
-- 30-day free trial is configured in Play Console base plan, not here.

insert into public.billing_plans
  (code, name, price_monthly_cents, currency, features, ai_monthly_limit, trial_days, is_active)
select * from (values
  ('vagus_pro_monthly',      'Vagus Pro',      999,  'USD', '{"iap":true}'::jsonb, 2000, 30, true),
  ('vagus_ultimate_monthly', 'Vagus Ultimate', 1999, 'USD', '{"iap":true}'::jsonb, 5000, 30, true)
) as v(code, name, price_monthly_cents, currency, features, ai_monthly_limit, trial_days, is_active)
on conflict (code) do nothing;

select 'iap google columns ready' as status;
