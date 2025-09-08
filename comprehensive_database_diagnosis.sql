-- ========================================
-- COMPREHENSIVE SUPABASE DATABASE DIAGNOSIS
-- ========================================
-- This script will check your entire database for issues and provide fixes

-- ========================================
-- 1. BASIC CONNECTION AND VERSION CHECK
-- ========================================
SELECT '=== DATABASE CONNECTION INFO ===' as section;
SELECT 
    'Connection successful!' as status,
    version() as postgres_version,
    current_database() as database_name,
    current_user as connected_user,
    now() as connection_time;

-- ========================================
-- 2. CHECK ALL TABLES AND THEIR STRUCTURE
-- ========================================
SELECT '=== TABLE STRUCTURE ANALYSIS ===' as section;

-- List all tables in public schema
SELECT 'All tables in public schema:' as info;
SELECT 
    table_name,
    table_type,
    CASE 
        WHEN table_type = 'BASE TABLE' THEN 'Table'
        WHEN table_type = 'VIEW' THEN 'View'
        ELSE table_type
    END as object_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check for missing core tables
SELECT 'Missing core tables check:' as info;
WITH required_tables AS (
    SELECT unnest(ARRAY[
        'profiles', 'ai_usage', 'user_files', 'user_devices', 
        'nutrition_plans', 'workout_plans', 'calendar_events',
        'message_threads', 'checkins', 'user_coach_links'
    ]) as table_name
),
existing_tables AS (
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
)
SELECT 
    rt.table_name,
    CASE 
        WHEN et.table_name IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as status
FROM required_tables rt
LEFT JOIN existing_tables et ON rt.table_name = et.table_name
ORDER BY rt.table_name;

-- ========================================
-- 3. CHECK PROFILES TABLE ISSUES
-- ========================================
SELECT '=== PROFILES TABLE ANALYSIS ===' as section;

-- Check profiles table structure
SELECT 'Profiles table structure:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'profiles' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check current user roles distribution
SELECT 'Current role distribution:' as info;
SELECT 
    COALESCE(role, 'NULL') as role,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM public.profiles 
GROUP BY role
ORDER BY user_count DESC;

-- Check for users with NULL or invalid roles
SELECT 'Users with problematic roles:' as info;
SELECT 
    id,
    email,
    name,
    role,
    created_at,
    updated_at,
    CASE 
        WHEN role IS NULL THEN 'NULL role'
        WHEN role NOT IN ('client', 'coach', 'admin') THEN 'Invalid role: ' || role
        ELSE 'Valid role'
    END as issue_type
FROM public.profiles 
WHERE role IS NULL OR role NOT IN ('client', 'coach', 'admin')
ORDER BY created_at DESC;

-- ========================================
-- 4. CHECK COACH_CLIENTS ISSUES
-- ========================================
SELECT '=== COACH_CLIENTS ANALYSIS ===' as section;

-- Check if coach_clients exists and what type
SELECT 'coach_clients object info:' as info;
SELECT 
    table_name,
    table_type,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'coach_clients' 
  AND table_schema = 'public';

-- If it's a view, show its definition
SELECT 'coach_clients view definition:' as info;
SELECT 
    view_definition
FROM information_schema.views 
WHERE table_name = 'coach_clients' 
  AND table_schema = 'public';

-- Check if user_coach_links exists (the underlying table)
SELECT 'user_coach_links table check:' as info;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_coach_links' AND table_schema = 'public')
        THEN '✅ user_coach_links table exists'
        ELSE '❌ user_coach_links table missing'
    END as status;

-- ========================================
-- 5. CHECK RLS (ROW LEVEL SECURITY) POLICIES
-- ========================================
SELECT '=== RLS POLICIES ANALYSIS ===' as section;

-- Check which tables have RLS enabled
SELECT 'Tables with RLS enabled:' as info;
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = true
ORDER BY tablename;

-- Check RLS policies
SELECT 'RLS policies summary:' as info;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    CASE 
        WHEN qual IS NOT NULL THEN 'Has USING clause'
        ELSE 'No USING clause'
    END as has_using_clause
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ========================================
-- 6. CHECK FOR SECURITY DEFINER VIEWS
-- ========================================
SELECT '=== SECURITY DEFINER VIEWS CHECK ===' as section;

-- Check for views with SECURITY DEFINER (security risk)
SELECT 'Views with SECURITY DEFINER:' as info;
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public' 
AND definition ILIKE '%security definer%';

-- ========================================
-- 7. CHECK FOREIGN KEY CONSTRAINTS
-- ========================================
SELECT '=== FOREIGN KEY CONSTRAINTS ===' as section;

-- Check all foreign key constraints
SELECT 'Foreign key constraints:' as info;
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    CASE 
        WHEN ccu.table_name IS NULL THEN '❌ BROKEN FK'
        ELSE '✅ Valid FK'
    END as status
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- ========================================
-- 8. CHECK FOR MISSING INDEXES
-- ========================================
SELECT '=== INDEX ANALYSIS ===' as section;

-- Check indexes on key tables
SELECT 'Indexes on key tables:' as info;
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename IN ('profiles', 'ai_usage', 'user_files', 'calendar_events', 'user_coach_links')
ORDER BY tablename, indexname;

-- ========================================
-- 9. CHECK DATA INTEGRITY ISSUES
-- ========================================
SELECT '=== DATA INTEGRITY CHECK ===' as section;

-- Check for orphaned records
SELECT 'Orphaned records check:' as info;

-- Check for profiles without corresponding auth.users
SELECT 'Profiles without auth.users:' as info;
SELECT COUNT(*) as orphaned_profiles
FROM public.profiles p
LEFT JOIN auth.users u ON p.id = u.id
WHERE u.id IS NULL;

-- Check for user_coach_links with invalid user IDs
SELECT 'Invalid user_coach_links:' as info;
SELECT COUNT(*) as invalid_links
FROM public.user_coach_links ucl
LEFT JOIN auth.users u1 ON ucl.coach_id = u1.id
LEFT JOIN auth.users u2 ON ucl.client_id = u2.id
WHERE u1.id IS NULL OR u2.id IS NULL;

-- ========================================
-- 10. CHECK FOR MISSING FUNCTIONS AND TRIGGERS
-- ========================================
SELECT '=== FUNCTIONS AND TRIGGERS ===' as section;

-- Check for important functions
SELECT 'Important functions check:' as info;
SELECT 
    routine_name,
    routine_type,
    CASE 
        WHEN routine_name IN ('assign_user_role', 'handle_new_user') THEN '✅ Important function exists'
        ELSE 'ℹ️ Function exists'
    END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('assign_user_role', 'handle_new_user', 'update_updated_at_column')
ORDER BY routine_name;

-- Check for triggers
SELECT 'Triggers on key tables:' as info;
SELECT 
    trigger_name,
    event_object_table,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('profiles', 'ai_usage', 'user_files')
ORDER BY event_object_table, trigger_name;

-- ========================================
-- 11. SUMMARY AND RECOMMENDATIONS
-- ========================================
SELECT '=== SUMMARY AND RECOMMENDATIONS ===' as section;

-- Generate summary report
WITH issues AS (
    SELECT 'Missing Tables' as issue_type, COUNT(*) as count
    FROM (
        SELECT unnest(ARRAY['profiles', 'ai_usage', 'user_files', 'user_devices', 'nutrition_plans', 'workout_plans', 'calendar_events', 'message_threads', 'checkins', 'user_coach_links']) as table_name
    ) required
    LEFT JOIN (
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    ) existing ON required.table_name = existing.table_name
    WHERE existing.table_name IS NULL
    
    UNION ALL
    
    SELECT 'Invalid Roles' as issue_type, COUNT(*) as count
    FROM public.profiles 
    WHERE role IS NULL OR role NOT IN ('client', 'coach', 'admin')
    
    UNION ALL
    
    SELECT 'Security Definer Views' as issue_type, COUNT(*) as count
    FROM pg_views 
    WHERE schemaname = 'public' AND definition ILIKE '%security definer%'
    
    UNION ALL
    
    SELECT 'Broken Foreign Keys' as issue_type, COUNT(*) as count
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    LEFT JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public'
        AND ccu.table_name IS NULL
)
SELECT 
    issue_type,
    count,
    CASE 
        WHEN count = 0 THEN '✅ No issues'
        WHEN count > 0 THEN '❌ Issues found'
    END as status
FROM issues
ORDER BY count DESC;

-- Final recommendations
SELECT 'RECOMMENDATIONS:' as info;
SELECT '1. Run complete_production_fix.sql to fix all structural issues' as recommendation;
SELECT '2. Run fix_user_roles.sql to fix role assignment issues' as recommendation;
SELECT '3. Run fix_supabase_security_issues.sql to fix security problems' as recommendation;
SELECT '4. Test all functionality after fixes are applied' as recommendation;

SELECT '=== DIAGNOSIS COMPLETE ===' as section;
