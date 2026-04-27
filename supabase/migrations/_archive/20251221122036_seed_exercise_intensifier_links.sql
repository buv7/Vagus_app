-- Migration: Seed Starter Exercise-Intensifier Links (Optional, Light)
-- Date: 2025-12-21
-- Purpose: Create initial links between common exercises and applicable intensifiers
--
-- Links:
--   - Bench press → rest-pause, drop set, paused reps
--   - Squat → paused reps, tempo, cluster
--   - Lat pulldown → myo-reps, drop set
--
-- Rules:
--   - Uses ON CONFLICT to prevent duplicates (idempotent)
--   - Only creates links if both exercise and intensifier exist
--   - Minimal set (20-50 links)

-- =====================================================
-- INSERT exercise-intensifier links
-- =====================================================
INSERT INTO public.exercise_intensifier_links (
  exercise_id,
  intensifier_id,
  notes
)
SELECT 
  ek.id AS exercise_id,
  ik.id AS intensifier_id,
  CASE 
    WHEN ik.name = 'Rest-Pause' THEN 'Excellent for strength and volume accumulation'
    WHEN ik.name = 'Drop Set' THEN 'Great for hypertrophy and finishing sets'
    WHEN ik.name = 'Paused Reps' THEN 'Improves strength and technique at bottom position'
    WHEN ik.name = 'Tempo Sets' THEN 'Enhances time under tension and control'
    WHEN ik.name = 'Cluster Sets' THEN 'Allows higher volume with heavy loads'
    WHEN ik.name = 'Myo-Reps' THEN 'Efficient for hypertrophy and muscle pump'
    ELSE 'Commonly used combination'
  END AS notes
FROM public.exercise_knowledge ek
CROSS JOIN public.intensifier_knowledge ik
WHERE 
  -- Bench Press links
  (
    LOWER(ek.name) IN ('bench press', 'barbell bench press', 'flat bench press', 'chest press')
    AND LOWER(ik.name) IN ('rest-pause', 'drop set', 'paused reps', 'tempo sets')
  )
  OR
  -- Squat links
  (
    LOWER(ek.name) IN ('squat', 'barbell squat', 'back squat', 'front squat')
    AND LOWER(ik.name) IN ('paused reps', 'tempo sets', 'cluster sets', 'slow eccentrics')
  )
  OR
  -- Lat Pulldown links
  (
    LOWER(ek.name) IN ('lat pulldown', 'lat pull down', 'pull down', 'cable pulldown')
    AND LOWER(ik.name) IN ('myo-reps', 'drop set', 'rest-pause')
  )
  OR
  -- Deadlift links
  (
    LOWER(ek.name) IN ('deadlift', 'barbell deadlift', 'conventional deadlift')
    AND LOWER(ik.name) IN ('paused reps', 'tempo sets', 'cluster sets')
  )
  OR
  -- Shoulder Press links
  (
    LOWER(ek.name) IN ('shoulder press', 'overhead press', 'military press', 'ohp')
    AND LOWER(ik.name) IN ('rest-pause', 'drop set', 'paused reps')
  )
  OR
  -- Row links
  (
    LOWER(ek.name) IN ('barbell row', 'row', 'bent over row', 'pendlay row')
    AND LOWER(ik.name) IN ('rest-pause', 'myo-reps', 'tempo sets')
  )
  OR
  -- Bicep Curl links
  (
    LOWER(ek.name) IN ('bicep curl', 'barbell curl', 'dumbbell curl', 'curl')
    AND LOWER(ik.name) IN ('drop set', 'myo-reps', 'rest-pause', 'cheat reps (controlled)')
  )
  OR
  -- Tricep Extension links
  (
    LOWER(ek.name) IN ('tricep extension', 'tricep pushdown', 'tricep extension', 'overhead extension')
    AND LOWER(ik.name) IN ('drop set', 'myo-reps', 'rest-pause')
  )
  OR
  -- Leg Press links
  (
    LOWER(ek.name) IN ('leg press', 'leg press machine')
    AND LOWER(ik.name) IN ('rest-pause', 'drop set', 'cluster sets')
  )
  OR
  -- Leg Extension links
  (
    LOWER(ek.name) IN ('leg extension', 'quad extension')
    AND LOWER(ik.name) IN ('myo-reps', 'drop set', 'pre-exhaust')
  )
ON CONFLICT (exercise_id, intensifier_id) 
DO NOTHING;

-- =====================================================
-- Verification
-- =====================================================
DO $$
DECLARE
  link_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO link_count
  FROM public.exercise_intensifier_links;
  
  RAISE NOTICE '✅ Migration complete: seed_exercise_intensifier_links';
  RAISE NOTICE '   - Created links: %', link_count;
END $$;
