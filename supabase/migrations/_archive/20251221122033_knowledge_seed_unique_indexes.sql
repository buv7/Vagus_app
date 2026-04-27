-- Migration: Add Unique Indexes for Knowledge Base Seed (Idempotent)
-- Date: 2025-12-21
-- Purpose: Enable ON CONFLICT upserts for idempotent seeding
--
-- Adds language-scoped unique indexes to prevent duplicate entries
-- when seeding from exercises_library and bulk inserting intensifiers

-- =====================================================
-- UNIQUE INDEX: exercise_knowledge (name, language)
-- =====================================================
DO $$
BEGIN
  -- Check if unique index already exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE schemaname = 'public' 
    AND tablename = 'exercise_knowledge' 
    AND indexname = 'idx_exercise_knowledge_unique_name_language'
  ) THEN
    CREATE UNIQUE INDEX idx_exercise_knowledge_unique_name_language
      ON public.exercise_knowledge (LOWER(name), language);
    
    RAISE NOTICE '✅ Created unique index: idx_exercise_knowledge_unique_name_language';
  ELSE
    RAISE NOTICE 'ℹ️  Index already exists: idx_exercise_knowledge_unique_name_language';
  END IF;
END $$;

-- =====================================================
-- UNIQUE INDEX: intensifier_knowledge (name, language)
-- =====================================================
DO $$
BEGIN
  -- Check if unique index already exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE schemaname = 'public' 
    AND tablename = 'intensifier_knowledge' 
    AND indexname = 'idx_intensifier_knowledge_unique_name_language'
  ) THEN
    CREATE UNIQUE INDEX idx_intensifier_knowledge_unique_name_language
      ON public.intensifier_knowledge (LOWER(name), language);
    
    RAISE NOTICE '✅ Created unique index: idx_intensifier_knowledge_unique_name_language';
  ELSE
    RAISE NOTICE 'ℹ️  Index already exists: idx_intensifier_knowledge_unique_name_language';
  END IF;
END $$;

-- =====================================================
-- Verification
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: knowledge_seed_unique_indexes';
  RAISE NOTICE '   - Unique indexes created for idempotent seeding';
END $$;
