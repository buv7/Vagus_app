-- Nutrition Phase 1 Part E - Preferences, Allergies, Halal Guardrails Migration
-- Creates preferences and allergies tables with proper RLS and policies
-- Idempotent migration with IF NOT EXISTS guards

-- ========================================
-- USER COACH LINKS TABLE (for RLS policies)
-- ========================================
-- This table establishes the relationship between clients and coaches
-- Required for the RLS policies to work correctly
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

-- ========================================
-- NUTRITION PREFERENCES TABLE
-- ========================================
create table if not exists public.nutrition_preferences (
  user_id uuid primary key,
  calorie_target int,
  protein_g int,
  carbs_g int,
  fat_g int,
  sodium_max_mg int,
  potassium_min_mg int,
  diet_tags text[],        -- e.g. ['keto','vegetarian']
  cuisine_prefs text[],    -- e.g. ['iraqi','levant','turkish']
  cost_tier text,          -- 'low','medium','high'
  halal boolean,
  fasting_window jsonb,    -- { "start": "20:00", "end": "12:00" }
  updated_at timestamptz not null default now()
);

-- ========================================
-- NUTRITION ALLERGIES TABLE
-- ========================================
-- Note: nutrition_allergies table already exists from vnext.sql migration
-- We need to add the missing column and update the structure

-- Add missing allergen column if it doesn't exist
alter table public.nutrition_allergies 
add column if not exists allergen text;

-- Update existing allergen_name values to allergen column if needed
update public.nutrition_allergies 
set allergen = allergen_name 
where allergen is null and allergen_name is not null;

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================
-- Index for user lookups
create index if not exists idx_nutrition_preferences_user_id on public.nutrition_preferences (user_id);
create index if not exists idx_nutrition_allergies_user_id on public.nutrition_allergies (user_id);

-- Index for allergen lookups
create index if not exists idx_nutrition_allergies_allergen on public.nutrition_allergies (allergen);

-- ========================================
-- ROW LEVEL SECURITY POLICIES
-- ========================================

-- Enable RLS on all tables
alter table public.user_coach_links enable row level security;
alter table public.nutrition_preferences enable row level security;
alter table public.nutrition_allergies enable row level security;

-- User Coach Links RLS Policies
do $$
begin
  -- Drop existing policies to recreate
  drop policy if exists user_coach_links_select on public.user_coach_links;
  drop policy if exists user_coach_links_insert on public.user_coach_links;
  drop policy if exists user_coach_links_update on public.user_coach_links;
  drop policy if exists user_coach_links_delete on public.user_coach_links;

  -- Read policy: users can read their own coach links
  if not exists (select 1 from pg_policies where policyname = 'user_coach_links_select') then
    create policy user_coach_links_select on public.user_coach_links
      for select using (
        auth.uid() = client_id or 
        auth.uid() = coach_id or
        auth.role() = 'service_role'
      );
  end if;

  -- Insert policy: coaches can create links with clients
  if not exists (select 1 from pg_policies where policyname = 'user_coach_links_insert') then
    create policy user_coach_links_insert on public.user_coach_links
      for insert to authenticated
      with check (auth.uid() = coach_id or auth.role() = 'service_role');
  end if;

  -- Update policy: coaches can update their own links
  if not exists (select 1 from pg_policies where policyname = 'user_coach_links_update') then
    create policy user_coach_links_update on public.user_coach_links
      for update using (auth.uid() = coach_id or auth.role() = 'service_role');
  end if;

  -- Delete policy: coaches can delete their own links
  if not exists (select 1 from pg_policies where policyname = 'user_coach_links_delete') then
    create policy user_coach_links_delete on public.user_coach_links
      for delete using (auth.uid() = coach_id or auth.role() = 'service_role');
  end if;
end $$;

-- Nutrition Preferences RLS Policies
do $$
begin
  -- Drop existing policies to recreate
  drop policy if exists prefs_select on public.nutrition_preferences;
  drop policy if exists prefs_upsert on public.nutrition_preferences;
  drop policy if exists prefs_update on public.nutrition_preferences;

  -- Read policy: users can read their own prefs, coaches can read their clients' prefs
  if not exists (select 1 from pg_policies where policyname = 'prefs_select') then
    create policy prefs_select on public.nutrition_preferences
      for select using (
        auth.uid() = user_id
        or exists (select 1 from public.user_coach_links ucl
                   where ucl.client_id = user_id and ucl.coach_id = auth.uid())
        or auth.role() = 'service_role'
      );
  end if;

  -- Insert policy: users can insert their own prefs
  if not exists (select 1 from pg_policies where policyname = 'prefs_upsert') then
    create policy prefs_upsert on public.nutrition_preferences
      for insert to authenticated
      with check (auth.uid() = user_id or auth.role() = 'service_role');
  end if;

  -- Update policy: users can update their own prefs
  if not exists (select 1 from pg_policies where policyname = 'prefs_update') then
    create policy prefs_update on public.nutrition_preferences
      for update using (auth.uid() = user_id or auth.role() = 'service_role');
  end if;
end $$;

-- Nutrition Allergies RLS Policies
do $$
begin
  -- Drop existing policies to recreate
  drop policy if exists allergies_select on public.nutrition_allergies;
  drop policy if exists allergies_cud on public.nutrition_allergies;

  -- Read policy: users can read their own allergies, coaches can read their clients' allergies
  if not exists (select 1 from pg_policies where policyname = 'allergies_select') then
    create policy allergies_select on public.nutrition_allergies
      for select using (
        auth.uid() = user_id
        or exists (select 1 from public.user_coach_links ucl
                   where ucl.client_id = user_id and ucl.coach_id = auth.uid())
        or auth.role() = 'service_role'
      );
  end if;

  -- CUD policy: users can manage their own allergies
  if not exists (select 1 from pg_policies where policyname = 'allergies_cud') then
    create policy allergies_cud on public.nutrition_allergies
      for all using (auth.uid() = user_id or auth.role() = 'service_role')
      with check (auth.uid() = user_id or auth.role() = 'service_role');
  end if;
end $$;

-- ========================================
-- FUNCTIONS FOR PREFERENCES MANAGEMENT
-- ========================================

-- Function to upsert preferences
create or replace function upsert_nutrition_preferences(
  user_uuid uuid,
  calorie_target_val int default null,
  protein_g_val int default null,
  carbs_g_val int default null,
  fat_g_val int default null,
  sodium_max_mg_val int default null,
  potassium_min_mg_val int default null,
  diet_tags_val text[] default null,
  cuisine_prefs_val text[] default null,
  cost_tier_val text default null,
  halal_val boolean default null,
  fasting_window_val jsonb default null
)
returns void as $$
begin
  insert into public.nutrition_preferences (
    user_id, calorie_target, protein_g, carbs_g, fat_g,
    sodium_max_mg, potassium_min_mg, diet_tags, cuisine_prefs,
    cost_tier, halal, fasting_window, updated_at
  ) values (
    user_uuid, calorie_target_val, protein_g_val, carbs_g_val, fat_g_val,
    sodium_max_mg_val, potassium_min_mg_val, diet_tags_val, cuisine_prefs_val,
    cost_tier_val, halal_val, fasting_window_val, now()
  )
  on conflict (user_id) do update set
    calorie_target = coalesce(excluded.calorie_target, nutrition_preferences.calorie_target),
    protein_g = coalesce(excluded.protein_g, nutrition_preferences.protein_g),
    carbs_g = coalesce(excluded.carbs_g, nutrition_preferences.carbs_g),
    fat_g = coalesce(excluded.fat_g, nutrition_preferences.fat_g),
    sodium_max_mg = coalesce(excluded.sodium_max_mg, nutrition_preferences.sodium_max_mg),
    potassium_min_mg = coalesce(excluded.potassium_min_mg, nutrition_preferences.potassium_min_mg),
    diet_tags = coalesce(excluded.diet_tags, nutrition_preferences.diet_tags),
    cuisine_prefs = coalesce(excluded.cuisine_prefs, nutrition_preferences.cuisine_prefs),
    cost_tier = coalesce(excluded.cost_tier, nutrition_preferences.cost_tier),
    halal = coalesce(excluded.halal, nutrition_preferences.halal),
    fasting_window = coalesce(excluded.fasting_window, nutrition_preferences.fasting_window),
    updated_at = now();
end;
$$ language plpgsql;

-- Function to set allergies (replace all)
create or replace function set_nutrition_allergies(
  user_uuid uuid,
  allergens_list text[]
)
returns void as $$
begin
  -- Delete existing allergies for user
  delete from public.nutrition_allergies where user_id = user_uuid;
  
  -- Insert new allergies
  if allergens_list is not null and array_length(allergens_list, 1) > 0 then
    insert into public.nutrition_allergies (user_id, allergen, allergen_name, severity)
    select user_uuid, unnest(allergens_list), unnest(allergens_list), 'moderate';
  end if;
end;
$$ language plpgsql;

-- ========================================
-- VIEWS FOR EASIER QUERYING
-- ========================================

-- View to get preferences with user info
create or replace view nutrition_preferences_with_info as
select 
  np.*,
  p.name as user_name,
  p.email as user_email
from public.nutrition_preferences np
left join public.profiles p on p.id = np.user_id;

-- View to get allergies with user info
create or replace view nutrition_allergies_with_info as
select 
  na.id,
  na.user_id,
  na.allergen,
  na.allergen_name,
  na.severity,
  na.notes,
  na.created_at,
  na.updated_at,
  p.name as user_name,
  p.email as user_email
from public.nutrition_allergies na
left join public.profiles p on p.id = na.user_id;

-- ========================================
-- TRIGGERS FOR UPDATED_AT
-- ========================================

-- Trigger function for updated_at
create or replace function update_nutrition_preferences_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Create trigger if it doesn't exist
do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'nutrition_preferences_updated_at') then
    create trigger nutrition_preferences_updated_at
      before update on public.nutrition_preferences
      for each row
      execute function update_nutrition_preferences_updated_at();
  end if;
end $$;

-- ========================================
-- COMPLETION MESSAGE
-- ========================================
select 'Nutrition Phase 1 Part E - Preferences, Allergies, Halal Guardrails migration completed successfully' as status;
