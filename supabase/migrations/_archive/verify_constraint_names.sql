-- =====================================================
-- VERIFY CONSTRAINT NAMES
-- Run this script to find exact constraint names before migration
-- =====================================================

-- Find exercises_library.difficulty constraint
SELECT 
  conname AS constraint_name,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'exercises_library'::regclass
  AND contype = 'c' -- CHECK constraint
  AND pg_get_constraintdef(oid) LIKE '%difficulty%';

-- Find exercise_groups.type constraint
SELECT 
  conname AS constraint_name,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'exercise_groups'::regclass
  AND contype = 'c' -- CHECK constraint
  AND pg_get_constraintdef(oid) LIKE '%type%';

-- Find workout_plans.goal constraint
SELECT 
  conname AS constraint_name,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'workout_plans'::regclass
  AND contype = 'c' -- CHECK constraint
  AND pg_get_constraintdef(oid) LIKE '%goal%';

-- Find workout_plans.status constraint (for reference)
SELECT 
  conname AS constraint_name,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'workout_plans'::regclass
  AND contype = 'c' -- CHECK constraint
  AND pg_get_constraintdef(oid) LIKE '%status%';

-- List ALL CHECK constraints on workout/exercise related tables (comprehensive)
SELECT 
  schemaname,
  tablename,
  conname AS constraint_name,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
JOIN pg_class ON pg_class.oid = conrelid
JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
WHERE schemaname = 'public'
  AND contype = 'c' -- CHECK constraint
  AND (
    tablename LIKE '%exercise%'
    OR tablename LIKE '%workout%'
    OR tablename LIKE '%plan%'
  )
ORDER BY tablename, conname;
