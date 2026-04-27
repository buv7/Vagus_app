-- Migration: Auto-Generate Exercise-Intensifier Links (Top 300-500 Exercises)
-- Date: 2025-01-22
-- Purpose: Populate exercise_intensifier_links for top exercises using heuristics
--
-- Rules:
--   - Only approved EN content
--   - Top 300-500 exercises (prefer seed_pack_v1, then by created_at)
--   - 5-8 intensifiers per exercise
--   - Idempotent (ON CONFLICT DO NOTHING)
--   - No deletes, no updates to existing links

-- =====================================================
-- TASK A: Ensure Unique Constraint (Already Exists)
-- =====================================================
-- The table already has UNIQUE(exercise_id, intensifier_id) constraint
-- from 20251221021539_workout_knowledge_base.sql
-- No action needed - constraint is already in place

-- =====================================================
-- TASK B: Build Intensifier Lookup CTE
-- =====================================================
WITH intensifier_lookup AS (
  SELECT 
    id,
    name,
    LOWER(name) AS name_lower,
    fatigue_cost,
    CASE 
      WHEN LOWER(name) LIKE '%rest-pause%' OR LOWER(name) LIKE '%rest pause%' THEN 'rest_pause'
      WHEN LOWER(name) LIKE '%drop set%' OR LOWER(name) LIKE '%dropset%' THEN 'drop_set'
      WHEN LOWER(name) LIKE '%paused rep%' OR LOWER(name) LIKE '%pause rep%' THEN 'paused_reps'
      WHEN LOWER(name) LIKE '%tempo%' THEN 'tempo'
      WHEN LOWER(name) LIKE '%lengthened partial%' OR LOWER(name) LIKE '%partial%' THEN 'lengthened_partials'
      WHEN LOWER(name) LIKE '%1.5 rep%' OR LOWER(name) LIKE '%one and a half%' THEN 'one_and_half_reps'
      WHEN LOWER(name) LIKE '%myo-rep%' OR LOWER(name) LIKE '%myorep%' THEN 'myo_reps'
      WHEN LOWER(name) LIKE '%slow eccentric%' OR LOWER(name) LIKE '%eccentric%' THEN 'slow_eccentric'
      WHEN LOWER(name) LIKE '%cluster%' THEN 'cluster_sets'
      WHEN LOWER(name) LIKE '%back-off%' OR LOWER(name) LIKE '%backoff%' THEN 'back_off_sets'
      WHEN LOWER(name) LIKE '%wave load%' OR LOWER(name) LIKE '%wave%' THEN 'wave_loading'
      WHEN LOWER(name) LIKE '%partial%' AND LOWER(name) NOT LIKE '%lengthened%' THEN 'partials'
      WHEN LOWER(name) LIKE '%iso-hold%' OR LOWER(name) LIKE '%isometric%' OR LOWER(name) LIKE '%hold%' THEN 'iso_holds'
      WHEN LOWER(name) LIKE '%density%' THEN 'density'
      WHEN LOWER(name) LIKE '%emom%' OR LOWER(name) LIKE '%every minute%' THEN 'emom'
      WHEN LOWER(name) LIKE '%isometric%' THEN 'isometrics'
      ELSE NULL
    END AS intensifier_type
  FROM public.intensifier_knowledge
  WHERE status = 'approved' AND language = 'en'
),
-- =====================================================
-- TASK C: Select Top Exercises (300-500)
-- =====================================================
top_exercises AS (
  SELECT 
    id,
    name,
    LOWER(name) AS name_lower,
    movement_pattern,
    equipment,
    primary_muscles,
    secondary_muscles,
    difficulty,
    source,
    -- Classify exercise type
    CASE 
      WHEN equipment && ARRAY['machine', 'cable', 'smith']::TEXT[] 
           OR LOWER(name) LIKE '%curl%'
           OR LOWER(name) LIKE '%extension%'
           OR LOWER(name) LIKE '%raise%'
           OR LOWER(name) LIKE '%fly%'
           OR LOWER(name) LIKE '%isolation%'
      THEN 'isolation_machine'
      WHEN LOWER(name) LIKE '%squat%'
           OR LOWER(name) LIKE '%deadlift%'
           OR LOWER(name) LIKE '%bench%'
           OR LOWER(name) LIKE '%row%'
           OR LOWER(name) LIKE '%press%'
           OR LOWER(name) LIKE '%pull-up%'
           OR LOWER(name) LIKE '%chin-up%'
           OR LOWER(name) LIKE '%lunge%'
      THEN 'compound_freeweight'
      ELSE 'other'
    END AS exercise_type,
    -- Extract movement pattern array
    CASE 
      WHEN movement_pattern IS NOT NULL THEN 
        CASE 
          WHEN movement_pattern::TEXT LIKE '%push%' THEN ARRAY['push']::TEXT[]
          WHEN movement_pattern::TEXT LIKE '%pull%' THEN ARRAY['pull']::TEXT[]
          WHEN movement_pattern::TEXT LIKE '%squat%' THEN ARRAY['squat']::TEXT[]
          WHEN movement_pattern::TEXT LIKE '%hinge%' THEN ARRAY['hinge']::TEXT[]
          WHEN movement_pattern::TEXT LIKE '%carry%' THEN ARRAY['carry']::TEXT[]
          WHEN movement_pattern::TEXT LIKE '%locomotion%' THEN ARRAY['locomotion']::TEXT[]
          WHEN movement_pattern::TEXT LIKE '%rotation%' THEN ARRAY['rotation']::TEXT[]
          WHEN movement_pattern::TEXT LIKE '%core%' THEN ARRAY['core']::TEXT[]
          ELSE ARRAY[]::TEXT[]
        END
      ELSE ARRAY[]::TEXT[]
    END AS movement_patterns
  FROM public.exercise_knowledge
  WHERE status = 'approved' AND language = 'en'
  ORDER BY 
    (source = 'seed_pack_v1') DESC,  -- Prefer seed_pack_v1
    created_at DESC                   -- Then by recency
  LIMIT 500
),
-- =====================================================
-- TASK D: Generate Links Based on Heuristics
-- =====================================================
generated_links AS (
  SELECT DISTINCT
    te.id AS exercise_id,
    il.id AS intensifier_id,
    CASE 
      -- Push compounds: Rest-Pause, Drop Set, Paused Reps, Tempo, Lengthened Partials, 1.5 Reps
      WHEN te.movement_patterns && ARRAY['push']::TEXT[] 
           AND te.exercise_type = 'compound_freeweight'
           AND il.intensifier_type IN ('rest_pause', 'drop_set', 'paused_reps', 'tempo', 'lengthened_partials', 'one_and_half_reps')
      THEN 'push_compound_default'
      
      -- Pull/back: Myo-Reps, Drop Set, Rest-Pause, Lengthened Partials, Slow Eccentric
      WHEN te.movement_patterns && ARRAY['pull']::TEXT[]
           AND il.intensifier_type IN ('myo_reps', 'drop_set', 'rest_pause', 'lengthened_partials', 'slow_eccentric', 'paused_reps')
      THEN 'pull_default'
      
      -- Squat/hinge: Paused Reps, Tempo, Cluster Sets, Back-off Sets, Wave Loading
      WHEN te.movement_patterns && ARRAY['squat', 'hinge']::TEXT[]
           AND il.intensifier_type IN ('paused_reps', 'tempo', 'cluster_sets', 'back_off_sets', 'wave_loading')
      THEN 'squat_hinge_default'
      
      -- Machines/isolation: Myo-Reps, Drop Set, Rest-Pause, Partials, Iso-holds
      WHEN te.exercise_type = 'isolation_machine'
           AND il.intensifier_type IN ('myo_reps', 'drop_set', 'rest_pause', 'partials', 'iso_holds')
      THEN 'machine_isolation_default'
      
      -- Carry/locomotion: Density, EMOM, Tempo
      WHEN te.movement_patterns && ARRAY['carry', 'locomotion']::TEXT[]
           AND il.intensifier_type IN ('density', 'emom', 'tempo')
      THEN 'carry_locomotion_default'
      
      -- Rotation/core: Tempo, Pauses, Isometrics
      WHEN te.movement_patterns && ARRAY['rotation', 'core']::TEXT[]
           AND il.intensifier_type IN ('tempo', 'paused_reps', 'iso_holds', 'isometrics')
      THEN 'rotation_core_default'
      
      -- Fallback: Common intensifiers for any exercise
      WHEN il.intensifier_type IN ('rest_pause', 'drop_set', 'paused_reps', 'tempo', 'myo_reps')
      THEN 'general_default'
      
      ELSE NULL
    END AS notes
  FROM top_exercises te
  CROSS JOIN intensifier_lookup il
  WHERE 
    -- Only include links with valid notes (heuristic matched)
    CASE 
      WHEN te.movement_patterns && ARRAY['push']::TEXT[] 
           AND te.exercise_type = 'compound_freeweight'
           AND il.intensifier_type IN ('rest_pause', 'drop_set', 'paused_reps', 'tempo', 'lengthened_partials', 'one_and_half_reps')
      THEN TRUE
      
      WHEN te.movement_patterns && ARRAY['pull']::TEXT[]
           AND il.intensifier_type IN ('myo_reps', 'drop_set', 'rest_pause', 'lengthened_partials', 'slow_eccentric', 'paused_reps')
      THEN TRUE
      
      WHEN te.movement_patterns && ARRAY['squat', 'hinge']::TEXT[]
           AND il.intensifier_type IN ('paused_reps', 'tempo', 'cluster_sets', 'back_off_sets', 'wave_loading')
      THEN TRUE
      
      WHEN te.exercise_type = 'isolation_machine'
           AND il.intensifier_type IN ('myo_reps', 'drop_set', 'rest_pause', 'partials', 'iso_holds')
      THEN TRUE
      
      WHEN te.movement_patterns && ARRAY['carry', 'locomotion']::TEXT[]
           AND il.intensifier_type IN ('density', 'emom', 'tempo')
      THEN TRUE
      
      WHEN te.movement_patterns && ARRAY['rotation', 'core']::TEXT[]
           AND il.intensifier_type IN ('tempo', 'paused_reps', 'iso_holds', 'isometrics')
      THEN TRUE
      
      WHEN il.intensifier_type IN ('rest_pause', 'drop_set', 'paused_reps', 'tempo', 'myo_reps')
      THEN TRUE
      
      ELSE FALSE
    END
),
-- =====================================================
-- Apply Fatigue Limiting and Ranking
-- =====================================================
ranked_links AS (
  SELECT 
    gl.exercise_id,
    gl.intensifier_id,
    gl.notes,
    il.fatigue_cost,
    te.exercise_type,
    ROW_NUMBER() OVER (
      PARTITION BY gl.exercise_id 
      ORDER BY 
        -- Prioritize by intensifier type priority (specific patterns first)
        CASE gl.notes
          WHEN 'push_compound_default' THEN 1
          WHEN 'pull_default' THEN 1
          WHEN 'squat_hinge_default' THEN 1
          WHEN 'machine_isolation_default' THEN 1
          WHEN 'carry_locomotion_default' THEN 1
          WHEN 'rotation_core_default' THEN 1
          WHEN 'general_default' THEN 2
          ELSE 3
        END,
        -- Then by fatigue cost (low/medium first for compounds)
        CASE 
          WHEN te.exercise_type = 'compound_freeweight' THEN
            CASE il.fatigue_cost
              WHEN 'low' THEN 1
              WHEN 'medium' THEN 2
              WHEN 'high' THEN 3
              ELSE 4
            END
          ELSE
            CASE il.fatigue_cost
              WHEN 'low' THEN 1
              WHEN 'medium' THEN 2
              WHEN 'high' THEN 3
              ELSE 4
            END
        END
    ) AS link_rank,
    -- Count high fatigue items up to this rank
    COUNT(*) FILTER (
      WHERE il.fatigue_cost = 'high' 
    ) OVER (
      PARTITION BY gl.exercise_id 
      ORDER BY 
        CASE gl.notes
          WHEN 'push_compound_default' THEN 1
          WHEN 'pull_default' THEN 1
          WHEN 'squat_hinge_default' THEN 1
          WHEN 'machine_isolation_default' THEN 1
          WHEN 'carry_locomotion_default' THEN 1
          WHEN 'rotation_core_default' THEN 1
          WHEN 'general_default' THEN 2
          ELSE 3
        END,
        CASE 
          WHEN te.exercise_type = 'compound_freeweight' THEN
            CASE il.fatigue_cost
              WHEN 'low' THEN 1
              WHEN 'medium' THEN 2
              WHEN 'high' THEN 3
              ELSE 4
            END
          ELSE
            CASE il.fatigue_cost
              WHEN 'low' THEN 1
              WHEN 'medium' THEN 2
              WHEN 'high' THEN 3
              ELSE 4
            END
        END
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS high_fatigue_count
  FROM generated_links gl
  JOIN intensifier_lookup il ON gl.intensifier_id = il.id
  JOIN top_exercises te ON gl.exercise_id = te.id
  WHERE gl.notes IS NOT NULL
),
-- =====================================================
-- Final Filter: Limit High Fatigue for Compounds
-- =====================================================
final_links AS (
  SELECT 
    rl.exercise_id,
    rl.intensifier_id,
    rl.notes
  FROM ranked_links rl
  WHERE 
    rl.link_rank <= 8  -- Max 8 links per exercise
    AND (
      -- For compound/free-weight: max 2 high fatigue
      (rl.exercise_type = 'compound_freeweight' AND (
        rl.fatigue_cost != 'high' OR rl.high_fatigue_count <= 2
      ))
      OR
      -- For machine/isolation: max 4 high fatigue
      (rl.exercise_type = 'isolation_machine' AND (
        rl.fatigue_cost != 'high' OR rl.high_fatigue_count <= 4
      ))
      OR
      -- For other types: allow all
      rl.exercise_type NOT IN ('compound_freeweight', 'isolation_machine')
    )
)

-- =====================================================
-- INSERT Links (Idempotent)
-- =====================================================
INSERT INTO public.exercise_intensifier_links (
  exercise_id,
  intensifier_id,
  notes
)
SELECT 
  exercise_id,
  intensifier_id,
  notes
FROM final_links
ON CONFLICT (exercise_id, intensifier_id) 
DO NOTHING;

-- =====================================================
-- Verification Queries
-- =====================================================
DO $$
DECLARE
  total_links INTEGER;
  total_exercises INTEGER;
  avg_links_per_exercise NUMERIC;
BEGIN
  -- Total links count
  SELECT COUNT(*) INTO total_links
  FROM public.exercise_intensifier_links;
  
  -- Total exercises with links
  SELECT COUNT(DISTINCT exercise_id) INTO total_exercises
  FROM public.exercise_intensifier_links;
  
  -- Average links per exercise
  SELECT 
    CASE 
      WHEN total_exercises > 0 THEN ROUND(total_links::NUMERIC / total_exercises, 2)
      ELSE 0
    END INTO avg_links_per_exercise;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Migration complete: auto_generate_exercise_intensifier_links';
  RAISE NOTICE '   - Total links created: %', total_links;
  RAISE NOTICE '   - Exercises with links: %', total_exercises;
  RAISE NOTICE '   - Avg links per exercise: %', avg_links_per_exercise;
  RAISE NOTICE '========================================';
END $$;

-- Sample 20 links with exercise name + intensifier name + notes
SELECT 
  ek.name AS exercise_name,
  ik.name AS intensifier_name,
  eil.notes,
  ik.fatigue_cost,
  te.exercise_type
FROM public.exercise_intensifier_links eil
JOIN public.exercise_knowledge ek ON eil.exercise_id = ek.id
JOIN public.intensifier_knowledge ik ON eil.intensifier_id = ik.id
LEFT JOIN (
  SELECT 
    id,
    CASE 
      WHEN equipment && ARRAY['machine', 'cable', 'smith']::TEXT[] 
           OR LOWER(name) LIKE '%curl%'
           OR LOWER(name) LIKE '%extension%'
           OR LOWER(name) LIKE '%raise%'
           OR LOWER(name) LIKE '%fly%'
      THEN 'isolation_machine'
      WHEN LOWER(name) LIKE '%squat%'
           OR LOWER(name) LIKE '%deadlift%'
           OR LOWER(name) LIKE '%bench%'
           OR LOWER(name) LIKE '%row%'
           OR LOWER(name) LIKE '%press%'
      THEN 'compound_freeweight'
      ELSE 'other'
    END AS exercise_type
  FROM public.exercise_knowledge
) te ON eil.exercise_id = te.id
WHERE ek.status = 'approved' AND ek.language = 'en'
  AND ik.status = 'approved' AND ik.language = 'en'
ORDER BY eil.created_at DESC
LIMIT 20;
