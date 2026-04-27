-- Diagnostic and fix queries for username issue in coach_profiles
-- Run: 2025-10-15

-- 1. Check the coach_profiles table schema
SELECT
  'coach_profiles schema' as query_name,
  column_name,
  data_type,
  is_nullable,
  character_maximum_length
FROM information_schema.columns
WHERE table_name = 'coach_profiles'
ORDER BY ordinal_position;

-- 2. Check if profiles table has username
SELECT
  'profiles username column' as query_name,
  column_name,
  data_type,
  is_nullable,
  character_maximum_length
FROM information_schema.columns
WHERE table_name = 'profiles' AND column_name = 'username';

-- 3. Add username column to coach_profiles if it doesn't exist
ALTER TABLE coach_profiles
ADD COLUMN IF NOT EXISTS username TEXT;

-- 4. Create an index on username for faster lookups
CREATE INDEX IF NOT EXISTS idx_coach_profiles_username ON coach_profiles(username);

-- 5. Update coach_profiles with usernames from profiles
UPDATE coach_profiles cp
SET username = p.username
FROM profiles p
WHERE cp.coach_id = p.id AND cp.username IS NULL;

-- 6. Verify the fix by checking sample rows
SELECT
  'Sample coach_profiles with username' as verification,
  coach_id,
  username,
  display_name,
  created_at
FROM coach_profiles
LIMIT 5;

-- 7. Count records with and without usernames
SELECT
  'Username statistics' as stats,
  COUNT(*) as total_coaches,
  COUNT(username) as with_username,
  COUNT(*) - COUNT(username) as without_username
FROM coach_profiles;
