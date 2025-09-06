-- Fix missing attachments column in calendar_events table
ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS attachments jsonb DEFAULT '[]'::jsonb;
