-- Add coach_id column to workout_plans table
-- This column references the coach (from auth.users) who created the workout plan

-- Step 1: Add the coach_id column with foreign key reference
ALTER TABLE workout_plans
ADD COLUMN IF NOT EXISTS coach_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Step 2: Create index for performance optimization
CREATE INDEX IF NOT EXISTS idx_workout_plans_coach_id ON workout_plans(coach_id);

-- Step 3: Migrate existing data from created_by to coach_id (if created_by exists)
-- This will only update rows where coach_id is NULL and created_by has a value
UPDATE workout_plans
SET coach_id = created_by
WHERE coach_id IS NULL AND created_by IS NOT NULL;

-- Step 4: Add comment for documentation
COMMENT ON COLUMN workout_plans.coach_id IS 'References the coach (auth.users) who created this workout plan';
