-- Migration: RPC Function to Regenerate Exercise-Intensifier Links
-- Date: 2025-01-22
-- Purpose: Admin-only RPC function to regenerate exercise_intensifier_links
--
-- Rules:
--   - Admin-only (enforced in SQL)
--   - Uses same heuristics as migration
--   - Idempotent (ON CONFLICT DO NOTHING)
--   - No deletes, no updates to existing links
--   - Returns JSON with statistics

-- =====================================================
-- CREATE OR REPLACE FUNCTION
-- =====================================================
CREATE OR REPLACE FUNCTION public.regenerate_exercise_intensifier_links(
  p_limit int DEFAULT 500
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_is_admin boolean;
  v_inserted_count int;
  v_exercises_considered int;
  v_exercises_with_new_links int;
  v_result jsonb;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'not authorized: user not authenticated';
  END IF;
  
  -- Check if user is admin
  SELECT EXISTS (
    SELECT 1 
    FROM public.profiles 
    WHERE id = v_user_id 
      AND role IN ('admin', 'superadmin')
  ) INTO v_is_admin;
  
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'not authorized: admin access required';
  END IF;
  
  -- Validate limit
  IF p_limit < 1 OR p_limit > 1000 THEN
    RAISE EXCEPTION 'invalid limit: must be between 1 and 1000';
  END IF;
  
  -- Execute the same logic as the migration
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
      (source = 'seed_pack_v1') DESC,
      created_at DESC
    LIMIT p_limit
  ),
  generated_links AS (
    SELECT DISTINCT
      te.id AS exercise_id,
      il.id AS intensifier_id,
      CASE 
        WHEN te.movement_patterns && ARRAY['push']::TEXT[] 
             AND te.exercise_type = 'compound_freeweight'
             AND il.intensifier_type IN ('rest_pause', 'drop_set', 'paused_reps', 'tempo', 'lengthened_partials', 'one_and_half_reps')
        THEN 'push_compound_default'
        
        WHEN te.movement_patterns && ARRAY['pull']::TEXT[]
             AND il.intensifier_type IN ('myo_reps', 'drop_set', 'rest_pause', 'lengthened_partials', 'slow_eccentric', 'paused_reps')
        THEN 'pull_default'
        
        WHEN te.movement_patterns && ARRAY['squat', 'hinge']::TEXT[]
             AND il.intensifier_type IN ('paused_reps', 'tempo', 'cluster_sets', 'back_off_sets', 'wave_loading')
        THEN 'squat_hinge_default'
        
        WHEN te.exercise_type = 'isolation_machine'
             AND il.intensifier_type IN ('myo_reps', 'drop_set', 'rest_pause', 'partials', 'iso_holds')
        THEN 'machine_isolation_default'
        
        WHEN te.movement_patterns && ARRAY['carry', 'locomotion']::TEXT[]
             AND il.intensifier_type IN ('density', 'emom', 'tempo')
        THEN 'carry_locomotion_default'
        
        WHEN te.movement_patterns && ARRAY['rotation', 'core']::TEXT[]
             AND il.intensifier_type IN ('tempo', 'paused_reps', 'iso_holds', 'isometrics')
        THEN 'rotation_core_default'
        
        WHEN il.intensifier_type IN ('rest_pause', 'drop_set', 'paused_reps', 'tempo', 'myo_reps')
        THEN 'general_default'
        
        ELSE NULL
      END AS notes
    FROM top_exercises te
    CROSS JOIN intensifier_lookup il
    WHERE 
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
      ) AS link_rank,
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
  final_links AS (
    SELECT 
      rl.exercise_id,
      rl.intensifier_id,
      rl.notes
    FROM ranked_links rl
    WHERE 
      rl.link_rank <= 8
      AND (
        (rl.exercise_type = 'compound_freeweight' AND (
          rl.fatigue_cost != 'high' OR rl.high_fatigue_count <= 2
        ))
        OR
        (rl.exercise_type = 'isolation_machine' AND (
          rl.fatigue_cost != 'high' OR rl.high_fatigue_count <= 4
        ))
        OR
        rl.exercise_type NOT IN ('compound_freeweight', 'isolation_machine')
      )
  )
  -- Store final_links in temp table so we can use it after WITH clause
  CREATE TEMP TABLE IF NOT EXISTS temp_final_links (
    exercise_id uuid,
    intensifier_id uuid,
    notes text
  ) ON COMMIT DROP;
  
  CREATE TEMP TABLE IF NOT EXISTS temp_inserted_links (
    exercise_id uuid,
    intensifier_id uuid
  ) ON COMMIT DROP;
  
  TRUNCATE TABLE temp_final_links;
  TRUNCATE TABLE temp_inserted_links;
  
  -- Store final_links in temp table
  INSERT INTO temp_final_links (exercise_id, intensifier_id, notes)
  SELECT exercise_id, intensifier_id, notes
  FROM final_links;
  
  -- Get exercises considered count
  SELECT COUNT(*) INTO v_exercises_considered
  FROM (
    SELECT id
    FROM public.exercise_knowledge
    WHERE status = 'approved' AND language = 'en'
    ORDER BY 
      (source = 'seed_pack_v1') DESC,
      created_at DESC
    LIMIT p_limit
  ) te;
  
  -- Insert links and capture inserted rows
  INSERT INTO temp_inserted_links (exercise_id, intensifier_id)
  SELECT 
    exercise_id,
    intensifier_id
  FROM (
    INSERT INTO public.exercise_intensifier_links (
      exercise_id,
      intensifier_id,
      notes
    )
    SELECT 
      exercise_id,
      intensifier_id,
      notes
    FROM temp_final_links
    ON CONFLICT (exercise_id, intensifier_id) 
    DO NOTHING
    RETURNING exercise_id, intensifier_id
  ) inserted;
  
  -- Get counts
  SELECT COUNT(*) INTO v_inserted_count
  FROM temp_inserted_links;
  
  SELECT COUNT(DISTINCT exercise_id) INTO v_exercises_with_new_links
  FROM temp_inserted_links;
  
  -- Build result JSON
  v_result := jsonb_build_object(
    'requested_limit', p_limit,
    'inserted_links', v_inserted_count,
    'exercises_considered', v_exercises_considered,
    'exercises_with_new_links', v_exercises_with_new_links
  );
  
  RETURN v_result;
END;
$$;

-- =====================================================
-- GRANT EXECUTE
-- =====================================================
GRANT EXECUTE ON FUNCTION public.regenerate_exercise_intensifier_links(int) TO authenticated;

-- =====================================================
-- COMMENT
-- =====================================================
COMMENT ON FUNCTION public.regenerate_exercise_intensifier_links(int) IS 
'Admin-only function to regenerate exercise-intensifier links using heuristics. Returns JSON with statistics.';
