-- Program Ingest System
-- OCR + AI parsing → staged import for coaches

-- 1. Create ingest_jobs table
CREATE TABLE IF NOT EXISTS public.ingest_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  source_file_id UUID REFERENCES public.user_files(id) ON DELETE SET NULL,
  source_text TEXT,
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'needs_review', 'applied', 'failed')),
  result_summary JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ingest_jobs_coach ON public.ingest_jobs(coach_id);
CREATE INDEX IF NOT EXISTS idx_ingest_jobs_status ON public.ingest_jobs(status);
CREATE INDEX IF NOT EXISTS idx_ingest_jobs_created ON public.ingest_jobs(created_at DESC);

-- 2. Create ingest_results table
CREATE TABLE IF NOT EXISTS public.ingest_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES public.ingest_jobs(id) ON DELETE CASCADE,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ingest_results_job ON public.ingest_results(job_id);

-- 3. Enable RLS
ALTER TABLE public.ingest_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingest_results ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for ingest_jobs
-- Coach owns their jobs
DROP POLICY IF EXISTS "coach_owns_jobs" ON public.ingest_jobs;
CREATE POLICY "coach_owns_jobs" ON public.ingest_jobs
  FOR ALL
  TO authenticated
  USING (auth.uid() = coach_id)
  WITH CHECK (auth.uid() = coach_id);

-- 5. RLS Policies for ingest_results
-- Coach reads results
DROP POLICY IF EXISTS "coach_reads_results" ON public.ingest_results;
CREATE POLICY "coach_reads_results" ON public.ingest_results
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.ingest_jobs j
      WHERE j.id = job_id 
      AND j.coach_id = auth.uid()
    )
  );

-- Service role can insert results
DROP POLICY IF EXISTS "service_role_insert_results" ON public.ingest_results;
CREATE POLICY "service_role_insert_results" ON public.ingest_results
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- 6. Trigger to update ingest_jobs timestamp
CREATE OR REPLACE FUNCTION public.update_ingest_job_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_ingest_job_timestamp ON public.ingest_jobs;
CREATE TRIGGER trigger_update_ingest_job_timestamp
BEFORE UPDATE ON public.ingest_jobs
FOR EACH ROW
EXECUTE FUNCTION public.update_ingest_job_timestamp();

-- 7. Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.ingest_jobs TO authenticated;
GRANT SELECT ON public.ingest_results TO authenticated;

-- 8. Comments
COMMENT ON TABLE public.ingest_jobs IS 'Coach program ingest jobs (OCR + AI parsing)';
COMMENT ON TABLE public.ingest_results IS 'Parsed program data awaiting review and application';
COMMENT ON COLUMN public.ingest_jobs.status IS 'queued|processing|needs_review|applied|failed';
COMMENT ON COLUMN public.ingest_results.payload IS 'Structured program data (notes, supplements, nutrition, workouts)';

