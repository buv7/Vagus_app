-- Migration: Exercise Aliases & Synonyms Support
-- Phase: Exercise Knowledge Enhancement
-- Date: 2025-01-22
--
-- This migration creates the exercise_aliases table to support multiple names
-- for the same exercise, improving search, AI reasoning, and user UX.
-- Supports multilingual aliases and scalable alias management.

-- =====================================================
-- TABLE: exercise_aliases
-- =====================================================
CREATE TABLE IF NOT EXISTS public.exercise_aliases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exercise_id UUID NOT NULL REFERENCES public.exercise_knowledge(id) ON DELETE CASCADE,
  alias TEXT NOT NULL,
  language TEXT DEFAULT 'en',
  source TEXT DEFAULT 'canonical', -- 'canonical', 'user', 'coach', 'system'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Prevent duplicate aliases for the same exercise
  UNIQUE(exercise_id, alias, language)
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Full-text search index for aliases (using GIN for fast text search)
CREATE INDEX IF NOT EXISTS idx_exercise_aliases_alias_search
  ON public.exercise_aliases USING gin (to_tsvector('english', alias));

-- Index for exercise_id lookups (for JOINs)
CREATE INDEX IF NOT EXISTS idx_exercise_aliases_exercise_id
  ON public.exercise_aliases(exercise_id);

-- Index for language filtering
CREATE INDEX IF NOT EXISTS idx_exercise_aliases_language
  ON public.exercise_aliases(language);

-- Composite index for common query patterns (exercise_id + language)
CREATE INDEX IF NOT EXISTS idx_exercise_aliases_exercise_language
  ON public.exercise_aliases(exercise_id, language);

-- Index for exact alias matching (case-insensitive)
CREATE INDEX IF NOT EXISTS idx_exercise_aliases_alias_lower
  ON public.exercise_aliases(lower(alias));

-- =====================================================
-- ENABLE RLS
-- =====================================================
ALTER TABLE public.exercise_aliases ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES
-- =====================================================
DO $$
BEGIN
  -- Authenticated users can SELECT aliases for approved exercises
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_aliases' AND policyname = 'ea_select_approved') THEN
    CREATE POLICY ea_select_approved ON public.exercise_aliases
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.exercise_knowledge ek
          WHERE ek.id = exercise_aliases.exercise_id
          AND ek.status = 'approved'
        )
      );
  END IF;

  -- Coaches/admins can INSERT aliases for exercises they created or are approved
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_aliases' AND policyname = 'ea_insert_coach_admin') THEN
    CREATE POLICY ea_insert_coach_admin ON public.exercise_aliases
      FOR INSERT
      TO authenticated
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role IN ('coach', 'admin')
        )
        AND EXISTS (
          SELECT 1 FROM public.exercise_knowledge ek
          WHERE ek.id = exercise_aliases.exercise_id
          AND (ek.created_by = auth.uid() OR ek.status = 'approved')
        )
      );
  END IF;

  -- Admins can UPDATE/DELETE all aliases
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_aliases' AND policyname = 'ea_update_admin') THEN
    CREATE POLICY ea_update_admin ON public.exercise_aliases
      FOR UPDATE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
      );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_aliases' AND policyname = 'ea_delete_admin') THEN
    CREATE POLICY ea_delete_admin ON public.exercise_aliases
      FOR DELETE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
      );
  END IF;

  -- Coaches can DELETE their own aliases
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_aliases' AND policyname = 'ea_delete_own') THEN
    CREATE POLICY ea_delete_own ON public.exercise_aliases
      FOR DELETE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'coach'
        )
        AND EXISTS (
          SELECT 1 FROM public.exercise_knowledge ek
          WHERE ek.id = exercise_aliases.exercise_id
          AND ek.created_by = auth.uid()
        )
      );
  END IF;
END $$;

-- =====================================================
-- VERIFICATION
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: exercise_aliases_table';
  RAISE NOTICE '   - Created table: exercise_aliases';
  RAISE NOTICE '   - Created indexes for search performance';
  RAISE NOTICE '   - RLS policies created';
END $$;
