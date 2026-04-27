-- Migration: Add Arabic Full-Text Search Index for Exercise Aliases
-- Phase: Multilingual Knowledge Expansion
-- Date: 2025-01-22
--
-- This migration adds an Arabic-specific full-text search index to the
-- exercise_aliases table to support fast Arabic alias search.
--
-- This complements the existing English index and enables efficient
-- Arabic alias search without impacting English search performance.

-- =====================================================
-- INDEX: Arabic Full-Text Search for Aliases
-- =====================================================

-- GIN index for Arabic full-text search on aliases
-- This is a separate index from the English one to optimize for Arabic text search
CREATE INDEX IF NOT EXISTS idx_exercise_aliases_alias_search_arabic
  ON public.exercise_aliases 
  USING gin (to_tsvector('arabic', alias))
  WHERE language = 'ar';

-- =====================================================
-- VERIFICATION
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: add_arabic_alias_index';
  RAISE NOTICE '   - Created Arabic GIN index: idx_exercise_aliases_alias_search_arabic';
  RAISE NOTICE '   - Index is filtered to Arabic language only for performance';
END $$;
