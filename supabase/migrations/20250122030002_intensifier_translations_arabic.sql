-- Migration: Intensifier Translations - Arabic Support
-- Phase: Multilingual Knowledge Expansion
-- Date: 2025-01-22
--
-- This migration creates the intensifier_translations table to support
-- multilingual intensifier names (Arabic, Kurdish, etc.) as first-class
-- searchable data, separate from the canonical English intensifier_knowledge.
--
-- Design principles:
-- - Arabic names are NOT stored in intensifier_knowledge (keeps English canonical)
-- - Arabic is fully searchable via full-text indexes
-- - Supports multiple languages per intensifier
-- - Idempotent and scalable

-- =====================================================
-- Enable required extensions
-- =====================================================
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =====================================================
-- TABLE: intensifier_translations
-- =====================================================
CREATE TABLE IF NOT EXISTS public.intensifier_translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  intensifier_id UUID NOT NULL REFERENCES public.intensifier_knowledge(id) ON DELETE CASCADE,
  language TEXT NOT NULL, -- 'ar', 'ku', etc.
  name TEXT NOT NULL, -- Canonical name in target language
  aliases TEXT[] DEFAULT '{}', -- Alternative names in target language
  description TEXT, -- Short description in target language (optional)
  source TEXT DEFAULT 'human_verified', -- 'canonical_ar_v1', 'coach_submitted', etc.
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure one translation per intensifier per language
  UNIQUE(intensifier_id, language)
);

-- =====================================================
-- INDEXES: Full-text search for Arabic
-- =====================================================

-- GIN index for Arabic full-text search on name
CREATE INDEX IF NOT EXISTS idx_intensifier_translations_name_ar
  ON public.intensifier_translations 
  USING gin (to_tsvector('arabic', name));

-- GIN index for Arabic full-text search on aliases
CREATE INDEX IF NOT EXISTS idx_intensifier_translations_aliases_ar
  ON public.intensifier_translations 
  USING gin (to_tsvector('arabic', array_to_string(aliases, ' ')));

-- B-tree indexes for filtering
CREATE INDEX IF NOT EXISTS idx_intensifier_translations_intensifier_id
  ON public.intensifier_translations(intensifier_id);

CREATE INDEX IF NOT EXISTS idx_intensifier_translations_language
  ON public.intensifier_translations(language);

-- GIN index for array search on aliases
CREATE INDEX IF NOT EXISTS idx_intensifier_translations_aliases_gin
  ON public.intensifier_translations USING GIN (aliases);

-- =====================================================
-- Enable RLS
-- =====================================================
ALTER TABLE public.intensifier_translations ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES: intensifier_translations
-- =====================================================
DO $$
BEGIN
  -- Authenticated users can SELECT all translations (for approved intensifiers)
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'intensifier_translations' AND policyname = 'it_select_approved') THEN
    CREATE POLICY it_select_approved ON public.intensifier_translations
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.intensifier_knowledge ik
          WHERE ik.id = intensifier_translations.intensifier_id
          AND ik.status = 'approved'
        )
      );
  END IF;

  -- Admins can INSERT/UPDATE/DELETE all translations
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'intensifier_translations' AND policyname = 'it_insert_admin') THEN
    CREATE POLICY it_insert_admin ON public.intensifier_translations
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

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'intensifier_translations' AND policyname = 'it_update_admin') THEN
    CREATE POLICY it_update_admin ON public.intensifier_translations
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

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'intensifier_translations' AND policyname = 'it_delete_admin') THEN
    CREATE POLICY it_delete_admin ON public.intensifier_translations
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
CREATE OR REPLACE FUNCTION update_intensifier_translations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_intensifier_translations_updated_at ON public.intensifier_translations;
CREATE TRIGGER trigger_update_intensifier_translations_updated_at
  BEFORE UPDATE ON public.intensifier_translations
  FOR EACH ROW
  EXECUTE FUNCTION update_intensifier_translations_updated_at();

-- =====================================================
-- VERIFICATION
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: intensifier_translations_arabic';
  RAISE NOTICE '   - Created table: intensifier_translations';
  RAISE NOTICE '   - Created Arabic full-text search indexes';
  RAISE NOTICE '   - RLS policies created';
  RAISE NOTICE '   - Triggers created';
END $$;
