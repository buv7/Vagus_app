-- Investigate Security Advisor Warnings
-- This migration will help us understand what the 54 warnings are about

-- Let's check what types of warnings we might have
SELECT '=== INVESTIGATING POTENTIAL WARNING SOURCES ===' as section;

-- 1. Check for tables without RLS enabled
SELECT '=== TABLES WITHOUT RLS ===' as section;
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity = true THEN '✅ RLS enabled'
        ELSE '⚠️ RLS disabled'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename NOT LIKE 'pg_%'
AND tablename NOT LIKE 'sql_%'
ORDER BY tablename;

-- 2. Check for tables with RLS but no policies
SELECT '=== TABLES WITH RLS BUT NO POLICIES ===' as section;
WITH tables_with_rls AS (
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
    AND rowsecurity = true
),
tables_with_policies AS (
    SELECT DISTINCT tablename 
    FROM pg_policies 
    WHERE schemaname = 'public'
)
SELECT 
    t.tablename,
    CASE 
        WHEN p.tablename IS NULL THEN '⚠️ RLS enabled but no policies'
        ELSE '✅ Has policies'
    END as policy_status
FROM tables_with_rls t
LEFT JOIN tables_with_policies p ON t.tablename = p.tablename
ORDER BY t.tablename;

-- 3. Check for functions without SECURITY DEFINER (might be warnings about missing it)
SELECT '=== FUNCTIONS SECURITY STATUS ===' as section;
SELECT 
    routine_name,
    routine_type,
    CASE 
        WHEN routine_definition ILIKE '%security definer%' THEN 'Has SECURITY DEFINER'
        ELSE 'No SECURITY DEFINER'
    END as security_status
FROM information_schema.routines 
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- 4. Check for missing indexes on foreign keys
SELECT '=== FOREIGN KEY INDEXES ===' as section;
SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    CASE 
        WHEN i.indexname IS NOT NULL THEN '✅ Has index'
        ELSE '⚠️ Missing index'
    END as index_status
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
LEFT JOIN pg_indexes i ON i.tablename = tc.table_name 
    AND i.indexdef LIKE '%' || kcu.column_name || '%'
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- 5. Check for tables without primary keys
SELECT '=== TABLES WITHOUT PRIMARY KEYS ===' as section;
SELECT 
    t.table_name,
    CASE 
        WHEN pk.column_name IS NOT NULL THEN '✅ Has primary key'
        ELSE '⚠️ Missing primary key'
    END as pk_status
FROM information_schema.tables t
LEFT JOIN (
    SELECT ku.table_name, ku.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage ku
        ON tc.constraint_name = ku.constraint_name
        AND tc.table_schema = ku.table_schema
    WHERE tc.constraint_type = 'PRIMARY KEY'
        AND tc.table_schema = 'public'
) pk ON t.table_name = pk.table_name
WHERE t.table_schema = 'public'
    AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name;

-- 6. Check for unused indexes (simplified)
SELECT '=== INDEX USAGE ANALYSIS ===' as section;
SELECT 
    schemaname,
    relname as tablename,
    indexrelname as indexname,
    idx_tup_read,
    idx_tup_fetch,
    CASE 
        WHEN idx_tup_read = 0 THEN '⚠️ Unused index'
        ELSE '✅ Used index'
    END as usage_status
FROM pg_stat_user_indexes 
WHERE schemaname = 'public'
ORDER BY idx_tup_read ASC;

-- 7. Check for missing NOT NULL constraints on important columns
SELECT '=== MISSING NOT NULL CONSTRAINTS ===' as section;
SELECT 
    table_name,
    column_name,
    is_nullable,
    CASE 
        WHEN is_nullable = 'YES' AND column_name IN ('id', 'user_id', 'created_at', 'email') THEN '⚠️ Should be NOT NULL'
        ELSE '✅ OK'
    END as constraint_status
FROM information_schema.columns 
WHERE table_schema = 'public'
    AND is_nullable = 'YES'
    AND column_name IN ('id', 'user_id', 'created_at', 'email', 'name', 'title')
ORDER BY table_name, column_name;

SELECT '=== WARNING INVESTIGATION COMPLETE ===' as section;
