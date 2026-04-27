-- Comprehensive migration to apply all pending changes safely
-- This migration handles all the updates needed without conflicting with existing objects

BEGIN;

-- =====================================================
-- FIX 1: Add missing column to workout_plans
-- =====================================================
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;

-- =====================================================
-- FIX 2: Add missing indexes
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_workout_plans_archived ON workout_plans(is_archived);
CREATE INDEX IF NOT EXISTS idx_workout_plans_coach ON workout_plans(coach_id);
CREATE INDEX IF NOT EXISTS idx_workout_plans_template ON workout_plans(is_template) WHERE is_template = true;

-- =====================================================
-- FIX 3: Ensure all necessary tables exist
-- (These will be skipped if they already exist)
-- =====================================================

-- Create notification system tables if they don't exist
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT,
  data JSONB DEFAULT '{}',
  read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(user_id, read) WHERE read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- Enable RLS on notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Notification policies (using DO block to avoid conflicts)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Users can view their own notifications'
  ) THEN
    CREATE POLICY "Users can view their own notifications" ON notifications
      FOR SELECT USING (user_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Users can update their own notifications'
  ) THEN
    CREATE POLICY "Users can update their own notifications" ON notifications
      FOR UPDATE USING (user_id = auth.uid());
  END IF;
END $$;

-- =====================================================
-- FIX 4: Add missing columns to profiles table
-- =====================================================
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- =====================================================
-- COMMIT ALL CHANGES
-- =====================================================
COMMIT;

