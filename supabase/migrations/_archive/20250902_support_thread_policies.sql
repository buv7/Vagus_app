-- Message threads table (create if it doesn't exist)
create table if not exists public.message_threads (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references auth.users(id) on delete cascade,
  coach_id uuid not null references auth.users(id) on delete cascade,
  subject text,
  status text default 'open' check (status in ('open', 'closed', 'resolved')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes for message_threads
create index if not exists idx_message_threads_client_id on public.message_threads(client_id);
create index if not exists idx_message_threads_coach_id on public.message_threads(coach_id);
create index if not exists idx_message_threads_status on public.message_threads(status);

-- Enable RLS on message_threads
alter table public.message_threads enable row level security;

-- Basic RLS policies for message_threads
do $$
begin
  -- Users can read threads they're part of
  if not exists (select 1 from pg_policies where policyname = 'message_threads_select_own') then
    create policy message_threads_select_own on public.message_threads
      for select to authenticated
      using (client_id = auth.uid() or coach_id = auth.uid());
  end if;

  -- Users can insert threads
  if not exists (select 1 from pg_policies where policyname = 'message_threads_insert_own') then
    create policy message_threads_insert_own on public.message_threads
      for insert to authenticated
      with check (client_id = auth.uid() or coach_id = auth.uid());
  end if;

  -- Users can update threads they're part of
  if not exists (select 1 from pg_policies where policyname = 'message_threads_update_own') then
    create policy message_threads_update_own on public.message_threads
      for update to authenticated
      using (client_id = auth.uid() or coach_id = auth.uid())
      with check (client_id = auth.uid() or coach_id = auth.uid());
  end if;
end $$;

-- Allow clients to open a support thread with an admin
drop policy if exists "client_can_open_support_thread_with_admin" on public.message_threads;
create policy "client_can_open_support_thread_with_admin"
on public.message_threads
for insert
to authenticated
with check (
  auth.uid() = client_id
  and exists (
    select 1
    from public.profiles p
    where p.id = coach_id
      and p.role = 'admin'
  )
);

-- Allow admins to open a thread with a client
drop policy if exists "admin_can_open_thread_with_client" on public.message_threads;
create policy "admin_can_open_thread_with_client"
on public.message_threads
for insert
to authenticated
with check (
  auth.uid() = coach_id
  and exists (
    select 1 from public.profiles p
    where p.id = client_id
  )
);

