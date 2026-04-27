-- Safe schema updates - only add missing columns and indexes

BEGIN;

-- Add missing columns to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Add missing columns to workout_plans if table exists
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'workout_plans') THEN
    ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;
    ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS duration_weeks INTEGER;
    ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS ai_generated BOOLEAN DEFAULT FALSE;
    
    -- Try to add coach_id if it doesn't exist
    IF NOT EXISTS (
      SELECT FROM information_schema.columns 
      WHERE table_name = 'workout_plans' AND column_name = 'coach_id'
    ) THEN
      ALTER TABLE workout_plans ADD COLUMN coach_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

-- Add performance indexes
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_updated_at ON profiles(updated_at DESC);

-- Workout plans indexes (only if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'workout_plans') THEN
    CREATE INDEX IF NOT EXISTS idx_workout_plans_archived ON workout_plans(is_archived);
    CREATE INDEX IF NOT EXISTS idx_workout_plans_coach ON workout_plans(coach_id);
    CREATE INDEX IF NOT EXISTS idx_workout_plans_start_date ON workout_plans(start_date);
    CREATE INDEX IF NOT EXISTS idx_workout_plans_ai_generated ON workout_plans(ai_generated) WHERE ai_generated = TRUE;
  END IF;
END $$;

-- Add uploaded_at column to user_files if table exists but column doesn't
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_files') THEN
    IF NOT EXISTS (
      SELECT FROM information_schema.columns 
      WHERE table_name = 'user_files' AND column_name = 'uploaded_at'
    ) THEN
      ALTER TABLE user_files ADD COLUMN uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    CREATE INDEX IF NOT EXISTS idx_user_files_user ON user_files(user_id);
    CREATE INDEX IF NOT EXISTS idx_user_files_uploaded ON user_files(uploaded_at DESC);
  END IF;
END $$;

COMMIT;

