-- Coach-Client Period Countdown System
-- Track coaching periods (e.g., 12-week blocks)

CREATE TABLE IF NOT EXISTS public.coach_client_periods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  start_date date NOT NULL,
  duration_weeks int NOT NULL DEFAULT 12,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_coach_client_periods_coach ON public.coach_client_periods(coach_id);
CREATE INDEX IF NOT EXISTS idx_coach_client_periods_client ON public.coach_client_periods(client_id);
CREATE INDEX IF NOT EXISTS idx_coach_client_periods_active ON public.coach_client_periods(coach_id, client_id, start_date);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_coach_client_periods_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_coach_client_periods_updated_at') THEN
    CREATE TRIGGER trigger_update_coach_client_periods_updated_at
      BEFORE UPDATE ON public.coach_client_periods
      FOR EACH ROW
      EXECUTE FUNCTION update_coach_client_periods_updated_at();
  END IF;
END $$;

-- Enable RLS
ALTER TABLE public.coach_client_periods ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Coach and client can read their own periods
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='coach_client_periods' AND policyname='ccp_read_own') THEN
    CREATE POLICY ccp_read_own ON public.coach_client_periods FOR SELECT
    USING (
      coach_id = auth.uid() 
      OR client_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('admin', 'superadmin')
      )
    );
  END IF;
END $$;

-- Coach can create/update periods for their clients
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='coach_client_periods' AND policyname='ccp_coach_manage') THEN
    CREATE POLICY ccp_coach_manage ON public.coach_client_periods
    FOR ALL
    USING (
      coach_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('admin', 'superadmin')
      )
    )
    WITH CHECK (
      coach_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('admin', 'superadmin')
      )
    );
  END IF;
END $$;
