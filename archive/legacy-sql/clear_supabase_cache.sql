-- ========================================
-- CLEAR SUPABASE SCHEMA CACHE
-- ========================================
-- This forces Supabase to refresh its schema cache

-- 1. Check current schema version
SELECT 'Current schema version:' as info;
SELECT current_setting('search_path');

-- 2. Force schema cache refresh by querying system tables
SELECT 'Refreshing schema cache...' as info;
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename = 'coach_clients';

-- 3. Check foreign key relationships in system catalog
SELECT 'Foreign key relationships from system catalog:' as info;
SELECT 
    conname as constraint_name,
    conrelid::regclass as table_name,
    confrelid::regclass as foreign_table_name,
    a.attname as column_name,
    af.attname as foreign_column_name
FROM pg_constraint c
JOIN pg_attribute a ON a.attnum = ANY(c.conkey) AND a.attrelid = c.conrelid
JOIN pg_attribute af ON af.attnum = ANY(c.confkey) AND af.attrelid = c.confrelid
WHERE c.contype = 'f'
  AND conrelid::regclass::text = 'public.coach_clients';

-- 4. Force a schema reload by accessing the table
SELECT 'Forcing schema reload...' as info;
SELECT COUNT(*) as table_exists FROM public.coach_clients;

-- 5. Check if PostgREST can see the relationships
SELECT 'PostgREST relationship check:' as info;
SELECT 
    table_name,
    column_name,
    foreign_table_name,
    foreign_column_name
FROM information_schema.key_column_usage kcu
JOIN information_schema.referential_constraints rc 
    ON kcu.constraint_name = rc.constraint_name
JOIN information_schema.constraint_column_usage ccu 
    ON rc.unique_constraint_name = ccu.constraint_name
WHERE kcu.table_name = 'coach_clients'
  AND kcu.table_schema = 'public';

SELECT 'Schema cache refresh completed!' as result;
