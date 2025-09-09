-- Coach Plans System
-- Handle workout and nutrition plans

-- Workout plans table
CREATE TABLE IF NOT EXISTS public.workout_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  difficulty text CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced')) DEFAULT 'Beginner',
  duration_weeks int DEFAULT 8,
  is_template boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Nutrition plans table
CREATE TABLE IF NOT EXISTS public.nutrition_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  difficulty text CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced')) DEFAULT 'Beginner',
  duration_weeks int DEFAULT 8,
  is_template boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Plan assignments table (links plans to clients)
CREATE TABLE IF NOT EXISTS public.plan_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL,
  plan_type text NOT NULL CHECK (plan_type IN ('workout', 'nutrition')),
  client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  assigned_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  assigned_at timestamptz DEFAULT now(),
  status text DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused')),
  UNIQUE(plan_id, plan_type, client_id)
);

-- Plan ratings table
CREATE TABLE IF NOT EXISTS public.plan_ratings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL,
  plan_type text NOT NULL CHECK (plan_type IN ('workout', 'nutrition')),
  client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating int CHECK (rating >= 1 AND rating <= 5),
  review text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(plan_id, plan_type, client_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_workout_plans_coach ON public.workout_plans(coach_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_plans_coach ON public.nutrition_plans(coach_id);
CREATE INDEX IF NOT EXISTS idx_plan_assignments_client ON public.plan_assignments(client_id);
CREATE INDEX IF NOT EXISTS idx_plan_assignments_plan ON public.plan_assignments(plan_id, plan_type);
CREATE INDEX IF NOT EXISTS idx_plan_ratings_plan ON public.plan_ratings(plan_id, plan_type);

-- Updated_at triggers
CREATE OR REPLACE FUNCTION update_workout_plans_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_nutrition_plans_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_workout_plans_updated_at') THEN
    CREATE TRIGGER trigger_update_workout_plans_updated_at
      BEFORE UPDATE ON public.workout_plans
      FOR EACH ROW
      EXECUTE FUNCTION update_workout_plans_updated_at();
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_nutrition_plans_updated_at') THEN
    CREATE TRIGGER trigger_update_nutrition_plans_updated_at
      BEFORE UPDATE ON public.nutrition_plans
      FOR EACH ROW
      EXECUTE FUNCTION update_nutrition_plans_updated_at();
  END IF;
END $$;

-- Enable RLS
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_ratings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for workout_plans
DO $$ 
BEGIN
  -- Coach can read/write their own plans
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='workout_plans' AND policyname='wp_rw_coach') THEN
    CREATE POLICY wp_rw_coach ON public.workout_plans
    FOR ALL
    USING (coach_id = auth.uid())
    WITH CHECK (coach_id = auth.uid());
  END IF;

  -- Clients can read plans assigned to them
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='workout_plans' AND policyname='wp_read_assigned') THEN
    CREATE POLICY wp_read_assigned ON public.workout_plans FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM public.plan_assignments pa
        WHERE pa.plan_id = workout_plans.id 
        AND pa.plan_type = 'workout'
        AND pa.client_id = auth.uid()
      )
    );
  END IF;

  -- Everyone can read template plans
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='workout_plans' AND policyname='wp_read_templates') THEN
    CREATE POLICY wp_read_templates ON public.workout_plans FOR SELECT
    USING (is_template = true);
  END IF;
END $$;

-- RLS Policies for nutrition_plans
DO $$ 
BEGIN
  -- Coach can read/write their own plans
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='nutrition_plans' AND policyname='np_rw_coach') THEN
    CREATE POLICY np_rw_coach ON public.nutrition_plans
    FOR ALL
    USING (coach_id = auth.uid())
    WITH CHECK (coach_id = auth.uid());
  END IF;

  -- Clients can read plans assigned to them
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='nutrition_plans' AND policyname='np_read_assigned') THEN
    CREATE POLICY np_read_assigned ON public.nutrition_plans FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM public.plan_assignments pa
        WHERE pa.plan_id = nutrition_plans.id 
        AND pa.plan_type = 'nutrition'
        AND pa.client_id = auth.uid()
      )
    );
  END IF;

  -- Everyone can read template plans
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='nutrition_plans' AND policyname='np_read_templates') THEN
    CREATE POLICY np_read_templates ON public.nutrition_plans FOR SELECT
    USING (is_template = true);
  END IF;
END $$;

-- RLS Policies for plan_assignments
DO $$ 
BEGIN
  -- Coach can manage assignments for their plans
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='plan_assignments' AND policyname='pa_rw_coach') THEN
    CREATE POLICY pa_rw_coach ON public.plan_assignments
    FOR ALL
    USING (
      assigned_by = auth.uid() OR
      EXISTS (
        SELECT 1 FROM public.workout_plans wp
        WHERE wp.id = plan_assignments.plan_id 
        AND wp.coach_id = auth.uid()
        AND plan_assignments.plan_type = 'workout'
      ) OR
      EXISTS (
        SELECT 1 FROM public.nutrition_plans np
        WHERE np.id = plan_assignments.plan_id 
        AND np.coach_id = auth.uid()
        AND plan_assignments.plan_type = 'nutrition'
      )
    )
    WITH CHECK (
      assigned_by = auth.uid() OR
      EXISTS (
        SELECT 1 FROM public.workout_plans wp
        WHERE wp.id = plan_assignments.plan_id 
        AND wp.coach_id = auth.uid()
        AND plan_assignments.plan_type = 'workout'
      ) OR
      EXISTS (
        SELECT 1 FROM public.nutrition_plans np
        WHERE np.id = plan_assignments.plan_id 
        AND np.coach_id = auth.uid()
        AND plan_assignments.plan_type = 'nutrition'
      )
    );
  END IF;

  -- Clients can read their own assignments
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='plan_assignments' AND policyname='pa_read_client') THEN
    CREATE POLICY pa_read_client ON public.plan_assignments FOR SELECT
    USING (client_id = auth.uid());
  END IF;
END $$;

-- RLS Policies for plan_ratings
DO $$ 
BEGIN
  -- Clients can read/write their own ratings
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='plan_ratings' AND policyname='pr_rw_client') THEN
    CREATE POLICY pr_rw_client ON public.plan_ratings
    FOR ALL
    USING (client_id = auth.uid())
    WITH CHECK (client_id = auth.uid());
  END IF;

  -- Coaches can read ratings for their plans
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='plan_ratings' AND policyname='pr_read_coach') THEN
    CREATE POLICY pr_read_coach ON public.plan_ratings FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM public.workout_plans wp
        WHERE wp.id = plan_ratings.plan_id 
        AND wp.coach_id = auth.uid()
        AND plan_ratings.plan_type = 'workout'
      ) OR
      EXISTS (
        SELECT 1 FROM public.nutrition_plans np
        WHERE np.id = plan_ratings.plan_id 
        AND np.coach_id = auth.uid()
        AND plan_ratings.plan_type = 'nutrition'
      )
    );
  END IF;
END $$;
