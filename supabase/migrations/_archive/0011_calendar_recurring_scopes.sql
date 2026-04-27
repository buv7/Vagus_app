-- Calendar & Booking System Migration
-- Section 9: MVP Schema Update

-- Drop existing tables if they exist (for clean migration)
drop table if exists public.booking_requests cascade;
drop table if exists public.calendar_events cascade;

-- Events Table (MVP requirements)
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id),
  coach_id uuid references auth.users(id),
  client_id uuid references auth.users(id),
  title text not null,
  start_at timestamptz not null,
  end_at timestamptz not null,
  all_day boolean default false,
  location text,
  notes text,
  tags text[] default '{}',
  attachments jsonb default '[]',
  visibility text default 'private',
  status text default 'scheduled',
  is_booking_slot boolean default false,
  capacity int default 1,
  recurrence_rule text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Event Participants Table
create table if not exists public.event_participants (
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'attendee',
  status text not null default 'confirmed',
  added_at timestamptz default now(),
  primary key (event_id, user_id)
);

-- Helpful indexes
create index if not exists idx_events_start_at on public.events(start_at);
create index if not exists idx_events_coach_id on public.events(coach_id);
create index if not exists idx_events_client_id on public.events(client_id);
create index if not exists idx_events_created_by on public.events(created_by);
create index if not exists idx_events_booking_slots on public.events(is_booking_slot) where is_booking_slot = true;
create index if not exists idx_event_participants_user_id on public.event_participants(user_id);
create index if not exists idx_event_participants_event_id on public.event_participants(event_id);

-- Enable RLS
alter table public.events enable row level security;
alter table public.event_participants enable row level security;

-- Events RLS Policies
create policy events_select_policy on public.events
  for select using (
    created_by = auth.uid() or
    coach_id = auth.uid() or
    client_id = auth.uid() or
    visibility = 'public' or
    exists (
      select 1 from public.event_participants 
      where event_id = events.id and user_id = auth.uid()
    )
  );

create policy events_insert_policy on public.events
  for insert with check (
    created_by = auth.uid() and
    (coach_id is null or coach_id = auth.uid() or 
     exists (
       select 1 from public.user_coach_links 
       where coach_id = auth.uid() and client_id = events.coach_id
     ))
  );

create policy events_update_policy on public.events
  for update using (created_by = auth.uid());

create policy events_delete_policy on public.events
  for delete using (created_by = auth.uid());

-- Event Participants RLS Policies
create policy event_participants_select_policy on public.event_participants
  for select using (
    user_id = auth.uid() or
    exists (
      select 1 from public.events 
      where id = event_participants.event_id and 
      (created_by = auth.uid() or coach_id = auth.uid())
    )
  );

create policy event_participants_insert_policy on public.event_participants
  for insert with check (
    user_id = auth.uid() or
    exists (
      select 1 from public.events 
      where id = event_participants.event_id and created_by = auth.uid()
    )
  );

create policy event_participants_update_policy on public.event_participants
  for update using (
    user_id = auth.uid() or
    exists (
      select 1 from public.events 
      where id = event_participants.event_id and created_by = auth.uid()
    )
  );

create policy event_participants_delete_policy on public.event_participants
  for delete using (
    user_id = auth.uid() or
    exists (
      select 1 from public.events 
      where id = event_participants.event_id and created_by = auth.uid()
    )
  );

-- Function to check booking conflicts
create or replace function check_booking_conflicts(
  p_user_id uuid,
  p_start_at timestamptz,
  p_end_at timestamptz
) returns boolean as $$
begin
  return exists (
    select 1 from public.events e
    inner join public.event_participants ep on e.id = ep.event_id
    where ep.user_id = p_user_id
    and e.status != 'cancelled'
    and (
      (e.start_at < p_end_at and e.end_at > p_start_at) or
      (p_start_at < e.end_at and p_end_at > e.start_at)
    )
  );
end;
$$ language plpgsql security definer;

-- Function to check capacity before booking
create or replace function check_event_capacity(
  p_event_id uuid
) returns boolean as $$
declare
  current_participants int;
  max_capacity int;
begin
  select count(*), e.capacity
  into current_participants, max_capacity
  from public.event_participants ep
  inner join public.events e on e.id = ep.event_id
  where ep.event_id = p_event_id and ep.status = 'confirmed'
  group by e.capacity;
  
  return current_participants < max_capacity;
end;
$$ language plpgsql security definer;
