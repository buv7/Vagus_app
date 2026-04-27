-- Nutrition vNext Migration - Phase 0
-- Creates missing tables for comprehensive nutrition system
-- Idempotent migration with IF NOT EXISTS guards

-- Enable required extensions
create extension if not exists pgcrypto;
create extension if not exists pg_trgm;

-- ========================================
-- NUTRITION PLANS TABLE
-- ========================================
-- Create nutrition_plans table if it doesn't exist
create table if not exists public.nutrition_plans (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  client_id uuid not null references auth.users(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes for nutrition_plans
create index if not exists idx_nutrition_plans_client_id on public.nutrition_plans(client_id);
create index if not exists idx_nutrition_plans_created_by on public.nutrition_plans(created_by);

-- Enable RLS on nutrition_plans
alter table public.nutrition_plans enable row level security;

-- RLS policies for nutrition_plans
do $$
begin
  -- Users can read their own plans
  if not exists (select 1 from pg_policies where policyname = 'nutrition_plans_read_own') then
    create policy nutrition_plans_read_own on public.nutrition_plans
      for select to authenticated
      using (client_id = auth.uid() or created_by = auth.uid());
  end if;

  -- Users can insert their own plans
  if not exists (select 1 from pg_policies where policyname = 'nutrition_plans_insert_own') then
    create policy nutrition_plans_insert_own on public.nutrition_plans
      for insert to authenticated
      with check (created_by = auth.uid());
  end if;

  -- Users can update their own plans
  if not exists (select 1 from pg_policies where policyname = 'nutrition_plans_update_own') then
    create policy nutrition_plans_update_own on public.nutrition_plans
      for update to authenticated
      using (created_by = auth.uid())
      with check (created_by = auth.uid());
  end if;

  -- Users can delete their own plans
  if not exists (select 1 from pg_policies where policyname = 'nutrition_plans_delete_own') then
    create policy nutrition_plans_delete_own on public.nutrition_plans
      for delete to authenticated
      using (created_by = auth.uid());
  end if;
end $$;

-- Note: nutrition_plans table already exists, adding missing columns
alter table public.nutrition_plans 
add column if not exists length_type text check (length_type in ('daily', 'weekly', 'program')),
add column if not exists meals jsonb default '[]'::jsonb,
add column if not exists daily_summary jsonb default '{}'::jsonb,
add column if not exists ai_generated boolean default false,
add column if not exists unseen_update boolean default false,
add column if not exists version integer default 1,
add column if not exists status text default 'draft' check (status in ('draft', 'published', 'archived')),
add column if not exists updated_at timestamptz default now();

-- Indexes for nutrition_plans
create index if not exists nutrition_plans_client_id_idx on public.nutrition_plans(client_id);
create index if not exists nutrition_plans_created_by_idx on public.nutrition_plans(created_by);
create index if not exists nutrition_plans_created_at_idx on public.nutrition_plans(created_at desc);

-- ========================================
-- NUTRITION DAYS TABLE
-- ========================================
create table if not exists public.nutrition_days (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.nutrition_plans(id) on delete cascade,
  day_number integer not null,
  date date,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(plan_id, day_number)
);

-- Indexes for nutrition_days
create index if not exists nutrition_days_plan_id_idx on public.nutrition_days(plan_id);
create index if not exists nutrition_days_date_idx on public.nutrition_days(date);

-- ========================================
-- NUTRITION MEALS TABLE
-- ========================================
create table if not exists public.nutrition_meals (
  id uuid primary key default gen_random_uuid(),
  day_id uuid not null references public.nutrition_days(id) on delete cascade,
  meal_type text not null check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack', 'pre_workout', 'post_workout')),
  label text not null,
  order_index integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes for nutrition_meals
create index if not exists nutrition_meals_day_id_idx on public.nutrition_meals(day_id);
create index if not exists nutrition_meals_meal_type_idx on public.nutrition_meals(meal_type);

-- ========================================
-- NUTRITION RECIPES TABLE
-- ========================================
-- Create nutrition_recipes table if it doesn't exist
create table if not exists public.nutrition_recipes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  instructions text,
  photo_url text,
  prep_time_minutes int,
  cook_time_minutes int,
  servings int default 1,
  is_public boolean default false,
  dietary_tags text[] default '{}',
  allergen_tags text[] default '{}',
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes for nutrition_recipes
create index if not exists idx_nutrition_recipes_created_by on public.nutrition_recipes(created_by);
create index if not exists idx_nutrition_recipes_title on public.nutrition_recipes(title);

-- Enable RLS on nutrition_recipes
alter table public.nutrition_recipes enable row level security;

-- RLS policies for nutrition_recipes
do $$
begin
  -- Users can read all recipes
  if not exists (select 1 from pg_policies where policyname = 'nutrition_recipes_read_all') then
    create policy nutrition_recipes_read_all on public.nutrition_recipes
      for select to authenticated
      using (true);
  end if;

  -- Users can insert their own recipes
  if not exists (select 1 from pg_policies where policyname = 'nutrition_recipes_insert_own') then
    create policy nutrition_recipes_insert_own on public.nutrition_recipes
      for insert to authenticated
      with check (created_by = auth.uid());
  end if;

  -- Users can update their own recipes
  if not exists (select 1 from pg_policies where policyname = 'nutrition_recipes_update_own') then
    create policy nutrition_recipes_update_own on public.nutrition_recipes
      for update to authenticated
      using (created_by = auth.uid())
      with check (created_by = auth.uid());
  end if;

  -- Users can delete their own recipes
  if not exists (select 1 from pg_policies where policyname = 'nutrition_recipes_delete_own') then
    create policy nutrition_recipes_delete_own on public.nutrition_recipes
      for delete to authenticated
      using (created_by = auth.uid());
  end if;
end $$;

-- ========================================
-- NUTRITION ITEMS TABLE
-- ========================================
create table if not exists public.nutrition_items (
  id uuid primary key default gen_random_uuid(),
  meal_id uuid not null references public.nutrition_meals(id) on delete cascade,
  food_item_id uuid references public.food_items(id) on delete set null,
  name text not null,
  amount_grams numeric(10,2) not null default 0.0,
  protein_g numeric(10,2) not null default 0.0,
  carbs_g numeric(10,2) not null default 0.0,
  fat_g numeric(10,2) not null default 0.0,
  kcal numeric(10,2) not null default 0.0,
  sodium_mg numeric(10,2) default 0.0,
  potassium_mg numeric(10,2) default 0.0,
  order_index integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes for nutrition_items
create index if not exists nutrition_items_meal_id_idx on public.nutrition_items(meal_id);
create index if not exists nutrition_items_food_item_id_idx on public.nutrition_items(food_item_id);

-- ========================================
-- NUTRITION COMMENTS TABLE
-- ========================================
-- Create nutrition_comments table if it doesn't exist
create table if not exists public.nutrition_comments (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.nutrition_plans(id) on delete cascade,
  meal_id uuid,
  day_id uuid,
  commenter_id uuid not null references auth.users(id) on delete cascade,
  comment_text text not null,
  comment_type text default 'general' check (comment_type in ('general', 'feedback', 'question')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes for nutrition_comments
create index if not exists idx_nutrition_comments_plan_id on public.nutrition_comments(plan_id);
create index if not exists idx_nutrition_comments_commenter_id on public.nutrition_comments(commenter_id);
create index if not exists idx_nutrition_comments_created_at on public.nutrition_comments(created_at desc);

-- Enable RLS on nutrition_comments
alter table public.nutrition_comments enable row level security;

-- RLS policies for nutrition_comments
do $$
begin
  -- Users can read comments on plans they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_comments_read_own') then
    create policy nutrition_comments_read_own on public.nutrition_comments
      for select to authenticated
      using (
        exists (
          select 1 from public.nutrition_plans np
          where np.id = nutrition_comments.plan_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      );
  end if;

  -- Users can insert comments on plans they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_comments_insert_own') then
    create policy nutrition_comments_insert_own on public.nutrition_comments
      for insert to authenticated
      with check (
        commenter_id = auth.uid()
        and exists (
          select 1 from public.nutrition_plans np
          where np.id = nutrition_comments.plan_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      );
  end if;

  -- Users can update their own comments
  if not exists (select 1 from pg_policies where policyname = 'nutrition_comments_update_own') then
    create policy nutrition_comments_update_own on public.nutrition_comments
      for update to authenticated
      using (commenter_id = auth.uid())
      with check (commenter_id = auth.uid());
  end if;

  -- Users can delete their own comments
  if not exists (select 1 from pg_policies where policyname = 'nutrition_comments_delete_own') then
    create policy nutrition_comments_delete_own on public.nutrition_comments
      for delete to authenticated
      using (commenter_id = auth.uid());
  end if;
end $$;

-- Note: nutrition_comments table already exists, adding missing columns
-- First add columns without foreign keys, then add constraints later
alter table public.nutrition_comments 
add column if not exists meal_id uuid,
add column if not exists day_id uuid,
add column if not exists commenter_id uuid,
add column if not exists comment_text text,
add column if not exists comment_type text,
add column if not exists updated_at timestamptz default now();

-- Add foreign key constraints after tables are created
-- (These will be added later in the migration after nutrition_meals and nutrition_days are created)

-- Indexes for nutrition_comments
create index if not exists nutrition_comments_plan_id_idx on public.nutrition_comments(plan_id);
create index if not exists nutrition_comments_meal_id_idx on public.nutrition_comments(meal_id);
create index if not exists nutrition_comments_day_id_idx on public.nutrition_comments(day_id);
create index if not exists nutrition_comments_commenter_id_idx on public.nutrition_comments(commenter_id);

-- ========================================
-- NUTRITION ATTACHMENTS TABLE
-- ========================================
create table if not exists public.nutrition_attachments (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.nutrition_plans(id) on delete cascade,
  meal_id uuid references public.nutrition_meals(id) on delete cascade,
  day_id uuid references public.nutrition_days(id) on delete cascade,
  file_name text not null,
  file_path text not null,
  file_size_bytes bigint,
  mime_type text,
  uploaded_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

-- Indexes for nutrition_attachments
create index if not exists nutrition_attachments_plan_id_idx on public.nutrition_attachments(plan_id);
create index if not exists nutrition_attachments_meal_id_idx on public.nutrition_attachments(meal_id);
create index if not exists nutrition_attachments_day_id_idx on public.nutrition_attachments(day_id);

-- ========================================
-- NUTRITION RECIPES TABLE
-- ========================================
create table if not exists public.nutrition_recipes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  servings integer not null default 1,
  prep_time_minutes integer default 0,
  cook_time_minutes integer default 0,
  total_time_minutes integer default 0,
  difficulty text check (difficulty in ('easy', 'medium', 'hard')),
  cuisine_type text,
  dietary_tags text[] default '{}',
  allergen_tags text[] default '{}',
  photo_url text,
  created_by uuid not null references auth.users(id) on delete cascade,
  is_public boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes for nutrition_recipes
create index if not exists nutrition_recipes_created_by_idx on public.nutrition_recipes(created_by);
create index if not exists nutrition_recipes_is_public_idx on public.nutrition_recipes(is_public);
create index if not exists nutrition_recipes_dietary_tags_gin on public.nutrition_recipes using gin (dietary_tags);
create index if not exists nutrition_recipes_allergen_tags_gin on public.nutrition_recipes using gin (allergen_tags);

-- ========================================
-- NUTRITION RECIPE STEPS TABLE
-- ========================================
create table if not exists public.nutrition_recipe_steps (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.nutrition_recipes(id) on delete cascade,
  step_number integer not null,
  instruction text not null,
  photo_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(recipe_id, step_number)
);

-- Indexes for nutrition_recipe_steps
create index if not exists nutrition_recipe_steps_recipe_id_idx on public.nutrition_recipe_steps(recipe_id);

-- ========================================
-- NUTRITION RECIPE INGREDIENTS TABLE
-- ========================================
create table if not exists public.nutrition_recipe_ingredients (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.nutrition_recipes(id) on delete cascade,
  food_item_id uuid references public.food_items(id) on delete set null,
  name text not null,
  amount_grams numeric(10,2) not null default 0.0,
  unit text,
  order_index integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes for nutrition_recipe_ingredients
create index if not exists nutrition_recipe_ingredients_recipe_id_idx on public.nutrition_recipe_ingredients(recipe_id);
create index if not exists nutrition_recipe_ingredients_food_item_id_idx on public.nutrition_recipe_ingredients(food_item_id);

-- ========================================
-- NUTRITION GROCERY LISTS TABLE
-- ========================================
create table if not exists public.nutrition_grocery_lists (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.nutrition_plans(id) on delete cascade,
  name text not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes for nutrition_grocery_lists
create index if not exists nutrition_grocery_lists_plan_id_idx on public.nutrition_grocery_lists(plan_id);
create index if not exists nutrition_grocery_lists_created_by_idx on public.nutrition_grocery_lists(created_by);

-- ========================================
-- NUTRITION GROCERY ITEMS TABLE
-- ========================================
create table if not exists public.nutrition_grocery_items (
  id uuid primary key default gen_random_uuid(),
  grocery_list_id uuid not null references public.nutrition_grocery_lists(id) on delete cascade,
  name text not null,
  amount numeric(10,2) not null default 0.0,
  unit text not null,
  category text,
  aisle text,
  is_purchased boolean default false,
  order_index integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes for nutrition_grocery_items
create index if not exists nutrition_grocery_items_grocery_list_id_idx on public.nutrition_grocery_items(grocery_list_id);
create index if not exists nutrition_grocery_items_category_idx on public.nutrition_grocery_items(category);

-- ========================================
-- NUTRITION PREFERENCES TABLE
-- ========================================
create table if not exists public.nutrition_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  dietary_restrictions text[] default '{}',
  allergies text[] default '{}',
  preferred_cuisines text[] default '{}',
  disliked_foods text[] default '{}',
  target_calories integer,
  target_protein_g numeric(10,2),
  target_carbs_g numeric(10,2),
  target_fat_g numeric(10,2),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id)
);

-- Indexes for nutrition_preferences
create index if not exists nutrition_preferences_user_id_idx on public.nutrition_preferences(user_id);
create index if not exists nutrition_preferences_dietary_restrictions_gin on public.nutrition_preferences using gin (dietary_restrictions);
create index if not exists nutrition_preferences_allergies_gin on public.nutrition_preferences using gin (allergies);

-- ========================================
-- NUTRITION ALLERGIES TABLE
-- ========================================
create table if not exists public.nutrition_allergies (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  allergen_name text not null,
  severity text not null check (severity in ('mild', 'moderate', 'severe')),
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes for nutrition_allergies
create index if not exists nutrition_allergies_user_id_idx on public.nutrition_allergies(user_id);
create index if not exists nutrition_allergies_allergen_name_idx on public.nutrition_allergies(allergen_name);

-- ========================================
-- NUTRITION VERSIONS TABLE
-- ========================================
create table if not exists public.nutrition_versions (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.nutrition_plans(id) on delete cascade,
  version_number integer not null,
  plan_data jsonb not null,
  change_summary text,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  unique(plan_id, version_number)
);

-- Indexes for nutrition_versions
create index if not exists nutrition_versions_plan_id_idx on public.nutrition_versions(plan_id);
create index if not exists nutrition_versions_created_at_idx on public.nutrition_versions(created_at desc);

-- ========================================
-- ROW LEVEL SECURITY POLICIES
-- ========================================

-- Enable RLS on all tables
alter table public.nutrition_plans enable row level security;
alter table public.nutrition_days enable row level security;
alter table public.nutrition_meals enable row level security;
alter table public.nutrition_items enable row level security;
alter table public.nutrition_comments enable row level security;
alter table public.nutrition_attachments enable row level security;
alter table public.nutrition_recipes enable row level security;
alter table public.nutrition_recipe_steps enable row level security;
alter table public.nutrition_recipe_ingredients enable row level security;
alter table public.nutrition_grocery_lists enable row level security;
alter table public.nutrition_grocery_items enable row level security;
alter table public.nutrition_preferences enable row level security;
alter table public.nutrition_allergies enable row level security;
alter table public.nutrition_versions enable row level security;

-- ========================================
-- NUTRITION PLANS POLICIES
-- ========================================
do $$
begin
  -- Clients can read their own plans
  if not exists (select 1 from pg_policies where policyname = 'nutrition_plans_read_client') then
    create policy nutrition_plans_read_client on public.nutrition_plans
      for select to authenticated
      using (nutrition_plans.client_id = auth.uid());
  end if;

  -- Coaches can read plans for their clients
  if not exists (select 1 from pg_policies where policyname = 'nutrition_plans_read_coach') then
    create policy nutrition_plans_read_coach on public.nutrition_plans
      for select to authenticated
      using (nutrition_plans.created_by = auth.uid());
  end if;

  -- Coaches can create plans for their clients
  if not exists (select 1 from pg_policies where policyname = 'nutrition_plans_insert_coach') then
    create policy nutrition_plans_insert_coach on public.nutrition_plans
      for insert to authenticated
      with check (nutrition_plans.created_by = auth.uid());
  end if;

  -- Coaches can update plans they created
  if not exists (select 1 from pg_policies where policyname = 'nutrition_plans_update_coach') then
    create policy nutrition_plans_update_coach on public.nutrition_plans
      for update to authenticated
      using (nutrition_plans.created_by = auth.uid())
      with check (nutrition_plans.created_by = auth.uid());
  end if;

  -- Coaches can delete plans they created
  if not exists (select 1 from pg_policies where policyname = 'nutrition_plans_delete_coach') then
    create policy nutrition_plans_delete_coach on public.nutrition_plans
      for delete to authenticated
      using (nutrition_plans.created_by = auth.uid());
  end if;
end $$;

-- ========================================
-- NUTRITION DAYS POLICIES
-- ========================================
do $$
begin
  -- Users can read days for plans they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_days_read') then
    create policy nutrition_days_read on public.nutrition_days
      for select to authenticated
      using (
        exists (
          select 1 from public.nutrition_plans np
          where np.id = nutrition_days.plan_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      );
  end if;

  -- Coaches can manage days for plans they created
  if not exists (select 1 from pg_policies where policyname = 'nutrition_days_manage_coach') then
    create policy nutrition_days_manage_coach on public.nutrition_days
      for all to authenticated
      using (
        exists (
          select 1 from public.nutrition_plans np
          where np.id = nutrition_days.plan_id
          and np.created_by = auth.uid()
        )
      )
      with check (
        exists (
          select 1 from public.nutrition_plans np
          where np.id = nutrition_days.plan_id
          and np.created_by = auth.uid()
        )
      );
  end if;
end $$;

-- ========================================
-- NUTRITION MEALS POLICIES
-- ========================================
do $$
begin
  -- Users can read meals for days they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_meals_read') then
    create policy nutrition_meals_read on public.nutrition_meals
      for select to authenticated
      using (
        exists (
          select 1 from public.nutrition_days nd
          join public.nutrition_plans np on np.id = nd.plan_id
          where nd.id = nutrition_meals.day_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      );
  end if;

  -- Coaches can manage meals for plans they created
  if not exists (select 1 from pg_policies where policyname = 'nutrition_meals_manage_coach') then
    create policy nutrition_meals_manage_coach on public.nutrition_meals
      for all to authenticated
      using (
        exists (
          select 1 from public.nutrition_days nd
          join public.nutrition_plans np on np.id = nd.plan_id
          where nd.id = nutrition_meals.day_id
          and np.created_by = auth.uid()
        )
      )
      with check (
        exists (
          select 1 from public.nutrition_days nd
          join public.nutrition_plans np on np.id = nd.plan_id
          where nd.id = nutrition_meals.day_id
          and np.created_by = auth.uid()
        )
      );
  end if;
end $$;

-- ========================================
-- NUTRITION ITEMS POLICIES
-- ========================================
do $$
begin
  -- Users can read items for meals they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_items_read') then
    create policy nutrition_items_read on public.nutrition_items
      for select to authenticated
      using (
        exists (
          select 1 from public.nutrition_meals nm
          join public.nutrition_days nd on nd.id = nm.day_id
          join public.nutrition_plans np on np.id = nd.plan_id
          where nm.id = nutrition_items.meal_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      );
  end if;

  -- Coaches can manage items for plans they created
  if not exists (select 1 from pg_policies where policyname = 'nutrition_items_manage_coach') then
    create policy nutrition_items_manage_coach on public.nutrition_items
      for all to authenticated
      using (
        exists (
          select 1 from public.nutrition_meals nm
          join public.nutrition_days nd on nd.id = nm.day_id
          join public.nutrition_plans np on np.id = nd.plan_id
          where nm.id = nutrition_items.meal_id
          and np.created_by = auth.uid()
        )
      )
      with check (
        exists (
          select 1 from public.nutrition_meals nm
          join public.nutrition_days nd on nd.id = nm.day_id
          join public.nutrition_plans np on np.id = nd.plan_id
          where nm.id = nutrition_items.meal_id
          and np.created_by = auth.uid()
        )
      );
  end if;
end $$;

-- ========================================
-- NUTRITION COMMENTS POLICIES
-- ========================================
do $$
begin
  -- Users can read comments for plans they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_comments_read') then
    create policy nutrition_comments_read on public.nutrition_comments
      for select to authenticated
      using (
        exists (
          select 1 from public.nutrition_plans np
          where np.id = nutrition_comments.plan_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      );
  end if;

  -- Users can insert comments for plans they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_comments_insert') then
    create policy nutrition_comments_insert on public.nutrition_comments
      for insert to authenticated
      with check (
        nutrition_comments.commenter_id = auth.uid()
        and exists (
          select 1 from public.nutrition_plans np
          where np.id = nutrition_comments.plan_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      );
  end if;

  -- Users can update their own comments
  if not exists (select 1 from pg_policies where policyname = 'nutrition_comments_update') then
    create policy nutrition_comments_update on public.nutrition_comments
      for update to authenticated
      using (nutrition_comments.commenter_id = auth.uid())
      with check (nutrition_comments.commenter_id = auth.uid());
  end if;

  -- Users can delete their own comments
  if not exists (select 1 from pg_policies where policyname = 'nutrition_comments_delete') then
    create policy nutrition_comments_delete on public.nutrition_comments
      for delete to authenticated
      using (nutrition_comments.commenter_id = auth.uid());
  end if;
end $$;

-- ========================================
-- NUTRITION ATTACHMENTS POLICIES
-- ========================================
do $$
begin
  -- Users can read attachments for plans they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_attachments_read') then
    create policy nutrition_attachments_read on public.nutrition_attachments
      for select to authenticated
      using (
        exists (
          select 1 from public.nutrition_plans np
          where np.id = nutrition_attachments.plan_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      );
  end if;

  -- Users can insert attachments for plans they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_attachments_insert') then
    create policy nutrition_attachments_insert on public.nutrition_attachments
      for insert to authenticated
      with check (
        nutrition_attachments.uploaded_by = auth.uid()
        and exists (
          select 1 from public.nutrition_plans np
          where np.id = nutrition_attachments.plan_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      );
  end if;

  -- Users can delete attachments they uploaded
  if not exists (select 1 from pg_policies where policyname = 'nutrition_attachments_delete') then
    create policy nutrition_attachments_delete on public.nutrition_attachments
      for delete to authenticated
      using (nutrition_attachments.uploaded_by = auth.uid());
  end if;
end $$;

-- ========================================
-- NUTRITION RECIPES POLICIES
-- ========================================
do $$
begin
  -- Users can read public recipes and their own recipes
  if not exists (select 1 from pg_policies where policyname = 'nutrition_recipes_read') then
    create policy nutrition_recipes_read on public.nutrition_recipes
      for select to authenticated
      using (nutrition_recipes.is_public = true or nutrition_recipes.created_by = auth.uid());
  end if;

  -- Users can create their own recipes
  if not exists (select 1 from pg_policies where policyname = 'nutrition_recipes_insert') then
    create policy nutrition_recipes_insert on public.nutrition_recipes
      for insert to authenticated
      with check (nutrition_recipes.created_by = auth.uid());
  end if;

  -- Users can update their own recipes
  if not exists (select 1 from pg_policies where policyname = 'nutrition_recipes_update') then
    create policy nutrition_recipes_update on public.nutrition_recipes
      for update to authenticated
      using (nutrition_recipes.created_by = auth.uid())
      with check (nutrition_recipes.created_by = auth.uid());
  end if;

  -- Users can delete their own recipes
  if not exists (select 1 from pg_policies where policyname = 'nutrition_recipes_delete') then
    create policy nutrition_recipes_delete on public.nutrition_recipes
      for delete to authenticated
      using (nutrition_recipes.created_by = auth.uid());
  end if;
end $$;

-- ========================================
-- NUTRITION RECIPE STEPS POLICIES
-- ========================================
do $$
begin
  -- Users can read steps for recipes they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_recipe_steps_read') then
    create policy nutrition_recipe_steps_read on public.nutrition_recipe_steps
      for select to authenticated
      using (
        exists (
          select 1 from public.nutrition_recipes nr
          where nr.id = nutrition_recipe_steps.recipe_id
          and (nr.is_public = true or nr.created_by = auth.uid())
        )
      );
  end if;

  -- Users can manage steps for their own recipes
  if not exists (select 1 from pg_policies where policyname = 'nutrition_recipe_steps_manage') then
    create policy nutrition_recipe_steps_manage on public.nutrition_recipe_steps
      for all to authenticated
      using (
        exists (
          select 1 from public.nutrition_recipes nr
          where nr.id = nutrition_recipe_steps.recipe_id
          and nr.created_by = auth.uid()
        )
      )
      with check (
        exists (
          select 1 from public.nutrition_recipes nr
          where nr.id = nutrition_recipe_steps.recipe_id
          and nr.created_by = auth.uid()
        )
      );
  end if;
end $$;

-- ========================================
-- NUTRITION RECIPE INGREDIENTS POLICIES
-- ========================================
do $$
begin
  -- Users can read ingredients for recipes they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_recipe_ingredients_read') then
    create policy nutrition_recipe_ingredients_read on public.nutrition_recipe_ingredients
      for select to authenticated
      using (
        exists (
          select 1 from public.nutrition_recipes nr
          where nr.id = nutrition_recipe_ingredients.recipe_id
          and (nr.is_public = true or nr.created_by = auth.uid())
        )
      );
  end if;

  -- Users can manage ingredients for their own recipes
  if not exists (select 1 from pg_policies where policyname = 'nutrition_recipe_ingredients_manage') then
    create policy nutrition_recipe_ingredients_manage on public.nutrition_recipe_ingredients
      for all to authenticated
      using (
        exists (
          select 1 from public.nutrition_recipes nr
          where nr.id = nutrition_recipe_ingredients.recipe_id
          and nr.created_by = auth.uid()
        )
      )
      with check (
        exists (
          select 1 from public.nutrition_recipes nr
          where nr.id = nutrition_recipe_ingredients.recipe_id
          and nr.created_by = auth.uid()
        )
      );
  end if;
end $$;

-- ========================================
-- NUTRITION GROCERY LISTS POLICIES
-- ========================================
do $$
begin
  -- Users can read grocery lists for plans they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_grocery_lists_read') then
    create policy nutrition_grocery_lists_read on public.nutrition_grocery_lists
      for select to authenticated
      using (
        exists (
          select 1 from public.nutrition_plans np
          where np.id = nutrition_grocery_lists.plan_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      );
  end if;

  -- Users can manage grocery lists for plans they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_grocery_lists_manage') then
    create policy nutrition_grocery_lists_manage on public.nutrition_grocery_lists
      for all to authenticated
      using (
        nutrition_grocery_lists.created_by = auth.uid()
        and exists (
          select 1 from public.nutrition_plans np
          where np.id = nutrition_grocery_lists.plan_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      )
      with check (
        nutrition_grocery_lists.created_by = auth.uid()
        and exists (
          select 1 from public.nutrition_plans np
          where np.id = nutrition_grocery_lists.plan_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      );
  end if;
end $$;

-- ========================================
-- NUTRITION GROCERY ITEMS POLICIES
-- ========================================
do $$
begin
  -- Users can read grocery items for lists they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_grocery_items_read') then
    create policy nutrition_grocery_items_read on public.nutrition_grocery_items
      for select to authenticated
      using (
        exists (
          select 1 from public.nutrition_grocery_lists ngl
          join public.nutrition_plans np on np.id = ngl.plan_id
          where ngl.id = nutrition_grocery_items.grocery_list_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      );
  end if;

  -- Users can manage grocery items for lists they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_grocery_items_manage') then
    create policy nutrition_grocery_items_manage on public.nutrition_grocery_items
      for all to authenticated
      using (
        exists (
          select 1 from public.nutrition_grocery_lists ngl
          join public.nutrition_plans np on np.id = ngl.plan_id
          where ngl.id = nutrition_grocery_items.grocery_list_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      )
      with check (
        exists (
          select 1 from public.nutrition_grocery_lists ngl
          join public.nutrition_plans np on np.id = ngl.plan_id
          where ngl.id = nutrition_grocery_items.grocery_list_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      );
  end if;
end $$;

-- ========================================
-- NUTRITION PREFERENCES POLICIES
-- ========================================
do $$
begin
  -- Users can read their own preferences
  if not exists (select 1 from pg_policies where policyname = 'nutrition_preferences_read') then
    create policy nutrition_preferences_read on public.nutrition_preferences
      for select to authenticated
      using (user_id = auth.uid());
  end if;

  -- Users can manage their own preferences
  if not exists (select 1 from pg_policies where policyname = 'nutrition_preferences_manage') then
    create policy nutrition_preferences_manage on public.nutrition_preferences
      for all to authenticated
      using (user_id = auth.uid())
      with check (user_id = auth.uid());
  end if;
end $$;

-- ========================================
-- NUTRITION ALLERGIES POLICIES
-- ========================================
do $$
begin
  -- Users can read their own allergies
  if not exists (select 1 from pg_policies where policyname = 'nutrition_allergies_read') then
    create policy nutrition_allergies_read on public.nutrition_allergies
      for select to authenticated
      using (user_id = auth.uid());
  end if;

  -- Users can manage their own allergies
  if not exists (select 1 from pg_policies where policyname = 'nutrition_allergies_manage') then
    create policy nutrition_allergies_manage on public.nutrition_allergies
      for all to authenticated
      using (user_id = auth.uid())
      with check (user_id = auth.uid());
  end if;
end $$;

-- ========================================
-- NUTRITION VERSIONS POLICIES
-- ========================================
do $$
begin
  -- Users can read versions for plans they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_versions_read') then
    create policy nutrition_versions_read on public.nutrition_versions
      for select to authenticated
      using (
        exists (
          select 1 from public.nutrition_plans np
          where np.id = nutrition_versions.plan_id
          and (np.client_id = auth.uid() or np.created_by = auth.uid())
        )
      );
  end if;

  -- Coaches can create versions for plans they created
  if not exists (select 1 from pg_policies where policyname = 'nutrition_versions_insert') then
    create policy nutrition_versions_insert on public.nutrition_versions
      for insert to authenticated
      with check (
        nutrition_versions.created_by = auth.uid()
        and exists (
          select 1 from public.nutrition_plans np
          where np.id = nutrition_versions.plan_id
          and np.created_by = auth.uid()
        )
      );
  end if;
end $$;

-- ========================================
-- STORAGE POLICIES FOR VAGUS-MEDIA BUCKET
-- ========================================

-- Create storage bucket if it doesn't exist
insert into storage.buckets (id, name, public)
values ('vagus-media', 'vagus-media', false)
on conflict (id) do nothing;

-- Storage policies for nutrition attachments
do $$
begin
  -- Users can read files for plans they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_storage_read') then
    create policy nutrition_storage_read on storage.objects
      for select to authenticated
      using (
        bucket_id = 'vagus-media'
        and (
          -- Check if file path contains nutrition plan ID they have access to
          exists (
            select 1 from public.nutrition_plans np
            where np.id::text = any(string_to_array(name, '/'))
            and (np.client_id = auth.uid() or np.created_by = auth.uid())
          )
        )
      );
  end if;

  -- Users can upload files for plans they have access to
  if not exists (select 1 from pg_policies where policyname = 'nutrition_storage_upload') then
    create policy nutrition_storage_upload on storage.objects
      for insert to authenticated
      with check (
        bucket_id = 'vagus-media'
        and (
          -- Check if file path contains nutrition plan ID they have access to
          exists (
            select 1 from public.nutrition_plans np
            where np.id::text = any(string_to_array(name, '/'))
            and (np.client_id = auth.uid() or np.created_by = auth.uid())
          )
        )
      );
  end if;

  -- Users can delete files they uploaded
  if not exists (select 1 from pg_policies where policyname = 'nutrition_storage_delete') then
    create policy nutrition_storage_delete on storage.objects
      for delete to authenticated
      using (
        bucket_id = 'vagus-media'
        and owner = auth.uid()
      );
  end if;
end $$;

-- ========================================
-- FUNCTIONS AND TRIGGERS
-- ========================================

-- Function to update updated_at timestamp
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Add updated_at triggers to relevant tables
do $$
begin
  -- nutrition_plans
  if not exists (select 1 from pg_trigger where tgname = 'nutrition_plans_updated_at') then
    create trigger nutrition_plans_updated_at
      before update on public.nutrition_plans
      for each row execute function update_updated_at_column();
  end if;

  -- nutrition_days
  if not exists (select 1 from pg_trigger where tgname = 'nutrition_days_updated_at') then
    create trigger nutrition_days_updated_at
      before update on public.nutrition_days
      for each row execute function update_updated_at_column();
  end if;

  -- nutrition_meals
  if not exists (select 1 from pg_trigger where tgname = 'nutrition_meals_updated_at') then
    create trigger nutrition_meals_updated_at
      before update on public.nutrition_meals
      for each row execute function update_updated_at_column();
  end if;

  -- nutrition_items
  if not exists (select 1 from pg_trigger where tgname = 'nutrition_items_updated_at') then
    create trigger nutrition_items_updated_at
      before update on public.nutrition_items
      for each row execute function update_updated_at_column();
  end if;

  -- nutrition_comments
  if not exists (select 1 from pg_trigger where tgname = 'nutrition_comments_updated_at') then
    create trigger nutrition_comments_updated_at
      before update on public.nutrition_comments
      for each row execute function update_updated_at_column();
  end if;

  -- nutrition_recipes
  if not exists (select 1 from pg_trigger where tgname = 'nutrition_recipes_updated_at') then
    create trigger nutrition_recipes_updated_at
      before update on public.nutrition_recipes
      for each row execute function update_updated_at_column();
  end if;

  -- nutrition_recipe_steps
  if not exists (select 1 from pg_trigger where tgname = 'nutrition_recipe_steps_updated_at') then
    create trigger nutrition_recipe_steps_updated_at
      before update on public.nutrition_recipe_steps
      for each row execute function update_updated_at_column();
  end if;

  -- nutrition_recipe_ingredients
  if not exists (select 1 from pg_trigger where tgname = 'nutrition_recipe_ingredients_updated_at') then
    create trigger nutrition_recipe_ingredients_updated_at
      before update on public.nutrition_recipe_ingredients
      for each row execute function update_updated_at_column();
  end if;

  -- nutrition_grocery_lists
  if not exists (select 1 from pg_trigger where tgname = 'nutrition_grocery_lists_updated_at') then
    create trigger nutrition_grocery_lists_updated_at
      before update on public.nutrition_grocery_lists
      for each row execute function update_updated_at_column();
  end if;

  -- nutrition_grocery_items
  if not exists (select 1 from pg_trigger where tgname = 'nutrition_grocery_items_updated_at') then
    create trigger nutrition_grocery_items_updated_at
      before update on public.nutrition_grocery_items
      for each row execute function update_updated_at_column();
  end if;

  -- nutrition_preferences
  if not exists (select 1 from pg_trigger where tgname = 'nutrition_preferences_updated_at') then
    create trigger nutrition_preferences_updated_at
      before update on public.nutrition_preferences
      for each row execute function update_updated_at_column();
  end if;

  -- nutrition_allergies
  if not exists (select 1 from pg_trigger where tgname = 'nutrition_allergies_updated_at') then
    create trigger nutrition_allergies_updated_at
      before update on public.nutrition_allergies
      for each row execute function update_updated_at_column();
  end if;
end $$;

-- ========================================
-- ADD FOREIGN KEY CONSTRAINTS TO EXISTING TABLES
-- ========================================

-- Add foreign key constraints to nutrition_comments table
do $$
begin
  -- Add meal_id foreign key constraint
  if not exists (
    select 1 from information_schema.table_constraints 
    where constraint_name = 'nutrition_comments_meal_id_fkey'
  ) then
    alter table public.nutrition_comments 
    add constraint nutrition_comments_meal_id_fkey 
    foreign key (meal_id) references public.nutrition_meals(id) on delete cascade;
  end if;

  -- Add day_id foreign key constraint
  if not exists (
    select 1 from information_schema.table_constraints 
    where constraint_name = 'nutrition_comments_day_id_fkey'
  ) then
    alter table public.nutrition_comments 
    add constraint nutrition_comments_day_id_fkey 
    foreign key (day_id) references public.nutrition_days(id) on delete cascade;
  end if;

  -- Add commenter_id foreign key constraint
  if not exists (
    select 1 from information_schema.table_constraints 
    where constraint_name = 'nutrition_comments_commenter_id_fkey'
  ) then
    alter table public.nutrition_comments 
    add constraint nutrition_comments_commenter_id_fkey 
    foreign key (commenter_id) references auth.users(id) on delete cascade;
  end if;
end $$;

-- ========================================
-- COMPLETION MESSAGE
-- ========================================
select 'Nutrition vNext migration completed successfully' as status;
