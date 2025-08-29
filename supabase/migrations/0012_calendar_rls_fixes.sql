-- Calendar & Booking RLS Fixes
-- Section 9: MVP Edge Case Patches

-- 1. Fix events_insert_policy link check
-- Allow a client to create an event with a coach_id ONLY if that client is linked to that coach
drop policy if exists events_insert_policy on public.events;
create policy events_insert_policy on public.events
  for insert with check (
    created_by = auth.uid() and
    (coach_id is null or coach_id = auth.uid() or 
     exists (
       select 1 from public.coach_clients cc 
       where cc.coach_id = events.coach_id and cc.client_id = auth.uid()
     ))
  );

-- 2. Optional admin bypass (read/update/delete) - non-blocking if profiles.role doesn't exist
drop policy if exists events_admin_select_policy on public.events;
create policy events_admin_select_policy on public.events
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

drop policy if exists events_admin_update_policy on public.events;
create policy events_admin_update_policy on public.events
  for update using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

drop policy if exists events_admin_delete_policy on public.events;
create policy events_admin_delete_policy on public.events
  for delete using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

-- 3. Harden capacity function for 0 participants
create or replace function check_event_capacity(
  p_event_id uuid
) returns boolean as $$
declare
  current_participants int;
  max_capacity int;
begin
  -- Get event capacity
  select capacity into max_capacity
  from public.events
  where id = p_event_id;
  
  -- Get current participant count (coalesce to 0 if no participants)
  select coalesce(count(*), 0) into current_participants
  from public.event_participants
  where event_id = p_event_id and status = 'confirmed';
  
  return current_participants < max_capacity;
end;
$$ language plpgsql security definer;

-- 4. Add updated_at trigger on events
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists update_events_updated_at on public.events;
create trigger update_events_updated_at
  before update on public.events
  for each row
  execute function update_updated_at_column();
