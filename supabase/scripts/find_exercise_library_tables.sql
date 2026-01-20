-- Table Discovery Helper: Find Exercise Library Tables
-- Purpose: Debug script to discover candidate tables for exercise import
-- Usage: Run this to see what exercise/library tables exist in the database

-- =====================================================
-- Find tables with 'exercise' or 'library' in name
-- =====================================================
SELECT 
  table_schema,
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (
    LOWER(table_name) LIKE '%exercise%' 
    OR LOWER(table_name) LIKE '%library%'
  )
ORDER BY table_name;

-- =====================================================
-- Check specific candidate tables (priority order)
-- =====================================================
SELECT 
  'public.exercises_library' AS candidate_table,
  CASE 
    WHEN to_regclass('public.exercises_library') IS NOT NULL THEN '✅ EXISTS'
    ELSE '❌ NOT FOUND'
  END AS status;

SELECT 
  'public.exercise_library' AS candidate_table,
  CASE 
    WHEN to_regclass('public.exercise_library') IS NOT NULL THEN '✅ EXISTS'
    ELSE '❌ NOT FOUND'
  END AS status;

SELECT 
  'public.exercise_library_items' AS candidate_table,
  CASE 
    WHEN to_regclass('public.exercise_library_items') IS NOT NULL THEN '✅ EXISTS'
    ELSE '❌ NOT FOUND'
  END AS status;

SELECT 
  'public.library_exercises' AS candidate_table,
  CASE 
    WHEN to_regclass('public.library_exercises') IS NOT NULL THEN '✅ EXISTS'
    ELSE '❌ NOT FOUND'
  END AS status;

SELECT 
  'public.exercise_library_data' AS candidate_table,
  CASE 
    WHEN to_regclass('public.exercise_library_data') IS NOT NULL THEN '✅ EXISTS'
    ELSE '❌ NOT FOUND'
  END AS status;

-- =====================================================
-- If a table exists, show its columns
-- =====================================================
DO $$
DECLARE
  table_name TEXT;
  col_record RECORD;
BEGIN
  -- Check each candidate table
  FOR table_name IN 
    SELECT unnest(ARRAY[
      'public.exercises_library',
      'public.exercise_library',
      'public.exercise_library_items',
      'public.library_exercises',
      'public.exercise_library_data'
    ])
  LOOP
    IF to_regclass(table_name) IS NOT NULL THEN
      RAISE NOTICE '========================================';
      RAISE NOTICE 'Table: %', table_name;
      RAISE NOTICE 'Columns:';
      
      FOR col_record IN
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_schema = split_part(table_name, '.', 1)
          AND table_name = split_part(table_name, '.', 2)
        ORDER BY ordinal_position
      LOOP
        RAISE NOTICE '  - % (%%)', col_record.column_name, col_record.data_type, 
          CASE WHEN col_record.is_nullable = 'YES' THEN 'nullable' ELSE 'NOT NULL' END;
      END LOOP;
      
      RAISE NOTICE '========================================';
    END IF;
  END LOOP;
END $$;
