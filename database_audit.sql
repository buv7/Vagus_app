-- VAGUS App - Database Schema Audit Script
-- Run this against the live database to verify schema state
-- Connection: postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres

-- ============================================================
-- 1. CONNECTION TEST
-- ============================================================
SELECT version() as postgres_version;
SELECT current_database() as current_db;
SELECT current_user;
SELECT now() as audit_timestamp;

-- ============================================================
-- 2. TABLE INVENTORY
-- ============================================================

-- Count total tables
SELECT COUNT(*) as total_tables
FROM information_schema.tables
WHERE table_schema = 'public';

-- List all tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- ============================================================
-- 3. VERIFY CRITICAL TABLES EXIST
-- ============================================================

SELECT
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles')
    THEN '✅' ELSE '❌' END as profiles,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'nutrition_plans')
    THEN '✅' ELSE '❌' END as nutrition_plans,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'workout_plans')
    THEN '✅' ELSE '❌' END as workout_plans,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'ai_usage')
    THEN '✅' ELSE '❌' END as ai_usage,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_files')
    THEN '✅' ELSE '❌' END as user_files,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'client_metrics')
    THEN '✅' ELSE '❌' END as client_metrics,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'progress_photos')
    THEN '✅' ELSE '❌' END as progress_photos,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'checkins')
    THEN '✅' ELSE '❌' END as checkins,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'coach_notes')
    THEN '✅' ELSE '❌' END as coach_notes,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'messages')
    THEN '✅' ELSE '❌' END as messages,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'message_threads')
    THEN '✅' ELSE '❌' END as message_threads,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'calendar_events')
    THEN '✅' ELSE '❌' END as calendar_events;

-- ============================================================
-- 4. TABLE SCHEMAS FOR CRITICAL TABLES
-- ============================================================

-- Profiles table structure
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default,
  character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY ordinal_position;

-- Nutrition plans structure
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'nutrition_plans'
ORDER BY ordinal_position;

-- Workout plans structure
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'workout_plans'
ORDER BY ordinal_position;

-- AI usage structure
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'ai_usage'
ORDER BY ordinal_position;

-- ============================================================
-- 5. RLS (ROW LEVEL SECURITY) AUDIT
-- ============================================================

-- Tables with RLS enabled
SELECT
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Count tables with/without RLS
SELECT
  COUNT(*) FILTER (WHERE rowsecurity = true) as tables_with_rls,
  COUNT(*) FILTER (WHERE rowsecurity = false) as tables_without_rls,
  COUNT(*) as total_tables
FROM pg_tables
WHERE schemaname = 'public';

-- List tables WITHOUT RLS (security risk)
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = false
ORDER BY tablename;

-- Count RLS policies
SELECT
  tablename,
  COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY policy_count DESC;

-- Total policy count
SELECT COUNT(*) as total_policies
FROM pg_policies
WHERE schemaname = 'public';

-- ============================================================
-- 6. VIEWS AUDIT
-- ============================================================

-- List all views
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;

-- Count views
SELECT COUNT(*) as total_views
FROM information_schema.views
WHERE table_schema = 'public';

-- Check critical nutrition view
SELECT
  CASE WHEN EXISTS (
    SELECT FROM information_schema.views
    WHERE table_schema = 'public'
    AND table_name = 'nutrition_grocery_items_with_info'
  ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as nutrition_grocery_view_status;

-- ============================================================
-- 7. FUNCTIONS AUDIT
-- ============================================================

-- List all functions
SELECT
  routine_name,
  routine_type,
  data_type as return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- Count functions
SELECT COUNT(*) as total_functions
FROM information_schema.routines
WHERE routine_schema = 'public';

-- Check critical AI functions
SELECT
  CASE WHEN EXISTS (
    SELECT FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname = 'update_ai_usage_tokens'
  ) THEN '✅' ELSE '❌' END as update_ai_usage_tokens,
  CASE WHEN EXISTS (
    SELECT FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname = 'increment_ai_usage'
  ) THEN '✅' ELSE '❌' END as increment_ai_usage,
  CASE WHEN EXISTS (
    SELECT FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname = 'handle_new_user'
  ) THEN '✅' ELSE '❌' END as handle_new_user;

-- ============================================================
-- 8. WORKOUT V2 VERIFICATION
-- ============================================================

-- List workout-related tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE '%workout%'
ORDER BY table_name;

-- Check for workout v2 tables
SELECT
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'workout_plan_weeks')
    THEN '✅' ELSE '❌' END as workout_plan_weeks,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'workout_plan_days')
    THEN '✅' ELSE '❌' END as workout_plan_days,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'workout_plan_exercises')
    THEN '✅' ELSE '❌' END as workout_plan_exercises,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'workout_sessions')
    THEN '✅' ELSE '❌' END as workout_sessions,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'exercise_library')
    THEN '✅' ELSE '❌' END as exercise_library;

-- ============================================================
-- 9. NUTRITION V2 VERIFICATION
-- ============================================================

-- List nutrition-related tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE '%nutrition%'
ORDER BY table_name;

-- Check for nutrition v2 tables
SELECT
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'nutrition_recipes')
    THEN '✅' ELSE '❌' END as nutrition_recipes,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'nutrition_recipe_ingredients')
    THEN '✅' ELSE '❌' END as nutrition_recipe_ingredients,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'nutrition_barcodes')
    THEN '✅' ELSE '❌' END as nutrition_barcodes,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'nutrition_pantry_items')
    THEN '✅' ELSE '❌' END as nutrition_pantry_items,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'nutrition_supplements')
    THEN '✅' ELSE '❌' END as nutrition_supplements;

-- ============================================================
-- 10. FOREIGN KEY CONSTRAINTS
-- ============================================================

-- List all foreign keys
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name
LIMIT 50;

-- Count foreign keys
SELECT COUNT(*) as total_foreign_keys
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
  AND table_schema = 'public';

-- ============================================================
-- 11. INDEXES AUDIT
-- ============================================================

-- List all indexes (sample)
SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname
LIMIT 50;

-- Count indexes
SELECT COUNT(*) as total_indexes
FROM pg_indexes
WHERE schemaname = 'public';

-- ============================================================
-- 12. MIGRATION TRACKING
-- ============================================================

-- Check for migration tracking table
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (table_name LIKE '%migration%' OR table_name LIKE '%schema_version%')
ORDER BY table_name;

-- If supabase_migrations exists, show recent migrations
-- Uncomment if table exists:
-- SELECT * FROM supabase_migrations ORDER BY version DESC LIMIT 20;

-- ============================================================
-- 13. DATA INTEGRITY CHECK
-- ============================================================

-- Row counts for critical tables
SELECT
  schemaname,
  tablename,
  n_live_tup as row_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'profiles', 'nutrition_plans', 'workout_plans',
    'ai_usage', 'user_files', 'client_metrics',
    'progress_photos', 'checkins', 'coach_notes',
    'messages', 'message_threads'
  )
ORDER BY tablename;

-- Tables with zero rows (potential issues)
SELECT
  schemaname,
  tablename,
  n_live_tup as row_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
  AND n_live_tup = 0
ORDER BY tablename
LIMIT 20;

-- ============================================================
-- 14. SUMMARY REPORT
-- ============================================================

SELECT
  'AUDIT COMPLETE' as status,
  now() as completed_at;

-- End of audit script
