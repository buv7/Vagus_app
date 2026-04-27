-- Migration: Muscle Translations Table - Arabic Muscle Names Support
-- Phase: Multilingual Anatomy Layer
-- Date: 2025-01-22
--
-- This migration creates the muscle_translations table to support
-- Arabic (and future) translations of muscle names.
--
-- Features:
-- - Canonical muscle keys (English/anatomical identifiers)
-- - Multilingual support (Arabic first, extensible)
-- - Gym-friendly aliases
-- - Full-text search support for Arabic
-- - Idempotent design (unique on muscle_key + language)

-- =====================================================
-- Enable required extensions
-- =====================================================
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =====================================================
-- TABLE: muscle_translations
-- =====================================================
CREATE TABLE IF NOT EXISTS public.muscle_translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  muscle_key TEXT NOT NULL,
  language TEXT NOT NULL DEFAULT 'ar',
  name TEXT NOT NULL,
  aliases TEXT[] DEFAULT '{}',
  description TEXT,
  source TEXT DEFAULT 'canonical_ar_v1',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (muscle_key, language)
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Unique index for muscle_key + language (already covered by UNIQUE constraint, but explicit for clarity)
CREATE INDEX IF NOT EXISTS idx_muscle_translations_key_language
  ON public.muscle_translations(muscle_key, language);

-- Full-text search index for Arabic names
CREATE INDEX IF NOT EXISTS idx_muscle_translations_name_ar
  ON public.muscle_translations USING GIN (to_tsvector('arabic', name))
  WHERE language = 'ar';

-- Full-text search index for Arabic aliases
CREATE INDEX IF NOT EXISTS idx_muscle_translations_aliases_ar
  ON public.muscle_translations USING GIN (
    to_tsvector('arabic', array_to_string(aliases, ' '))
  )
  WHERE language = 'ar';

-- GIN index for aliases array (for array operations)
CREATE INDEX IF NOT EXISTS idx_muscle_translations_aliases_gin
  ON public.muscle_translations USING GIN (aliases);

-- Index for muscle_key lookups
CREATE INDEX IF NOT EXISTS idx_muscle_translations_muscle_key
  ON public.muscle_translations(muscle_key);

-- Index for language filtering
CREATE INDEX IF NOT EXISTS idx_muscle_translations_language
  ON public.muscle_translations(language);

-- =====================================================
-- RLS (Row Level Security)
-- =====================================================

-- Enable RLS
ALTER TABLE public.muscle_translations ENABLE ROW LEVEL SECURITY;

-- Policy: All authenticated users can read approved translations
CREATE POLICY "muscle_translations_read_authenticated"
  ON public.muscle_translations
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Admins can insert/update/delete
CREATE POLICY "muscle_translations_admin_all"
  ON public.muscle_translations
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_muscle_translations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER muscle_translations_updated_at
  BEFORE UPDATE ON public.muscle_translations
  FOR EACH ROW
  EXECUTE FUNCTION update_muscle_translations_updated_at();

-- =====================================================
-- VERIFICATION
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: muscle_translations table created';
  RAISE NOTICE '   - Table: muscle_translations';
  RAISE NOTICE '   - Unique constraint: (muscle_key, language)';
  RAISE NOTICE '   - Full-text search indexes for Arabic';
  RAISE NOTICE '   - RLS policies configured';
  RAISE NOTICE '   - Ready for Arabic muscle name seeding';
END $$;
