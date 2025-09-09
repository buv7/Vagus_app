-- Coach Requests System
-- Handle coach-client connection requests

-- Coach requests table
CREATE TABLE IF NOT EXISTS public.coach_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  message text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(coach_id, client_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_coach_requests_coach ON public.coach_requests(coach_id);
CREATE INDEX IF NOT EXISTS idx_coach_requests_client ON public.coach_requests(client_id);
CREATE INDEX IF NOT EXISTS idx_coach_requests_status ON public.coach_requests(status);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_coach_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_coach_requests_updated_at') THEN
    CREATE TRIGGER trigger_update_coach_requests_updated_at
      BEFORE UPDATE ON public.coach_requests
      FOR EACH ROW
      EXECUTE FUNCTION update_coach_requests_updated_at();
  END IF;
END $$;

-- Enable RLS
ALTER TABLE public.coach_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Coach can read/write their own requests
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='coach_requests' AND policyname='cr_rw_coach') THEN
    CREATE POLICY cr_rw_coach ON public.coach_requests
    FOR ALL
    USING (coach_id = auth.uid())
    WITH CHECK (coach_id = auth.uid());
  END IF;
END $$;

-- Client can read requests sent to them
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='coach_requests' AND policyname='cr_read_client') THEN
    CREATE POLICY cr_read_client ON public.coach_requests FOR SELECT
    USING (client_id = auth.uid());
  END IF;
END $$;

-- Admins can read all requests
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='coach_requests' AND policyname='cr_admin_all') THEN
    CREATE POLICY cr_admin_all ON public.coach_requests
    FOR ALL
    USING (
      EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('admin', 'superadmin')
      )
    )
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('admin', 'superadmin')
      )
    );
  END IF;
END $$;
