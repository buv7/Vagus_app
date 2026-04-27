-- Verification Queries for Knowledge Base Seed
-- Run this after all seed migrations to verify data

-- =====================================================
-- 1. Exercise Knowledge Counts
-- =====================================================
SELECT 
  'exercise_knowledge' AS table_name,
  COUNT(*) AS total_count,
  COUNT(*) FILTER (WHERE source = 'imported_from_exercises_library') AS imported_count,
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
  COUNT(*) FILTER (WHERE language = 'en') AS english_count
FROM public.intensifier_knowledge;

-- =====================================================
-- 3. Exercise-Intensifier Links Count
-- =====================================================
SELECT 
  'exercise_intensifier_links' AS table_name,
  COUNT(*) AS total_links
FROM public.exercise_intensifier_links;

-- =====================================================
-- 4. Sample Exercises (10 rows)
-- =====================================================
SELECT 
  name,
  short_desc,
  primary_muscles,
  equipment,
  difficulty,
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
-- 6. Check for Duplicates (should be 0)
-- =====================================================
SELECT 
  LOWER(name) AS name_lower,
  language,
  COUNT(*) AS count
FROM public.exercise_knowledge
GROUP BY LOWER(name), language
HAVING COUNT(*) > 1;

SELECT 
  LOWER(name) AS name_lower,
  language,
  COUNT(*) AS count
FROM public.intensifier_knowledge
GROUP BY LOWER(name), language
HAVING COUNT(*) > 1;

-- =====================================================
-- 7. Exercises with Media
-- =====================================================
SELECT 
  COUNT(*) AS exercises_with_media
FROM public.exercise_knowledge
WHERE media != '{}'::jsonb 
  AND media IS NOT NULL;

-- =====================================================
-- 8. Intensifiers with JSON Rules
-- =====================================================
SELECT 
  COUNT(*) AS intensifiers_with_rules
FROM public.intensifier_knowledge
WHERE intensity_rules != '{}'::jsonb 
  AND intensity_rules IS NOT NULL;
