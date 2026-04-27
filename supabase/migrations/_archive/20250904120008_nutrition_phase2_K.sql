-- Phase 2 / Part K: Hydration & Supplements
-- Add hydration logging and supplement tracking

-- Hydration logs table
CREATE TABLE IF NOT EXISTS public.nutrition_hydration_logs (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date date NOT NULL,
  ml int NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, date)
);

-- Supplements table
CREATE TABLE IF NOT EXISTS public.nutrition_supplements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL REFERENCES public.nutrition_plans(id) ON DELETE CASCADE,
  day_index int NOT NULL,
  name text NOT NULL,
  dosage text,
  timing text, -- 'morning'|'preworkout'|'bedtime'|'with_meal'|'other'
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_hydration_user ON public.nutrition_hydration_logs(user_id, date);
CREATE INDEX IF NOT EXISTS idx_supplements_plan_day ON public.nutrition_supplements(plan_id, day_index);
CREATE INDEX IF NOT EXISTS idx_supplements_timing ON public.nutrition_supplements(timing) WHERE timing IS NOT NULL;

-- Updated_at trigger for nutrition_supplements
CREATE OR REPLACE FUNCTION update_nutrition_supplements_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_nutrition_supplements_updated_at') THEN
    CREATE TRIGGER trigger_update_nutrition_supplements_updated_at
      BEFORE UPDATE ON public.nutrition_supplements
      FOR EACH ROW
      EXECUTE FUNCTION update_nutrition_supplements_updated_at();
  END IF;
END $$;

-- Enable RLS on both tables
ALTER TABLE public.nutrition_hydration_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_supplements ENABLE ROW LEVEL SECURITY;

-- RLS policies for nutrition_hydration_logs
-- Users can read/write their own hydration logs
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'nutrition_hydration_logs' AND policyname = 'nutrition_hydration_logs_own') THEN
    CREATE POLICY nutrition_hydration_logs_own ON public.nutrition_hydration_logs
      FOR ALL
      TO authenticated
      USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- Coaches can read their clients' hydration logs
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'nutrition_hydration_logs' AND policyname = 'nutrition_hydration_logs_coach_read') THEN
    CREATE POLICY nutrition_hydration_logs_coach_read ON public.nutrition_hydration_logs
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.nutrition_plans np
          WHERE np.client_id = nutrition_hydration_logs.user_id
          AND np.created_by = auth.uid()
        )
      );
  END IF;
END $$;

-- RLS policies for nutrition_supplements
-- Users can read supplements for plans they have access to
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'nutrition_supplements' AND policyname = 'nutrition_supplements_read') THEN
    CREATE POLICY nutrition_supplements_read ON public.nutrition_supplements
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.nutrition_plans np
          WHERE np.id = nutrition_supplements.plan_id
          AND (np.client_id = auth.uid() OR np.created_by = auth.uid())
        )
      );
  END IF;
END $$;

-- Coaches can manage supplements for plans they created
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'nutrition_supplements' AND policyname = 'nutrition_supplements_manage_coach') THEN
    CREATE POLICY nutrition_supplements_manage_coach ON public.nutrition_supplements
      FOR ALL
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.nutrition_plans np
          WHERE np.id = nutrition_supplements.plan_id
          AND np.created_by = auth.uid()
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.nutrition_plans np
          WHERE np.id = nutrition_supplements.plan_id
          AND np.created_by = auth.uid()
        )
      );
  END IF;
END $$;

-- Analytics views for hydration and supplements
CREATE OR REPLACE VIEW nutrition_hydration_summary AS
SELECT 
  user_id,
  date,
  ml,
  CASE 
    WHEN ml >= 3000 THEN 'excellent'
    WHEN ml >= 2000 THEN 'good'
    WHEN ml >= 1000 THEN 'fair'
    ELSE 'low'
  END as hydration_status,
  updated_at
FROM public.nutrition_hydration_logs
WHERE date >= CURRENT_DATE - INTERVAL '30 days';

CREATE OR REPLACE VIEW nutrition_supplements_summary AS
SELECT 
  plan_id,
  day_index,
  COUNT(*) as total_supplements,
  COUNT(*) FILTER (WHERE timing IS NOT NULL) as supplements_with_timing,
  STRING_AGG(DISTINCT timing, ', ') as timings_used
FROM public.nutrition_supplements
GROUP BY plan_id, day_index;

-- Grant access to the views
GRANT SELECT ON public.nutrition_hydration_summary TO authenticated;
GRANT SELECT ON public.nutrition_supplements_summary TO authenticated;

-- Add hydration target to preferences if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'nutrition_preferences' 
    AND column_name = 'hydration_target_ml'
  ) THEN
    ALTER TABLE public.nutrition_preferences
      ADD COLUMN IF NOT EXISTS hydration_target_ml int DEFAULT 3000;
  END IF;
END $$;
