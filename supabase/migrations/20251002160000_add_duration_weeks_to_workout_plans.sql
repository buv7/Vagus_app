-- Add missing columns to workout_plans table

ALTER TABLE workout_plans
ADD COLUMN IF NOT EXISTS duration_weeks INTEGER,
ADD COLUMN IF NOT EXISTS is_template BOOLEAN DEFAULT false;

-- Add comments to the columns
COMMENT ON COLUMN workout_plans.duration_weeks IS 'Total duration of the workout plan in weeks';
COMMENT ON COLUMN workout_plans.is_template IS 'Whether this plan is a template for reuse';
