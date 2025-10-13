-- Sprint 7: Calendar & Booking - Recurrence, Tags, Attachments, Indices
-- Add recurring event support, tagging, and booking conflict prevention

-- 1. Add new columns to calendar_events
ALTER TABLE IF EXISTS public.calendar_events
  ADD COLUMN IF NOT EXISTS rrule TEXT,
  ADD COLUMN IF NOT EXISTS attachments JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS reminder_minutes INT[] DEFAULT '{30}';

-- 2. Add performance indexes
CREATE INDEX IF NOT EXISTS idx_calendar_events_start ON public.calendar_events(start_at);
CREATE INDEX IF NOT EXISTS idx_calendar_events_rrule ON public.calendar_events(rrule);
CREATE INDEX IF NOT EXISTS idx_calendar_events_tags ON public.calendar_events USING GIN(tags);

-- 3. Create booking_requests table if not exists
CREATE TABLE IF NOT EXISTS public.booking_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_id UUID REFERENCES public.calendar_events(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_booking_requests_coach ON public.booking_requests(coach_id);
CREATE INDEX IF NOT EXISTS idx_booking_requests_client ON public.booking_requests(client_id);
CREATE INDEX IF NOT EXISTS idx_booking_requests_status ON public.booking_requests(status) WHERE status = 'pending';

-- 4. Enable RLS on booking_requests
ALTER TABLE public.booking_requests ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for booking_requests
DO $$
BEGIN
  -- Client or coach can view their booking requests
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'booking_requests' AND policyname = 'client_or_coach_view'
  ) THEN
    CREATE POLICY "client_or_coach_view" ON public.booking_requests
      FOR SELECT 
      USING (auth.uid() IN (client_id, coach_id));
  END IF;

  -- Client can create booking requests
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'booking_requests' AND policyname = 'client_create'
  ) THEN
    CREATE POLICY "client_create" ON public.booking_requests
      FOR INSERT 
      WITH CHECK (auth.uid() = client_id);
  END IF;

  -- Coach can update booking requests (approve/reject)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'booking_requests' AND policyname = 'coach_update'
  ) THEN
    CREATE POLICY "coach_update" ON public.booking_requests
      FOR UPDATE 
      USING (auth.uid() = coach_id) 
      WITH CHECK (auth.uid() = coach_id);
  END IF;
END$$;

-- 6. Function to check calendar conflicts
CREATE OR REPLACE FUNCTION public.check_calendar_conflicts(
  p_coach_id UUID,
  p_start_at TIMESTAMPTZ,
  p_end_at TIMESTAMPTZ,
  p_exclude_event_id UUID DEFAULT NULL
)
RETURNS TABLE(
  conflict_id UUID,
  conflict_title TEXT,
  conflict_start TIMESTAMPTZ,
  conflict_end TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ce.id,
    ce.title,
    ce.start_at,
    ce.end_at
  FROM public.calendar_events ce
  WHERE ce.coach_id = p_coach_id
    AND (p_exclude_event_id IS NULL OR ce.id != p_exclude_event_id)
    AND ce.start_at < p_end_at
    AND ce.end_at > p_start_at
  ORDER BY ce.start_at;
END;
$$;

-- 7. Trigger to update booking_requests timestamp
CREATE OR REPLACE FUNCTION public.update_booking_request_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_booking_request_timestamp ON public.booking_requests;
CREATE TRIGGER trigger_update_booking_request_timestamp
BEFORE UPDATE ON public.booking_requests
FOR EACH ROW
EXECUTE FUNCTION public.update_booking_request_timestamp();

-- 8. Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.booking_requests TO authenticated;

-- 9. Comments
COMMENT ON COLUMN public.calendar_events.rrule IS 'RFC 5545 recurrence rule (e.g., FREQ=WEEKLY;BYDAY=MO,WE,FR)';
COMMENT ON COLUMN public.calendar_events.tags IS 'User-defined or AI-suggested tags for categorization';
COMMENT ON COLUMN public.calendar_events.attachments IS 'Array of file URLs or file_ids attached to event';
COMMENT ON COLUMN public.calendar_events.reminder_minutes IS 'Array of minutes before event to send reminders (e.g., [30, 15, 5])';
COMMENT ON TABLE public.booking_requests IS 'Client booking requests requiring coach approval';
COMMENT ON FUNCTION public.check_calendar_conflicts IS 'Returns overlapping events for a coach in given time range';

