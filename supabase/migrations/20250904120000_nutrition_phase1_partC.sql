-- Nutrition Phase 1 Part C - Meal Builder Recipe Integration Migration
-- Extends nutrition_items table to support recipe integration
-- Idempotent migration with IF NOT EXISTS guards

-- ========================================
-- EXTEND NUTRITION ITEMS TABLE FOR RECIPES
-- ========================================
-- Add recipe integration fields to existing nutrition_items table
alter table public.nutrition_items 
add column if not exists recipe_id uuid references public.nutrition_recipes(id) on delete set null,
add column if not exists servings numeric(10,2) default 1.0;

-- ========================================
-- ADD INDEXES FOR PERFORMANCE
-- ========================================
-- Index for recipe lookups
create index if not exists nutrition_items_recipe_id_idx on public.nutrition_items(recipe_id);

-- Composite index for meal + recipe queries
create index if not exists nutrition_items_meal_recipe_idx on public.nutrition_items(meal_id, recipe_id);

-- ========================================
-- UPDATE ROW LEVEL SECURITY POLICIES
-- ========================================
-- Enhanced RLS policies for nutrition_items with recipe access
do $$
begin
  -- Drop existing policies to recreate with enhanced logic
  drop policy if exists nutrition_items_read on public.nutrition_items;
  drop policy if exists nutrition_items_manage_coach on public.nutrition_items;

  -- Enhanced read policy: users can read items for meals they have access to
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

  -- Enhanced manage policy: coaches can manage items for plans they created
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
end $$;

-- ========================================
-- FUNCTIONS FOR RECIPE NUTRITION CALCULATION
-- ========================================

-- Function to calculate nutrition for a recipe item with servings
create or replace function calculate_recipe_item_nutrition(
  recipe_uuid uuid,
  serving_count numeric
)
returns table (
  total_calories numeric,
  total_protein numeric,
  total_carbs numeric,
  total_fat numeric,
  total_sodium_mg numeric,
  total_potassium_mg numeric,
  total_micros jsonb
) as $$
declare
  base_servings numeric;
  recipe_nutrition record;
begin
  -- Get base serving size from recipe
  select serving_size into base_servings 
  from public.nutrition_recipes 
  where id = recipe_uuid;
  
  -- Calculate nutrition for the recipe
  select * into recipe_nutrition
  from calculate_recipe_nutrition(recipe_uuid);
  
  -- Scale by serving count
  return query
  select 
    (recipe_nutrition.total_calories * serving_count / base_servings) as total_calories,
    (recipe_nutrition.total_protein * serving_count / base_servings) as total_protein,
    (recipe_nutrition.total_carbs * serving_count / base_servings) as total_carbs,
    (recipe_nutrition.total_fat * serving_count / base_servings) as total_fat,
    (recipe_nutrition.total_sodium_mg * serving_count / base_servings) as total_sodium_mg,
    (recipe_nutrition.total_potassium_mg * serving_count / base_servings) as total_potassium_mg,
    (
      select jsonb_object_agg(
        key, 
        value::numeric * serving_count / base_servings
      )
      from jsonb_each(recipe_nutrition.total_micros)
    ) as total_micros;
end;
$$ language plpgsql;

-- Function to get similar recipes for quick swap
create or replace function find_similar_recipes(
  base_recipe_uuid uuid,
  max_results integer default 3
)
returns table (
  recipe_id uuid,
  title text,
  protein numeric,
  cuisine_tags text[],
  similarity_score numeric
) as $$
declare
  base_recipe record;
  protein_min numeric;
  protein_max numeric;
begin
  -- Get base recipe details
  select 
    protein,
    cuisine_tags
  into base_recipe
  from public.nutrition_recipes
  where id = base_recipe_uuid;
  
  -- Calculate protein range (±15%)
  protein_min := base_recipe.protein * 0.85;
  protein_max := base_recipe.protein * 1.15;
  
  -- Find similar recipes
  return query
  select 
    nr.id as recipe_id,
    nr.title,
    nr.protein,
    nr.cuisine_tags,
    -- Simple similarity score based on protein match and cuisine overlap
    (
      case 
        when nr.cuisine_tags && base_recipe.cuisine_tags then 0.7
        else 0.3
      end
    ) as similarity_score
  from public.nutrition_recipes nr
  where nr.id != base_recipe_uuid
    and nr.visibility = 'public'
    and nr.protein between protein_min and protein_max
    and (
      nr.cuisine_tags && base_recipe.cuisine_tags
      or nr.cuisine_tags = '{}'
      or base_recipe.cuisine_tags = '{}'
    )
  order by similarity_score desc, nr.protein
  limit max_results;
end;
$$ language plpgsql;

-- ========================================
-- TRIGGERS FOR AUTOMATIC NUTRITION UPDATES
-- ========================================

-- Function to update nutrition item when recipe or servings change
create or replace function update_nutrition_item_from_recipe()
returns trigger as $$
declare
  recipe_nutrition record;
begin
  -- Only update if this is a recipe item
  if NEW.recipe_id is not null then
    -- Calculate nutrition for the recipe with current servings
    select * into recipe_nutrition
    from calculate_recipe_item_nutrition(NEW.recipe_id, NEW.servings);
    
    -- Update the nutrition values
    NEW.protein_g := recipe_nutrition.total_protein;
    NEW.carbs_g := recipe_nutrition.total_carbs;
    NEW.fat_g := recipe_nutrition.total_fat;
    NEW.kcal := recipe_nutrition.total_calories;
    NEW.sodium_mg := recipe_nutrition.total_sodium_mg;
    NEW.potassium_mg := recipe_nutrition.total_potassium_mg;
    
    -- Update the name to include recipe title if not already set
    if NEW.name is null or NEW.name = '' then
      select title into NEW.name
      from public.nutrition_recipes
      where id = NEW.recipe_id;
    end if;
  end if;
  
  return NEW;
end;
$$ language plpgsql;

-- Create trigger for automatic nutrition updates
drop trigger if exists update_nutrition_item_from_recipe_trigger on public.nutrition_items;

create trigger update_nutrition_item_from_recipe_trigger
  before insert or update on public.nutrition_items
  for each row execute function update_nutrition_item_from_recipe();

-- ========================================
-- VIEWS FOR EASIER QUERYING
-- ========================================

-- View to get nutrition items with recipe details
create or replace view nutrition_items_with_recipes as
select 
  ni.*,
  nr.title as recipe_title,
  nr.photo_url as recipe_photo_url,
  nr.prep_time_minutes,
  nr.cook_time_minutes,
  (nr.prep_time_minutes + nr.cook_time_minutes) as total_minutes,
  nr.dietary_tags as recipe_dietary_tags,
  nr.allergen_tags as recipe_allergen_tags,
  nr.allergen_tags as recipe_allergens
from public.nutrition_items ni
left join public.nutrition_recipes nr on nr.id = ni.recipe_id;

-- ========================================
-- COMPLETION MESSAGE
-- ========================================
select 'Nutrition Phase 1 Part C - Meal Builder Recipe Integration migration completed successfully' as status;
