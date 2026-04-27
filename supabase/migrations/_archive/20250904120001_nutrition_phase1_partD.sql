-- Nutrition Phase 1 Part D - Smart Grocery Lists Migration (Fixed)
-- Creates grocery lists and items tables with proper RLS and indexes
-- Idempotent migration with IF NOT EXISTS guards

-- ========================================
-- GROCERY LISTS TABLE
-- ========================================
create table if not exists public.nutrition_grocery_lists (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null,                -- client user_id
  coach_id uuid,                      -- optional coach who generated
  plan_id uuid not null,
  week_index int not null,            -- week # in plan
  created_at timestamptz not null default now()
);

-- Add missing columns if table already exists without them
-- This handles the case where the table was created in a previous migration
-- but doesn't have all the required columns yet
-- NOTE: The default values are temporary placeholders for existing rows
-- You should update these with real values after the migration completes
alter table public.nutrition_grocery_lists 
add column if not exists owner uuid not null default gen_random_uuid(),
add column if not exists coach_id uuid,
add column if not exists plan_id uuid not null default gen_random_uuid(),
add column if not exists week_index int not null default 0,
add column if not exists created_at timestamptz not null default now();

-- ========================================
-- GROCERY ITEMS TABLE
-- ========================================
create table if not exists public.nutrition_grocery_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references public.nutrition_grocery_lists(id) on delete cascade,
  name text not null,
  amount numeric,                     -- normalized base units
  unit text,                          -- 'g','kg','ml','l','pcs', etc.
  aisle text,                         -- 'produce','meat','dairy','bakery','frozen','canned','grains','spices','beverages','snacks','other'
  notes text,
  is_checked boolean not null default false,
  allergen text                       -- allergen information for filtering
);

-- Add missing columns if table already exists without them
-- This handles the case where the table was created in a previous migration
-- but doesn't have all the required columns yet
-- NOTE: The default values are temporary placeholders for existing rows
-- You should update these with real values after the migration completes
alter table public.nutrition_grocery_items 
add column if not exists list_id uuid not null default gen_random_uuid(),
add column if not exists name text not null default '',
add column if not exists amount numeric,
add column if not exists unit text,
add column if not exists aisle text,
add column if not exists notes text,
add column if not exists is_checked boolean not null default false,
add column if not exists allergen text;

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================
-- Index for plan/week lookups
create index if not exists idx_grocery_lists_plan_week on public.nutrition_grocery_lists (plan_id, week_index);

-- Index for owner lookups
create index if not exists idx_grocery_lists_owner on public.nutrition_grocery_lists (owner);

-- Index for coach lookups
create index if not exists idx_grocery_lists_coach on public.nutrition_grocery_lists (coach_id);

-- Index for grocery items by list
create index if not exists idx_grocery_items_list on public.nutrition_grocery_items (list_id);

-- Index for aisle grouping
create index if not exists idx_grocery_items_aisle on public.nutrition_grocery_items (aisle);

-- Index for allergen filtering
create index if not exists idx_grocery_items_allergen on public.nutrition_grocery_items (allergen);

-- ========================================
-- ROW LEVEL SECURITY POLICIES
-- ========================================

-- Enable RLS on both tables
alter table public.nutrition_grocery_lists enable row level security;
alter table public.nutrition_grocery_items enable row level security;

-- Grocery Lists RLS Policies
do $$
begin
  -- Drop existing policies to recreate
  drop policy if exists nutrition_grocery_lists_read on public.nutrition_grocery_lists;
  drop policy if exists nutrition_grocery_lists_write on public.nutrition_grocery_lists;

  -- Read policy: users can read their own lists, coaches can read their clients' lists
  create policy nutrition_grocery_lists_read on public.nutrition_grocery_lists
    for select to authenticated
    using (
      owner = auth.uid() or 
      coach_id = auth.uid() or
      exists (
        select 1 from public.nutrition_plans np
        where np.id = plan_id
        and (np.created_by = auth.uid() or np.client_id = auth.uid())
      )
    );

  -- Write policy: users can manage their own lists, coaches can manage their clients' lists
  create policy nutrition_grocery_lists_write on public.nutrition_grocery_lists
    for all to authenticated
    using (
      owner = auth.uid() or 
      coach_id = auth.uid() or
      exists (
        select 1 from public.nutrition_plans np
        where np.id = plan_id
        and np.created_by = auth.uid()
      )
    )
    with check (
      owner = auth.uid() or 
      coach_id = auth.uid() or
      exists (
        select 1 from public.nutrition_plans np
        where np.id = plan_id
        and np.created_by = auth.uid()
      )
    );
end $$;

-- Grocery Items RLS Policies
do $$
begin
  -- Drop existing policies to recreate
  drop policy if exists nutrition_grocery_items_read on public.nutrition_grocery_items;
  drop policy if exists nutrition_grocery_items_write on public.nutrition_grocery_items;

  -- Read policy: users can read items for lists they have access to
  create policy nutrition_grocery_items_read on public.nutrition_grocery_items
    for select to authenticated
    using (
      exists (
        select 1 from public.nutrition_grocery_lists gl
        where gl.id = list_id
        and (
          gl.owner = auth.uid() or 
          gl.coach_id = auth.uid() or
          exists (
            select 1 from public.nutrition_plans np
            where np.id = gl.plan_id
            and (np.created_by = auth.uid() or np.client_id = auth.uid())
          )
        )
      )
    );

  -- Write policy: users can manage items for lists they have access to
  create policy nutrition_grocery_items_write on public.nutrition_grocery_items
    for all to authenticated
    using (
      exists (
        select 1 from public.nutrition_grocery_lists gl
        where gl.id = list_id
        and (
          gl.owner = auth.uid() or 
          gl.coach_id = auth.uid() or
          exists (
            select 1 from public.nutrition_plans np
            where np.id = gl.plan_id
            and np.created_by = auth.uid()
          )
        )
      )
    )
    with check (
      exists (
        select 1 from public.nutrition_grocery_lists gl
        where gl.id = list_id
        and (
          gl.owner = auth.uid() or 
          gl.coach_id = auth.uid() or
          exists (
            select 1 from public.nutrition_plans np
            where np.id = gl.plan_id
            and np.created_by = auth.uid()
          )
        )
      )
    );
end $$;

-- ========================================
-- FUNCTIONS FOR GROCERY LIST GENERATION
-- ========================================

-- Function to generate grocery list from nutrition plan week
create or replace function generate_grocery_list_for_week(
  plan_uuid uuid,
  week_number int,
  owner_uuid uuid,
  coach_uuid uuid default null
)
returns uuid as $$
declare
  grocery_list_id uuid;
  plan_exists boolean;
begin
  -- Check if plan exists and user has access
  select exists(
    select 1 from public.nutrition_plans 
    where id = plan_uuid 
    and (client_id = owner_uuid or created_by = coach_uuid)
  ) into plan_exists;
  
  if not plan_exists then
    raise exception 'Plan not found or access denied';
  end if;
  
  -- Create grocery list
  insert into public.nutrition_grocery_lists (owner, coach_id, plan_id, week_index)
  values (owner_uuid, coach_uuid, plan_uuid, week_number)
  returning id into grocery_list_id;
  
  return grocery_list_id;
end;
$$ language plpgsql;

-- Function to add grocery item with deduplication
create or replace function add_grocery_item_deduplicated(
  list_uuid uuid,
  item_name text,
  item_amount numeric,
  item_unit text,
  item_aisle text default 'other',
  item_notes text default null
)
returns uuid as $$
declare
  item_id uuid;
  existing_item record;
  normalized_name text;
begin
  -- Normalize item name for deduplication (lowercase, trim)
  normalized_name := lower(trim(item_name));
  
  -- Check for existing item with same normalized name and unit
  select * into existing_item
  from public.nutrition_grocery_items
  where list_id = list_uuid
  and lower(trim(name)) = normalized_name
  and unit = item_unit;
  
  if existing_item.id is not null then
    -- Update existing item by adding amounts
    update public.nutrition_grocery_items
    set amount = amount + item_amount,
        notes = case 
          when notes is null then item_notes
          when item_notes is null then notes
          else notes || '; ' || item_notes
        end
    where id = existing_item.id
    returning id into item_id;
  else
    -- Create new item
    insert into public.nutrition_grocery_items (list_id, name, amount, unit, aisle, notes)
    values (list_uuid, item_name, item_amount, item_unit, item_aisle, item_notes)
    returning id into item_id;
  end if;
  
  return item_id;
end;
$$ language plpgsql;

-- ========================================
-- VIEWS FOR EASIER QUERYING
-- ========================================

-- View to get grocery lists with plan and owner info
create or replace view nutrition_grocery_lists_with_info as
select 
  gl.*,
  np.name as plan_name,
  np.client_id,
  np.created_by as plan_created_by,
  p_owner.name as owner_name,
  p_coach.name as coach_name
from public.nutrition_grocery_lists gl
left join public.nutrition_plans np on np.id = gl.plan_id
left join public.profiles p_owner on p_owner.id = gl.owner
left join public.profiles p_coach on p_coach.id = gl.coach_id;

-- View to get grocery items with list info
-- Drop the view first to avoid column conflicts
drop view if exists nutrition_grocery_items_with_info;

create view nutrition_grocery_items_with_info as
select 
  gi.id,
  gi.list_id,
  gi.name,
  gi.amount,
  gi.unit,
  gi.aisle,
  gi.notes,
  gi.is_checked,
  gi.allergen,
  gl.owner,
  gl.coach_id,
  gl.plan_id,
  gl.week_index,
  gl.created_at as list_created_at
from public.nutrition_grocery_items gi
join public.nutrition_grocery_lists gl on gl.id = gi.list_id;

-- ========================================
-- POST-MIGRATION DATA CLEANUP
-- ========================================
-- IMPORTANT: After this migration completes, you should update any rows
-- that have placeholder values with real data. For example:
--
-- UPDATE public.nutrition_grocery_lists 
-- SET owner = '<real-user-uuid>', 
--     plan_id = '<real-plan-uuid>',
--     week_index = 1
-- WHERE owner = gen_random_uuid(); -- or use a more specific condition
--
-- UPDATE public.nutrition_grocery_items 
-- SET list_id = '<real-list-uuid>',
--     name = '<real-item-name>'
-- WHERE name = ''; -- or use a more specific condition

-- ========================================
-- COMPLETION MESSAGE
-- ========================================
select 'Nutrition Phase 1 Part D - Smart Grocery Lists migration completed successfully' as status;
