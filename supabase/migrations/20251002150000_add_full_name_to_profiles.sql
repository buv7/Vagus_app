-- =====================================================
-- ADD FULL_NAME COLUMN TO PROFILES TABLE
-- Migration to add full_name column and migrate existing data
-- Created: 2025-10-02
-- =====================================================

BEGIN;

-- =====================================================
-- PART 1: ADD FULL_NAME COLUMN
-- =====================================================

-- Add full_name column to profiles table
-- Set as nullable since existing records won't have it initially
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS full_name TEXT;

-- Add comment for documentation
COMMENT ON COLUMN profiles.full_name IS 'Full name of the user. Separate from email display name, allows for proper name storage.';

-- =====================================================
-- PART 2: MIGRATE EXISTING DATA
-- =====================================================

-- Copy data from 'name' column to 'full_name' for existing records
-- This preserves any existing name data
UPDATE profiles
SET full_name = name
WHERE full_name IS NULL AND name IS NOT NULL;

-- =====================================================
-- PART 3: ADD INDEX FOR SEARCHING
-- =====================================================

-- Add index on full_name for efficient searching
-- Using GIN index with pg_trgm for fuzzy search support (if extension available)
-- Otherwise, falls back to B-tree index
DO $$
BEGIN
  -- Try to create trigram index if pg_trgm extension is available
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') THEN
    CREATE INDEX IF NOT EXISTS idx_profiles_full_name_trgm
    ON profiles USING gin (full_name gin_trgm_ops);
  ELSE
    -- Fall back to standard B-tree index for pattern matching
    CREATE INDEX IF NOT EXISTS idx_profiles_full_name
    ON profiles(full_name);

    -- Also add a lowercase index for case-insensitive search
    CREATE INDEX IF NOT EXISTS idx_profiles_full_name_lower
    ON profiles(LOWER(full_name));
  END IF;
END $$;

-- =====================================================
-- PART 4: VERIFICATION AND REPORTING
-- =====================================================

-- Report on the migration status
DO $$
DECLARE
  total_profiles INTEGER;
  profiles_with_name INTEGER;
  profiles_with_full_name INTEGER;
  profiles_migrated INTEGER;
BEGIN
  -- Count total profiles
  SELECT COUNT(*) INTO total_profiles FROM profiles;

  -- Count profiles with 'name'
  SELECT COUNT(*) INTO profiles_with_name
  FROM profiles WHERE name IS NOT NULL;

  -- Count profiles with 'full_name'
  SELECT COUNT(*) INTO profiles_with_full_name
  FROM profiles WHERE full_name IS NOT NULL;

  -- Count profiles where we migrated data
  SELECT COUNT(*) INTO profiles_migrated
  FROM profiles WHERE full_name IS NOT NULL AND name IS NOT NULL;

  -- Report results
  RAISE NOTICE '=================================================';
  RAISE NOTICE 'PROFILES TABLE - FULL_NAME MIGRATION REPORT';
  RAISE NOTICE '=================================================';
  RAISE NOTICE 'Total profiles: %', total_profiles;
  RAISE NOTICE 'Profiles with name column: %', profiles_with_name;
  RAISE NOTICE 'Profiles with full_name column: %', profiles_with_full_name;
  RAISE NOTICE 'Profiles migrated (name -> full_name): %', profiles_migrated;
  RAISE NOTICE '=================================================';
END $$;

COMMIT;

-- =====================================================
-- POST-MIGRATION VERIFICATION QUERIES
-- =====================================================

-- Verify column exists
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
  AND column_name = 'full_name';

-- Check indexes created
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'profiles'
  AND indexname LIKE '%full_name%';

-- Sample data check (first 5 records)
SELECT
  id,
  name,
  full_name,
  email,
  role
FROM profiles
LIMIT 5;

SELECT '✓ Full_name column migration completed successfully!' AS status;
