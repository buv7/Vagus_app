-- Migration: Intensifier Aliases & Synonyms Support
-- Phase: Multilingual Knowledge Expansion
-- Date: 2025-01-22
--
-- This migration creates the intensifier_aliases table to support multiple names
-- for the same intensifier, improving Arabic search, AI reasoning, and user UX.
-- Supports multilingual aliases and scalable alias management.
--
-- Design principles:
-- - Each alias is a separate row (normalized, not array)
-- - Optimized for Arabic full-text search
-- - Idempotent and scalable
-- - Follows same pattern as exercise_aliases

-- =====================================================
-- Enable required extensions
-- =====================================================
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =====================================================
-- TABLE: intensifier_aliases
-- =====================================================
CREATE TABLE IF NOT EXISTS public.intensifier_aliases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  intensifier_id UUID NOT NULL REFERENCES public.intensifier_knowledge(id) ON DELETE CASCADE,
  alias TEXT NOT NULL,
  language TEXT NOT NULL DEFAULT 'ar',
  source TEXT DEFAULT 'canonical_ar_intensifier_alias_v1',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Prevent duplicate aliases for the same intensifier and language
  UNIQUE(intensifier_id, language, alias)
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Full-text search index for Arabic aliases (using GIN for fast text search)
CREATE INDEX IF NOT EXISTS idx_intensifier_aliases_ar
  ON public.intensifier_aliases 
  USING gin (to_tsvector('arabic', alias))
  WHERE language = 'ar';

-- Index for intensifier_id lookups (for JOINs)
CREATE INDEX IF NOT EXISTS idx_intensifier_aliases_intensifier_id
  ON public.intensifier_aliases(intensifier_id);

-- Index for language filtering
CREATE INDEX IF NOT EXISTS idx_intensifier_aliases_language
  ON public.intensifier_aliases(language);

-- Composite index for common query patterns (intensifier_id + language)
CREATE INDEX IF NOT EXISTS idx_intensifier_aliases_intensifier_language
  ON public.intensifier_aliases(intensifier_id, language);

-- Index for exact alias matching (case-insensitive)
CREATE INDEX IF NOT EXISTS idx_intensifier_aliases_alias_lower
  ON public.intensifier_aliases(lower(alias));

-- =====================================================
-- ENABLE RLS
-- =====================================================
ALTER TABLE public.intensifier_aliases ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES
-- =====================================================
DO $$
BEGIN
  -- Authenticated users can SELECT aliases for approved intensifiers
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'intensifier_aliases' AND policyname = 'ia_select_approved') THEN
    CREATE POLICY ia_select_approved ON public.intensifier_aliases
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.intensifier_knowledge ik
          WHERE ik.id = intensifier_aliases.intensifier_id
          AND ik.status = 'approved'
        )
      );
  END IF;

  -- Admins can INSERT aliases
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'intensifier_aliases' AND policyname = 'ia_insert_admin') THEN
    CREATE POLICY ia_insert_admin ON public.intensifier_aliases
      FOR INSERT
      TO authenticated
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
        AND EXISTS (
          SELECT 1 FROM public.intensifier_knowledge ik
          WHERE ik.id = intensifier_aliases.intensifier_id
          AND ik.status = 'approved'
        )
      );
  END IF;

  -- Admins can UPDATE/DELETE all aliases
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'intensifier_aliases' AND policyname = 'ia_update_admin') THEN
    CREATE POLICY ia_update_admin ON public.intensifier_aliases
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

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'intensifier_aliases' AND policyname = 'ia_delete_admin') THEN
    CREATE POLICY ia_delete_admin ON public.intensifier_aliases
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
  RAISE NOTICE '✅ Migration complete: intensifier_aliases_table';
  RAISE NOTICE '   - Created table: intensifier_aliases';
  RAISE NOTICE '   - Created indexes for search performance';
  RAISE NOTICE '   - Arabic full-text search index enabled';
  RAISE NOTICE '   - RLS policies created';
END $$;
