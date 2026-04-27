-- Fix user_devices to allow null onesignal_id even if it was part of PK

-- 1) Add surrogate PK column if missing
alter table public.user_devices
add column if not exists id uuid default gen_random_uuid();

-- 2) Drop existing primary key (which includes onesignal_id)
do $$
declare
  pk_name text;
begin
  select constraint_name into pk_name
  from information_schema.table_constraints
  where table_schema='public'
    and table_name='user_devices'
    and constraint_type='PRIMARY KEY'
  limit 1;

  if pk_name is not null then
    execute format('alter table public.user_devices drop constraint %I', pk_name);
  end if;
end $$;

-- 3) Create new PK on surrogate id
alter table public.user_devices
add constraint user_devices_pkey primary key (id);

-- 4) Make onesignal_id nullable
alter table public.user_devices alter column onesignal_id drop not null;

-- 5) Document change
comment on column public.user_devices.onesignal_id is 'Nullable since OneSignal service is currently disabled';

-- 6) Unique only when onesignal_id is present
drop index if exists user_devices_user_id_onesignal_id_key;
drop index if exists user_devices_user_id_onesignal_id_idx;
create unique index if not exists user_devices_user_onesignal_unique
on public.user_devices(user_id, onesignal_id)
where onesignal_id is not null;

-- 7) Optional: only one null-device per user (keep commented if not desired)
-- create unique index if not exists user_devices_user_only_when_null
-- on public.user_devices(user_id)
-- where onesignal_id is null;

-- 8) Fix RLS policies for user_devices table
alter table public.user_devices enable row level security;

-- Drop existing policies if they exist
drop policy if exists "Users can insert their own devices" on public.user_devices;
drop policy if exists "Users can view their own devices" on public.user_devices;
drop policy if exists "Users can update their own devices" on public.user_devices;
drop policy if exists "Users can delete their own devices" on public.user_devices;

-- Create new RLS policies
create policy "Users can insert their own devices"
on public.user_devices for insert
to authenticated
with check (auth.uid() = user_id);

create policy "Users can view their own devices"
on public.user_devices for select
to authenticated
using (auth.uid() = user_id);

create policy "Users can update their own devices"
on public.user_devices for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete their own devices"
on public.user_devices for delete
to authenticated
using (auth.uid() = user_id);

-- 9) Grant necessary permissions
grant usage on schema public to authenticated;
grant all on public.user_devices to authenticated;
