-- Migration: Auto-detect and Import Exercises from Library Table (Idempotent)
-- Date: 2025-12-21
-- Purpose: Automatically detect and import exercises from various possible library table names
--
-- Behavior:
--   - Searches for tables in priority order: exercises_library, exercise_library, etc.
--   - Auto-detects column names (name/exercise_name/title, muscle_group/primary_muscle, etc.)
--   - Maps to exercise_knowledge with smart defaults
--   - Idempotent: only fills missing fields

-- =====================================================
-- Find source table and detect columns
-- =====================================================
DO $$
DECLARE
  source_table TEXT;
  name_col TEXT;
  muscle_col TEXT;
  equipment_col TEXT;
  desc_col TEXT;
  difficulty_col TEXT;
  image_col TEXT;
  video_col TEXT;
  secondary_muscles_col TEXT;
  is_compound_col TEXT;
  sql_stmt TEXT;
  table_schema_name TEXT;
  table_name_only TEXT;
BEGIN
  -- Priority list of candidate tables
  FOR source_table IN 
    SELECT unnest(ARRAY[
      'public.exercises_library',
      'public.exercise_library',
      'public.exercise_library_items',
      'public.library_exercises',
      'public.exercise_library_data'
    ])
  LOOP
    IF to_regclass(source_table) IS NOT NULL THEN
      RAISE NOTICE '✅ Found source table: %', source_table;
      
      -- Extract schema and table name
      table_schema_name := split_part(source_table, '.', 1);
      table_name_only := split_part(source_table, '.', 2);
      
      -- Detect name column (priority: name, exercise_name, title)
      SELECT column_name INTO name_col
      FROM information_schema.columns
      WHERE table_schema = table_schema_name
        AND table_name = table_name_only
        AND column_name IN ('name', 'exercise_name', 'title')
      ORDER BY CASE column_name
        WHEN 'name' THEN 1
        WHEN 'exercise_name' THEN 2
        WHEN 'title' THEN 3
      END
      LIMIT 1;
      
      -- Detect muscle column (priority: muscle_group, primary_muscle, primary_muscles)
      SELECT column_name INTO muscle_col
      FROM information_schema.columns
      WHERE table_schema = table_schema_name
        AND table_name = table_name_only
        AND column_name IN ('muscle_group', 'primary_muscle', 'primary_muscles', 'muscle_groups')
      ORDER BY CASE column_name
        WHEN 'muscle_group' THEN 1
        WHEN 'primary_muscle' THEN 2
        WHEN 'primary_muscles' THEN 3
        WHEN 'muscle_groups' THEN 4
      END
      LIMIT 1;
      
      -- Detect equipment column (priority: equipment_needed, equipment, equipment_list)
      SELECT column_name INTO equipment_col
      FROM information_schema.columns
      WHERE table_schema = table_schema_name
        AND table_name = table_name_only
        AND column_name IN ('equipment_needed', 'equipment', 'equipment_list', 'equipment_required')
      ORDER BY CASE column_name
        WHEN 'equipment_needed' THEN 1
        WHEN 'equipment' THEN 2
        WHEN 'equipment_list' THEN 3
        WHEN 'equipment_required' THEN 4
      END
      LIMIT 1;
      
      -- Detect description column
      SELECT column_name INTO desc_col
      FROM information_schema.columns
      WHERE table_schema = table_schema_name
        AND table_name = table_name_only
        AND column_name IN ('description', 'desc', 'instructions', 'short_desc')
      ORDER BY CASE column_name
        WHEN 'description' THEN 1
        WHEN 'desc' THEN 2
        WHEN 'instructions' THEN 3
        WHEN 'short_desc' THEN 4
      END
      LIMIT 1;
      
      -- Detect difficulty column
      SELECT column_name INTO difficulty_col
      FROM information_schema.columns
      WHERE table_schema = table_schema_name
        AND table_name = table_name_only
        AND column_name IN ('difficulty', 'difficulty_level', 'level')
      LIMIT 1;
      
      -- Detect image/video columns
      SELECT column_name INTO image_col
      FROM information_schema.columns
      WHERE table_schema = table_schema_name
        AND table_name = table_name_only
        AND column_name IN ('image_url', 'image', 'thumbnail_url', 'thumbnail')
      LIMIT 1;
      
      SELECT column_name INTO video_col
      FROM information_schema.columns
      WHERE table_schema = table_schema_name
        AND table_name = table_name_only
        AND column_name IN ('video_url', 'video')
      LIMIT 1;
      
      -- Detect secondary_muscles column
      SELECT column_name INTO secondary_muscles_col
      FROM information_schema.columns
      WHERE table_schema = table_schema_name
        AND table_name = table_name_only
        AND column_name IN ('secondary_muscles', 'secondary_muscle_groups', 'secondary')
      LIMIT 1;
      
      -- Detect is_compound column
      SELECT column_name INTO is_compound_col
      FROM information_schema.columns
      WHERE table_schema = table_schema_name
        AND table_name = table_name_only
        AND column_name IN ('is_compound', 'compound', 'type')
      LIMIT 1;
      
      -- Validate required columns
      IF name_col IS NULL THEN
        RAISE NOTICE '⚠️  No name column found in %. Skipping.', source_table;
        CONTINUE;
      END IF;
      
      RAISE NOTICE '   Detected columns:';
      RAISE NOTICE '     name: %', COALESCE(name_col, 'NOT FOUND');
      RAISE NOTICE '     muscle: %', COALESCE(muscle_col, 'NOT FOUND');
      RAISE NOTICE '     equipment: %', COALESCE(equipment_col, 'NOT FOUND');
      RAISE NOTICE '     description: %', COALESCE(desc_col, 'NOT FOUND');
      
      -- Build dynamic INSERT statement
      sql_stmt := format('
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
          %I AS name,
          COALESCE(
            %s,
            CASE 
              WHEN %s IS NOT NULL THEN 
                ''A '' || 
                CASE 
                  WHEN %s = true THEN ''compound ''
                  WHEN %s = ''compound'' THEN ''compound ''
                  ELSE ''''
                END ||
                ''exercise targeting '' || %s || 
                CASE 
                  WHEN %s IS NOT NULL AND array_length(%s, 1) > 0 
                  THEN '' and '' || array_to_string(%s[1:LEAST(2, array_length(%s, 1))], '', '')
                  ELSE ''''
                END || ''.''
              ELSE ''Exercise from library.''
            END
          ) AS short_desc,
          CASE 
            WHEN %s IS NOT NULL AND %s != '''' THEN 
              CASE 
                WHEN pg_typeof(%s)::text LIKE ''%%[]'' THEN %s
                ELSE ARRAY[%s::text]
              END
            ELSE ARRAY[]::TEXT[]
          END AS primary_muscles,
          CASE 
            WHEN %s IS NOT NULL THEN 
              CASE 
                WHEN pg_typeof(%s)::text LIKE ''%%[]'' THEN %s
                ELSE ARRAY[%s::text]
              END
            ELSE ARRAY[]::TEXT[]
          END AS secondary_muscles,
          CASE 
            WHEN %s IS NOT NULL THEN 
              CASE 
                WHEN pg_typeof(%s)::text LIKE ''%%[]'' THEN %s
                ELSE ARRAY[]::TEXT[]
              END
            ELSE ARRAY[]::TEXT[]
          END AS equipment,
          %s AS difficulty,
          CASE 
            WHEN %s IS NOT NULL OR %s IS NOT NULL THEN
              jsonb_build_object(
                ''image_url'', %s,
                ''video_url'', %s
              )
            ELSE ''{}''::jsonb
          END AS media,
          ''imported_from_library_autodetect'' AS source,
          ''en'' AS language,
          ''approved'' AS status,
          NULL AS created_by
        FROM %s el
        WHERE %I IS NOT NULL 
          AND %I != ''''
        ON CONFLICT (LOWER(name), language)
        DO UPDATE SET
          short_desc = COALESCE(
            NULLIF(exercise_knowledge.short_desc, ''''),
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
            WHEN exercise_knowledge.media = ''{}''::jsonb 
              OR exercise_knowledge.media IS NULL
            THEN EXCLUDED.media
            ELSE exercise_knowledge.media
          END,
          source = COALESCE(exercise_knowledge.source, EXCLUDED.source),
          updated_at = NOW()',
        -- Parameters for format()
        name_col,
        COALESCE('el.' || desc_col, 'NULL'),
        COALESCE('el.' || muscle_col, 'NULL'),
        COALESCE('el.' || is_compound_col, 'NULL'),
        COALESCE('el.' || is_compound_col, 'NULL'),
        COALESCE('el.' || muscle_col, 'NULL'),
        COALESCE('el.' || secondary_muscles_col, 'NULL'),
        COALESCE('el.' || secondary_muscles_col, 'NULL'),
        COALESCE('el.' || secondary_muscles_col, 'NULL'),
        COALESCE('el.' || secondary_muscles_col, 'NULL'),
        COALESCE('el.' || muscle_col, 'NULL'),
        COALESCE('el.' || muscle_col, 'NULL'),
        COALESCE('el.' || muscle_col, 'NULL'),
        COALESCE('el.' || muscle_col, 'NULL'),
        COALESCE('el.' || muscle_col, 'NULL'),
        COALESCE('el.' || secondary_muscles_col, 'NULL'),
        COALESCE('el.' || secondary_muscles_col, 'NULL'),
        COALESCE('el.' || secondary_muscles_col, 'NULL'),
        COALESCE('el.' || secondary_muscles_col, 'NULL'),
        COALESCE('el.' || equipment_col, 'NULL'),
        COALESCE('el.' || equipment_col, 'NULL'),
        COALESCE('el.' || equipment_col, 'NULL'),
        COALESCE('el.' || equipment_col, 'NULL'),
        COALESCE('el.' || difficulty_col, 'NULL'),
        COALESCE('el.' || image_col, 'NULL'),
        COALESCE('el.' || video_col, 'NULL'),
        COALESCE('el.' || image_col, 'NULL'),
        COALESCE('el.' || video_col, 'NULL'),
        source_table,
        name_col,
        name_col
      );
      
      -- Execute the INSERT
      BEGIN
        EXECUTE sql_stmt;
        RAISE NOTICE '✅ Successfully imported exercises from %', source_table;
        EXIT; -- Exit loop after first successful import
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Error importing from %: %', source_table, SQLERRM;
        -- Continue to next table
      END;
    END IF;
  END LOOP;
  
  IF source_table IS NULL THEN
    RAISE NOTICE '⚠️  No exercise library table found. Skipping import.';
    RAISE NOTICE '   Searched for: exercises_library, exercise_library, exercise_library_items, library_exercises, exercise_library_data';
  END IF;
END $$;

-- =====================================================
-- Verification
-- =====================================================
DO $$
DECLARE
  imported_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO imported_count
  FROM public.exercise_knowledge
  WHERE source = 'imported_from_library_autodetect';
  
  RAISE NOTICE '✅ Migration complete: seed_exercise_knowledge_autodetect';
  RAISE NOTICE '   - Imported exercises: %', imported_count;
END $$;
