-- ========================================
-- MCP SUPABASE TEST QUERIES
-- ========================================
-- Use these queries to test your MCP Supabase connection in Cursor IDE

-- ========================================
-- 1. BASIC CONNECTION TESTS
-- ========================================

-- Test basic connection
SELECT 'MCP Connection Test' as test_name, now() as current_time;

-- Check database version
SELECT version() as postgres_version;

-- Check current user and database
SELECT 
    current_user as connected_user,
    current_database() as database_name,
    current_schema() as current_schema;

-- ========================================
-- 2. TABLE STRUCTURE TESTS
-- ========================================

-- List all tables
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

-- Check profiles table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- ========================================
-- 3. USER STATISTICS TESTS
-- ========================================

-- User count by role
SELECT 
    COALESCE(role, 'NULL') as role,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM profiles 
GROUP BY role
ORDER BY user_count DESC;

-- Recent users
SELECT 
    id,
    email,
    name,
    role,
    created_at
FROM profiles 
ORDER BY created_at DESC 
LIMIT 10;

-- ========================================
-- 4. COACH-CLIENT RELATIONSHIP TESTS
-- ========================================

-- Check if user_coach_links table exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_coach_links' AND table_schema = 'public')
        THEN '✅ user_coach_links table exists'
        ELSE '❌ user_coach_links table missing'
    END as status;

-- Coach-client relationships (if table exists)
SELECT 
    cc.coach_id,
    p1.name as coach_name,
    cc.client_id,
    p2.name as client_name,
    cc.status,
    cc.created_at
FROM user_coach_links cc
JOIN profiles p1 ON cc.coach_id = p1.id
JOIN profiles p2 ON cc.client_id = p2.id
ORDER BY cc.created_at DESC
LIMIT 10;

-- ========================================
-- 5. AI USAGE TESTS
-- ========================================

-- Check if ai_usage table exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ai_usage' AND table_schema = 'public')
        THEN '✅ ai_usage table exists'
        ELSE '❌ ai_usage table missing'
    END as status;

-- AI usage statistics (if table exists)
SELECT 
    au.user_id,
    p.name as user_name,
    au.month,
    au.year,
    au.tokens_used,
    au.request_count,
    au.created_at
FROM ai_usage au
JOIN profiles p ON au.user_id = p.id
ORDER BY au.created_at DESC
LIMIT 10;

-- ========================================
-- 6. FILE MANAGEMENT TESTS
-- ========================================

-- Check if user_files table exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_files' AND table_schema = 'public')
        THEN '✅ user_files table exists'
        ELSE '❌ user_files table missing'
    END as status;

-- File statistics (if table exists)
SELECT 
    file_type,
    COUNT(*) as file_count,
    SUM(file_size) as total_size
FROM user_files
GROUP BY file_type
ORDER BY file_count DESC;

-- ========================================
-- 7. CALENDAR EVENTS TESTS
-- ========================================

-- Check if calendar_events table exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'calendar_events' AND table_schema = 'public')
        THEN '✅ calendar_events table exists'
        ELSE '❌ calendar_events table missing'
    END as status;

-- Recent calendar events (if table exists)
SELECT 
    id,
    title,
    start_at,
    end_at,
    created_by,
    status
FROM calendar_events
ORDER BY start_at DESC
LIMIT 10;

-- ========================================
-- 8. DATABASE HEALTH CHECKS
-- ========================================

-- Table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Active connections
SELECT 
    COUNT(*) as active_connections,
    COUNT(CASE WHEN state = 'active' THEN 1 END) as active_queries
FROM pg_stat_activity 
WHERE datname = current_database();

-- ========================================
-- 9. RLS POLICIES CHECK
-- ========================================

-- Check RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ========================================
-- 10. PERFORMANCE MONITORING
-- ========================================

-- Index usage statistics
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch,
    idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_tup_read DESC
LIMIT 10;

-- Table access statistics
SELECT 
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_tup_ins,
    n_tup_upd,
    n_tup_del
FROM pg_stat_user_tables
ORDER BY seq_tup_read DESC
LIMIT 10;

-- ========================================
-- 11. SECURITY CHECKS
-- ========================================

-- Check for SECURITY DEFINER views
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public' 
AND definition ILIKE '%security definer%';

-- Check foreign key constraints
SELECT 
    tc.constraint_name,
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
ORDER BY tc.table_name, tc.constraint_name;

-- ========================================
-- 12. SUMMARY REPORT
-- ========================================

-- Generate a summary report
WITH table_count AS (
    SELECT COUNT(*) as total_tables
    FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
),
user_count AS (
    SELECT COUNT(*) as total_users
    FROM profiles
),
role_distribution AS (
    SELECT 
        role,
        COUNT(*) as count
    FROM profiles 
    GROUP BY role
)
SELECT 
    'Database Summary' as report_type,
    tc.total_tables as tables_count,
    uc.total_users as users_count,
    (SELECT string_agg(role || ': ' || count, ', ') FROM role_distribution) as role_distribution;
