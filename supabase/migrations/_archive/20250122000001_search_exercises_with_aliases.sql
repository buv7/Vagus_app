-- Migration: Search Exercises with Aliases Support
-- Phase: Exercise Knowledge Enhancement
-- Date: 2025-01-22
--
-- This migration creates an RPC function to search exercises including aliases
-- for better search results and user experience.

-- =====================================================
-- FUNCTION: search_exercises_with_aliases
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
  updated_at TIMESTAMPTZ
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
    ek.updated_at
  FROM exercise_knowledge ek
  LEFT JOIN exercise_aliases ea ON ea.exercise_id = ek.id
  WHERE
    -- Status filter
    ek.status = p_status
    
    -- Language filter
    AND (p_language IS NULL OR ek.language = p_language)
    
    -- Muscle filter (array overlap)
    AND (p_muscles IS NULL OR p_muscles = '{}' OR ek.primary_muscles && p_muscles)
    
    -- Equipment filter (array overlap)
    AND (p_equipment IS NULL OR p_equipment = '{}' OR ek.equipment && p_equipment)
    
    -- Text search on name, short_desc, OR aliases
    AND (
      p_query IS NULL 
      OR p_query = ''
      OR ek.name ILIKE '%' || p_query || '%'
      OR ek.short_desc ILIKE '%' || p_query || '%'
      OR ea.alias ILIKE '%' || p_query || '%'
    )
  ORDER BY 
    -- Prioritize exact name matches, then alias matches, then partial matches
    CASE 
      WHEN p_query IS NOT NULL AND ek.name ILIKE p_query THEN 1
      WHEN p_query IS NOT NULL AND ek.name ILIKE p_query || '%' THEN 2
      WHEN p_query IS NOT NULL AND ea.alias ILIKE p_query THEN 3
      WHEN p_query IS NOT NULL AND (ek.name ILIKE '%' || p_query || '%' OR ea.alias ILIKE '%' || p_query || '%') THEN 4
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
  RAISE NOTICE '✅ Migration complete: search_exercises_with_aliases';
  RAISE NOTICE '   - Created function: search_exercises_with_aliases';
  RAISE NOTICE '   - Function includes alias search support';
  RAISE NOTICE '   - Function maintains backward compatibility';
END $$;
