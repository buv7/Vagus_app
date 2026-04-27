-- Migration: Update Search to Include Arabic Muscle Translations
-- Phase: Multilingual Anatomy Layer
-- Date: 2025-01-22
--
-- This migration updates the search_exercises_with_aliases function
-- to include Arabic muscle translations in search results.
--
-- Search now matches:
-- - English muscle keys
-- - Arabic muscle names
-- - Arabic muscle aliases
-- - Full-text search on Arabic muscle names

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
DECLARE
  v_muscle_keys TEXT[];
BEGIN
  -- If p_muscles contains Arabic text, try to resolve to muscle keys
  IF p_muscles IS NOT NULL AND p_muscles != '{}' THEN
    -- Check if any muscle filter contains Arabic characters
    IF EXISTS (
      SELECT 1 FROM unnest(p_muscles) m 
      WHERE m ~ '[ء-ي]'
    ) THEN
      -- Resolve Arabic muscle names/aliases to muscle keys
      SELECT ARRAY_AGG(DISTINCT mt.muscle_key)
      INTO v_muscle_keys
      FROM muscle_translations mt
      WHERE mt.language = 'ar'
        AND (
          -- Match Arabic name
          mt.name = ANY(p_muscles)
          OR mt.name ILIKE ANY(SELECT '%' || m || '%' FROM unnest(p_muscles) m)
          -- Match Arabic aliases
          OR mt.aliases && p_muscles
          OR EXISTS (
            SELECT 1 
            FROM unnest(mt.aliases) alias
            WHERE alias ILIKE ANY(SELECT '%' || m || '%' FROM unnest(p_muscles) m)
          )
          -- Full-text search on Arabic
          OR to_tsvector('arabic', mt.name) @@ plainto_tsquery('arabic', array_to_string(p_muscles, ' '))
          OR to_tsvector('arabic', array_to_string(mt.aliases, ' ')) @@ plainto_tsquery('arabic', array_to_string(p_muscles, ' '))
        );
      
      -- Combine resolved keys with original English keys
      IF v_muscle_keys IS NOT NULL THEN
        v_muscle_keys := ARRAY(
          SELECT DISTINCT unnest(COALESCE(v_muscle_keys, ARRAY[]::TEXT[]) || p_muscles)
        );
      ELSE
        v_muscle_keys := p_muscles;
      END IF;
    ELSE
      -- All English keys, use as-is
      v_muscle_keys := p_muscles;
    END IF;
  END IF;

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
  -- Left join Arabic translations (existing)
  LEFT JOIN exercise_translations et_ar 
    ON et_ar.exercise_id = ek.id 
    AND et_ar.language = 'ar'
  -- Left join Arabic muscle translations for primary muscles
  LEFT JOIN LATERAL (
    SELECT ARRAY_AGG(DISTINCT mt.name) as arabic_names
    FROM unnest(ek.primary_muscles) pm
    JOIN muscle_translations mt ON mt.muscle_key = pm AND mt.language = 'ar'
  ) mt_primary ON true
  -- Left join Arabic muscle translations for secondary muscles
  LEFT JOIN LATERAL (
    SELECT ARRAY_AGG(DISTINCT mt.name) as arabic_names
    FROM unnest(ek.secondary_muscles) sm
    JOIN muscle_translations mt ON mt.muscle_key = sm AND mt.language = 'ar'
  ) mt_secondary ON true
  WHERE
    -- Status filter
    ek.status = p_status
    
    -- Language filter (for exercise_knowledge language, not translation language)
    AND (p_language IS NULL OR ek.language = p_language)
    
    -- Muscle filter (array overlap) - now supports Arabic muscle names
    AND (
      v_muscle_keys IS NULL 
      OR v_muscle_keys = '{}' 
      -- Match English muscle keys
      OR ek.primary_muscles && v_muscle_keys
      OR ek.secondary_muscles && v_muscle_keys
      -- Match Arabic muscle names in primary muscles
      OR EXISTS (
        SELECT 1
        FROM unnest(ek.primary_muscles) pm
        JOIN muscle_translations mt ON mt.muscle_key = pm AND mt.language = 'ar'
        WHERE 
          mt.name = ANY(v_muscle_keys)
          OR mt.aliases && v_muscle_keys
          OR EXISTS (
            SELECT 1 FROM unnest(mt.aliases) alias
            WHERE alias = ANY(v_muscle_keys)
          )
      )
      -- Match Arabic muscle names in secondary muscles
      OR EXISTS (
        SELECT 1
        FROM unnest(ek.secondary_muscles) sm
        JOIN muscle_translations mt ON mt.muscle_key = sm AND mt.language = 'ar'
        WHERE 
          mt.name = ANY(v_muscle_keys)
          OR mt.aliases && v_muscle_keys
          OR EXISTS (
            SELECT 1 FROM unnest(mt.aliases) alias
            WHERE alias = ANY(v_muscle_keys)
          )
      )
    )
    
    -- Equipment filter (array overlap)
    AND (p_equipment IS NULL OR p_equipment = '{}' OR ek.equipment && p_equipment)
    
    -- Text search on name, short_desc, OR aliases (English)
    -- OR Arabic name OR Arabic aliases
    -- OR Arabic muscle names (NEW)
    AND (
      p_query IS NULL 
      OR p_query = ''
      -- English search
      OR ek.name ILIKE '%' || p_query || '%'
      OR ek.short_desc ILIKE '%' || p_query || '%'
      OR ea.alias ILIKE '%' || p_query || '%'
      -- Arabic exercise search (existing)
      OR et_ar.name ILIKE '%' || p_query || '%'
      OR EXISTS (
        SELECT 1 
        FROM unnest(et_ar.aliases) a 
        WHERE a ILIKE '%' || p_query || '%'
      )
      -- Full-text search on Arabic exercises (existing)
      OR to_tsvector('arabic', et_ar.name) @@ plainto_tsquery('arabic', p_query)
      OR to_tsvector('arabic', array_to_string(et_ar.aliases, ' ')) @@ plainto_tsquery('arabic', p_query)
      -- Arabic muscle search (NEW)
      OR EXISTS (
        SELECT 1
        FROM unnest(ek.primary_muscles || ek.secondary_muscles) muscle_key
        JOIN muscle_translations mt ON mt.muscle_key = muscle_key AND mt.language = 'ar'
        WHERE 
          mt.name ILIKE '%' || p_query || '%'
          OR EXISTS (
            SELECT 1 FROM unnest(mt.aliases) alias
            WHERE alias ILIKE '%' || p_query || '%'
          )
          OR to_tsvector('arabic', mt.name) @@ plainto_tsquery('arabic', p_query)
          OR to_tsvector('arabic', array_to_string(mt.aliases, ' ')) @@ plainto_tsquery('arabic', p_query)
      )
    )
  ORDER BY 
    -- Prioritize exact name matches, then alias matches, then partial matches
    -- Now includes Arabic matches (exercises and muscles)
    CASE 
      -- Exact English name match
      WHEN p_query IS NOT NULL AND ek.name ILIKE p_query THEN 1
      -- Exact Arabic name match
      WHEN p_query IS NOT NULL AND et_ar.name ILIKE p_query THEN 1
      -- English name starts with query
      WHEN p_query IS NOT NULL AND ek.name ILIKE p_query || '%' THEN 2
      -- Arabic name starts with query
      WHEN p_query IS NOT NULL AND et_ar.name ILIKE p_query || '%' THEN 2
      -- English alias exact match
      WHEN p_query IS NOT NULL AND ea.alias ILIKE p_query THEN 3
      -- Arabic alias exact match
      WHEN p_query IS NOT NULL AND EXISTS (
        SELECT 1 FROM unnest(et_ar.aliases) a WHERE a ILIKE p_query
      ) THEN 3
      -- Arabic muscle name exact match (NEW)
      WHEN p_query IS NOT NULL AND EXISTS (
        SELECT 1
        FROM unnest(ek.primary_muscles || ek.secondary_muscles) muscle_key
        JOIN muscle_translations mt ON mt.muscle_key = muscle_key AND mt.language = 'ar'
        WHERE mt.name ILIKE p_query
      ) THEN 3
      -- Partial matches
      WHEN p_query IS NOT NULL AND (
        ek.name ILIKE '%' || p_query || '%' 
        OR ea.alias ILIKE '%' || p_query || '%'
        OR et_ar.name ILIKE '%' || p_query || '%'
        OR EXISTS (
          SELECT 1 FROM unnest(et_ar.aliases) a WHERE a ILIKE '%' || p_query || '%'
        )
        OR EXISTS (
          SELECT 1
          FROM unnest(ek.primary_muscles || ek.secondary_muscles) muscle_key
          JOIN muscle_translations mt ON mt.muscle_key = muscle_key AND mt.language = 'ar'
          WHERE mt.name ILIKE '%' || p_query || '%'
            OR EXISTS (
              SELECT 1 FROM unnest(mt.aliases) alias
              WHERE alias ILIKE '%' || p_query || '%'
            )
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
  RAISE NOTICE '✅ Migration complete: update_search_with_arabic_muscles';
  RAISE NOTICE '   - Updated function: search_exercises_with_aliases';
  RAISE NOTICE '   - Function now includes Arabic muscle translation search';
  RAISE NOTICE '   - Muscle filters now support Arabic names/aliases';
  RAISE NOTICE '   - Full-text search on Arabic muscle names enabled';
  RAISE NOTICE '   - Function maintains backward compatibility';
END $$;
