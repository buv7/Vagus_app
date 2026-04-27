-- Sprint 5: Client Dashboard - Compliance & Analytics
-- Add compliance tracking and file attachments to check-ins

-- 1. Add compliance_score to checkins table
ALTER TABLE IF EXISTS public.checkins
ADD COLUMN IF NOT EXISTS compliance_score INTEGER DEFAULT 0 CHECK (compliance_score >= 0 AND compliance_score <= 100);

-- 2. Create checkin_files junction table
CREATE TABLE IF NOT EXISTS public.checkin_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checkin_id UUID NOT NULL REFERENCES public.checkins(id) ON DELETE CASCADE,
  file_id UUID NOT NULL REFERENCES public.user_files(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(checkin_id, file_id)
);

CREATE INDEX IF NOT EXISTS idx_checkin_files_checkin ON public.checkin_files(checkin_id);
CREATE INDEX IF NOT EXISTS idx_checkin_files_file ON public.checkin_files(file_id);

-- 3. Enable RLS on checkin_files
ALTER TABLE public.checkin_files ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for checkin_files
-- Users can view their own checkin files (as client)
DROP POLICY IF EXISTS "Users can view own checkin files" ON public.checkin_files;
CREATE POLICY "Users can view own checkin files"
ON public.checkin_files FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.checkins
    WHERE id = checkin_files.checkin_id
    AND client_id = auth.uid()
  )
);

-- Coaches can view client checkin files
DROP POLICY IF EXISTS "Coaches can view client checkin files" ON public.checkin_files;
CREATE POLICY "Coaches can view client checkin files"
ON public.checkin_files FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.checkins c
    JOIN public.coach_clients cc ON c.client_id = cc.client_id
    WHERE c.id = checkin_files.checkin_id
    AND cc.coach_id = auth.uid()
    AND cc.status = 'active'
  )
);

-- Users can attach files to their own checkins
DROP POLICY IF EXISTS "Users can attach files to own checkins" ON public.checkin_files;
CREATE POLICY "Users can attach files to own checkins"
ON public.checkin_files FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.checkins
    WHERE id = checkin_files.checkin_id
    AND client_id = auth.uid()
  )
  AND EXISTS (
    SELECT 1 FROM public.user_files
    WHERE id = checkin_files.file_id
    AND user_id = auth.uid()
  )
);

-- Users can remove files from their own checkins
DROP POLICY IF EXISTS "Users can remove files from own checkins" ON public.checkin_files;
CREATE POLICY "Users can remove files from own checkins"
ON public.checkin_files FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.checkins
    WHERE id = checkin_files.checkin_id
    AND client_id = auth.uid()
  )
);

-- 5. Function to calculate compliance score
CREATE OR REPLACE FUNCTION public.calculate_compliance_score(
  p_client_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_days INTEGER;
  v_compliant_days INTEGER;
  v_score INTEGER;
BEGIN
  -- Calculate total days in range
  v_total_days := (p_end_date - p_start_date) + 1;
  
  -- Count days with checkins meeting criteria
  SELECT COUNT(DISTINCT DATE(created_at))
  INTO v_compliant_days
  FROM public.checkins
  WHERE client_id = p_client_id
  AND DATE(created_at) BETWEEN p_start_date AND p_end_date
  AND (
    notes IS NOT NULL AND LENGTH(notes) > 10
    OR weight IS NOT NULL
    OR EXISTS (
      SELECT 1 FROM public.checkin_files cf
      WHERE cf.checkin_id = checkins.id
    )
  );
  
  -- Calculate percentage
  IF v_total_days > 0 THEN
    v_score := ROUND((v_compliant_days::DECIMAL / v_total_days) * 100);
  ELSE
    v_score := 0;
  END IF;
  
  RETURN v_score;
END;
$$;

-- 6. Function to get weekly compliance streak
CREATE OR REPLACE FUNCTION public.get_compliance_streak(p_client_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_streak INTEGER := 0;
  v_current_week DATE;
  v_has_checkin BOOLEAN;
BEGIN
  v_current_week := DATE_TRUNC('week', CURRENT_DATE)::DATE;
  
  -- Loop backwards through weeks
  LOOP
    -- Check if user has checkin this week
    SELECT EXISTS (
      SELECT 1 FROM public.checkins
      WHERE client_id = p_client_id
      AND DATE(created_at) >= v_current_week
      AND DATE(created_at) < v_current_week + INTERVAL '7 days'
    ) INTO v_has_checkin;
    
    -- Break if no checkin found
    EXIT WHEN NOT v_has_checkin;
    
    -- Increment streak and move to previous week
    v_streak := v_streak + 1;
    v_current_week := v_current_week - INTERVAL '7 days';
    
    -- Safety limit
    EXIT WHEN v_streak >= 52;
  END LOOP;
  
  RETURN v_streak;
END;
$$;

-- 7. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.checkin_files TO authenticated;

COMMENT ON TABLE public.checkin_files IS 'Links files to check-ins for progress tracking';
COMMENT ON COLUMN public.checkins.compliance_score IS 'Weekly compliance percentage (0-100)';
COMMENT ON FUNCTION public.calculate_compliance_score IS 'Calculates user compliance over date range';
COMMENT ON FUNCTION public.get_compliance_streak IS 'Returns current weekly check-in streak';
