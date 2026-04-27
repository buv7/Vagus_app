-- Regional Foods Catalog (idempotent)
create extension if not exists pgcrypto;
create extension if not exists pg_trgm;

create table if not exists public.food_items (
  id uuid primary key default gen_random_uuid(),
  name_en text not null,
  name_ar text,
  name_ku text,
  portion_grams numeric(10,2) default 100.0, -- default reference serving
  kcal numeric(10,2) not null,
  protein_g numeric(10,2) not null,
  carbs_g numeric(10,2) not null,
  fat_g numeric(10,2) not null,
  sodium_mg integer,
  potassium_mg integer,
  tags text[] default '{}',
  created_at timestamptz default now(),
  created_by uuid default auth.uid()
);

create index if not exists food_items_name_trgm on public.food_items using gin (name_en gin_trgm_ops);
create index if not exists food_items_tags_gin on public.food_items using gin (tags);

alter table public.food_items enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'food_items_read_all_auth') then
    create policy food_items_read_all_auth on public.food_items
      for select to authenticated
      using (true);
  end if;

  if not exists (select 1 from pg_policies where policyname = 'food_items_insert_own') then
    create policy food_items_insert_own on public.food_items
      for insert to authenticated
      with check (created_by = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'food_items_update_own') then
    create policy food_items_update_own on public.food_items
      for update to authenticated
      using (created_by = auth.uid())
      with check (created_by = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'food_items_delete_own') then
    create policy food_items_delete_own on public.food_items
      for delete to authenticated
      using (created_by = auth.uid());
  end if;
end $$;

-- Optional tiny seed for sanity (safe if repeated due to natural unique constraint absence)
insert into public.food_items (name_en, name_ar, name_ku, kcal, protein_g, carbs_g, fat_g, sodium_mg, potassium_mg, tags)
select * from (values
 ('Chicken Breast (grilled)', 'صدر دجاج مشوي', 'سەری مرۆک بریانکراو', 165, 31, 0, 3.6, 74, 256, array['protein','meat']),
 ('Rice (cooked, white)', 'رز أبيض مطبوخ', 'برنج سپی پێوە', 130, 2.4, 28, 0.3, 1, 35, array['carb','grain']),
 ('Dates (Medjool)', 'تمر', 'خۆرما', 277, 1.8, 75, 0.2, 1, 696, array['fruit','regional']),
 ('Kebab (beef, grilled)', 'كباب', 'کباب', 245, 20, 3, 17, 70, 290, array['protein','regional'])
) as t(name_en, name_ar, name_ku, kcal, protein_g, carbs_g, fat_g, sodium_mg, potassium_mg, tags)
where not exists (
  select 1 from public.food_items f where f.name_en = t.name_en
);

select 'food_items catalog ready' as status;
