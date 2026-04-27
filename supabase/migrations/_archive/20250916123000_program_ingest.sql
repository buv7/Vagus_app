-- storage bucket for uploads
insert into storage.buckets (id, name, public)
select 'program_ingest','program_ingest', false
where not exists (select 1 from storage.buckets where id='program_ingest');

-- jobs
create table if not exists public.program_ingest_jobs (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.profiles(id) on delete cascade,
  coach_id uuid not null references public.profiles(id) on delete cascade,
  source text not null check (source in ('file','text')),
  storage_path text,       -- when source='file'
  raw_text text,           -- when source='text' or after OCR
  status text not null default 'queued' check (status in ('queued','processing','succeeded','failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  error text
);

-- results
create table if not exists public.program_ingest_results (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.program_ingest_jobs(id) on delete cascade,
  parsed_json jsonb not null,          -- conforms to schema below
  model_hint text,
  created_at timestamptz not null default now()
);

-- optional supplements table if not present
create table if not exists public.supplements (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  dosage text,
  timing text,
  notes text,
  created_at timestamptz not null default now()
);

-- client notes table for storing general notes
create table if not exists public.client_notes (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.profiles(id) on delete cascade,
  coach_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- RLS
alter table public.program_ingest_jobs enable row level security;
alter table public.program_ingest_results enable row level security;
alter table public.supplements enable row level security;
alter table public.client_notes enable row level security;

-- Policies: coach who owns the job and the client can read; only coach can insert their jobs
drop policy if exists "jobs_select_parties" on public.program_ingest_jobs;
create policy "jobs_select_parties" on public.program_ingest_jobs
for select using (auth.uid() = coach_id or auth.uid() = client_id);

drop policy if exists "jobs_insert_coach" on public.program_ingest_jobs;
create policy "jobs_insert_coach" on public.program_ingest_jobs
for insert with check (auth.uid() = coach_id);

drop policy if exists "jobs_update_owner" on public.program_ingest_jobs;
create policy "jobs_update_owner" on public.program_ingest_jobs
for update using (auth.uid() = coach_id);

drop policy if exists "res_select_parties" on public.program_ingest_results;
create policy "res_select_parties" on public.program_ingest_results
for select using (
  exists (select 1 from public.program_ingest_jobs j where j.id = job_id and (auth.uid() = j.coach_id or auth.uid() = j.client_id))
);

drop policy if exists "res_insert_service" on public.program_ingest_results;
create policy "res_insert_service" on public.program_ingest_results
for insert with check (auth.role() = 'service_role');

-- supplements: coach or client can read; coach inserts
drop policy if exists "supp_select_parties" on public.supplements;
create policy "supp_select_parties" on public.supplements
for select using (auth.uid() = client_id or exists(select 1 from public.user_coach_links l where l.client_id = client_id and l.coach_id = auth.uid()));

drop policy if exists "supp_insert_coach" on public.supplements;
create policy "supp_insert_coach" on public.supplements
for insert with check (exists(select 1 from public.user_coach_links l where l.client_id = supplements.client_id and l.coach_id = auth.uid()));

-- client_notes: coach or client can read; coach inserts
drop policy if exists "notes_select_parties" on public.client_notes;
create policy "notes_select_parties" on public.client_notes
for select using (auth.uid() = client_id or auth.uid() = coach_id);

drop policy if exists "notes_insert_coach" on public.client_notes;
create policy "notes_insert_coach" on public.client_notes
for insert with check (auth.uid() = coach_id);

drop policy if exists "notes_update_coach" on public.client_notes;
create policy "notes_update_coach" on public.client_notes
for update using (auth.uid() = coach_id);

-- storage policies for program_ingest
create policy if not exists "program_ingest_owner_write"
on storage.objects for insert to authenticated
with check (bucket_id='program_ingest' and owner = auth.uid());

create policy if not exists "program_ingest_owner_read"
on storage.objects for select to authenticated
using (bucket_id='program_ingest' and owner = auth.uid());
