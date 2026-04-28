-- Workout Schema Testing Script
-- Run with: psql -h localhost -U postgres -d vagus -f test_workout_schema.sql

\echo '==================================='
\echo 'WORKOUT SCHEMA TESTING'
\echo '==================================='
\echo ''

-- ====================
-- Part 1: Schema Verification
-- ====================

\echo '1. Verifying tables exist...'
SELECT EXISTS (
  SELECT FROM information_schema.tables
  WHERE table_name = 'workout_plans'
) AS workout_plans_exists;

SELECT EXISTS (
  SELECT FROM information_schema.tables
  WHERE table_name = 'workout_weeks'
) AS workout_weeks_exists;

SELECT EXISTS (
  SELECT FROM information_schema.tables
  WHERE table_name = 'workout_days'
) AS workout_days_exists;

SELECT EXISTS (
  SELECT FROM information_schema.tables
  WHERE table_name = 'exercises'
) AS exercises_exists;

-- ====================
-- Part 2: Column Verification
-- ====================

\echo ''
\echo '2. Verifying required columns...'
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'workout_plans'
ORDER BY ordinal_position;

-- ====================
-- Part 3: RLS Policy Testing
-- ====================

\echo ''
\echo '3. Testing RLS policies...'

-- Create test user
DO $$
DECLARE
  test_user_id UUID;
  other_user_id UUID;
BEGIN
  -- Insert test users
  INSERT INTO auth.users (id) VALUES
    ('11111111-1111-1111-1111-111111111111'),
    ('22222222-2222-2222-2222-222222222222')
  ON CONFLICT DO NOTHING;

  test_user_id := '11111111-1111-1111-1111-111111111111';
  other_user_id := '22222222-2222-2222-2222-222222222222';

  -- Set current user
  PERFORM set_config('request.jwt.claim.sub', test_user_id::text, true);

  -- Test 1: User can insert own plan
  BEGIN
    INSERT INTO workout_plans (id, user_id, name, goal, total_weeks)
    VALUES ('plan-test-1', test_user_id, 'Test Plan', 'hypertrophy', 8);
    RAISE NOTICE 'PASS: User can insert own plan';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'FAIL: User cannot insert own plan - %', SQLERRM;
  END;

  -- Test 2: User cannot insert plan for other user
  BEGIN
    INSERT INTO workout_plans (id, user_id, name, goal, total_weeks)
    VALUES ('plan-test-2', other_user_id, 'Other Plan', 'strength', 8);
    RAISE NOTICE 'FAIL: User can insert plan for other user';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'PASS: User cannot insert plan for other user';
  END;

  -- Test 3: User can view own plan
  IF EXISTS (
    SELECT 1 FROM workout_plans WHERE id = 'plan-test-1'
  ) THEN
    RAISE NOTICE 'PASS: User can view own plan';
  ELSE
    RAISE NOTICE 'FAIL: User cannot view own plan';
  END IF;

  -- Test 4: User cannot view other user's plan
  IF NOT EXISTS (
    SELECT 1 FROM workout_plans WHERE user_id = other_user_id
  ) THEN
    RAISE NOTICE 'PASS: User cannot view other user''s plan';
  ELSE
    RAISE NOTICE 'FAIL: User can view other user''s plan';
  END IF;
END $$;

-- ====================
-- Part 4: Cascade Delete Testing
-- ====================

\echo ''
\echo '4. Testing cascade deletes...'

DO $$
DECLARE
  plan_id UUID;
  week_id UUID;
  day_id UUID;
BEGIN
  -- Create test hierarchy
  INSERT INTO workout_plans (id, user_id, name, goal, total_weeks)
  VALUES ('cascade-test-plan', '11111111-1111-1111-1111-111111111111', 'Cascade Test', 'hypertrophy', 1)
  RETURNING id INTO plan_id;

  INSERT INTO workout_weeks (id, plan_id, week_number, start_date, end_date)
  VALUES ('cascade-test-week', plan_id, 1, CURRENT_DATE, CURRENT_DATE + 7)
  RETURNING id INTO week_id;

  INSERT INTO workout_days (id, week_id, day_label, date)
  VALUES ('cascade-test-day', week_id, 'Test Day', CURRENT_DATE)
  RETURNING id INTO day_id;

  INSERT INTO exercises (id, day_id, name, muscle_group, sets, target_reps_min, target_reps_max)
  VALUES ('cascade-test-ex', day_id, 'Test Exercise', 'chest', 3, 8, 12);

  -- Delete plan
  DELETE FROM workout_plans WHERE id = plan_id;

  -- Verify cascades
  IF NOT EXISTS (SELECT 1 FROM workout_weeks WHERE id = week_id) THEN
    RAISE NOTICE 'PASS: Week deleted on plan cascade';
  ELSE
    RAISE NOTICE 'FAIL: Week not deleted on plan cascade';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM workout_days WHERE id = day_id) THEN
    RAISE NOTICE 'PASS: Day deleted on plan cascade';
  ELSE
    RAISE NOTICE 'FAIL: Day not deleted on plan cascade';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM exercises WHERE id = 'cascade-test-ex') THEN
    RAISE NOTICE 'PASS: Exercise deleted on plan cascade';
  ELSE
    RAISE NOTICE 'FAIL: Exercise not deleted on plan cascade';
  END IF;
END $$;

-- ====================
-- Part 5: Index Verification
-- ====================

\echo ''
\echo '5. Verifying indexes exist...'
SELECT schemaname, tablename, indexname
FROM pg_indexes
WHERE tablename IN ('workout_plans', 'workout_weeks', 'workout_days', 'exercises')
ORDER BY tablename, indexname;

-- ====================
-- Part 6: Performance Benchmarks
-- ====================

\echo ''
\echo '6. Running performance benchmarks...'

-- Benchmark 1: Load plan with all data
EXPLAIN ANALYZE
SELECT
  p.*,
  w.*,
  d.*,
  e.*
FROM workout_plans p
LEFT JOIN workout_weeks w ON w.plan_id = p.id
LEFT JOIN workout_days d ON d.week_id = w.id
LEFT JOIN exercises e ON e.day_id = d.id
WHERE p.id = 'plan-test-1';

-- Benchmark 2: Calculate total volume
EXPLAIN ANALYZE
SELECT
  SUM(e.sets * e.target_reps_avg * e.target_weight) as total_volume
FROM exercises e
JOIN workout_days d ON e.day_id = d.id
JOIN workout_weeks w ON d.week_id = w.id
WHERE w.plan_id = 'plan-test-1';

-- Benchmark 3: Get muscle group distribution
EXPLAIN ANALYZE
SELECT
  e.muscle_group,
  COUNT(*) as exercise_count,
  SUM(e.sets) as total_sets
FROM exercises e
JOIN workout_days d ON e.day_id = d.id
JOIN workout_weeks w ON d.week_id = w.id
WHERE w.plan_id = 'plan-test-1'
GROUP BY e.muscle_group;

-- ====================
-- Part 7: Constraint Testing
-- ====================

\echo ''
\echo '7. Testing constraints...'

-- Test NOT NULL constraint
DO $$
BEGIN
  INSERT INTO workout_plans (id, user_id, name, goal)
  VALUES ('constraint-test', '11111111-1111-1111-1111-111111111111', NULL, 'hypertrophy');
  RAISE NOTICE 'FAIL: NULL name allowed';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'PASS: NULL name rejected';
END $$;

-- Test CHECK constraint on sets > 0
DO $$
BEGIN
  INSERT INTO exercises (day_id, name, muscle_group, sets, target_reps_min, target_reps_max)
  VALUES ('cascade-test-day', 'Bad Exercise', 'chest', 0, 8, 12);
  RAISE NOTICE 'FAIL: Zero sets allowed';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'PASS: Zero sets rejected';
END $$;

-- Test UNIQUE constraint
DO $$
DECLARE
  plan_id UUID := 'unique-test-plan';
  week_id UUID := 'unique-test-week';
BEGIN
  -- Create plan and week
  INSERT INTO workout_plans (id, user_id, name, goal, total_weeks)
  VALUES (plan_id, '11111111-1111-1111-1111-111111111111', 'Unique Test', 'strength', 1);

  INSERT INTO workout_weeks (id, plan_id, week_number, start_date, end_date)
  VALUES (week_id, plan_id, 1, CURRENT_DATE, CURRENT_DATE + 7);

  -- Try duplicate week_number
  BEGIN
    INSERT INTO workout_weeks (plan_id, week_number, start_date, end_date)
    VALUES (plan_id, 1, CURRENT_DATE, CURRENT_DATE + 7);
    RAISE NOTICE 'FAIL: Duplicate week_number allowed';
  EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'PASS: Duplicate week_number rejected';
  END;

  -- Cleanup
  DELETE FROM workout_plans WHERE id = plan_id;
END $$;

-- ====================
-- Part 8: Function Testing
-- ====================

\echo ''
\echo '8. Testing database functions...'

-- Test calculate_plan_volume if exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'calculate_plan_volume'
  ) THEN
    PERFORM calculate_plan_volume('plan-test-1');
    RAISE NOTICE 'PASS: calculate_plan_volume executes';
  ELSE
    RAISE NOTICE 'SKIP: calculate_plan_volume not found';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'FAIL: calculate_plan_volume error - %', SQLERRM;
END $$;

-- ====================
-- Part 9: Trigger Testing
-- ====================

\echo ''
\echo '9. Testing triggers...'

-- Test updated_at trigger
DO $$
DECLARE
  old_updated_at TIMESTAMPTZ;
  new_updated_at TIMESTAMPTZ;
BEGIN
  SELECT updated_at INTO old_updated_at
  FROM workout_plans WHERE id = 'plan-test-1';

  -- Wait 1 second and update
  PERFORM pg_sleep(1);
  UPDATE workout_plans SET name = 'Updated Name' WHERE id = 'plan-test-1';

  SELECT updated_at INTO new_updated_at
  FROM workout_plans WHERE id = 'plan-test-1';

  IF new_updated_at > old_updated_at THEN
    RAISE NOTICE 'PASS: updated_at trigger works';
  ELSE
    RAISE NOTICE 'FAIL: updated_at trigger not working';
  END IF;
END $$;

-- ====================
-- Part 10: Data Integrity
-- ====================

\echo ''
\echo '10. Checking data integrity...'

-- Check for orphaned weeks
SELECT COUNT(*) as orphaned_weeks
FROM workout_weeks w
WHERE NOT EXISTS (
  SELECT 1 FROM workout_plans p WHERE p.id = w.plan_id
);

-- Check for orphaned days
SELECT COUNT(*) as orphaned_days
FROM workout_days d
WHERE NOT EXISTS (
  SELECT 1 FROM workout_weeks w WHERE w.id = d.week_id
);

-- Check for orphaned exercises
SELECT COUNT(*) as orphaned_exercises
FROM exercises e
WHERE NOT EXISTS (
  SELECT 1 FROM workout_days d WHERE d.id = e.day_id
);

-- Check for invalid order_index
SELECT
  day_id,
  COUNT(*) as exercises,
  COUNT(DISTINCT order_index) as unique_orders
FROM exercises
GROUP BY day_id
HAVING COUNT(*) != COUNT(DISTINCT order_index);

-- ====================
-- Cleanup
-- ====================

\echo ''
\echo '11. Cleaning up test data...'
DELETE FROM workout_plans WHERE name LIKE '%Test%';

\echo ''
\echo '==================================='
\echo 'TESTING COMPLETE'
\echo '==================================='
