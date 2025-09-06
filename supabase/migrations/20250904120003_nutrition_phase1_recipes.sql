-- Nutrition Phase 1 Part A - Enhanced Recipe System Migration
-- Extends existing recipe tables with missing fields for pro-grade recipes
-- Idempotent migration with IF NOT EXISTS guards

-- ========================================
-- ENHANCE NUTRITION RECIPES TABLE
-- ========================================
-- Add missing fields to existing nutrition_recipes table
alter table public.nutrition_recipes 
add column if not exists owner uuid references auth.users(id) on delete cascade,
add column if not exists coach_id uuid references auth.users(id) on delete set null,
add column if not exists title text,
add column if not exists summary text,
add column if not exists cuisine_tags text[] default '{}',
add column if not exists diet_tags text[] default '{}',
add column if not exists allergens text[] default '{}',
add column if not exists halal boolean default false,
add column if not exists serving_size numeric(10,2) default 1.0,
add column if not exists unit text default 'serving',
add column if not exists prep_minutes integer default 0,
add column if not exists cook_minutes integer default 0,
add column if not exists calories numeric(10,2) default 0.0,
add column if not exists protein numeric(10,2) default 0.0,
add column if not exists carbs numeric(10,2) default 0.0,
add column if not exists fat numeric(10,2) default 0.0,
add column if not exists sodium_mg numeric(10,2) default 0.0,
add column if not exists potassium_mg numeric(10,2) default 0.0,
add column if not exists micros jsonb default '{}',
add column if not exists visibility text default 'private' check (visibility in ('private', 'client', 'team', 'public'));

-- Update total_time_minutes to be generated column
alter table public.nutrition_recipes 
drop column if exists total_time_minutes;

alter table public.nutrition_recipes 
add column if not exists total_minutes integer generated always as (prep_minutes + cook_minutes) stored;

-- ========================================
-- ENHANCE NUTRITION RECIPE STEPS TABLE
-- ========================================
-- Add missing fields to existing nutrition_recipe_steps table
alter table public.nutrition_recipe_steps 
add column if not exists step_index integer,
add column if not exists instruction text;

-- Update step_number to step_index for consistency
update public.nutrition_recipe_steps 
set step_index = step_number 
where step_index is null and step_number is not null;

-- ========================================
-- ENHANCE NUTRITION RECIPE INGREDIENTS TABLE
-- ========================================
-- Add missing nutrition fields to existing nutrition_recipe_ingredients table
alter table public.nutrition_recipe_ingredients 
add column if not exists amount numeric(10,2) default 0.0,
add column if not exists calories numeric(10,2) default 0.0,
add column if not exists protein numeric(10,2) default 0.0,
add column if not exists carbs numeric(10,2) default 0.0,
add column if not exists fat numeric(10,2) default 0.0,
add column if not exists sodium_mg numeric(10,2) default 0.0,
add column if not exists potassium_mg numeric(10,2) default 0.0,
add column if not exists micros jsonb default '{}';

-- ========================================
-- ADD MISSING INDEXES
-- ========================================
-- Indexes for enhanced recipe fields
create index if not exists nutrition_recipes_owner_idx on public.nutrition_recipes(owner);
create index if not exists nutrition_recipes_coach_id_idx on public.nutrition_recipes(coach_id);
create index if not exists nutrition_recipes_title_idx on public.nutrition_recipes using gin (to_tsvector('english', title));
create index if not exists nutrition_recipes_visibility_idx on public.nutrition_recipes(visibility);
create index if not exists nutrition_recipes_cuisine_tags_gin on public.nutrition_recipes using gin (cuisine_tags);
create index if not exists nutrition_recipes_diet_tags_gin on public.nutrition_recipes using gin (diet_tags);
create index if not exists nutrition_recipes_allergens_gin on public.nutrition_recipes using gin (allergens);
create index if not exists nutrition_recipes_halal_idx on public.nutrition_recipes(halal);

-- Index for recipe steps
create index if not exists nutrition_recipe_steps_step_index_idx on public.nutrition_recipe_steps(recipe_id, step_index);

-- ========================================
-- UPDATE ROW LEVEL SECURITY POLICIES
-- ========================================
-- Enhanced RLS policies for recipes with owner/coach access
do $$
begin
  -- Drop existing policies to recreate with enhanced logic
  drop policy if exists nutrition_recipes_read on public.nutrition_recipes;
  drop policy if exists nutrition_recipes_insert on public.nutrition_recipes;
  drop policy if exists nutrition_recipes_update on public.nutrition_recipes;
  drop policy if exists nutrition_recipes_delete on public.nutrition_recipes;

  -- Enhanced read policy: owner, assigned coach, or public recipes
  create policy nutrition_recipes_read on public.nutrition_recipes
    for select to authenticated
    using (
      nutrition_recipes.visibility = 'public' 
      or nutrition_recipes.owner = auth.uid() 
      or nutrition_recipes.created_by = auth.uid()
      or nutrition_recipes.coach_id = auth.uid()
      or (
        nutrition_recipes.visibility = 'client' 
        and exists (
          select 1 from public.nutrition_plans np
          where np.client_id = auth.uid() 
          and np.created_by = nutrition_recipes.coach_id
        )
      )
      or (
        nutrition_recipes.visibility = 'team' 
        and nutrition_recipes.coach_id = auth.uid()
      )
    );

  -- Enhanced insert policy: owner or coach can create
  create policy nutrition_recipes_insert on public.nutrition_recipes
    for insert to authenticated
    with check (
      nutrition_recipes.owner = auth.uid() 
      or nutrition_recipes.created_by = auth.uid()
      or nutrition_recipes.coach_id = auth.uid()
    );

  -- Enhanced update policy: owner, creator, or assigned coach can update
  create policy nutrition_recipes_update on public.nutrition_recipes
    for update to authenticated
    using (
      nutrition_recipes.owner = auth.uid() 
      or nutrition_recipes.created_by = auth.uid()
      or nutrition_recipes.coach_id = auth.uid()
    )
    with check (
      nutrition_recipes.owner = auth.uid() 
      or nutrition_recipes.created_by = auth.uid()
      or nutrition_recipes.coach_id = auth.uid()
    );

  -- Enhanced delete policy: owner, creator, or assigned coach can delete
  create policy nutrition_recipes_delete on public.nutrition_recipes
    for delete to authenticated
    using (
      nutrition_recipes.owner = auth.uid() 
      or nutrition_recipes.created_by = auth.uid()
      or nutrition_recipes.coach_id = auth.uid()
    );
end $$;

-- ========================================
-- FUNCTIONS FOR RECIPE NUTRITION CALCULATION
-- ========================================

-- Function to calculate recipe nutrition from ingredients
create or replace function calculate_recipe_nutrition(recipe_uuid uuid)
returns table (
  total_calories numeric,
  total_protein numeric,
  total_carbs numeric,
  total_fat numeric,
  total_sodium_mg numeric,
  total_potassium_mg numeric,
  total_micros jsonb
) as $$
begin
  return query
  select 
    coalesce(sum(ri.calories * ri.amount / 100.0), 0) as total_calories,
    coalesce(sum(ri.protein * ri.amount / 100.0), 0) as total_protein,
    coalesce(sum(ri.carbs * ri.amount / 100.0), 0) as total_carbs,
    coalesce(sum(ri.fat * ri.amount / 100.0), 0) as total_fat,
    coalesce(sum(ri.sodium_mg * ri.amount / 100.0), 0) as total_sodium_mg,
    coalesce(sum(ri.potassium_mg * ri.amount / 100.0), 0) as total_potassium_mg,
    coalesce(
      jsonb_object_agg(
        key, 
        value::numeric * ri.amount / 100.0
      ) filter (where key is not null), 
      '{}'::jsonb
    ) as total_micros
  from public.nutrition_recipe_ingredients ri
  where ri.recipe_id = recipe_uuid;
end;
$$ language plpgsql;

-- Function to scale recipe nutrition for different serving sizes
create or replace function scale_recipe_nutrition(
  recipe_uuid uuid, 
  target_servings numeric
)
returns table (
  scaled_calories numeric,
  scaled_protein numeric,
  scaled_carbs numeric,
  scaled_fat numeric,
  scaled_sodium_mg numeric,
  scaled_potassium_mg numeric,
  scaled_micros jsonb
) as $$
declare
  base_servings numeric;
begin
  -- Get base serving size
  select serving_size into base_servings 
  from public.nutrition_recipes 
  where id = recipe_uuid;
  
  -- Calculate scaling factor
  return query
  select 
    (calc.total_calories * target_servings / base_servings) as scaled_calories,
    (calc.total_protein * target_servings / base_servings) as scaled_protein,
    (calc.total_carbs * target_servings / base_servings) as scaled_carbs,
    (calc.total_fat * target_servings / base_servings) as scaled_fat,
    (calc.total_sodium_mg * target_servings / base_servings) as scaled_sodium_mg,
    (calc.total_potassium_mg * target_servings / base_servings) as scaled_potassium_mg,
    (
      select jsonb_object_agg(
        key, 
        value::numeric * target_servings / base_servings
      )
      from jsonb_each(calc.total_micros)
    ) as scaled_micros
  from calculate_recipe_nutrition(recipe_uuid) calc;
end;
$$ language plpgsql;

-- ========================================
-- TRIGGERS FOR AUTOMATIC NUTRITION UPDATES
-- ========================================

-- Function to update recipe nutrition when ingredients change
create or replace function update_recipe_nutrition()
returns trigger as $$
declare
  recipe_uuid uuid;
  nutrition_data record;
begin
  -- Get recipe ID from the trigger context
  if TG_OP = 'DELETE' then
    recipe_uuid := OLD.recipe_id;
  else
    recipe_uuid := NEW.recipe_id;
  end if;

  -- Calculate new nutrition values
  select * into nutrition_data
  from calculate_recipe_nutrition(recipe_uuid);

  -- Update the recipe with new nutrition values
  update public.nutrition_recipes
  set 
    calories = nutrition_data.total_calories,
    protein = nutrition_data.total_protein,
    carbs = nutrition_data.total_carbs,
    fat = nutrition_data.total_fat,
    sodium_mg = nutrition_data.total_sodium_mg,
    potassium_mg = nutrition_data.total_potassium_mg,
    micros = nutrition_data.total_micros,
    updated_at = now()
  where id = recipe_uuid;

  return coalesce(NEW, OLD);
end;
$$ language plpgsql;

-- Create triggers for automatic nutrition updates
drop trigger if exists update_recipe_nutrition_on_ingredient_change on public.nutrition_recipe_ingredients;

create trigger update_recipe_nutrition_on_ingredient_change
  after insert or update or delete on public.nutrition_recipe_ingredients
  for each row execute function update_recipe_nutrition();

-- ========================================
-- COMPLETION MESSAGE
-- ========================================
select 'Nutrition Phase 1 Part A - Enhanced Recipe System migration completed successfully' as status;
