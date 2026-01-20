-- Verification Queries for Expanded Knowledge Base Seed
-- Run this after all seed migrations to verify data

-- =====================================================
-- 1. Exercise Knowledge Counts (by source)
-- =====================================================
SELECT 
  'exercise_knowledge' AS table_name,
  COUNT(*) AS total_count,
  COUNT(*) FILTER (WHERE source = 'imported_from_exercises_library') AS from_library_old,
  COUNT(*) FILTER (WHERE source = 'imported_from_library_autodetect') AS from_autodetect,
  COUNT(*) FILTER (WHERE status = 'approved') AS approved_count,
  COUNT(*) FILTER (WHERE language = 'en') AS english_count
FROM public.exercise_knowledge;

-- =====================================================
-- 2. Intensifier Knowledge Counts
-- =====================================================
SELECT 
  'intensifier_knowledge' AS table_name,
  COUNT(*) AS total_count,
  COUNT(*) FILTER (WHERE status = 'approved') AS approved_count,
  COUNT(*) FILTER (WHERE language = 'en') AS english_count,
  COUNT(*) FILTER (WHERE intensity_rules != '{}'::jsonb) AS with_rules_count
FROM public.intensifier_knowledge;

-- =====================================================
-- 3. Exercise-Intensifier Links Count
-- =====================================================
SELECT 
  'exercise_intensifier_links' AS table_name,
  COUNT(*) AS total_links,
  COUNT(DISTINCT exercise_id) AS unique_exercises,
  COUNT(DISTINCT intensifier_id) AS unique_intensifiers
FROM public.exercise_intensifier_links;

-- =====================================================
-- 4. Sample Exercises (10 rows)
-- =====================================================
SELECT 
  name,
  short_desc,
  primary_muscles,
  equipment,
  source,
  status
FROM public.exercise_knowledge
WHERE status = 'approved'
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- 5. Sample Intensifiers (10 rows)
-- =====================================================
SELECT 
  name,
  short_desc,
  fatigue_cost,
  best_for,
  status
FROM public.intensifier_knowledge
WHERE status = 'approved'
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- 6. Intensifier Categories (by fatigue_cost)
-- =====================================================
SELECT 
  fatigue_cost,
  COUNT(*) AS count
FROM public.intensifier_knowledge
WHERE status = 'approved' AND language = 'en'
GROUP BY fatigue_cost
ORDER BY 
  CASE fatigue_cost
    WHEN 'low' THEN 1
    WHEN 'medium' THEN 2
    WHEN 'high' THEN 3
    WHEN 'very_high' THEN 4
    ELSE 5
  END;

-- =====================================================
-- 7. Intensifier Categories (by best_for tags)
-- =====================================================
SELECT 
  unnest(best_for) AS tag,
  COUNT(*) AS count
FROM public.intensifier_knowledge
WHERE status = 'approved' AND language = 'en'
GROUP BY tag
ORDER BY count DESC
LIMIT 20;

-- =====================================================
-- 8. Check for Duplicates (should be 0)
-- =====================================================
SELECT 
  'exercise_knowledge duplicates' AS check_type,
  COUNT(*) AS duplicate_count
FROM (
  SELECT 
    LOWER(name) AS name_lower,
    language,
    COUNT(*) AS count
  FROM public.exercise_knowledge
  GROUP BY LOWER(name), language
  HAVING COUNT(*) > 1
) duplicates;

SELECT 
  'intensifier_knowledge duplicates' AS check_type,
  COUNT(*) AS duplicate_count
FROM (
  SELECT 
    LOWER(name) AS name_lower,
    language,
    COUNT(*) AS count
  FROM public.intensifier_knowledge
  GROUP BY LOWER(name), language
  HAVING COUNT(*) > 1
) duplicates;

-- =====================================================
-- 9. Exercises with Media
-- =====================================================
SELECT 
  COUNT(*) AS exercises_with_media,
  COUNT(*) FILTER (WHERE media->>'image_url' IS NOT NULL) AS with_images,
  COUNT(*) FILTER (WHERE media->>'video_url' IS NOT NULL) AS with_videos
FROM public.exercise_knowledge
WHERE media != '{}'::jsonb 
  AND media IS NOT NULL;

-- =====================================================
-- 10. Intensifiers with JSON Rules
-- =====================================================
SELECT 
  COUNT(*) AS intensifiers_with_rules,
  COUNT(*) FILTER (WHERE intensity_rules != '{}'::jsonb) AS with_non_empty_rules
FROM public.intensifier_knowledge
WHERE intensity_rules IS NOT NULL;
