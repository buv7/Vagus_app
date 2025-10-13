-- Supplements: Coach-Client Access RLS Fix
-- Migration: 20251011100000_supplements_coach_access_rls.sql
-- Purpose: Enable coaches to view/edit their clients' supplements
-- IDEMPOTENT: Safe to re-run

-- ============================================================================
-- 1) ENSURE BASE TABLES EXIST (minimal schema)
-- ============================================================================

-- SUPPLEMENTS (owner-scoped)
CREATE TABLE IF NOT EXISTS supplements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (char_length(name) >= 1 AND char_length(name) <= 100),
  dosage TEXT CHECK (char_length(dosage) <= 100),
  category TEXT DEFAULT 'general' CHECK (category IN (
    'vitamin', 'mineral', 'protein', 'pre_workout', 
    'post_workout', 'omega', 'probiotic', 'herbal', 'general'
  )),
  color TEXT DEFAULT '#6C83F7' CHECK (char_length(color) <= 7),
  icon TEXT DEFAULT 'medication' CHECK (char_length(icon) <= 50),
  notes TEXT CHECK (char_length(notes) <= 500),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add missing columns if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='supplements' AND column_name='owner_id') THEN
    ALTER TABLE supplements ADD COLUMN owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='supplements' AND column_name='is_active') THEN
    ALTER TABLE supplements ADD COLUMN is_active BOOLEAN DEFAULT true;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='supplements' AND column_name='notes') THEN
    ALTER TABLE supplements ADD COLUMN notes TEXT CHECK (char_length(notes) <= 500);
  END IF;
END $$;

-- SCHEDULES (owner-scoped)
CREATE TABLE IF NOT EXISTS supplement_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  supplement_id UUID NOT NULL REFERENCES supplements(id) ON DELETE CASCADE,
  kind TEXT NOT NULL DEFAULT 'fixed_times' CHECK (kind IN ('fixed_times', 'interval', 'weekly')),
  fixed_times JSONB DEFAULT '[]',      -- e.g., ["08:00","14:00","20:00"]
  interval_hours INT CHECK (interval_hours >= 1 AND interval_hours <= 24),
  dow INT[] DEFAULT '{}',              -- 0=Mon..6=Sun
  start_date DATE DEFAULT CURRENT_DATE,
  end_date DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add missing columns
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='supplement_schedules' AND column_name='owner_id') THEN
    ALTER TABLE supplement_schedules ADD COLUMN owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='supplement_schedules' AND column_name='kind') THEN
    ALTER TABLE supplement_schedules ADD COLUMN kind TEXT DEFAULT 'fixed_times';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='supplement_schedules' AND column_name='fixed_times') THEN
    ALTER TABLE supplement_schedules ADD COLUMN fixed_times JSONB DEFAULT '[]';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='supplement_schedules' AND column_name='dow') THEN
    ALTER TABLE supplement_schedules ADD COLUMN dow INT[] DEFAULT '{}';
  END IF;
END $$;

-- LOGS (owner-scoped)
CREATE TABLE IF NOT EXISTS supplement_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  schedule_id UUID NOT NULL REFERENCES supplement_schedules(id) ON DELETE CASCADE,
  taken_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'taken' CHECK (status IN ('taken','skipped','snoozed')),
  note TEXT CHECK (char_length(note) <= 500),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add missing columns
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='supplement_logs' AND column_name='owner_id') THEN
    ALTER TABLE supplement_logs ADD COLUMN owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='supplement_logs' AND column_name='note') THEN
    ALTER TABLE supplement_logs ADD COLUMN note TEXT CHECK (char_length(note) <= 500);
  END IF;
END $$;

-- ============================================================================
-- 2) INDEXES (idempotent)
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_supp_owner ON supplements(owner_id);
CREATE INDEX IF NOT EXISTS idx_supp_active ON supplements(is_active);
CREATE INDEX IF NOT EXISTS idx_supp_category ON supplements(category);

CREATE INDEX IF NOT EXISTS idx_sched_owner ON supplement_schedules(owner_id);
CREATE INDEX IF NOT EXISTS idx_sched_supplement ON supplement_schedules(supplement_id);
CREATE INDEX IF NOT EXISTS idx_sched_active ON supplement_schedules(is_active);

CREATE INDEX IF NOT EXISTS idx_logs_owner ON supplement_logs(owner_id);
CREATE INDEX IF NOT EXISTS idx_logs_schedule ON supplement_logs(schedule_id);
CREATE INDEX IF NOT EXISTS idx_logs_taken_at ON supplement_logs(taken_at);
CREATE INDEX IF NOT EXISTS idx_logs_status ON supplement_logs(status);

-- ============================================================================
-- 3) HELPER FUNCTIONS
-- ============================================================================

-- Check if current user is admin
CREATE OR REPLACE FUNCTION is_admin() 
RETURNS BOOLEAN
LANGUAGE SQL STABLE AS $$
  SELECT EXISTS(
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid() AND p.role IN ('admin','superadmin')
  );
$$;

-- Check if current user is a coach for a given client
CREATE OR REPLACE FUNCTION is_coach_for_client(client_user_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL STABLE AS $$
  SELECT EXISTS(
    SELECT 1 FROM coach_clients cc
    WHERE cc.coach_id = auth.uid()
      AND cc.client_id = client_user_id
      AND COALESCE(cc.status, 'active') = 'active'
  );
$$;

-- ============================================================================
-- 4) ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS
ALTER TABLE supplements ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplement_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplement_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to recreate them)
DO $$ 
BEGIN
  -- Supplements policies
  DROP POLICY IF EXISTS supp_owner_rw ON supplements;
  DROP POLICY IF EXISTS supp_coach_rw ON supplements;
  DROP POLICY IF EXISTS supp_admin_rw ON supplements;
  
  -- Schedules policies
  DROP POLICY IF EXISTS sched_owner_rw ON supplement_schedules;
  DROP POLICY IF EXISTS sched_coach_rw ON supplement_schedules;
  DROP POLICY IF EXISTS sched_admin_rw ON supplement_schedules;
  
  -- Logs policies
  DROP POLICY IF EXISTS logs_owner_rw ON supplement_logs;
  DROP POLICY IF EXISTS logs_coach_rw ON supplement_logs;
  DROP POLICY IF EXISTS logs_admin_rw ON supplement_logs;
END $$;

-- ============================================================================
-- SUPPLEMENTS POLICIES
-- ============================================================================

-- Owner can read/write their own supplements
CREATE POLICY supp_owner_rw ON supplements
  FOR ALL 
  USING (owner_id = auth.uid()) 
  WITH CHECK (owner_id = auth.uid());

-- Coach can read/write supplements for their active clients
CREATE POLICY supp_coach_rw ON supplements
  FOR ALL 
  USING (is_coach_for_client(owner_id))
  WITH CHECK (is_coach_for_client(owner_id));

-- Admin can read/write all supplements
CREATE POLICY supp_admin_rw ON supplements
  FOR ALL 
  USING (is_admin()) 
  WITH CHECK (is_admin());

-- ============================================================================
-- SCHEDULES POLICIES
-- ============================================================================

-- Owner can read/write their own schedules
CREATE POLICY sched_owner_rw ON supplement_schedules
  FOR ALL 
  USING (owner_id = auth.uid()) 
  WITH CHECK (owner_id = auth.uid());

-- Coach can read/write schedules for their active clients
CREATE POLICY sched_coach_rw ON supplement_schedules
  FOR ALL 
  USING (is_coach_for_client(owner_id))
  WITH CHECK (is_coach_for_client(owner_id));

-- Admin can read/write all schedules
CREATE POLICY sched_admin_rw ON supplement_schedules
  FOR ALL 
  USING (is_admin()) 
  WITH CHECK (is_admin());

-- ============================================================================
-- LOGS POLICIES
-- ============================================================================

-- Owner can read/write their own logs
CREATE POLICY logs_owner_rw ON supplement_logs
  FOR ALL 
  USING (owner_id = auth.uid()) 
  WITH CHECK (owner_id = auth.uid());

-- Coach can read/write logs for their active clients
CREATE POLICY logs_coach_rw ON supplement_logs
  FOR ALL 
  USING (is_coach_for_client(owner_id))
  WITH CHECK (is_coach_for_client(owner_id));

-- Admin can read/write all logs
CREATE POLICY logs_admin_rw ON supplement_logs
  FOR ALL 
  USING (is_admin()) 
  WITH CHECK (is_admin());

-- ============================================================================
-- 5) TRIGGERS
-- ============================================================================

-- Update updated_at on row changes
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to supplements
DROP TRIGGER IF EXISTS update_supplements_updated_at ON supplements;
CREATE TRIGGER update_supplements_updated_at
    BEFORE UPDATE ON supplements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to schedules
DROP TRIGGER IF EXISTS update_supplement_schedules_updated_at ON supplement_schedules;
CREATE TRIGGER update_supplement_schedules_updated_at
    BEFORE UPDATE ON supplement_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 6) COMMENTS
-- ============================================================================

COMMENT ON TABLE supplements IS 'Supplement definitions with owner-scoped access and coach visibility';
COMMENT ON TABLE supplement_schedules IS 'Supplement schedules (fixed times, intervals, weekly) with owner-scoped access';
COMMENT ON TABLE supplement_logs IS 'Supplement intake records with owner-scoped access';
COMMENT ON FUNCTION is_admin() IS 'Check if current user is admin/superadmin';
COMMENT ON FUNCTION is_coach_for_client(UUID) IS 'Check if current user is an active coach for the given client';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

