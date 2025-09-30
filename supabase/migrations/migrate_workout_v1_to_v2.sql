-- =====================================================
-- Workout v1 to v2 Migration Script
-- =====================================================
-- This script migrates existing workout data from v1 (flat structure)
-- to v2 (hierarchical structure: Plans → Weeks → Days → Exercises)
--
-- IMPORTANT: Always backup database before running this script!
--
-- Usage:
--   psql -h <host> -U postgres -d postgres -f migrate_workout_v1_to_v2.sql
--
-- Author: Vagus Development Team
-- Date: 2025-09-30
-- Version: 1.0
-- =====================================================

\echo ''
\echo '========================================='
\echo 'WORKOUT V1 → V2 MIGRATION'
\echo '========================================='
\echo ''

-- Enable transaction for safety
BEGIN;

\echo '1. Preserving v1 tables...'

-- Rename existing v1 tables (don't drop, for safety)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'workout_plans' AND table_schema = 'public') THEN
    ALTER TABLE IF EXISTS workout_plans RENAME TO workout_plans_v1;
    ALTER TABLE IF EXISTS workout_plan_weeks RENAME TO workout_plan_weeks_v1;
    ALTER TABLE IF EXISTS workout_plan_days RENAME TO workout_plan_days_v1;
    ALTER TABLE IF EXISTS workout_exercises RENAME TO workout_exercises_v1;
    ALTER TABLE IF EXISTS workout_cardio RENAME TO workout_cardio_v1;
    ALTER TABLE IF EXISTS workout_sessions RENAME TO workout_sessions_v1;
    ALTER TABLE IF EXISTS exercise_logs RENAME TO exercise_logs_v1;

    RAISE NOTICE 'v1 tables renamed to *_v1';
  ELSE
    RAISE NOTICE 'No v1 tables found to rename';
  END IF;
END $$;

\echo ''
\echo '2. Creating v2 schema...'

-- =====================================================
-- V2 Tables
-- =====================================================

-- workout_plans (enhanced)
CREATE TABLE IF NOT EXISTS workout_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  goal TEXT CHECK (goal IN ('strength', 'hypertrophy', 'endurance', 'powerlifting', 'general_fitness', 'weight_loss')),
  total_weeks INTEGER NOT NULL CHECK (total_weeks > 0 AND total_weeks <= 52),
  current_week INTEGER DEFAULT 1 CHECK (current_week > 0),
  status TEXT DEFAULT 'active' CHECK (status IN ('draft', 'active', 'completed', 'archived')),
  is_template BOOLEAN DEFAULT FALSE,
  template_category TEXT,
  created_by UUID REFERENCES auth.users(id),
  ai_generated BOOLEAN DEFAULT FALSE,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- workout_weeks
CREATE TABLE IF NOT EXISTS workout_weeks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_id UUID NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE,
  week_number INTEGER NOT NULL CHECK (week_number > 0),
  start_date DATE,
  end_date DATE,
  notes TEXT,
  deload BOOLEAN DEFAULT FALSE,
  attachments JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(plan_id, week_number)
);

-- workout_days
CREATE TABLE IF NOT EXISTS workout_days (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  week_id UUID NOT NULL REFERENCES workout_weeks(id) ON DELETE CASCADE,
  day_label TEXT NOT NULL,
  day_number INTEGER,
  date DATE,
  notes TEXT,
  client_comment TEXT,
  estimated_duration INTEGER, -- minutes
  muscle_groups TEXT[],
  attachments JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- exercise_groups (NEW in v2)
CREATE TABLE IF NOT EXISTS exercise_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  day_id UUID NOT NULL REFERENCES workout_days(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('superset', 'triset', 'giant_set', 'circuit', 'drop_set')),
  rest_between_rounds INTEGER DEFAULT 90, -- seconds
  rounds INTEGER DEFAULT 1,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- exercises (enhanced)
CREATE TABLE IF NOT EXISTS exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  day_id UUID NOT NULL REFERENCES workout_days(id) ON DELETE CASCADE,
  group_id UUID REFERENCES exercise_groups(id) ON DELETE SET NULL,

  -- Exercise identification
  name TEXT NOT NULL,
  muscle_group TEXT NOT NULL,
  equipment TEXT,

  -- Prescription
  sets INTEGER NOT NULL CHECK (sets > 0),
  target_reps_min INTEGER CHECK (target_reps_min > 0),
  target_reps_max INTEGER CHECK (target_reps_max >= target_reps_min),
  target_reps_avg INTEGER GENERATED ALWAYS AS ((target_reps_min + target_reps_max) / 2) STORED,
  target_weight DECIMAL(6,2),
  target_rpe_min DECIMAL(3,1) CHECK (target_rpe_min >= 1 AND target_rpe_min <= 10),
  target_rpe_max DECIMAL(3,1) CHECK (target_rpe_max >= target_rpe_min AND target_rpe_max <= 10),

  -- Timing
  rest_seconds INTEGER DEFAULT 90 CHECK (rest_seconds >= 0),
  tempo TEXT, -- e.g., "3-0-1-0"

  -- Additional info
  notes TEXT,
  video_url TEXT,
  order_index INTEGER NOT NULL,

  -- Legacy fields (for migration compatibility)
  client_comment TEXT,
  attachments JSONB,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- workout_sessions (enhanced)
CREATE TABLE IF NOT EXISTS workout_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  day_id UUID NOT NULL REFERENCES workout_days(id) ON DELETE CASCADE,

  started_at TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ,

  -- Calculated metrics
  total_volume DECIMAL(10,2),
  total_sets INTEGER,
  average_rpe DECIMAL(3,1),

  -- Session feedback
  notes TEXT,
  energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 5),

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- exercise_logs (enhanced)
CREATE TABLE IF NOT EXISTS exercise_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,

  set_number INTEGER NOT NULL CHECK (set_number > 0),
  reps INTEGER NOT NULL CHECK (reps >= 0),
  weight DECIMAL(6,2) NOT NULL CHECK (weight >= 0),
  rpe DECIMAL(3,1) CHECK (rpe >= 1 AND rpe <= 10),
  tempo TEXT,
  rest_seconds INTEGER,

  notes TEXT,
  form_rating INTEGER CHECK (form_rating >= 1 AND form_rating <= 5),
  completed_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(session_id, exercise_id, set_number)
);

-- notification_preferences (NEW in v2)
CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  preferences JSONB NOT NULL DEFAULT '{
    "workout_reminders_enabled": true,
    "workout_reminder_time": "18:00",
    "reminder_minutes_before": 30,
    "rest_day_reminders_enabled": true,
    "pr_celebration_enabled": true,
    "coach_feedback_enabled": true,
    "weekly_summary_enabled": true,
    "weekly_summary_day": "monday",
    "deload_week_alerts_enabled": true,
    "missed_workout_followup_enabled": true,
    "timezone": "UTC"
  }'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- scheduled_notifications (NEW in v2)
CREATE TABLE IF NOT EXISTS scheduled_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES workout_plans(id) ON DELETE CASCADE,
  day_id UUID REFERENCES workout_days(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL,
  send_at TIMESTAMPTZ NOT NULL,
  onesignal_notification_id TEXT,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'sent', 'cancelled', 'failed')),
  payload JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  sent_at TIMESTAMPTZ
);

-- notification_history (NEW in v2)
CREATE TABLE IF NOT EXISTS notification_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  payload JSONB,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  opened_at TIMESTAMPTZ,
  action_taken TEXT
);

\echo ''
\echo '3. Creating indexes...'

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_workout_plans_user_id ON workout_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_plans_status ON workout_plans(status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_workout_plans_template ON workout_plans(is_template) WHERE is_template = TRUE;

CREATE INDEX IF NOT EXISTS idx_workout_weeks_plan_id ON workout_weeks(plan_id);
CREATE INDEX IF NOT EXISTS idx_workout_weeks_dates ON workout_weeks(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_workout_days_week_id ON workout_days(week_id);
CREATE INDEX IF NOT EXISTS idx_workout_days_date ON workout_days(date);
CREATE INDEX IF NOT EXISTS idx_workout_days_muscle_groups ON workout_days USING GIN(muscle_groups);

CREATE INDEX IF NOT EXISTS idx_exercise_groups_day_id ON exercise_groups(day_id);

CREATE INDEX IF NOT EXISTS idx_exercises_day_id ON exercises(day_id);
CREATE INDEX IF NOT EXISTS idx_exercises_group_id ON exercises(group_id) WHERE group_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_exercises_muscle_group ON exercises(muscle_group);
CREATE INDEX IF NOT EXISTS idx_exercises_name ON exercises(name);

CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_day_id ON workout_sessions(day_id);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_started_at ON workout_sessions(started_at);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_completed ON workout_sessions(completed_at) WHERE completed_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_exercise_logs_session_id ON exercise_logs(session_id);
CREATE INDEX IF NOT EXISTS idx_exercise_logs_exercise_id ON exercise_logs(exercise_id);
CREATE INDEX IF NOT EXISTS idx_exercise_logs_completed_at ON exercise_logs(completed_at);

CREATE INDEX IF NOT EXISTS idx_scheduled_notifications_user_id ON scheduled_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_notifications_send_at ON scheduled_notifications(send_at) WHERE status = 'scheduled';

CREATE INDEX IF NOT EXISTS idx_notification_history_user_id ON notification_history(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_history_sent_at ON notification_history(sent_at);

\echo ''
\echo '4. Creating functions...'

-- Function: Calculate plan volume
CREATE OR REPLACE FUNCTION calculate_plan_volume(p_plan_id UUID)
RETURNS DECIMAL(10,2) AS $$
DECLARE
  total_volume DECIMAL(10,2);
BEGIN
  SELECT COALESCE(SUM(e.sets * e.target_reps_avg * e.target_weight), 0)
  INTO total_volume
  FROM exercises e
  JOIN workout_days d ON e.day_id = d.id
  JOIN workout_weeks w ON d.week_id = w.id
  WHERE w.plan_id = p_plan_id;

  RETURN total_volume;
END;
$$ LANGUAGE plpgsql;

-- Function: Detect PRs
CREATE OR REPLACE FUNCTION detect_prs(p_user_id UUID, p_exercise_name TEXT)
RETURNS TABLE(
  pr_type TEXT,
  value DECIMAL,
  achieved_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  -- Max weight
  SELECT
    'max_weight'::TEXT as pr_type,
    MAX(el.weight) as value,
    MAX(el.completed_at) as achieved_at
  FROM exercise_logs el
  JOIN workout_sessions ws ON el.session_id = ws.id
  JOIN exercises e ON el.exercise_id = e.id
  WHERE ws.user_id = p_user_id
    AND e.name = p_exercise_name

  UNION ALL

  -- Max reps
  SELECT
    'max_reps'::TEXT as pr_type,
    MAX(el.reps)::DECIMAL as value,
    MAX(el.completed_at) as achieved_at
  FROM exercise_logs el
  JOIN workout_sessions ws ON el.session_id = ws.id
  JOIN exercises e ON el.exercise_id = e.id
  WHERE ws.user_id = p_user_id
    AND e.name = p_exercise_name

  UNION ALL

  -- Max volume single set
  SELECT
    'max_volume_single_set'::TEXT as pr_type,
    MAX(el.weight * el.reps) as value,
    MAX(el.completed_at) as achieved_at
  FROM exercise_logs el
  JOIN workout_sessions ws ON el.session_id = ws.id
  JOIN exercises e ON el.exercise_id = e.id
  WHERE ws.user_id = p_user_id
    AND e.name = p_exercise_name;
END;
$$ LANGUAGE plpgsql;

-- Function: Get muscle group volume
CREATE OR REPLACE FUNCTION get_muscle_group_volume(
  p_user_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(
  muscle_group TEXT,
  total_volume DECIMAL,
  total_sets INTEGER,
  session_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.muscle_group,
    SUM(el.weight * el.reps) as total_volume,
    COUNT(el.*)::INTEGER as total_sets,
    COUNT(DISTINCT ws.id)::INTEGER as session_count
  FROM exercise_logs el
  JOIN workout_sessions ws ON el.session_id = ws.id
  JOIN exercises e ON el.exercise_id = e.id
  WHERE ws.user_id = p_user_id
    AND DATE(ws.started_at) BETWEEN p_start_date AND p_end_date
    AND ws.completed_at IS NOT NULL
  GROUP BY e.muscle_group
  ORDER BY total_volume DESC;
END;
$$ LANGUAGE plpgsql;

-- Function: Auto update timestamp
CREATE OR REPLACE FUNCTION auto_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

\echo ''
\echo '5. Creating triggers...'

-- Triggers for auto-updating timestamps
DROP TRIGGER IF EXISTS update_workout_plans_timestamp ON workout_plans;
CREATE TRIGGER update_workout_plans_timestamp
  BEFORE UPDATE ON workout_plans
  FOR EACH ROW
  EXECUTE FUNCTION auto_update_timestamp();

DROP TRIGGER IF EXISTS update_workout_weeks_timestamp ON workout_weeks;
CREATE TRIGGER update_workout_weeks_timestamp
  BEFORE UPDATE ON workout_weeks
  FOR EACH ROW
  EXECUTE FUNCTION auto_update_timestamp();

DROP TRIGGER IF EXISTS update_workout_days_timestamp ON workout_days;
CREATE TRIGGER update_workout_days_timestamp
  BEFORE UPDATE ON workout_days
  FOR EACH ROW
  EXECUTE FUNCTION auto_update_timestamp();

DROP TRIGGER IF EXISTS update_exercises_timestamp ON exercises;
CREATE TRIGGER update_exercises_timestamp
  BEFORE UPDATE ON exercises
  FOR EACH ROW
  EXECUTE FUNCTION auto_update_timestamp();

\echo ''
\echo '6. Enabling RLS...'

-- Enable RLS on all tables
ALTER TABLE workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_history ENABLE ROW LEVEL SECURITY;

\echo ''
\echo '7. Creating RLS policies...'

-- Workout Plans Policies
DROP POLICY IF EXISTS "Users can view own plans" ON workout_plans;
CREATE POLICY "Users can view own plans"
  ON workout_plans FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own plans" ON workout_plans;
CREATE POLICY "Users can insert own plans"
  ON workout_plans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own plans" ON workout_plans;
CREATE POLICY "Users can update own plans"
  ON workout_plans FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own plans" ON workout_plans;
CREATE POLICY "Users can delete own plans"
  ON workout_plans FOR DELETE
  USING (auth.uid() = user_id);

-- Apply similar policies to child tables (they inherit access through foreign keys)
-- Weeks
DROP POLICY IF EXISTS "Users can view weeks" ON workout_weeks;
CREATE POLICY "Users can view weeks"
  ON workout_weeks FOR ALL
  USING (EXISTS (
    SELECT 1 FROM workout_plans WHERE id = workout_weeks.plan_id AND user_id = auth.uid()
  ));

-- Days
DROP POLICY IF EXISTS "Users can view days" ON workout_days;
CREATE POLICY "Users can view days"
  ON workout_days FOR ALL
  USING (EXISTS (
    SELECT 1 FROM workout_weeks w
    JOIN workout_plans p ON w.plan_id = p.id
    WHERE w.id = workout_days.week_id AND p.user_id = auth.uid()
  ));

-- Exercise Groups
DROP POLICY IF EXISTS "Users can view exercise groups" ON exercise_groups;
CREATE POLICY "Users can view exercise groups"
  ON exercise_groups FOR ALL
  USING (EXISTS (
    SELECT 1 FROM workout_days d
    JOIN workout_weeks w ON d.week_id = w.id
    JOIN workout_plans p ON w.plan_id = p.id
    WHERE d.id = exercise_groups.day_id AND p.user_id = auth.uid()
  ));

-- Exercises
DROP POLICY IF EXISTS "Users can view exercises" ON exercises;
CREATE POLICY "Users can view exercises"
  ON exercises FOR ALL
  USING (EXISTS (
    SELECT 1 FROM workout_days d
    JOIN workout_weeks w ON d.week_id = w.id
    JOIN workout_plans p ON w.plan_id = p.id
    WHERE d.id = exercises.day_id AND p.user_id = auth.uid()
  ));

-- Sessions
DROP POLICY IF EXISTS "Users can view own sessions" ON workout_sessions;
CREATE POLICY "Users can view own sessions"
  ON workout_sessions FOR ALL
  USING (auth.uid() = user_id);

-- Exercise Logs
DROP POLICY IF EXISTS "Users can view own logs" ON exercise_logs;
CREATE POLICY "Users can view own logs"
  ON exercise_logs FOR ALL
  USING (EXISTS (
    SELECT 1 FROM workout_sessions WHERE id = exercise_logs.session_id AND user_id = auth.uid()
  ));

-- Notification Preferences
DROP POLICY IF EXISTS "Users can view own preferences" ON notification_preferences;
CREATE POLICY "Users can view own preferences"
  ON notification_preferences FOR ALL
  USING (auth.uid() = user_id);

-- Scheduled Notifications
DROP POLICY IF EXISTS "Users can view own scheduled notifications" ON scheduled_notifications;
CREATE POLICY "Users can view own scheduled notifications"
  ON scheduled_notifications FOR ALL
  USING (auth.uid() = user_id);

-- Notification History
DROP POLICY IF EXISTS "Users can view own notification history" ON notification_history;
CREATE POLICY "Users can view own notification history"
  ON notification_history FOR ALL
  USING (auth.uid() = user_id);

\echo ''
\echo '8. Migrating data from v1 to v2...'

-- Data migration logic
DO $$
DECLARE
  v1_plan_rec RECORD;
  v1_week_rec RECORD;
  v1_day_rec RECORD;
  v1_exercise_rec RECORD;

  v2_plan_id UUID;
  v2_week_id UUID;
  v2_day_id UUID;

  migration_count INTEGER := 0;
BEGIN
  -- Check if v1 tables exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'workout_plans_v1') THEN
    RAISE NOTICE 'No v1 data to migrate';
    RETURN;
  END IF;

  RAISE NOTICE 'Starting data migration...';

  -- Migrate plans
  FOR v1_plan_rec IN
    SELECT * FROM workout_plans_v1 ORDER BY created_at
  LOOP
    -- Insert plan
    INSERT INTO workout_plans (
      id, user_id, name, description, goal, total_weeks, current_week,
      status, is_template, template_category, created_by, ai_generated, metadata,
      created_at, updated_at
    )
    VALUES (
      v1_plan_rec.id,
      COALESCE(v1_plan_rec.client_id, v1_plan_rec.coach_id, v1_plan_rec.created_by),
      v1_plan_rec.name,
      v1_plan_rec.description,
      'general_fitness', -- Default goal
      COALESCE(v1_plan_rec.duration_weeks, 4),
      1, -- current_week
      'active', -- status
      v1_plan_rec.is_template,
      v1_plan_rec.template_category,
      v1_plan_rec.created_by,
      v1_plan_rec.ai_generated,
      v1_plan_rec.metadata,
      v1_plan_rec.created_at,
      v1_plan_rec.updated_at
    )
    RETURNING id INTO v2_plan_id;

    -- Migrate weeks for this plan
    FOR v1_week_rec IN
      SELECT * FROM workout_plan_weeks_v1 WHERE plan_id = v1_plan_rec.id ORDER BY week_number
    LOOP
      INSERT INTO workout_weeks (
        id, plan_id, week_number, start_date, end_date, notes, deload, attachments,
        created_at, updated_at
      )
      VALUES (
        v1_week_rec.id,
        v2_plan_id,
        v1_week_rec.week_number,
        NULL, -- start_date
        NULL, -- end_date
        v1_week_rec.notes,
        FALSE, -- deload
        v1_week_rec.attachments,
        v1_week_rec.created_at,
        v1_week_rec.updated_at
      )
      RETURNING id INTO v2_week_id;

      -- Migrate days for this week
      FOR v1_day_rec IN
        SELECT * FROM workout_plan_days_v1 WHERE week_id = v1_week_rec.id ORDER BY day_number
      LOOP
        INSERT INTO workout_days (
          id, week_id, day_label, day_number, date, notes, client_comment,
          estimated_duration, muscle_groups, attachments, created_at, updated_at
        )
        VALUES (
          v1_day_rec.id,
          v2_week_id,
          COALESCE(v1_day_rec.label, 'Day ' || v1_day_rec.day_number),
          v1_day_rec.day_number,
          NULL, -- date
          NULL, -- notes
          v1_day_rec.client_comment,
          NULL, -- estimated_duration
          NULL, -- muscle_groups
          v1_day_rec.attachments,
          v1_day_rec.created_at,
          v1_day_rec.updated_at
        )
        RETURNING id INTO v2_day_id;

        -- Migrate exercises for this day
        FOR v1_exercise_rec IN
          SELECT * FROM workout_exercises_v1 WHERE day_id = v1_day_rec.id ORDER BY order_index
        LOOP
          INSERT INTO exercises (
            id, day_id, group_id, name, muscle_group, equipment,
            sets, target_reps_min, target_reps_max, target_weight,
            target_rpe_min, target_rpe_max, rest_seconds, tempo,
            notes, video_url, order_index, client_comment, attachments,
            created_at, updated_at
          )
          VALUES (
            v1_exercise_rec.id,
            v2_day_id,
            NULL, -- group_id
            v1_exercise_rec.name,
            COALESCE(v1_exercise_rec.muscle_group, 'general'),
            v1_exercise_rec.equipment,
            COALESCE(v1_exercise_rec.sets, 3),
            v1_exercise_rec.target_reps_min,
            v1_exercise_rec.target_reps_max,
            v1_exercise_rec.target_weight,
            NULL, -- target_rpe_min
            NULL, -- target_rpe_max
            COALESCE(v1_exercise_rec.rest_seconds, 90),
            v1_exercise_rec.tempo,
            v1_exercise_rec.notes,
            v1_exercise_rec.video_url,
            v1_exercise_rec.order_index,
            v1_exercise_rec.client_comment,
            v1_exercise_rec.attachments,
            v1_exercise_rec.created_at,
            v1_exercise_rec.updated_at
          );
        END LOOP;
      END LOOP;
    END LOOP;

    migration_count := migration_count + 1;
  END LOOP;

  RAISE NOTICE 'Migrated % plans from v1 to v2', migration_count;
END $$;

\echo ''
\echo '9. Creating default notification preferences...'

-- Create default notification preferences for all users
INSERT INTO notification_preferences (user_id)
SELECT u.id
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM notification_preferences np WHERE np.user_id = u.id
);

\echo ''
\echo '10. Verifying migration...'

-- Verification queries
DO $$
DECLARE
  v1_plan_count INTEGER;
  v2_plan_count INTEGER;
  v1_exercise_count INTEGER;
  v2_exercise_count INTEGER;
BEGIN
  -- Count v1 records
  SELECT COUNT(*) INTO v1_plan_count FROM workout_plans_v1;
  SELECT COUNT(*) INTO v1_exercise_count FROM workout_exercises_v1;

  -- Count v2 records
  SELECT COUNT(*) INTO v2_plan_count FROM workout_plans;
  SELECT COUNT(*) INTO v2_exercise_count FROM exercises;

  RAISE NOTICE '';
  RAISE NOTICE 'Migration Verification:';
  RAISE NOTICE '  v1 Plans: %', v1_plan_count;
  RAISE NOTICE '  v2 Plans: %', v2_plan_count;
  RAISE NOTICE '  v1 Exercises: %', v1_exercise_count;
  RAISE NOTICE '  v2 Exercises: %', v2_exercise_count;

  IF v1_plan_count = v2_plan_count AND v1_exercise_count = v2_exercise_count THEN
    RAISE NOTICE '  ✅ Migration counts match!';
  ELSE
    RAISE WARNING '  ⚠️  Migration counts do not match. Please investigate.';
  END IF;
END $$;

-- Commit transaction
COMMIT;

\echo ''
\echo '========================================='
\echo 'MIGRATION COMPLETE'
\echo '========================================='
\echo ''
\echo 'Next steps:'
\echo '1. Run post-migration verification: psql -f test_workout_schema.sql'
\echo '2. Test application with migrated data'
\echo '3. If successful, v1 tables can be dropped (keep for 30 days as backup)'
\echo ''
\echo 'To rollback: psql -f rollback_workout_v2.sql'
\echo ''
