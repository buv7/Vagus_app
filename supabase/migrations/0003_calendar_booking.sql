-- Calendar & Booking System Migration
-- Section 9: Core v1

-- Ensure pgcrypto extension
create extension if not exists pgcrypto;

-- Calendar Events Table
create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid references auth.users(id),
  client_id uuid references auth.users(id),
  title text not null,
  description text,
  location text,
  start_at timestamptz not null,
  end_at timestamptz not null,
  timezone text,
  recurrence_rule text,
  status text not null default 'scheduled',
  attachments jsonb default '[]',
  created_by uuid not null references auth.users(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Booking Requests Table
create table if not exists public.booking_requests (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references auth.users(id),
  coach_id uuid not null references auth.users(id),
  requested_start_at timestamptz not null,
  requested_end_at timestamptz not null,
  message text,
  status text not null default 'pending',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes for calendar_events
create index if not exists idx_calendar_events_coach_start 
  on public.calendar_events(coach_id, start_at);
create index if not exists idx_calendar_events_client_start 
  on public.calendar_events(client_id, start_at);
create index if not exists idx_calendar_events_attachments 
  on public.calendar_events using gin(attachments);

-- Indexes for booking_requests
create index if not exists idx_booking_requests_coach_start 
  on public.booking_requests(coach_id, requested_start_at);
create index if not exists idx_booking_requests_client_start 
  on public.booking_requests(client_id, requested_start_at);

-- Enable RLS
alter table public.calendar_events enable row level security;
alter table public.booking_requests enable row level security;

-- Calendar Events Policies
do $$
begin
  -- Select policy for calendar_events
  if not exists (
    select 1 from pg_policies 
    where tablename = 'calendar_events' and policyname = 'calendar_events_select_policy'
  ) then
    create policy calendar_events_select_policy on public.calendar_events
      for select using (
        client_id = auth.uid() or 
        coach_id = auth.uid() or 
        created_by = auth.uid()
      );
  end if;

  -- Insert policy for calendar_events
  if not exists (
    select 1 from pg_policies 
    where tablename = 'calendar_events' and policyname = 'calendar_events_insert_policy'
  ) then
    create policy calendar_events_insert_policy on public.calendar_events
      for insert with check (
        created_by = auth.uid() and
        (client_id is null or client_id = auth.uid() or 
         exists (
           select 1 from public.coach_client_relationships 
           where coach_id = auth.uid() and client_id = calendar_events.client_id
         ))
      );
  end if;

  -- Update policy for calendar_events
  if not exists (
    select 1 from pg_policies 
    where tablename = 'calendar_events' and policyname = 'calendar_events_update_policy'
  ) then
    create policy calendar_events_update_policy on public.calendar_events
      for update using (created_by = auth.uid());
  end if;

  -- Delete policy for calendar_events
  if not exists (
    select 1 from pg_policies 
    where tablename = 'calendar_events' and policyname = 'calendar_events_delete_policy'
  ) then
    create policy calendar_events_delete_policy on public.calendar_events
      for delete using (created_by = auth.uid());
  end if;
end $$;

-- Booking Requests Policies
do $$
begin
  -- Select policy for booking_requests (clients)
  if not exists (
    select 1 from pg_policies 
    where tablename = 'booking_requests' and policyname = 'booking_requests_select_client_policy'
  ) then
    create policy booking_requests_select_client_policy on public.booking_requests
      for select using (client_id = auth.uid());
  end if;

  -- Select policy for booking_requests (coaches)
  if not exists (
    select 1 from pg_policies 
    where tablename = 'booking_requests' and policyname = 'booking_requests_select_coach_policy'
  ) then
    create policy booking_requests_select_coach_policy on public.booking_requests
      for select using (coach_id = auth.uid());
  end if;

  -- Insert policy for booking_requests
  if not exists (
    select 1 from pg_policies 
    where tablename = 'booking_requests' and policyname = 'booking_requests_insert_policy'
  ) then
    create policy booking_requests_insert_policy on public.booking_requests
      for insert with check (client_id = auth.uid());
  end if;

  -- Update policy for booking_requests (clients can update pending requests)
  if not exists (
    select 1 from pg_policies 
    where tablename = 'booking_requests' and policyname = 'booking_requests_update_client_policy'
  ) then
    create policy booking_requests_update_client_policy on public.booking_requests
      for update using (
        client_id = auth.uid() and status = 'pending'
      );
  end if;

  -- Update policy for booking_requests (coaches can update status)
  if not exists (
    select 1 from pg_policies 
    where tablename = 'booking_requests' and policyname = 'booking_requests_update_coach_policy'
  ) then
    create policy booking_requests_update_coach_policy on public.booking_requests
      for update using (coach_id = auth.uid());
  end if;
end $$;
