-- Migration: Add missing columns to workout_logs and calendar_events
-- Created: 2025-10-02
-- Description: Adds client_id to workout_logs (with FK and index) and location to calendar_events

-- Add client_id column to workout_logs
ALTER TABLE workout_logs
ADD COLUMN IF NOT EXISTS client_id UUID;

-- Add foreign key constraint for workout_logs.client_id
-- References auth.users(id) with CASCADE delete
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'workout_logs_client_id_fkey'
  ) THEN
    ALTER TABLE workout_logs
    ADD CONSTRAINT workout_logs_client_id_fkey
    FOREIGN KEY (client_id)
    REFERENCES auth.users(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add index on workout_logs.client_id for performance
CREATE INDEX IF NOT EXISTS idx_workout_logs_client_id
ON workout_logs(client_id);

-- Add location column to calendar_events
ALTER TABLE calendar_events
ADD COLUMN IF NOT EXISTS location TEXT;

-- Add comments for documentation
COMMENT ON COLUMN workout_logs.client_id IS 'References the client (user) who performed the workout. NULL allowed for logs without specific client assignment.';
COMMENT ON COLUMN calendar_events.location IS 'Location of the calendar event (e.g., "Gym A", "Online", etc.)';
