-- Migration: Update Search to Include Arabic Aliases from intensifier_aliases Table
-- Phase: Multilingual Knowledge Expansion
-- Date: 2025-01-22
--
-- This migration updates the search_intensifiers_with_aliases function
-- to include Arabic aliases from the intensifier_aliases table.
--
-- Search now matches:
-- - English name
-- - English aliases (from intensifier_knowledge.aliases array)
-- - Arabic name (from intensifier_translations)
-- - Arabic aliases (from intensifier_translations.aliases array)
-- - Arabic aliases (from intensifier_aliases table) [NEW]

-- =====================================================
-- FUNCTION: search_intensifiers_with_aliases (UPDATED)
-- =====================================================
CREATE OR REPLACE FUNCTION public.search_intensifiers_with_aliases(
  p_query TEXT DEFAULT NULL,
  p_status TEXT DEFAULT 'approved',
  p_language TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  aliases TEXT[],
  short_desc TEXT,
  how_to TEXT,
  setup_steps TEXT[],
  best_for TEXT[],
  fatigue_cost TEXT,
  when_to_use TEXT,
  when_to_avoid TEXT,
  intensity_rules JSONB,
  examples TEXT[],
  language TEXT,
  status TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  -- Arabic translation fields (if available)
  arabic_name TEXT,
  arabic_aliases TEXT[]
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT
    ik.id,
    ik.name,
    ik.aliases,
    ik.short_desc,
    ik.how_to,
    ik.setup_steps,
    ik.best_for,
    ik.fatigue_cost,
    ik.when_to_use,
    ik.when_to_avoid,
    ik.intensity_rules,
    ik.examples,
    ik.language,
    ik.status,
    ik.created_by,
    ik.created_at,
    ik.updated_at,
    -- Arabic translation (if exists)
    it_ar.name as arabic_name,
    it_ar.aliases as arabic_aliases
  FROM intensifier_knowledge ik
  -- Left join Arabic translations (from intensifier_translations table)
  LEFT JOIN intensifier_translations it_ar 
    ON it_ar.intensifier_id = ik.id 
    AND it_ar.language = 'ar'
  -- Left join Arabic aliases (NEW - from intensifier_aliases table)
  LEFT JOIN intensifier_aliases ia_ar 
    ON ia_ar.intensifier_id = ik.id 
    AND ia_ar.language = 'ar'
  WHERE
    -- Status filter
    ik.status = p_status
    
    -- Language filter (for intensifier_knowledge language, not translation/alias language)
    AND (p_language IS NULL OR ik.language = p_language)
    
    -- Text search on name, short_desc, OR aliases
    -- English: name, short_desc, English aliases (from array)
    -- Arabic: translation name, translation aliases (from array), Arabic aliases (from intensifier_aliases table)
    AND (
      p_query IS NULL 
      OR p_query = ''
      -- English search
      OR ik.name ILIKE '%' || p_query || '%'
      OR ik.short_desc ILIKE '%' || p_query || '%'
      OR EXISTS (
        SELECT 1 
        FROM unnest(ik.aliases) a 
        WHERE a ILIKE '%' || p_query || '%'
      )
      -- Arabic search: translations (from intensifier_translations table)
      OR it_ar.name ILIKE '%' || p_query || '%'
      OR EXISTS (
        SELECT 1 
        FROM unnest(it_ar.aliases) a 
        WHERE a ILIKE '%' || p_query || '%'
      )
      -- Arabic search: aliases from intensifier_aliases table (NEW)
      OR ia_ar.alias ILIKE '%' || p_query || '%'
      -- Full-text search on Arabic (PostgreSQL full-text search)
      OR to_tsvector('arabic', it_ar.name) @@ plainto_tsquery('arabic', p_query)
      OR to_tsvector('arabic', array_to_string(it_ar.aliases, ' ')) @@ plainto_tsquery('arabic', p_query)
      -- Full-text search on Arabic aliases from intensifier_aliases (NEW)
      OR to_tsvector('arabic', ia_ar.alias) @@ plainto_tsquery('arabic', p_query)
    )
  ORDER BY 
    -- Prioritize exact name matches, then alias matches, then partial matches
    -- Includes both English and Arabic matches (translation + aliases table)
    CASE 
      -- Exact English name match
      WHEN p_query IS NOT NULL AND ik.name ILIKE p_query THEN 1
      -- Exact Arabic name match (from translations)
      WHEN p_query IS NOT NULL AND it_ar.name ILIKE p_query THEN 1
      -- Exact Arabic alias match (from intensifier_aliases table)
      WHEN p_query IS NOT NULL AND ia_ar.alias ILIKE p_query THEN 1
      -- English name starts with query
      WHEN p_query IS NOT NULL AND ik.name ILIKE p_query || '%' THEN 2
      -- Arabic name starts with query (from translations)
      WHEN p_query IS NOT NULL AND it_ar.name ILIKE p_query || '%' THEN 2
      -- Arabic alias starts with query (from intensifier_aliases table)
      WHEN p_query IS NOT NULL AND ia_ar.alias ILIKE p_query || '%' THEN 2
      -- English alias exact match (from array)
      WHEN p_query IS NOT NULL AND EXISTS (
        SELECT 1 FROM unnest(ik.aliases) a WHERE a ILIKE p_query
      ) THEN 3
      -- Arabic alias exact match (from translations array)
      WHEN p_query IS NOT NULL AND EXISTS (
        SELECT 1 FROM unnest(it_ar.aliases) a WHERE a ILIKE p_query
      ) THEN 3
      -- Partial matches (English)
      WHEN p_query IS NOT NULL AND (
        ik.name ILIKE '%' || p_query || '%' 
        OR EXISTS (
          SELECT 1 FROM unnest(ik.aliases) a WHERE a ILIKE '%' || p_query || '%'
        )
      ) THEN 4
      -- Partial matches (Arabic - translations + aliases table)
      WHEN p_query IS NOT NULL AND (
        it_ar.name ILIKE '%' || p_query || '%'
        OR EXISTS (
          SELECT 1 FROM unnest(it_ar.aliases) a WHERE a ILIKE '%' || p_query || '%'
        )
        OR ia_ar.alias ILIKE '%' || p_query || '%'
      ) THEN 4
      ELSE 5
    END,
    ik.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.search_intensifiers_with_aliases TO authenticated;

-- =====================================================
-- VERIFICATION
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: update_search_intensifiers_with_aliases';
  RAISE NOTICE '   - Updated function: search_intensifiers_with_aliases';
  RAISE NOTICE '   - Function now includes Arabic aliases from intensifier_aliases table';
  RAISE NOTICE '   - Function searches both intensifier_translations AND intensifier_aliases for Arabic';
  RAISE NOTICE '   - Function maintains backward compatibility';
  RAISE NOTICE '   - Arabic full-text search enabled for both sources';
END $$;
