-- Settings & Themes v1 (idempotent, additive-only)
create extension if not exists pgcrypto;

-- user_settings: per-user preferences
create table if not exists public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  theme_mode text not null default 'system',   -- system|light|dark
  language_code text not null default 'en',    -- en|ar|ku
  reminder_defaults jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- RLS
alter table public.user_settings enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where policyname='user_settings_owner_rw') then
    create policy user_settings_owner_rw on public.user_settings
    for all to authenticated
    using (user_id = auth.uid())
    with check (user_id = auth.uid());
  end if;

  -- optional: admins read-only for support
  if not exists (select 1 from pg_policies where policyname='user_settings_admin_ro') then
    create policy user_settings_admin_ro on public.user_settings
    for select to authenticated
    using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
  end if;
end $$;

-- seed row helper: not needed; UI upserts the row on first save

-- Global defaults in admin_settings (add keys if missing)
-- Reuse admin_settings table from 0007_admin_polish.sql
insert into public.admin_settings (key, value)
select 'ui.default_theme', jsonb_build_object('mode','system')
where not exists (select 1 from public.admin_settings where key='ui.default_theme');

insert into public.admin_settings (key, value)
select 'ui.default_language', jsonb_build_object('code','en')
where not exists (select 1 from public.admin_settings where key='ui.default_language');

select 'settings_themes_v1 ready' as status;
