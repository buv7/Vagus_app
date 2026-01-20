-- Migration: Muscle Aliases & Synonyms Support
-- Phase: Multilingual Knowledge Expansion
-- Date: 2025-01-22
--
-- This migration creates the muscle_aliases table to support multiple names
-- for the same muscle, improving Arabic search, AI reasoning, and user UX.
-- Supports multilingual aliases and scalable alias management.
--
-- Design principles:
-- - Muscle keys are text identifiers (not foreign keys to a table)
-- - Each alias is a separate row (normalized, not array)
-- - Optimized for Arabic full-text search
-- - Idempotent and scalable

-- =====================================================
-- Enable required extensions
-- =====================================================
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =====================================================
-- TABLE: muscle_aliases
-- =====================================================
CREATE TABLE IF NOT EXISTS public.muscle_aliases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  muscle_key TEXT NOT NULL,
  language TEXT NOT NULL DEFAULT 'ar',
  alias TEXT NOT NULL,
  source TEXT DEFAULT 'canonical_ar_muscle_alias_v1',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Prevent duplicate aliases for the same muscle key and language
  UNIQUE(muscle_key, language, alias)
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Full-text search index for Arabic aliases (using GIN for fast text search)
CREATE INDEX IF NOT EXISTS idx_muscle_aliases_ar_alias
  ON public.muscle_aliases 
  USING gin (to_tsvector('arabic', alias))
  WHERE language = 'ar';

-- Index for muscle_key lookups (for JOINs and filtering)
CREATE INDEX IF NOT EXISTS idx_muscle_aliases_muscle_key
  ON public.muscle_aliases(muscle_key);

-- Index for language filtering
CREATE INDEX IF NOT EXISTS idx_muscle_aliases_language
  ON public.muscle_aliases(language);

-- Composite index for common query patterns (muscle_key + language)
CREATE INDEX IF NOT EXISTS idx_muscle_aliases_muscle_language
  ON public.muscle_aliases(muscle_key, language);

-- Index for exact alias matching (case-insensitive, for ILIKE queries)
CREATE INDEX IF NOT EXISTS idx_muscle_aliases_alias_lower
  ON public.muscle_aliases(lower(alias));

-- Composite index for alias search (language + alias)
CREATE INDEX IF NOT EXISTS idx_muscle_aliases_language_alias
  ON public.muscle_aliases(language, lower(alias));

-- =====================================================
-- ENABLE RLS
-- =====================================================
ALTER TABLE public.muscle_aliases ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES
-- =====================================================
DO $$
BEGIN
  -- Authenticated users can SELECT all muscle aliases (for search)
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'muscle_aliases' AND policyname = 'ma_select_authenticated') THEN
    CREATE POLICY ma_select_authenticated ON public.muscle_aliases
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  -- Admins can INSERT/UPDATE/DELETE all aliases
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'muscle_aliases' AND policyname = 'ma_insert_admin') THEN
    CREATE POLICY ma_insert_admin ON public.muscle_aliases
      FOR INSERT
      TO authenticated
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
      );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'muscle_aliases' AND policyname = 'ma_update_admin') THEN
    CREATE POLICY ma_update_admin ON public.muscle_aliases
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

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'muscle_aliases' AND policyname = 'ma_delete_admin') THEN
    CREATE POLICY ma_delete_admin ON public.muscle_aliases
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
END $$;

-- =====================================================
-- VERIFICATION
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: muscle_aliases_table';
  RAISE NOTICE '   - Created table: muscle_aliases';
  RAISE NOTICE '   - Created indexes for Arabic search performance';
  RAISE NOTICE '   - RLS policies created';
  RAISE NOTICE '   - Ready for Arabic muscle alias seeding';
END $$;
