-- Music Integration v1 Schema
-- Sprint F: Deep links for Spotify/SoundCloud integration

-- Music links table
create table if not exists public.music_links (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('spotify', 'soundcloud')),
  uri text not null,
  title text not null,
  art text null,
  tags text[] default '{}',
  created_at timestamptz default now()
);

-- Workout music references
create table if not exists public.workout_music_refs (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.workout_plans(id) on delete cascade,
  week_idx int null,
  day_idx int null,
  music_link_id uuid not null references public.music_links(id) on delete cascade,
  created_at timestamptz default now()
);

-- Event music references
create table if not exists public.event_music_refs (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  music_link_id uuid not null references public.music_links(id) on delete cascade,
  created_at timestamptz default now()
);

-- User music preferences
create table if not exists public.user_music_prefs (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  default_provider text null check (default_provider in ('spotify', 'soundcloud', null)),
  auto_open bool default true,
  genres text[] default '{}',
  bpm_min int null,
  bpm_max int null,
  updated_at timestamptz default now()
);

-- Indexes for performance
create index if not exists idx_workout_music_refs_plan_week_day 
  on public.workout_music_refs(plan_id, week_idx, day_idx);

create index if not exists idx_event_music_refs_event
  on public.event_music_refs(event_id);

create index if not exists idx_music_links_owner 
  on public.music_links(owner_id);

-- Enable RLS
alter table public.music_links enable row level security;
alter table public.workout_music_refs enable row level security;
alter table public.event_music_refs enable row level security;
alter table public.user_music_prefs enable row level security;

-- RLS Policies for music_links
create policy music_links_select_policy on public.music_links
  for select using (owner_id = auth.uid());

create policy music_links_insert_policy on public.music_links
  for insert with check (owner_id = auth.uid());

create policy music_links_update_policy on public.music_links
  for update using (owner_id = auth.uid());

create policy music_links_delete_policy on public.music_links
  for delete using (owner_id = auth.uid());

-- RLS Policies for workout_music_refs
create policy workout_music_refs_select_policy on public.workout_music_refs
  for select using (
    exists (
      select 1 from public.workout_plans wp 
      where wp.id = workout_music_refs.plan_id 
      and (wp.coach_id = auth.uid() or wp.client_id = auth.uid())
    )
  );

create policy workout_music_refs_insert_policy on public.workout_music_refs
  for insert with check (
    exists (
      select 1 from public.workout_plans wp 
      where wp.id = workout_music_refs.plan_id 
      and wp.coach_id = auth.uid()
    )
  );

create policy workout_music_refs_update_policy on public.workout_music_refs
  for update using (
    exists (
      select 1 from public.workout_plans wp 
      where wp.id = workout_music_refs.plan_id 
      and wp.coach_id = auth.uid()
    )
  );

create policy workout_music_refs_delete_policy on public.workout_music_refs
  for delete using (
    exists (
      select 1 from public.workout_plans wp 
      where wp.id = workout_music_refs.plan_id 
      and wp.coach_id = auth.uid()
    )
  );

-- RLS Policies for event_music_refs
create policy event_music_refs_select_policy on public.event_music_refs
  for select using (
    exists (
      select 1 from public.events e
      where e.id = event_music_refs.event_id
      and (e.coach_id = auth.uid() or e.client_id = auth.uid())
    )
  );

create policy event_music_refs_insert_policy on public.event_music_refs
  for insert with check (
    exists (
      select 1 from public.events e
      where e.id = event_music_refs.event_id
      and e.coach_id = auth.uid()
    )
  );

create policy event_music_refs_update_policy on public.event_music_refs
  for update using (
    exists (
      select 1 from public.events e
      where e.id = event_music_refs.event_id
      and e.coach_id = auth.uid()
    )
  );

create policy event_music_refs_delete_policy on public.event_music_refs
  for delete using (
    exists (
      select 1 from public.events e
      where e.id = event_music_refs.event_id
      and e.coach_id = auth.uid()
    )
  );

-- RLS Policies for user_music_prefs
create policy user_music_prefs_select_policy on public.user_music_prefs
  for select using (user_id = auth.uid());

create policy user_music_prefs_insert_policy on public.user_music_prefs
  for insert with check (user_id = auth.uid());

create policy user_music_prefs_update_policy on public.user_music_prefs
  for update using (user_id = auth.uid());

create policy user_music_prefs_delete_policy on public.user_music_prefs
  for delete using (user_id = auth.uid());

-- Admin policies (read-all for admin users)
create policy music_links_admin_select_policy on public.music_links
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy workout_music_refs_admin_select_policy on public.workout_music_refs
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy event_music_refs_admin_select_policy on public.event_music_refs
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy user_music_prefs_admin_select_policy on public.user_music_prefs
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );
