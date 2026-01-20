-- Migration: Add Arabic Description Fields to exercise_translations
-- Phase: Multilingual Knowledge Expansion - Full Descriptions
-- Date: 2025-01-22
--
-- This migration adds full description fields to exercise_translations:
-- - short_desc: Short description in Arabic
-- - how_to: Step-by-step instructions in Arabic
-- - cues: Coaching cues array in Arabic
-- - common_mistakes: Common mistakes array in Arabic
--
-- This enables full Arabic exercise descriptions (not just names)
-- while keeping English as the canonical source in exercise_knowledge.

-- =====================================================
-- ALTER TABLE: Add description fields
-- =====================================================
ALTER TABLE public.exercise_translations
  ADD COLUMN IF NOT EXISTS short_desc TEXT,
  ADD COLUMN IF NOT EXISTS how_to TEXT,
  ADD COLUMN IF NOT EXISTS cues TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS common_mistakes TEXT[] DEFAULT '{}';

-- =====================================================
-- INDEXES: Full-text search for Arabic descriptions
-- =====================================================

-- GIN index for Arabic full-text search on name + short_desc + how_to
CREATE INDEX IF NOT EXISTS idx_exercise_translations_ar_text
  ON public.exercise_translations 
  USING gin (
    to_tsvector(
      'arabic',
      coalesce(name, '') || ' ' ||
      coalesce(short_desc, '') || ' ' ||
      coalesce(how_to, '')
    )
  );

-- GIN index for array search on cues
CREATE INDEX IF NOT EXISTS idx_exercise_translations_cues_gin
  ON public.exercise_translations USING GIN (cues);

-- GIN index for array search on common_mistakes
CREATE INDEX IF NOT EXISTS idx_exercise_translations_mistakes_gin
  ON public.exercise_translations USING GIN (common_mistakes);

-- =====================================================
-- VERIFICATION
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: add_arabic_descriptions_to_translations';
  RAISE NOTICE '   - Added short_desc, how_to, cues, common_mistakes to exercise_translations';
  RAISE NOTICE '   - Created Arabic full-text search index on descriptions';
  RAISE NOTICE '   - Created GIN indexes on cues and common_mistakes arrays';
END $$;
