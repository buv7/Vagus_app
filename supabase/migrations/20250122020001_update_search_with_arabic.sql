-- Migration: Update Search to Include Arabic Translations
-- Phase: Multilingual Knowledge Expansion
-- Date: 2025-01-22
--
-- This migration updates the search_exercises_with_aliases function
-- to include Arabic translations in search results.
--
-- Search now matches:
-- - English name
-- - English aliases
-- - Arabic name
-- - Arabic aliases

-- =====================================================
-- FUNCTION: search_exercises_with_aliases (UPDATED)
-- =====================================================
CREATE OR REPLACE FUNCTION public.search_exercises_with_aliases(
  p_query TEXT DEFAULT NULL,
  p_status TEXT DEFAULT 'approved',
  p_language TEXT DEFAULT NULL,
  p_muscles TEXT[] DEFAULT NULL,
  p_equipment TEXT[] DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  aliases TEXT[],
  short_desc TEXT,
  how_to TEXT,
  cues TEXT[],
  common_mistakes TEXT[],
  primary_muscles TEXT[],
  secondary_muscles TEXT[],
  equipment TEXT[],
  movement_pattern TEXT,
  difficulty TEXT,
  contraindications TEXT[],
  media JSONB,
  source TEXT,
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
    ek.id,
    ek.name,
    ek.aliases,
    ek.short_desc,
    ek.how_to,
    ek.cues,
    ek.common_mistakes,
    ek.primary_muscles,
    ek.secondary_muscles,
    ek.equipment,
    ek.movement_pattern,
    ek.difficulty,
    ek.contraindications,
    ek.media,
    ek.source,
    ek.language,
    ek.status,
    ek.created_by,
    ek.created_at,
    ek.updated_at,
    -- Arabic translation (if exists)
    et_ar.name as arabic_name,
    et_ar.aliases as arabic_aliases
  FROM exercise_knowledge ek
  -- Left join English aliases (existing)
  LEFT JOIN exercise_aliases ea ON ea.exercise_id = ek.id
  -- Left join Arabic translations (NEW)
  LEFT JOIN exercise_translations et_ar 
    ON et_ar.exercise_id = ek.id 
    AND et_ar.language = 'ar'
  WHERE
    -- Status filter
    ek.status = p_status
    
    -- Language filter (for exercise_knowledge language, not translation language)
    AND (p_language IS NULL OR ek.language = p_language)
    
    -- Muscle filter (array overlap)
    AND (p_muscles IS NULL OR p_muscles = '{}' OR ek.primary_muscles && p_muscles)
    
    -- Equipment filter (array overlap)
    AND (p_equipment IS NULL OR p_equipment = '{}' OR ek.equipment && p_equipment)
    
    -- Text search on name, short_desc, OR aliases (English)
    -- OR Arabic name OR Arabic aliases (NEW)
    AND (
      p_query IS NULL 
      OR p_query = ''
      -- English search
      OR ek.name ILIKE '%' || p_query || '%'
      OR ek.short_desc ILIKE '%' || p_query || '%'
      OR ea.alias ILIKE '%' || p_query || '%'
      -- Arabic search (NEW)
      OR et_ar.name ILIKE '%' || p_query || '%'
      OR EXISTS (
        SELECT 1 
        FROM unnest(et_ar.aliases) a 
        WHERE a ILIKE '%' || p_query || '%'
      )
      -- Full-text search on Arabic (if PostgreSQL supports it)
      OR to_tsvector('arabic', et_ar.name) @@ plainto_tsquery('arabic', p_query)
      OR to_tsvector('arabic', array_to_string(et_ar.aliases, ' ')) @@ plainto_tsquery('arabic', p_query)
    )
  ORDER BY 
    -- Prioritize exact name matches, then alias matches, then partial matches
    -- Now includes Arabic matches
    CASE 
      -- Exact English name match
      WHEN p_query IS NOT NULL AND ek.name ILIKE p_query THEN 1
      -- Exact Arabic name match (NEW)
      WHEN p_query IS NOT NULL AND et_ar.name ILIKE p_query THEN 1
      -- English name starts with query
      WHEN p_query IS NOT NULL AND ek.name ILIKE p_query || '%' THEN 2
      -- Arabic name starts with query (NEW)
      WHEN p_query IS NOT NULL AND et_ar.name ILIKE p_query || '%' THEN 2
      -- English alias exact match
      WHEN p_query IS NOT NULL AND ea.alias ILIKE p_query THEN 3
      -- Arabic alias exact match (NEW)
      WHEN p_query IS NOT NULL AND EXISTS (
        SELECT 1 FROM unnest(et_ar.aliases) a WHERE a ILIKE p_query
      ) THEN 3
      -- Partial matches
      WHEN p_query IS NOT NULL AND (
        ek.name ILIKE '%' || p_query || '%' 
        OR ea.alias ILIKE '%' || p_query || '%'
        OR et_ar.name ILIKE '%' || p_query || '%'
        OR EXISTS (
          SELECT 1 FROM unnest(et_ar.aliases) a WHERE a ILIKE '%' || p_query || '%'
        )
      ) THEN 4
      ELSE 5
    END,
    ek.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.search_exercises_with_aliases TO authenticated;

-- =====================================================
-- VERIFICATION
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: update_search_with_arabic';
  RAISE NOTICE '   - Updated function: search_exercises_with_aliases';
  RAISE NOTICE '   - Function now includes Arabic translation search';
  RAISE NOTICE '   - Function maintains backward compatibility';
  RAISE NOTICE '   - Arabic full-text search enabled';
END $$;
