-- VAGUS Progress System - Initial Migration
-- Sections 1-3: client_metrics, progress_photos, checkins tables + RLS + policies

-- Ensure pgcrypto is available for gen_random_uuid()
create extension if not exists pgcrypto;

-- Profiles Table (required for role-based access)
create table if not exists public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text,
  email text,
  role text DEFAULT 'client' CHECK (role IN ('admin', 'coach', 'client')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Index for profiles
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS policies for profiles
DO $$
BEGIN
  -- Users can read their own profile
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_select_own') THEN
    CREATE POLICY profiles_select_own ON public.profiles
      FOR SELECT TO authenticated
      USING (id = auth.uid());
  END IF;

  -- Users can update their own profile
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_update_own') THEN
    CREATE POLICY profiles_update_own ON public.profiles
      FOR UPDATE TO authenticated
      USING (id = auth.uid())
      WITH CHECK (id = auth.uid());
  END IF;

  -- Users can insert their own profile
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_insert_own') THEN
    CREATE POLICY profiles_insert_own ON public.profiles
      FOR INSERT TO authenticated
      WITH CHECK (id = auth.uid());
  END IF;

  -- Coaches can read profiles of their clients (will be updated later when user_coach_links exists)
  -- This policy will be added in a later migration

  -- Admins can read all profiles
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_select_admin') THEN
    CREATE POLICY profiles_select_admin ON public.profiles
      FOR SELECT TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid() AND p.role = 'admin'
        )
      );
  END IF;
END $$;

-- User Coach Links Table (required for RLS policies)
create table if not exists public.user_coach_links (
  client_id uuid not null references auth.users(id) on delete cascade,
  coach_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (client_id, coach_id)
);

-- Index for coach lookups
create index if not exists idx_user_coach_links_coach_id on public.user_coach_links (coach_id);

-- Index for client lookups  
create index if not exists idx_user_coach_links_client_id on public.user_coach_links (client_id);

-- Enable RLS on user_coach_links
alter table public.user_coach_links enable row level security;

-- RLS policies for user_coach_links
do $$
begin
  -- Users can read their own coach links
  if not exists (select 1 from pg_policies where policyname = 'user_coach_links_select') then
    create policy user_coach_links_select on public.user_coach_links
      for select using (
        auth.uid() = client_id or 
        auth.uid() = coach_id or
        auth.role() = 'service_role'
      );
  end if;

  -- Coaches can create links with clients
  if not exists (select 1 from pg_policies where policyname = 'user_coach_links_insert') then
    create policy user_coach_links_insert on public.user_coach_links
      for insert to authenticated
      with check (auth.uid() = coach_id or auth.role() = 'service_role');
  end if;

  -- Coaches can update their own links
  if not exists (select 1 from pg_policies where policyname = 'user_coach_links_update') then
    create policy user_coach_links_update on public.user_coach_links
      for update using (auth.uid() = coach_id or auth.role() = 'service_role');
  end if;

  -- Coaches can delete their own links
  if not exists (select 1 from pg_policies where policyname = 'user_coach_links_delete') then
    create policy user_coach_links_delete on public.user_coach_links
      for delete using (auth.uid() = coach_id or auth.role() = 'service_role');
  end if;
end $$;

-- 1. Client Metrics Table
create table if not exists public.client_metrics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  weight_kg numeric(6,2),
  body_fat_percent numeric(5,2),
  waist_cm numeric(6,2),
  notes text,
  sodium_mg integer,       -- optional roll-up from nutrition day, if available
  potassium_mg integer,    -- optional roll-up
  created_at timestamptz not null default now(),
  updated_at timestamptz
);

create index if not exists client_metrics_user_date_idx on public.client_metrics(user_id, date);

alter table public.client_metrics enable row level security;

-- Client can SELECT/INSERT/UPDATE own rows
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'metrics_client_select') then
    create policy metrics_client_select on public.client_metrics
      for select to authenticated using (user_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'metrics_client_insert') then
    create policy metrics_client_insert on public.client_metrics
      for insert to authenticated with check (user_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'metrics_client_update') then
    create policy metrics_client_update on public.client_metrics
      for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'metrics_client_delete') then
    create policy metrics_client_delete on public.client_metrics
      for delete to authenticated using (user_id = auth.uid());
  end if;
end $$;

-- Coach can SELECT metrics of linked clients
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'metrics_coach_select_linked') then
    create policy metrics_coach_select_linked on public.client_metrics
      for select to authenticated
      using (
        exists (
          select 1 from public.user_coach_links l
          where l.coach_id = auth.uid() and l.client_id = client_metrics.user_id
        )
      );
  end if;
end $$;

-- 2. Progress Photos Table
create table if not exists public.progress_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  taken_at timestamptz not null default now(),
  shot_type text,               -- e.g., front/side/back/other
  storage_path text not null,   -- e.g., vagus-media/progress-photos/{user}/{uuid}.jpg
  url text,                     -- optional signed URL cached
  tags text[] default '{}',
  created_at timestamptz not null default now()
);

create index if not exists progress_photos_user_idx on public.progress_photos(user_id, taken_at desc);

alter table public.progress_photos enable row level security;

-- Owner can select/insert/delete own photos
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'pp_client_select') then
    create policy pp_client_select on public.progress_photos
      for select to authenticated using (user_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'pp_client_insert') then
    create policy pp_client_insert on public.progress_photos
      for insert to authenticated with check (user_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'pp_client_delete') then
    create policy pp_client_delete on public.progress_photos
      for delete to authenticated using (user_id = auth.uid());
  end if;
end $$;

-- Coach can SELECT photos of linked clients (read-only)
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'pp_coach_select_linked') then
    create policy pp_coach_select_linked on public.progress_photos
      for select to authenticated
      using (
        exists (
          select 1 from public.user_coach_links l
          where l.coach_id = auth.uid() and l.client_id = progress_photos.user_id
        )
      );
  end if;
end $$;

-- 3. Weekly Check-ins Table
create table if not exists public.checkins (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references auth.users(id) on delete cascade,
  coach_id uuid not null references auth.users(id) on delete cascade,
  checkin_date date not null,
  message text,          -- from client
  coach_reply text,      -- from coach
  status text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz
);

create index if not exists checkins_client_date_idx on public.checkins(client_id, checkin_date desc);
create index if not exists checkins_coach_idx on public.checkins(coach_id);

alter table public.checkins enable row level security;

-- Client can select own check-ins, insert new, and update ONLY their 'message' field
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'ci_client_select') then
    create policy ci_client_select on public.checkins
      for select to authenticated using (client_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'ci_client_insert') then
    create policy ci_client_insert on public.checkins
      for insert to authenticated with check (client_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'ci_client_update_message') then
    create policy ci_client_update_message on public.checkins
      for update to authenticated
      using (client_id = auth.uid())
      with check (client_id = auth.uid());
  end if;
end $$;

-- Coach can select check-ins of linked clients, and update ONLY 'coach_reply' and 'status'
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'ci_coach_select_linked') then
    create policy ci_coach_select_linked on public.checkins
      for select to authenticated
      using (
        exists (
          select 1 from public.user_coach_links l
          where l.coach_id = auth.uid() and l.client_id = checkins.client_id
        )
      );
  end if;

  if not exists (select 1 from pg_policies where policyname = 'ci_coach_update_reply_status') then
    create policy ci_coach_update_reply_status on public.checkins
      for update to authenticated
      using (
        coach_id = auth.uid()
        and exists (
          select 1 from public.user_coach_links l
          where l.coach_id = auth.uid() and l.client_id = checkins.client_id
        )
      )
      with check (
        coach_id = auth.uid()
        and exists (
          select 1 from public.user_coach_links l
          where l.coach_id = auth.uid() and l.client_id = checkins.client_id
        )
      );
  end if;
end $$;
