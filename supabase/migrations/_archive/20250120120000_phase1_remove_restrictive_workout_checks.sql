-- =====================================================
-- PHASE 1: Remove Restrictive CHECK Constraints
-- Allows unlimited expansion of difficulty, group types, and goals
-- 
-- Target Constraints:
-- 1. exercises_library.difficulty CHECK (IN ('beginner','intermediate','advanced'))
-- 2. exercise_groups.type CHECK (IN ('superset','triset','giant_set','circuit','drop_set'))
-- 3. workout_plans.goal CHECK (IN ('strength','hypertrophy','endurance','powerlifting','general_fitness','weight_loss'))
-- 
-- This migration is idempotent - safe to run multiple times
-- =====================================================

BEGIN;

-- =====================================================
-- 1. Remove exercises_library.difficulty CHECK constraint
-- =====================================================
DO $$
DECLARE
  constraint_name TEXT;
  constraint_def TEXT;
BEGIN
  -- Find the constraint by matching the definition pattern
  SELECT con.conname, pg_get_constraintdef(con.oid)
  INTO constraint_name, constraint_def
  FROM pg_constraint con
  JOIN pg_class c ON c.oid = con.conrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname = 'exercises_library'
    AND con.contype = 'c' -- CHECK constraint
    AND pg_get_constraintdef(con.oid) LIKE '%difficulty%'
    AND pg_get_constraintdef(con.oid) LIKE '%IN%'
    AND (
      pg_get_constraintdef(con.oid) LIKE '%beginner%'
      OR pg_get_constraintdef(con.oid) LIKE '%intermediate%'
      OR pg_get_constraintdef(con.oid) LIKE '%advanced%'
    )
  LIMIT 1;
  
  IF constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.exercises_library DROP CONSTRAINT IF EXISTS %I', constraint_name);
    RAISE NOTICE '✓ Dropped constraint: public.exercises_library.% (%)', constraint_name, constraint_def;
  ELSE
    RAISE NOTICE 'ℹ exercises_library.difficulty constraint not found (may already be removed)';
  END IF;
END $$;

-- =====================================================
-- 2. Remove exercise_groups.type CHECK constraint
-- =====================================================
DO $$
DECLARE
  constraint_name TEXT;
  constraint_def TEXT;
BEGIN
  -- Find the constraint by matching the definition pattern
  SELECT con.conname, pg_get_constraintdef(con.oid)
  INTO constraint_name, constraint_def
  FROM pg_constraint con
  JOIN pg_class c ON c.oid = con.conrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname = 'exercise_groups'
    AND con.contype = 'c' -- CHECK constraint
    AND pg_get_constraintdef(con.oid) LIKE '%type%'
    AND pg_get_constraintdef(con.oid) LIKE '%IN%'
    AND (
      pg_get_constraintdef(con.oid) LIKE '%superset%'
      OR pg_get_constraintdef(con.oid) LIKE '%circuit%'
      OR pg_get_constraintdef(con.oid) LIKE '%drop_set%'
    )
  LIMIT 1;
  
  IF constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.exercise_groups DROP CONSTRAINT IF EXISTS %I', constraint_name);
    RAISE NOTICE '✓ Dropped constraint: public.exercise_groups.% (%)', constraint_name, constraint_def;
  ELSE
    RAISE NOTICE 'ℹ exercise_groups.type constraint not found (may already be removed)';
  END IF;
END $$;

-- =====================================================
-- 3. Remove workout_plans.goal CHECK constraint
-- =====================================================
DO $$
DECLARE
  constraint_name TEXT;
  constraint_def TEXT;
BEGIN
  -- Find the constraint by matching the definition pattern
  SELECT con.conname, pg_get_constraintdef(con.oid)
  INTO constraint_name, constraint_def
  FROM pg_constraint con
  JOIN pg_class c ON c.oid = con.conrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname = 'workout_plans'
    AND con.contype = 'c' -- CHECK constraint
    AND pg_get_constraintdef(con.oid) LIKE '%goal%'
    AND pg_get_constraintdef(con.oid) LIKE '%IN%'
    AND (
      pg_get_constraintdef(con.oid) LIKE '%strength%'
      OR pg_get_constraintdef(con.oid) LIKE '%hypertrophy%'
      OR pg_get_constraintdef(con.oid) LIKE '%endurance%'
    )
  LIMIT 1;
  
  IF constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.workout_plans DROP CONSTRAINT IF EXISTS %I', constraint_name);
    RAISE NOTICE '✓ Dropped constraint: public.workout_plans.% (%)', constraint_name, constraint_def;
  ELSE
    RAISE NOTICE 'ℹ workout_plans.goal constraint not found (may already be removed)';
  END IF;
END $$;

-- =====================================================
-- Verification: List remaining CHECK constraints (for confirmation)
-- =====================================================
DO $$
DECLARE
  constraint_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO constraint_count
  FROM pg_constraint con
  JOIN pg_class c ON c.oid = con.conrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND con.contype = 'c'
    AND c.relname IN ('exercises_library', 'exercise_groups', 'workout_plans')
    AND (
      -- Count only the constraints we tried to remove (should be 0 now)
      (c.relname = 'exercises_library' AND pg_get_constraintdef(con.oid) LIKE '%difficulty%IN%')
      OR (c.relname = 'exercise_groups' AND pg_get_constraintdef(con.oid) LIKE '%type%IN%')
      OR (c.relname = 'workout_plans' AND pg_get_constraintdef(con.oid) LIKE '%goal%IN%')
    );
  
  IF constraint_count = 0 THEN
    RAISE NOTICE '✓ Verification: All target CHECK constraints have been removed';
  ELSE
    RAISE WARNING '⚠ Verification: % target constraint(s) still remain - please check manually', constraint_count;
  END IF;
END $$;

COMMIT;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- 
-- What was changed:
-- - Removed CHECK constraint on exercises_library.difficulty
-- - Removed CHECK constraint on exercise_groups.type  
-- - Removed CHECK constraint on workout_plans.goal
-- 
-- What was NOT changed:
-- - No columns modified
-- - No data modified
-- - No other constraints removed
-- - No tables created/modified
-- 
-- Backward Compatibility:
-- - All existing data remains valid
-- - Existing queries continue to work
-- - Can now insert values outside the old CHECK constraints
-- 
-- Next Steps:
-- - Phase 2: Update Dart enum parsing to be tolerant
-- - Phase 3: Make UI components dynamic
-- =====================================================
