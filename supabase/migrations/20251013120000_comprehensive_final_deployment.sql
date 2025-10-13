-- =====================================================
-- COMPREHENSIVE DEPLOYMENT MIGRATION
-- Safely applies all remaining schema updates
-- =====================================================

BEGIN;

-- =====================================================
-- SPRINT 3: Files & Media System
-- =====================================================

-- User files table
CREATE TABLE IF NOT EXISTS user_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT,
  file_type TEXT,
  mime_type TEXT,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_user_files_user ON user_files(user_id);
CREATE INDEX IF NOT EXISTS idx_user_files_uploaded ON user_files(uploaded_at DESC);

ALTER TABLE user_files ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_files' AND policyname = 'Users can view their own files'
  ) THEN
    CREATE POLICY "Users can view their own files" ON user_files
      FOR SELECT USING (user_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_files' AND policyname = 'Users can upload their own files'
  ) THEN
    CREATE POLICY "Users can upload their own files" ON user_files
      FOR INSERT WITH CHECK (user_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_files' AND policyname = 'Users can delete their own files'
  ) THEN
    CREATE POLICY "Users can delete their own files" ON user_files
      FOR DELETE USING (user_id = auth.uid());
  END IF;
END $$;

-- =====================================================
-- SPRINT 5: Progress & Analytics
-- =====================================================

-- Client progress tracking
CREATE TABLE IF NOT EXISTS client_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  coach_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  progress_type TEXT NOT NULL,
  value DECIMAL(10,2),
  unit TEXT,
  notes TEXT,
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_client_progress_client ON client_progress(client_id);
CREATE INDEX IF NOT EXISTS idx_client_progress_coach ON client_progress(coach_id);
CREATE INDEX IF NOT EXISTS idx_client_progress_recorded ON client_progress(recorded_at DESC);

ALTER TABLE client_progress ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'client_progress' AND policyname = 'Clients can view their own progress'
  ) THEN
    CREATE POLICY "Clients can view their own progress" ON client_progress
      FOR SELECT USING (client_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'client_progress' AND policyname = 'Coaches can view client progress'
  ) THEN
    CREATE POLICY "Coaches can view client progress" ON client_progress
      FOR SELECT USING (coach_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'client_progress' AND policyname = 'Coaches can create client progress'
  ) THEN
    CREATE POLICY "Coaches can create client progress" ON client_progress
      FOR INSERT WITH CHECK (coach_id = auth.uid());
  END IF;
END $$;

-- =====================================================
-- SPRINT 9: Billing System
-- =====================================================

-- Subscription plans
CREATE TABLE IF NOT EXISTS subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  price_monthly DECIMAL(10,2),
  price_yearly DECIMAL(10,2),
  features JSONB DEFAULT '[]',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User subscriptions
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES subscription_plans(id) ON DELETE SET NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'cancelled', 'expired', 'trial')),
  billing_cycle TEXT CHECK (billing_cycle IN ('monthly', 'yearly')),
  current_period_start TIMESTAMP WITH TIME ZONE,
  current_period_end TIMESTAMP WITH TIME ZONE,
  cancel_at_period_end BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON user_subscriptions(status);

ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_subscriptions' AND policyname = 'Users can view their own subscriptions'
  ) THEN
    CREATE POLICY "Users can view their own subscriptions" ON user_subscriptions
      FOR SELECT USING (user_id = auth.uid());
  END IF;
END $$;

-- =====================================================
-- SPRINT 10: Settings & Data Export
-- =====================================================

-- User devices for push notifications
CREATE TABLE IF NOT EXISTS user_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  onesignal_id TEXT,
  platform TEXT,
  model TEXT,
  os_version TEXT,
  app_version TEXT,
  last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, device_id)
);

CREATE INDEX IF NOT EXISTS idx_user_devices_user ON user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_onesignal ON user_devices(onesignal_id);

ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_devices' AND policyname = 'Users can manage their own devices'
  ) THEN
    CREATE POLICY "Users can manage their own devices" ON user_devices
      FOR ALL USING (user_id = auth.uid());
  END IF;
END $$;

-- =====================================================
-- SPRINT 11: Performance Indexes
-- =====================================================

-- Add performance indexes to existing tables
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_updated_at ON profiles(updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_workout_plans_start_date ON workout_plans(start_date);
CREATE INDEX IF NOT EXISTS idx_workout_plans_ai_generated ON workout_plans(ai_generated) WHERE ai_generated = TRUE;

-- =====================================================
-- Add missing columns safely
-- =====================================================

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS duration_weeks INTEGER;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS coach_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS ai_generated BOOLEAN DEFAULT FALSE;

-- =====================================================
-- Create missing indexes
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_workout_plans_archived ON workout_plans(is_archived);
CREATE INDEX IF NOT EXISTS idx_workout_plans_coach ON workout_plans(coach_id);

COMMIT;

