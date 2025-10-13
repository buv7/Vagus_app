-- Add missing is_archived column to workout_plans if it doesn't exist
ALTER TABLE workout_plans 
ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;

-- Create index on is_archived column if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_workout_plans_archived ON workout_plans(is_archived);

COMMENT ON COLUMN workout_plans.is_archived IS 'Flag to mark archived workout plans';

