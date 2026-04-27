-- =========================
-- CLUSTER 1: Workout Fatigue/Recovery/Readiness + Session Modes
-- =========================

-- Fatigue tracking
create table if not exists public.fatigue_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  workout_session_id uuid,

  fatigue_score int check (fatigue_score between 0 and 10),
  recovery_score int check (recovery_score between 0 and 10),
  readiness_score int check (readiness_score between 0 and 10),
  sleep_quality int check (sleep_quality between 0 and 10),
  stress_level int check (stress_level between 0 and 10),
  energy_level int check (energy_level between 0 and 10),

  notes text,
  logged_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists idx_fatigue_logs_user_logged_at on public.fatigue_logs(user_id, logged_at desc);
create index if not exists idx_fatigue_logs_session on public.fatigue_logs(workout_session_id);

-- Recovery scores (aggregated)
create table if not exists public.recovery_scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  date date not null,
  overall_recovery numeric(3,1) check (overall_recovery between 0 and 10),
  calculated_from_fatigue_logs boolean default false,
  recommendation text,
  created_at timestamptz not null default now(),
  unique(user_id, date)
);

create index if not exists idx_recovery_scores_user_date on public.recovery_scores(user_id, date desc);

-- Add foreign key constraint for workout_session_id only if workout_sessions table exists
do $$
begin
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'workout_sessions') then
    if not exists (
      select 1 from information_schema.table_constraints 
      where constraint_schema = 'public' 
      and constraint_name = 'fk_fatigue_logs_workout_session'
    ) then
      alter table public.fatigue_logs
      add constraint fk_fatigue_logs_workout_session
      foreign key (workout_session_id) references public.workout_sessions(id) on delete set null;
    end if;
  end if;
end $$;

-- Session transformation modes (only if workout_sessions table exists)
do $$
begin
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'workout_sessions') then
    alter table public.workout_sessions
    add column if not exists transformation_mode text
    check (transformation_mode in ('strength','hypertrophy','endurance','deload','power','default'));
  end if;
end $$;

-- =========================
-- RLS
-- =========================
alter table public.fatigue_logs enable row level security;
alter table public.recovery_scores enable row level security;

-- fatigue_logs policies
drop policy if exists "Users can view own fatigue logs" on public.fatigue_logs;
create policy "Users can view own fatigue logs"
on public.fatigue_logs for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert own fatigue logs" on public.fatigue_logs;
create policy "Users can insert own fatigue logs"
on public.fatigue_logs for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update own fatigue logs" on public.fatigue_logs;
create policy "Users can update own fatigue logs"
on public.fatigue_logs for update
using (auth.uid() = user_id);

drop policy if exists "Coaches can view client fatigue logs" on public.fatigue_logs;
create policy "Coaches can view client fatigue logs"
on public.fatigue_logs for select
using (
  exists (
    select 1 from public.coach_clients cc
    where cc.coach_id = auth.uid()
      and cc.client_id = fatigue_logs.user_id
  )
);

-- recovery_scores policies
drop policy if exists "Users can view own recovery scores" on public.recovery_scores;
create policy "Users can view own recovery scores"
on public.recovery_scores for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert own recovery scores" on public.recovery_scores;
create policy "Users can insert own recovery scores"
on public.recovery_scores for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update own recovery scores" on public.recovery_scores;
create policy "Users can update own recovery scores"
on public.recovery_scores for update
using (auth.uid() = user_id);

drop policy if exists "Coaches can view client recovery scores" on public.recovery_scores;
create policy "Coaches can view client recovery scores"
on public.recovery_scores for select
using (
  exists (
    select 1 from public.coach_clients cc
    where cc.coach_id = auth.uid()
      and cc.client_id = recovery_scores.user_id
  )
);
