-- Migration: Seed exercise_knowledge from exercises_library (Idempotent)
-- Date: 2025-12-21
-- Purpose: Bulk import exercises from exercises_library into exercise_knowledge
--
-- Mapping:
--   exercises_library.name → exercise_knowledge.name
--   exercises_library.muscle_group → exercise_knowledge.primary_muscles (as array)
--   exercises_library.secondary_muscles → exercise_knowledge.secondary_muscles
--   exercises_library.equipment_needed → exercise_knowledge.equipment
--   exercises_library.difficulty → exercise_knowledge.difficulty
--   exercises_library.description → exercise_knowledge.short_desc (if not null)
--   exercises_library.{image_url, video_url, thumbnail_url} → exercise_knowledge.media (JSONB)
--
-- Rules:
--   - Uses ON CONFLICT to prevent duplicates (idempotent)
--   - Only fills missing fields, preserves existing rich content
--   - Sets source='imported_from_exercises_library', status='approved', language='en'
--   - created_by=NULL (system import)

-- =====================================================
-- INSERT exercises from exercises_library (if table exists)
-- =====================================================
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'exercises_library'
  ) THEN
    -- Table exists, proceed with import
    INSERT INTO public.exercise_knowledge (
  name,
  short_desc,
  primary_muscles,
  secondary_muscles,
  equipment,
  difficulty,
  media,
  source,
  language,
  status,
  created_by
)
SELECT
  el.name,
  -- Generate short_desc from description or muscle_group
  COALESCE(
    el.description,
    CASE 
      WHEN el.muscle_group IS NOT NULL THEN 
        'A ' || 
        CASE 
          WHEN el.is_compound THEN 'compound ' 
          ELSE '' 
        END ||
        'exercise targeting ' || el.muscle_group || 
        CASE 
          WHEN array_length(el.secondary_muscles, 1) > 0 
          THEN ' and ' || array_to_string(el.secondary_muscles[1:LEAST(2, array_length(el.secondary_muscles, 1))], ', ')
          ELSE ''
        END || '.'
      ELSE 'Exercise from library.'
    END
  ) AS short_desc,
  -- Convert single muscle_group to array
  CASE 
    WHEN el.muscle_group IS NOT NULL AND el.muscle_group != '' 
    THEN ARRAY[el.muscle_group]
    ELSE ARRAY[]::TEXT[]
  END AS primary_muscles,
  -- Use secondary_muscles array (already array)
  COALESCE(el.secondary_muscles, ARRAY[]::TEXT[]) AS secondary_muscles,
  -- Use equipment_needed array (already array)
  COALESCE(el.equipment_needed, ARRAY[]::TEXT[]) AS equipment,
  -- Map difficulty (remove CHECK constraint, keep as free text)
  el.difficulty,
  -- Build media JSONB from URLs
  CASE 
    WHEN el.image_url IS NOT NULL OR el.video_url IS NOT NULL OR el.thumbnail_url IS NOT NULL
    THEN jsonb_build_object(
      'image_url', el.image_url,
      'video_url', el.video_url,
      'thumbnail_url', el.thumbnail_url
    )
    ELSE '{}'::jsonb
  END AS media,
  'imported_from_exercises_library' AS source,
  'en' AS language,
  'approved' AS status,
  NULL AS created_by
    FROM public.exercises_library el
    WHERE el.name IS NOT NULL 
      AND el.name != ''
    ON CONFLICT (LOWER(name), language)
    DO UPDATE SET
      -- Only update fields that are NULL or empty in target
      short_desc = COALESCE(
        NULLIF(exercise_knowledge.short_desc, ''),
        EXCLUDED.short_desc
      ),
      primary_muscles = CASE 
        WHEN array_length(exercise_knowledge.primary_muscles, 1) IS NULL 
          OR array_length(exercise_knowledge.primary_muscles, 1) = 0
        THEN EXCLUDED.primary_muscles
        ELSE exercise_knowledge.primary_muscles
      END,
      secondary_muscles = CASE 
        WHEN array_length(exercise_knowledge.secondary_muscles, 1) IS NULL 
          OR array_length(exercise_knowledge.secondary_muscles, 1) = 0
        THEN EXCLUDED.secondary_muscles
        ELSE exercise_knowledge.secondary_muscles
      END,
      equipment = CASE 
        WHEN array_length(exercise_knowledge.equipment, 1) IS NULL 
          OR array_length(exercise_knowledge.equipment, 1) = 0
        THEN EXCLUDED.equipment
        ELSE exercise_knowledge.equipment
      END,
      difficulty = COALESCE(exercise_knowledge.difficulty, EXCLUDED.difficulty),
      media = CASE 
        WHEN exercise_knowledge.media = '{}'::jsonb 
          OR exercise_knowledge.media IS NULL
        THEN EXCLUDED.media
        ELSE exercise_knowledge.media
      END,
      -- Always update source if it's not set
      source = COALESCE(exercise_knowledge.source, EXCLUDED.source),
      -- Update updated_at via trigger
      updated_at = NOW();
    
    RAISE NOTICE '✅ Imported exercises from exercises_library';
  ELSE
    RAISE NOTICE '⚠️  exercises_library table does not exist. Skipping exercise import.';
    RAISE NOTICE '   To import exercises, ensure exercises_library table exists with required columns.';
  END IF;
END $$;

-- =====================================================
-- Verification
-- =====================================================
DO $$
DECLARE
  imported_count INTEGER;
  total_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO imported_count
  FROM public.exercise_knowledge
  WHERE source = 'imported_from_exercises_library';
  
  SELECT COUNT(*) INTO total_count
  FROM public.exercise_knowledge;
  
  RAISE NOTICE '✅ Migration complete: seed_exercise_knowledge_from_library';
  RAISE NOTICE '   - Imported/updated exercises: %', imported_count;
  RAISE NOTICE '   - Total exercises in knowledge base: %', total_count;
END $$;
