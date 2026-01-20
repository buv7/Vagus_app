-- Migration: Verify Exercise Knowledge Base State
-- Date: 2025-01-22
-- Purpose: Diagnostic script to verify exercise_knowledge table state
-- This is a verification-only migration (no data changes)

-- =====================================================
-- STEP 1: Verify table exists
-- =====================================================
DO $$
DECLARE
  table_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'exercise_knowledge'
  ) INTO table_exists;
  
  IF table_exists THEN
    RAISE NOTICE '✅ STEP 1: exercise_knowledge table EXISTS';
  ELSE
    RAISE NOTICE '❌ STEP 1: exercise_knowledge table DOES NOT EXIST';
    RAISE EXCEPTION 'exercise_knowledge table is missing. Run migration 20251221021539_workout_knowledge_base.sql first.';
  END IF;
END $$;

-- =====================================================
-- STEP 2: Count total exercises
-- =====================================================
DO $$
DECLARE
  total_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_count
  FROM public.exercise_knowledge;
  
  RAISE NOTICE '📊 STEP 2: Total exercises in knowledge base: %', total_count;
  
  IF total_count = 0 THEN
    RAISE NOTICE '⚠️  WARNING: Table is EMPTY. Seeding required.';
  ELSIF total_count < 100 THEN
    RAISE NOTICE '⚠️  WARNING: Only % exercises found. Expected 1000+.', total_count;
  ELSE
    RAISE NOTICE '✅ Table has % exercises (acceptable).', total_count;
  END IF;
END $$;

-- =====================================================
-- STEP 3: Check status distribution
-- =====================================================
DO $$
DECLARE
  approved_count INTEGER;
  pending_count INTEGER;
  draft_count INTEGER;
  rejected_count INTEGER;
  null_status_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO approved_count
  FROM public.exercise_knowledge
  WHERE status = 'approved';
  
  SELECT COUNT(*) INTO pending_count
  FROM public.exercise_knowledge
  WHERE status = 'pending';
  
  SELECT COUNT(*) INTO draft_count
  FROM public.exercise_knowledge
  WHERE status = 'draft';
  
  SELECT COUNT(*) INTO rejected_count
  FROM public.exercise_knowledge
  WHERE status = 'rejected';
  
  SELECT COUNT(*) INTO null_status_count
  FROM public.exercise_knowledge
  WHERE status IS NULL;
  
  RAISE NOTICE '📊 STEP 3: Status Distribution:';
  RAISE NOTICE '   - approved: %', approved_count;
  RAISE NOTICE '   - pending: %', pending_count;
  RAISE NOTICE '   - draft: %', draft_count;
  RAISE NOTICE '   - rejected: %', rejected_count;
  RAISE NOTICE '   - NULL: %', null_status_count;
  
  IF approved_count = 0 AND (pending_count > 0 OR draft_count > 0) THEN
    RAISE NOTICE '⚠️  WARNING: No approved exercises! UI will show 0 exercises.';
    RAISE NOTICE '   Consider updating status to "approved" for existing exercises.';
  END IF;
END $$;

-- =====================================================
-- STEP 4: Check unique index exists
-- =====================================================
DO $$
DECLARE
  index_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
    AND tablename = 'exercise_knowledge'
    AND indexname = 'idx_exercise_knowledge_unique_name_language'
  ) INTO index_exists;
  
  IF index_exists THEN
    RAISE NOTICE '✅ STEP 4: Unique index (name, language) EXISTS';
  ELSE
    RAISE NOTICE '⚠️  STEP 4: Unique index (name, language) MISSING';
    RAISE NOTICE '   Run migration 20251221122033_knowledge_seed_unique_indexes.sql';
  END IF;
END $$;

-- =====================================================
-- STEP 5: Check if exercises_library exists (for seeding)
-- =====================================================
DO $$
DECLARE
  library_exists BOOLEAN;
  library_count INTEGER;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'exercises_library'
  ) INTO library_exists;
  
  IF library_exists THEN
    SELECT COUNT(*) INTO library_count
    FROM public.exercises_library;
    
    RAISE NOTICE '✅ STEP 5: exercises_library table EXISTS with % exercises', library_count;
  ELSE
    RAISE NOTICE '⚠️  STEP 5: exercises_library table DOES NOT EXIST';
    RAISE NOTICE '   Seed migration will need to create exercises directly.';
  END IF;
END $$;

-- =====================================================
-- STEP 6: Sample approved exercises (if any)
-- =====================================================
DO $$
DECLARE
  sample_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO sample_count
  FROM public.exercise_knowledge
  WHERE status = 'approved'
  LIMIT 5;
  
  IF sample_count > 0 THEN
    RAISE NOTICE '✅ STEP 6: Sample approved exercises found';
  ELSE
    RAISE NOTICE '❌ STEP 6: No approved exercises found';
  END IF;
END $$;

-- =====================================================
-- Summary Report
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'VERIFICATION COMPLETE';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. If table is empty → Run comprehensive seed migration';
  RAISE NOTICE '2. If status is wrong → Update status to "approved"';
  RAISE NOTICE '3. If unique index missing → Run unique index migration';
  RAISE NOTICE '';
END $$;
