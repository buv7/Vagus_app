-- CLUSTER 4: Daily Missions + Death Spiral Prevention + Dopamine Open

-- 1) Daily missions
CREATE TABLE IF NOT EXISTS daily_missions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  mission_type TEXT NOT NULL CHECK (mission_type IN ('workout', 'nutrition', 'checkin', 'message', 'custom')),
  mission_title TEXT NOT NULL,
  mission_description TEXT,
  mission_data JSONB,
  completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  xp_reward INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, date, mission_type)
);

CREATE INDEX IF NOT EXISTS idx_daily_missions_user_date ON daily_missions(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_missions_completed ON daily_missions(user_id, completed, date DESC);

-- 2) Death spiral prevention logs
CREATE TABLE IF NOT EXISTS death_spiral_prevention_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  missed_date DATE NOT NULL,
  prevention_action TEXT NOT NULL CHECK (prevention_action IN ('reminder', 'encouragement', 'streak_protection', 'mission_adjustment')),
  action_data JSONB,
  action_taken_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  success BOOLEAN,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_death_spiral_user_date ON death_spiral_prevention_logs(user_id, missed_date DESC);

-- 3) Dopamine open events tracking
CREATE TABLE IF NOT EXISTS dopamine_open_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  dopamine_trigger TEXT,
  trigger_data JSONB,
  engagement_duration_seconds INTEGER
);

CREATE INDEX IF NOT EXISTS idx_dopamine_events_user_date ON dopamine_open_events(user_id, opened_at DESC);

-- RLS
ALTER TABLE daily_missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE death_spiral_prevention_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE dopamine_open_events ENABLE ROW LEVEL SECURITY;

-- daily_missions policies
DROP POLICY IF EXISTS "Users can view own daily missions" ON daily_missions;
DROP POLICY IF EXISTS "Users can insert own daily missions" ON daily_missions;
DROP POLICY IF EXISTS "Users can update own daily missions" ON daily_missions;

CREATE POLICY "Users can view own daily missions"
ON daily_missions FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily missions"
ON daily_missions FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily missions"
ON daily_missions FOR UPDATE
USING (auth.uid() = user_id);

-- death_spiral_prevention_logs policies
DROP POLICY IF EXISTS "Users can view own prevention logs" ON death_spiral_prevention_logs;
DROP POLICY IF EXISTS "System can insert prevention logs" ON death_spiral_prevention_logs;

CREATE POLICY "Users can view own prevention logs"
ON death_spiral_prevention_logs FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "System can insert prevention logs"
ON death_spiral_prevention_logs FOR INSERT
WITH CHECK (true); -- System inserts (via service)

-- dopamine_open_events policies
DROP POLICY IF EXISTS "Users can view own dopamine events" ON dopamine_open_events;
DROP POLICY IF EXISTS "System can insert dopamine events" ON dopamine_open_events;

CREATE POLICY "Users can view own dopamine events"
ON dopamine_open_events FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "System can insert dopamine events"
ON dopamine_open_events FOR INSERT
WITH CHECK (true); -- System inserts (via service)
