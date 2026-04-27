-- Fix calendar_events table - add missing attachments column
-- This migration fixes the issue where the attachments column is missing

-- Check if calendar_events table exists and add attachments column if missing
DO $$
BEGIN
    -- Check if the table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'calendar_events' AND table_schema = 'public') THEN
        -- Check if attachments column exists
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calendar_events' AND table_schema = 'public' AND column_name = 'attachments') THEN
            -- Add the missing attachments column
            ALTER TABLE public.calendar_events ADD COLUMN attachments jsonb DEFAULT '[]';
            RAISE NOTICE 'Added missing attachments column to calendar_events table';
        ELSE
            RAISE NOTICE 'attachments column already exists in calendar_events table';
        END IF;
        
        -- Create the GIN index for attachments if it doesn't exist
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'calendar_events' AND indexname = 'idx_calendar_events_attachments') THEN
            CREATE INDEX idx_calendar_events_attachments ON public.calendar_events USING gin(attachments);
            RAISE NOTICE 'Created GIN index for attachments column';
        ELSE
            RAISE NOTICE 'GIN index for attachments already exists';
        END IF;
    ELSE
        RAISE NOTICE 'calendar_events table does not exist - this migration will be skipped';
    END IF;
END $$;
