-- Migration: Search Intensifiers with Aliases (Including Arabic)
-- Phase: Multilingual Knowledge Expansion
-- Date: 2025-01-22
--
-- This migration creates the search_intensifiers_with_aliases function
-- to include Arabic translations in search results.
--
-- Search now matches:
-- - English name
-- - English aliases
-- - Arabic name
-- - Arabic aliases

-- =====================================================
-- FUNCTION: search_intensifiers_with_aliases
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
  -- Left join Arabic translations (NEW)
  LEFT JOIN intensifier_translations it_ar 
    ON it_ar.intensifier_id = ik.id 
    AND it_ar.language = 'ar'
  WHERE
    -- Status filter
    ik.status = p_status
    
    -- Language filter (for intensifier_knowledge language, not translation language)
    AND (p_language IS NULL OR ik.language = p_language)
    
    -- Text search on name, short_desc, OR aliases (English)
    -- OR Arabic name OR Arabic aliases (NEW)
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
      -- Arabic search (NEW)
      OR it_ar.name ILIKE '%' || p_query || '%'
      OR EXISTS (
        SELECT 1 
        FROM unnest(it_ar.aliases) a 
        WHERE a ILIKE '%' || p_query || '%'
      )
      -- Full-text search on Arabic (if PostgreSQL supports it)
      OR to_tsvector('arabic', it_ar.name) @@ plainto_tsquery('arabic', p_query)
      OR to_tsvector('arabic', array_to_string(it_ar.aliases, ' ')) @@ plainto_tsquery('arabic', p_query)
    )
  ORDER BY 
    -- Prioritize exact name matches, then alias matches, then partial matches
    -- Now includes Arabic matches
    CASE 
      -- Exact English name match
      WHEN p_query IS NOT NULL AND ik.name ILIKE p_query THEN 1
      -- Exact Arabic name match (NEW)
      WHEN p_query IS NOT NULL AND it_ar.name ILIKE p_query THEN 1
      -- English name starts with query
      WHEN p_query IS NOT NULL AND ik.name ILIKE p_query || '%' THEN 2
      -- Arabic name starts with query (NEW)
      WHEN p_query IS NOT NULL AND it_ar.name ILIKE p_query || '%' THEN 2
      -- English alias exact match
      WHEN p_query IS NOT NULL AND EXISTS (
        SELECT 1 FROM unnest(ik.aliases) a WHERE a ILIKE p_query
      ) THEN 3
      -- Arabic alias exact match (NEW)
      WHEN p_query IS NOT NULL AND EXISTS (
        SELECT 1 FROM unnest(it_ar.aliases) a WHERE a ILIKE p_query
      ) THEN 3
      -- Partial matches
      WHEN p_query IS NOT NULL AND (
        ik.name ILIKE '%' || p_query || '%' 
        OR EXISTS (
          SELECT 1 FROM unnest(ik.aliases) a WHERE a ILIKE '%' || p_query || '%'
        )
        OR it_ar.name ILIKE '%' || p_query || '%'
        OR EXISTS (
          SELECT 1 FROM unnest(it_ar.aliases) a WHERE a ILIKE '%' || p_query || '%'
        )
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
  RAISE NOTICE '✅ Migration complete: search_intensifiers_with_aliases';
  RAISE NOTICE '   - Created function: search_intensifiers_with_aliases';
  RAISE NOTICE '   - Function includes Arabic translation search';
  RAISE NOTICE '   - Function maintains backward compatibility';
  RAISE NOTICE '   - Arabic full-text search enabled';
END $$;
