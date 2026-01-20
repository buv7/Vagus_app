-- =====================================================
-- VERIFY CONSTRAINT NAMES - PHASE 1 UNBLOCKING
-- Run this script to find exact constraint names before migration
-- 
-- Usage: Run against Supabase database to verify constraint names
-- =====================================================

-- =====================================================
-- TARGET CONSTRAINTS TO REMOVE
-- =====================================================

-- 1. exercises_library.difficulty CHECK constraint
SELECT 
  'exercises_library' AS table_name,
  conname AS constraint_name,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.exercises_library'::regclass
  AND contype = 'c' -- CHECK constraint
  AND pg_get_constraintdef(oid) LIKE '%difficulty%'
  AND pg_get_constraintdef(oid) LIKE '%IN%'
  AND (
    pg_get_constraintdef(oid) LIKE '%beginner%'
    OR pg_get_constraintdef(oid) LIKE '%intermediate%'
    OR pg_get_constraintdef(oid) LIKE '%advanced%'
  );

-- 2. exercise_groups.type CHECK constraint
SELECT 
  'exercise_groups' AS table_name,
  conname AS constraint_name,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.exercise_groups'::regclass
  AND contype = 'c' -- CHECK constraint
  AND pg_get_constraintdef(oid) LIKE '%type%'
  AND pg_get_constraintdef(oid) LIKE '%IN%'
  AND (
    pg_get_constraintdef(oid) LIKE '%superset%'
    OR pg_get_constraintdef(oid) LIKE '%circuit%'
  );

-- 3. workout_plans.goal CHECK constraint
SELECT 
  'workout_plans' AS table_name,
  conname AS constraint_name,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.workout_plans'::regclass
  AND contype = 'c' -- CHECK constraint
  AND pg_get_constraintdef(oid) LIKE '%goal%'
  AND pg_get_constraintdef(oid) LIKE '%IN%'
  AND (
    pg_get_constraintdef(oid) LIKE '%strength%'
    OR pg_get_constraintdef(oid) LIKE '%hypertrophy%'
  );

-- =====================================================
-- COMPREHENSIVE CHECK: All CHECK constraints on target tables
-- =====================================================

SELECT 
  n.nspname AS schema_name,
  c.relname AS table_name,
  con.conname AS constraint_name,
  pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
JOIN pg_class c ON c.oid = con.conrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND con.contype = 'c' -- CHECK constraint
  AND c.relname IN ('exercises_library', 'exercise_groups', 'workout_plans')
ORDER BY c.relname, con.conname;
