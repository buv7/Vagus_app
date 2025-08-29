-- Admin Panel Polish (idempotent)
create extension if not exists pgcrypto;

-- Helper: is_admin(uid)
create or replace function public.is_admin(uid uuid)
returns boolean language sql stable as $$
  select exists(select 1 from public.profiles p where p.id = uid and p.role = 'admin');
$$;

-- Admin Settings KV
create table if not exists public.admin_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);
alter table public.admin_settings enable row level security;
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'admin_settings_rw_admins') then
    create policy admin_settings_rw_admins on public.admin_settings
      for all to authenticated
      using (public.is_admin(auth.uid()))
      with check (public.is_admin(auth.uid()));
  end if;
end $$;

-- Admin Audit Log
create table if not exists public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references auth.users(id),
  action text not null,
  target text,
  meta jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table public.admin_audit_log enable row level security;
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'admin_audit_log_ro_admins') then
    create policy admin_audit_log_ro_admins on public.admin_audit_log
      for select to authenticated
      using (public.is_admin(auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where policyname = 'admin_audit_log_insert_admins') then
    create policy admin_audit_log_insert_admins on public.admin_audit_log
      for insert to authenticated
      with check (public.is_admin(auth.uid()));
  end if;
end $$;

-- Back-compat view if existing code references public.audit_logs
do $$
begin
  if not exists (select 1 from pg_class where relname = 'audit_logs' and relkind in ('r','v')) then
    create view public.audit_logs as
      select id, actor_id, action, target, meta, created_at
      from public.admin_audit_log;
  end if;
end $$;

-- Seed defaults (safe if re-run)
insert into public.admin_settings(key, value)
select * from (values
  ('ai.models', '{}'::jsonb),
  ('plan.limits', jsonb_build_object('free', jsonb_build_object('monthly_ai_calls', 200), 'pro', jsonb_build_object('monthly_ai_calls', 2000))),
  ('feature.flags', jsonb_build_object('enable_moderation', false))
) as t(key, value)
where not exists (select 1 from public.admin_settings s where s.key = t.key);

select 'admin panel polish ready' as status;
