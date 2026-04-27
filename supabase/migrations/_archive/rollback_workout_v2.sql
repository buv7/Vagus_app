-- =====================================================
-- Workout v2 Rollback Script
-- =====================================================
-- This script safely rolls back the workout v2 migration,
-- restoring v1 tables and removing v2 schema.
--
-- IMPORTANT: This should only be run if v2 migration fails
-- or critical issues are discovered post-migration.
--
-- Usage:
--   psql -h <host> -U postgres -d postgres -f rollback_workout_v2.sql
--
-- Author: Vagus Development Team
-- Date: 2025-09-30
-- Version: 1.0
-- =====================================================

\echo ''
\echo '========================================='
\echo 'WORKOUT V2 ROLLBACK'
\echo '========================================='
\echo ''

-- Prompt for confirmation
\echo 'WARNING: This will remove all v2 schema and restore v1 tables.'
\echo 'Press Ctrl+C to cancel, or Enter to continue...'
\prompt 'Type "ROLLBACK" to confirm: ' confirmation

-- Check confirmation
DO $$
BEGIN
  IF current_setting('confirmation', true) != 'ROLLBACK' THEN
    RAISE EXCEPTION 'Rollback cancelled by user';
  END IF;
END $$;

-- Enable transaction for safety
BEGIN;

\echo ''
\echo '1. Checking if v1 backup tables exist...'

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'workout_plans_v1') THEN
    RAISE EXCEPTION 'v1 backup tables not found! Cannot rollback safely.';
  END IF;

  RAISE NOTICE '✅ v1 backup tables found';
END $$;

\echo ''
\echo '2. Backing up v2 data (if any new data was created)...'

-- Create v2 backup tables
CREATE TABLE IF NOT EXISTS workout_plans_v2_backup AS SELECT * FROM workout_plans;
CREATE TABLE IF NOT EXISTS workout_weeks_v2_backup AS SELECT * FROM workout_weeks;
CREATE TABLE IF NOT EXISTS workout_days_v2_backup AS SELECT * FROM workout_days;
CREATE TABLE IF NOT EXISTS exercise_groups_v2_backup AS SELECT * FROM exercise_groups;
CREATE TABLE IF NOT EXISTS exercises_v2_backup AS SELECT * FROM exercises;
CREATE TABLE IF NOT EXISTS workout_sessions_v2_backup AS SELECT * FROM workout_sessions;
CREATE TABLE IF NOT EXISTS exercise_logs_v2_backup AS SELECT * FROM exercise_logs;

\echo ''
\echo '3. Dropping v2 triggers...'

DROP TRIGGER IF EXISTS update_workout_plans_timestamp ON workout_plans;
DROP TRIGGER IF EXISTS update_workout_weeks_timestamp ON workout_weeks;
DROP TRIGGER IF EXISTS update_workout_days_timestamp ON workout_days;
DROP TRIGGER IF EXISTS update_exercises_timestamp ON exercises;

\echo ''
\echo '4. Dropping v2 functions...'

DROP FUNCTION IF EXISTS calculate_plan_volume(UUID);
DROP FUNCTION IF EXISTS detect_prs(UUID, TEXT);
DROP FUNCTION IF EXISTS get_muscle_group_volume(UUID, DATE, DATE);

-- Keep auto_update_timestamp as it may be used by other tables
-- DROP FUNCTION IF EXISTS auto_update_timestamp();

\echo ''
\echo '5. Dropping v2 RLS policies...'

-- Workout Plans
DROP POLICY IF EXISTS "Users can view own plans" ON workout_plans;
DROP POLICY IF EXISTS "Users can insert own plans" ON workout_plans;
DROP POLICY IF EXISTS "Users can update own plans" ON workout_plans;
DROP POLICY IF EXISTS "Users can delete own plans" ON workout_plans;

-- Weeks
DROP POLICY IF EXISTS "Users can view weeks" ON workout_weeks;

-- Days
DROP POLICY IF EXISTS "Users can view days" ON workout_days;

-- Exercise Groups
DROP POLICY IF EXISTS "Users can view exercise groups" ON exercise_groups;

-- Exercises
DROP POLICY IF EXISTS "Users can view exercises" ON exercises;

-- Sessions
DROP POLICY IF EXISTS "Users can view own sessions" ON workout_sessions;

-- Exercise Logs
DROP POLICY IF EXISTS "Users can view own logs" ON exercise_logs;

-- Notification Preferences
DROP POLICY IF EXISTS "Users can view own preferences" ON notification_preferences;

-- Scheduled Notifications
DROP POLICY IF EXISTS "Users can view own scheduled notifications" ON scheduled_notifications;

-- Notification History
DROP POLICY IF EXISTS "Users can view own notification history" ON notification_history;

\echo ''
\echo '6. Dropping v2 indexes...'

DROP INDEX IF EXISTS idx_workout_plans_user_id;
DROP INDEX IF EXISTS idx_workout_plans_status;
DROP INDEX IF EXISTS idx_workout_plans_template;

DROP INDEX IF EXISTS idx_workout_weeks_plan_id;
DROP INDEX IF EXISTS idx_workout_weeks_dates;

DROP INDEX IF EXISTS idx_workout_days_week_id;
DROP INDEX IF EXISTS idx_workout_days_date;
DROP INDEX IF EXISTS idx_workout_days_muscle_groups;

DROP INDEX IF EXISTS idx_exercise_groups_day_id;

DROP INDEX IF EXISTS idx_exercises_day_id;
DROP INDEX IF EXISTS idx_exercises_group_id;
DROP INDEX IF EXISTS idx_exercises_muscle_group;
DROP INDEX IF EXISTS idx_exercises_name;

DROP INDEX IF EXISTS idx_workout_sessions_user_id;
DROP INDEX IF EXISTS idx_workout_sessions_day_id;
DROP INDEX IF EXISTS idx_workout_sessions_started_at;
DROP INDEX IF EXISTS idx_workout_sessions_completed;

DROP INDEX IF EXISTS idx_exercise_logs_session_id;
DROP INDEX IF EXISTS idx_exercise_logs_exercise_id;
DROP INDEX IF EXISTS idx_exercise_logs_completed_at;

DROP INDEX IF EXISTS idx_scheduled_notifications_user_id;
DROP INDEX IF EXISTS idx_scheduled_notifications_send_at;

DROP INDEX IF EXISTS idx_notification_history_user_id;
DROP INDEX IF EXISTS idx_notification_history_sent_at;

\echo ''
\echo '7. Dropping v2 tables...'

DROP TABLE IF EXISTS notification_history CASCADE;
DROP TABLE IF EXISTS scheduled_notifications CASCADE;
DROP TABLE IF EXISTS notification_preferences CASCADE;
DROP TABLE IF EXISTS exercise_logs CASCADE;
DROP TABLE IF EXISTS workout_sessions CASCADE;
DROP TABLE IF EXISTS exercises CASCADE;
DROP TABLE IF EXISTS exercise_groups CASCADE;
DROP TABLE IF EXISTS workout_days CASCADE;
DROP TABLE IF EXISTS workout_weeks CASCADE;
DROP TABLE IF EXISTS workout_plans CASCADE;

\echo ''
\echo '8. Restoring v1 tables...'

-- Rename v1 backup tables back to original names
ALTER TABLE IF EXISTS workout_plans_v1 RENAME TO workout_plans;
ALTER TABLE IF EXISTS workout_plan_weeks_v1 RENAME TO workout_plan_weeks;
ALTER TABLE IF EXISTS workout_plan_days_v1 RENAME TO workout_plan_days;
ALTER TABLE IF EXISTS workout_exercises_v1 RENAME TO workout_exercises;
ALTER TABLE IF EXISTS workout_cardio_v1 RENAME TO workout_cardio;
ALTER TABLE IF EXISTS workout_sessions_v1 RENAME TO workout_sessions;
ALTER TABLE IF EXISTS exercise_logs_v1 RENAME TO exercise_logs;

\echo ''
\echo '9. Recreating v1 indexes...'

-- Recreate common v1 indexes (adjust based on your original schema)
CREATE INDEX IF NOT EXISTS idx_workout_plans_coach_id ON workout_plans(coach_id);
CREATE INDEX IF NOT EXISTS idx_workout_plans_client_id ON workout_plans(client_id);
CREATE INDEX IF NOT EXISTS idx_workout_plan_weeks_plan_id ON workout_plan_weeks(plan_id);
CREATE INDEX IF NOT EXISTS idx_workout_plan_days_week_id ON workout_plan_days(week_id);
CREATE INDEX IF EXISTS idx_workout_exercises_day_id ON workout_exercises(day_id);

\echo ''
\echo '10. Recreating v1 RLS policies...'

-- Enable RLS
ALTER TABLE workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_plan_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_plan_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_exercises ENABLE ROW LEVEL SECURITY;

-- Recreate v1 policies (adjust based on your original schema)
DROP POLICY IF EXISTS "workout_plans_policy" ON workout_plans;
CREATE POLICY "workout_plans_policy"
  ON workout_plans FOR ALL
  USING (
    auth.uid() = coach_id OR
    auth.uid() = client_id OR
    auth.uid() = created_by
  );

DROP POLICY IF EXISTS "workout_plan_weeks_policy" ON workout_plan_weeks;
CREATE POLICY "workout_plan_weeks_policy"
  ON workout_plan_weeks FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM workout_plans
      WHERE id = workout_plan_weeks.plan_id
        AND (auth.uid() = coach_id OR auth.uid() = client_id OR auth.uid() = created_by)
    )
  );

DROP POLICY IF EXISTS "workout_plan_days_policy" ON workout_plan_days;
CREATE POLICY "workout_plan_days_policy"
  ON workout_plan_days FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM workout_plan_weeks w
      JOIN workout_plans p ON w.plan_id = p.id
      WHERE w.id = workout_plan_days.week_id
        AND (auth.uid() = p.coach_id OR auth.uid() = p.client_id OR auth.uid() = p.created_by)
    )
  );

DROP POLICY IF EXISTS "workout_exercises_policy" ON workout_exercises;
CREATE POLICY "workout_exercises_policy"
  ON workout_exercises FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM workout_plan_days d
      JOIN workout_plan_weeks w ON d.week_id = w.id
      JOIN workout_plans p ON w.plan_id = p.id
      WHERE d.id = workout_exercises.day_id
        AND (auth.uid() = p.coach_id OR auth.uid() = p.client_id OR auth.uid() = p.created_by)
    )
  );

\echo ''
\echo '11. Verifying rollback...'

DO $$
DECLARE
  v1_plan_count INTEGER;
  v1_exercise_count INTEGER;
  v2_backup_plan_count INTEGER;
BEGIN
  -- Count restored v1 records
  SELECT COUNT(*) INTO v1_plan_count FROM workout_plans;
  SELECT COUNT(*) INTO v1_exercise_count FROM workout_exercises;

  -- Count v2 backup records
  SELECT COUNT(*) INTO v2_backup_plan_count FROM workout_plans_v2_backup;

  RAISE NOTICE '';
  RAISE NOTICE 'Rollback Verification:';
  RAISE NOTICE '  Restored v1 Plans: %', v1_plan_count;
  RAISE NOTICE '  Restored v1 Exercises: %', v1_exercise_count;
  RAISE NOTICE '  v2 Backup Plans: %', v2_backup_plan_count;

  IF v1_plan_count > 0 THEN
    RAISE NOTICE '  ✅ v1 tables restored successfully';
  ELSE
    RAISE WARNING '  ⚠️  No v1 plans found. Check if rollback completed correctly.';
  END IF;
END $$;

-- Commit transaction
COMMIT;

\echo ''
\echo '========================================='
\echo 'ROLLBACK COMPLETE'
\echo '========================================='
\echo ''
\echo 'v1 tables have been restored.'
\echo 'v2 data has been backed up to *_v2_backup tables.'
\echo ''
\echo 'Next steps:'
\echo '1. Test application with restored v1 data'
\echo '2. Review rollback logs for any warnings'
\echo '3. Investigate root cause of migration failure'
\echo '4. Update migration script to fix issues'
\echo '5. Plan re-migration when ready'
\echo ''
\echo 'v2 backup tables can be dropped after verification:'
\echo '  DROP TABLE workout_plans_v2_backup;'
\echo '  DROP TABLE workout_weeks_v2_backup;'
\echo '  DROP TABLE workout_days_v2_backup;'
\echo '  DROP TABLE exercise_groups_v2_backup;'
\echo '  DROP TABLE exercises_v2_backup;'
\echo '  DROP TABLE workout_sessions_v2_backup;'
\echo '  DROP TABLE exercise_logs_v2_backup;'
\echo ''
