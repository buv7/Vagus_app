-- Google Apps Integration v1 Schema
-- Sprint G: Google Sheets/Drive + Forms ingest integration

-- Google account connections
create table if not exists public.integrations_google_accounts (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('coach', 'org')),
  email text not null,
  connected_at timestamptz default now(),
  workspace_folder text null,
  creds_meta jsonb default '{}'::jsonb
);

-- Google Drive file links
create table if not exists public.google_file_links (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  google_id text not null,
  mime text not null,
  name text not null,
  web_url text not null,
  created_at timestamptz default now()
);

-- Google exports to Sheets
create table if not exists public.google_exports (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('metrics', 'checkins', 'workouts', 'nutrition')),
  status text not null check (status in ('queued', 'running', 'done', 'error')) default 'queued',
  sheet_url text null,
  error text null,
  created_at timestamptz default now()
);

-- Forms mappings for coaches
create table if not exists public.forms_mappings (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.profiles(id) on delete cascade,
  external_id text not null,
  map_json jsonb not null default '{}'::jsonb,
  webhook_secret text not null,
  created_at timestamptz default now()
);

-- (Pro) Scheduled exports
create table if not exists public.google_export_schedules (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('metrics', 'checkins', 'workouts', 'nutrition')),
  cron text not null,
  active bool default true,
  created_at timestamptz default now()
);

-- Indexes for performance
create index if not exists idx_google_file_links_owner 
  on public.google_file_links(owner_id);

create index if not exists idx_google_exports_owner_created 
  on public.google_exports(owner_id, created_at desc);

create index if not exists idx_forms_mappings_coach_external 
  on public.forms_mappings(coach_id, external_id);

create index if not exists idx_google_export_schedules_owner 
  on public.google_export_schedules(owner_id);

-- Enable RLS
alter table public.integrations_google_accounts enable row level security;
alter table public.google_file_links enable row level security;
alter table public.google_exports enable row level security;
alter table public.forms_mappings enable row level security;
alter table public.google_export_schedules enable row level security;

-- RLS Policies for integrations_google_accounts
create policy integrations_google_accounts_select_policy on public.integrations_google_accounts
  for select using (user_id = auth.uid());

create policy integrations_google_accounts_insert_policy on public.integrations_google_accounts
  for insert with check (user_id = auth.uid());

create policy integrations_google_accounts_update_policy on public.integrations_google_accounts
  for update using (user_id = auth.uid());

create policy integrations_google_accounts_delete_policy on public.integrations_google_accounts
  for delete using (user_id = auth.uid());

-- RLS Policies for google_file_links
create policy google_file_links_select_policy on public.google_file_links
  for select using (owner_id = auth.uid());

create policy google_file_links_insert_policy on public.google_file_links
  for insert with check (owner_id = auth.uid());

create policy google_file_links_update_policy on public.google_file_links
  for update using (owner_id = auth.uid());

create policy google_file_links_delete_policy on public.google_file_links
  for delete using (owner_id = auth.uid());

-- RLS Policies for google_exports
create policy google_exports_select_policy on public.google_exports
  for select using (owner_id = auth.uid());

create policy google_exports_insert_policy on public.google_exports
  for insert with check (owner_id = auth.uid());

create policy google_exports_update_policy on public.google_exports
  for update using (owner_id = auth.uid());

create policy google_exports_delete_policy on public.google_exports
  for delete using (owner_id = auth.uid());

-- RLS Policies for forms_mappings
create policy forms_mappings_select_policy on public.forms_mappings
  for select using (coach_id = auth.uid());

create policy forms_mappings_insert_policy on public.forms_mappings
  for insert with check (coach_id = auth.uid());

create policy forms_mappings_update_policy on public.forms_mappings
  for update using (coach_id = auth.uid());

create policy forms_mappings_delete_policy on public.forms_mappings
  for delete using (coach_id = auth.uid());

-- RLS Policies for google_export_schedules
create policy google_export_schedules_select_policy on public.google_export_schedules
  for select using (owner_id = auth.uid());

create policy google_export_schedules_insert_policy on public.google_export_schedules
  for insert with check (owner_id = auth.uid());

create policy google_export_schedules_update_policy on public.google_export_schedules
  for update using (owner_id = auth.uid());

create policy google_export_schedules_delete_policy on public.google_export_schedules
  for delete using (owner_id = auth.uid());

-- Admin policies (read-all for admin users)
create policy integrations_google_accounts_admin_select_policy on public.integrations_google_accounts
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy google_file_links_admin_select_policy on public.google_file_links
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy google_exports_admin_select_policy on public.google_exports
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy forms_mappings_admin_select_policy on public.forms_mappings
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy google_export_schedules_admin_select_policy on public.google_export_schedules
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );
