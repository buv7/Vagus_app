-- Calendar & Booking Polish v1.1 (idempotent, additive-only)
create extension if not exists pgcrypto;

-- Add columns to calendar_events if missing (category, reminders)
-- Note: time_zone already exists as 'timezone' field
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema='public' and table_name='calendar_events' and column_name='category') then
    alter table public.calendar_events add column category text default 'session'; -- session|call|assessment|other
  end if;
  if not exists (select 1 from information_schema.columns where table_schema='public' and table_name='calendar_events' and column_name='reminders') then
    alter table public.calendar_events add column reminders jsonb not null default '[]'::jsonb; -- array of offsets in minutes
  end if;
end $$;

-- Per-attendee tracking
create table if not exists public.calendar_attendees (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.calendar_events(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  role text not null default 'participant', -- coach|client|participant|guest
  status text not null default 'invited',   -- invited|accepted|declined|tentative|cancelled
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  unique(event_id, user_id)
);
create index if not exists calendar_attendees_event_idx on public.calendar_attendees(event_id);
create index if not exists calendar_attendees_user_idx on public.calendar_attendees(user_id);

-- Recurrence overrides (detached/modified/cancelled instances)
create table if not exists public.calendar_event_overrides (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.calendar_events(id) on delete cascade,
  occur_date date not null,                  -- date of the occurrence in the series
  override jsonb not null default '{}'::jsonb, -- fields to override: start_at, end_at, location, notes, cancelled: true
  created_at timestamptz not null default now(),
  unique(event_id, occur_date)
);
create index if not exists calendar_event_overrides_event_idx on public.calendar_event_overrides(event_id, occur_date);

-- Coach booking policies (availability & constraints)
create table if not exists public.booking_policies (
  coach_id uuid primary key references auth.users(id) on delete cascade,
  time_zone text not null default 'UTC',
  slot_minutes int not null default 60,
  buffer_before_min int not null default 0,
  buffer_after_min int not null default 0,
  work_days int[] not null default '{1,2,3,4,5}',     -- 1=Mon..7=Sun
  work_start_min int not null default 9*60,           -- minutes from 00:00
  work_end_min int not null default 17*60,
  min_lead_time_min int not null default 12*60,
  cancel_cutoff_min int not null default 6*60,
  max_sessions_per_day int not null default 6,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- RLS
alter table public.calendar_attendees enable row level security;
alter table public.calendar_event_overrides enable row level security;
alter table public.booking_policies enable row level security;

do $$
begin
  -- attendees: event owner (coach) full; attendee read; admin full
  if not exists (select 1 from pg_policies where policyname='attendees_event_owner_all') then
    create policy attendees_event_owner_all on public.calendar_attendees
    for all to authenticated
    using (exists (select 1 from public.calendar_events e where e.id = calendar_attendees.event_id and e.coach_id = auth.uid()))
    with check (exists (select 1 from public.calendar_events e where e.id = calendar_attendees.event_id and e.coach_id = auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where policyname='attendees_self_ro') then
    create policy attendees_self_ro on public.calendar_attendees
    for select to authenticated
    using (user_id = auth.uid());
  end if;

  -- overrides: event owner only; admin full
  if not exists (select 1 from pg_policies where policyname='overrides_event_owner_all') then
    create policy overrides_event_owner_all on public.calendar_event_overrides
    for all to authenticated
    using (exists (select 1 from public.calendar_events e where e.id = calendar_event_overrides.event_id and e.coach_id = auth.uid()))
    with check (exists (select 1 from public.calendar_events e where e.id = calendar_event_overrides.event_id and e.coach_id = auth.uid()));
  end if;

  -- booking_policies: coach owner rw; admin ro
  if not exists (select 1 from pg_policies where policyname='booking_policies_owner_rw') then
    create policy booking_policies_owner_rw on public.booking_policies
    for all to authenticated
    using (coach_id = auth.uid())
    with check (coach_id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where policyname='booking_policies_admin_ro') then
    create policy booking_policies_admin_ro on public.booking_policies
    for select to authenticated
    using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role='admin'));
  end if;
end $$;

-- Seed: nothing forced; UI will upsert booking_policies on first save

select 'calendar_polish_v1_1_ready' as status;
