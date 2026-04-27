-- =====================================================
-- VERIFICATION SCRIPT FOR FULL_NAME MIGRATION
-- Run this after executing 20251002150000_add_full_name_to_profiles.sql
-- =====================================================

\echo '================================================='
\echo 'VERIFYING FULL_NAME COLUMN MIGRATION'
\echo '================================================='
\echo ''

-- =====================================================
-- CHECK 1: Column Existence and Structure
-- =====================================================

\echo 'CHECK 1: Column Structure'
\echo '-------------------------------------------------'

SELECT
  column_name,
  data_type,
  is_nullable,
  column_default,
  character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND column_name IN ('name', 'full_name')
ORDER BY column_name;

\echo ''

-- =====================================================
-- CHECK 2: Indexes on full_name
-- =====================================================

\echo 'CHECK 2: Indexes on full_name Column'
\echo '-------------------------------------------------'

SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'profiles'
  AND indexname LIKE '%full_name%'
ORDER BY indexname;

\echo ''

-- =====================================================
-- CHECK 3: Data Migration Statistics
-- =====================================================

\echo 'CHECK 3: Data Migration Statistics'
\echo '-------------------------------------------------'

SELECT
  COUNT(*) AS total_profiles,
  COUNT(name) AS profiles_with_name,
  COUNT(full_name) AS profiles_with_full_name,
  COUNT(CASE WHEN name IS NOT NULL AND full_name IS NOT NULL THEN 1 END) AS profiles_migrated,
  COUNT(CASE WHEN name IS NULL AND full_name IS NULL THEN 1 END) AS profiles_without_names,
  COUNT(CASE WHEN name IS NOT NULL AND full_name IS NULL THEN 1 END) AS migration_failures
FROM profiles;

\echo ''

-- =====================================================
-- CHECK 4: Sample Data Comparison
-- =====================================================

\echo 'CHECK 4: Sample Data (name vs full_name)'
\echo '-------------------------------------------------'

SELECT
  id,
  COALESCE(name, '(null)') AS name_column,
  COALESCE(full_name, '(null)') AS full_name_column,
  CASE
    WHEN name = full_name THEN '✓ Match'
    WHEN name IS NULL AND full_name IS NULL THEN '○ Both NULL'
    WHEN name IS NOT NULL AND full_name IS NULL THEN '✗ Migration Issue'
    ELSE '? Different'
  END AS migration_status,
  role,
  created_at
FROM profiles
ORDER BY created_at DESC
LIMIT 10;

\echo ''

-- =====================================================
-- CHECK 5: Index Usage Check
-- =====================================================

\echo 'CHECK 5: Index Usage Statistics'
\echo '-------------------------------------------------'

SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan AS index_scans,
  idx_tup_read AS tuples_read,
  idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE tablename = 'profiles'
  AND indexname LIKE '%full_name%';

\echo ''

-- =====================================================
-- CHECK 6: Search Performance Test
-- =====================================================

\echo 'CHECK 6: Search Performance Test'
\echo '-------------------------------------------------'
\echo 'Testing search on full_name column...'

EXPLAIN ANALYZE
SELECT id, full_name, email, role
FROM profiles
WHERE full_name ILIKE '%test%'
LIMIT 10;

\echo ''

-- =====================================================
-- CHECK 7: RLS Policies (ensure they still work)
-- =====================================================

\echo 'CHECK 7: Row Level Security Policies'
\echo '-------------------------------------------------'

SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

\echo ''

-- =====================================================
-- SUMMARY
-- =====================================================

\echo '================================================='
\echo 'VERIFICATION SUMMARY'
\echo '================================================='

DO $$
DECLARE
  col_exists BOOLEAN;
  index_count INTEGER;
  total_profiles INTEGER;
  migrated_count INTEGER;
  failed_count INTEGER;
BEGIN
  -- Check if column exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'full_name'
  ) INTO col_exists;

  -- Count indexes
  SELECT COUNT(*) INTO index_count
  FROM pg_indexes
  WHERE tablename = 'profiles' AND indexname LIKE '%full_name%';

  -- Get migration stats
  SELECT
    COUNT(*),
    COUNT(CASE WHEN name IS NOT NULL AND full_name IS NOT NULL THEN 1 END),
    COUNT(CASE WHEN name IS NOT NULL AND full_name IS NULL THEN 1 END)
  INTO total_profiles, migrated_count, failed_count
  FROM profiles;

  -- Display summary
  RAISE NOTICE '✓ Column exists: %', CASE WHEN col_exists THEN 'YES' ELSE 'NO' END;
  RAISE NOTICE '✓ Indexes created: %', index_count;
  RAISE NOTICE '✓ Total profiles: %', total_profiles;
  RAISE NOTICE '✓ Successfully migrated: %', migrated_count;
  RAISE NOTICE '✓ Migration failures: %', failed_count;

  -- Overall status
  IF col_exists AND index_count > 0 AND failed_count = 0 THEN
    RAISE NOTICE '';
    RAISE NOTICE '=================================================';
    RAISE NOTICE '✓✓✓ MIGRATION SUCCESSFUL! ✓✓✓';
    RAISE NOTICE '=================================================';
  ELSIF failed_count > 0 THEN
    RAISE WARNING 'Migration completed with % failures', failed_count;
  ELSE
    RAISE WARNING 'Migration may have issues. Review checks above.';
  END IF;
END $$;

\echo ''
\echo 'Verification complete!'
\echo ''
