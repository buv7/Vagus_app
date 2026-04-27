-- Migration: Exercise Translations - Arabic Support
-- Phase: Multilingual Knowledge Expansion
-- Date: 2025-01-22
--
-- This migration creates the exercise_translations table to support
-- multilingual exercise names (Arabic, Kurdish, etc.) as first-class
-- searchable data, separate from the canonical English exercise_knowledge.
--
-- Design principles:
-- - Arabic names are NOT stored in exercise_knowledge (keeps English canonical)
-- - Arabic is fully searchable via full-text indexes
-- - Supports multiple languages per exercise
-- - Idempotent and scalable

-- =====================================================
-- Enable required extensions
-- =====================================================
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =====================================================
-- TABLE: exercise_translations
-- =====================================================
CREATE TABLE IF NOT EXISTS public.exercise_translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exercise_id UUID NOT NULL REFERENCES public.exercise_knowledge(id) ON DELETE CASCADE,
  language TEXT NOT NULL, -- 'ar', 'ku', etc.
  name TEXT NOT NULL, -- Canonical name in target language
  aliases TEXT[] DEFAULT '{}', -- Alternative names in target language
  source TEXT DEFAULT 'human_verified', -- 'canonical_ar_v1', 'coach_submitted', etc.
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure one translation per exercise per language
  UNIQUE(exercise_id, language)
);

-- =====================================================
-- INDEXES: Full-text search for Arabic
-- =====================================================

-- GIN index for Arabic full-text search on name
CREATE INDEX IF NOT EXISTS idx_exercise_translations_name_ar
  ON public.exercise_translations 
  USING gin (to_tsvector('arabic', name));

-- GIN index for Arabic full-text search on aliases
CREATE INDEX IF NOT EXISTS idx_exercise_translations_aliases_ar
  ON public.exercise_translations 
  USING gin (to_tsvector('arabic', array_to_string(aliases, ' ')));

-- B-tree indexes for filtering
CREATE INDEX IF NOT EXISTS idx_exercise_translations_exercise_id
  ON public.exercise_translations(exercise_id);

CREATE INDEX IF NOT EXISTS idx_exercise_translations_language
  ON public.exercise_translations(language);

-- GIN index for array search on aliases
CREATE INDEX IF NOT EXISTS idx_exercise_translations_aliases_gin
  ON public.exercise_translations USING GIN (aliases);

-- =====================================================
-- Enable RLS
-- =====================================================
ALTER TABLE public.exercise_translations ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES: exercise_translations
-- =====================================================
DO $$
BEGIN
  -- Authenticated users can SELECT all translations (for approved exercises)
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_translations' AND policyname = 'et_select_approved') THEN
    CREATE POLICY et_select_approved ON public.exercise_translations
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.exercise_knowledge ek
          WHERE ek.id = exercise_translations.exercise_id
          AND ek.status = 'approved'
        )
      );
  END IF;

  -- Admins can INSERT/UPDATE/DELETE all translations
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_translations' AND policyname = 'et_insert_admin') THEN
    CREATE POLICY et_insert_admin ON public.exercise_translations
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

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_translations' AND policyname = 'et_update_admin') THEN
    CREATE POLICY et_update_admin ON public.exercise_translations
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

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_translations' AND policyname = 'et_delete_admin') THEN
    CREATE POLICY et_delete_admin ON public.exercise_translations
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
-- Trigger function to update updated_at timestamp
-- =====================================================
CREATE OR REPLACE FUNCTION update_exercise_translations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_exercise_translations_updated_at ON public.exercise_translations;
CREATE TRIGGER trigger_update_exercise_translations_updated_at
  BEFORE UPDATE ON public.exercise_translations
  FOR EACH ROW
  EXECUTE FUNCTION update_exercise_translations_updated_at();

-- =====================================================
-- VERIFICATION
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: exercise_translations_arabic';
  RAISE NOTICE '   - Created table: exercise_translations';
  RAISE NOTICE '   - Created Arabic full-text search indexes';
  RAISE NOTICE '   - RLS policies created';
  RAISE NOTICE '   - Triggers created';
END $$;
