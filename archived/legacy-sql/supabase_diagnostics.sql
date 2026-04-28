-- Supabase Database Diagnostics
-- Run these queries in your Supabase SQL editor to help diagnose the issue

-- 1. Check if nutrition_meals table exists and its structure
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name LIKE 'nutrition_%'
ORDER BY table_name, ordinal_position;

-- 2. Check if any nutrition tables exist at all
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE 'nutrition_%'
ORDER BY table_name;

-- 3. Check if food_items table exists (this was causing issues earlier)
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name = 'food_items';

-- 4. Check for any existing foreign key constraints
SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_schema = 'public'
  AND tc.table_name LIKE 'nutrition_%'
ORDER BY tc.table_name;

-- 5. Check migration history (if available)
SELECT * FROM supabase_migrations.schema_migrations 
ORDER BY version DESC 
LIMIT 10;
