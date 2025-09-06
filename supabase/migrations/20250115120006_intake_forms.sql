-- Coach Intake Form Builder & Allergy Enforcement
-- Google Forms-like intake forms with mandatory allergy questions

-- Coach intake forms table
CREATE TABLE IF NOT EXISTS public.coach_intake_forms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  schema jsonb NOT NULL, -- form definition (questions, types, required, options)
  updated_at timestamptz DEFAULT now()
);

-- Intake responses table
CREATE TABLE IF NOT EXISTS public.intake_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  form_id uuid REFERENCES public.coach_intake_forms(id) ON DELETE CASCADE,
  client_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  answers jsonb NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Client allergies registry (derived from latest intake or manual edit)
CREATE TABLE IF NOT EXISTS public.client_allergies (
  client_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  foods text[], -- normalized food names
  substances text[], -- drugs/supplements
  updated_at timestamptz DEFAULT now()
);

-- Plan violation counter for allergy enforcement
CREATE TABLE IF NOT EXISTS public.plan_violation_counts (
  id bigserial PRIMARY KEY,
  coach_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  violation_count int NOT NULL DEFAULT 0,
  last_violation_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_coach_intake_forms_coach ON public.coach_intake_forms(coach_id);
CREATE INDEX IF NOT EXISTS idx_intake_responses_form ON public.intake_responses(form_id);
CREATE INDEX IF NOT EXISTS idx_intake_responses_client ON public.intake_responses(client_id);
CREATE INDEX IF NOT EXISTS idx_client_allergies_client ON public.client_allergies(client_id);
CREATE INDEX IF NOT EXISTS idx_plan_violation_counts_coach_client ON public.plan_violation_counts(coach_id, client_id);

-- Updated_at triggers
CREATE OR REPLACE FUNCTION update_coach_intake_forms_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_client_allergies_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_coach_intake_forms_updated_at') THEN
    CREATE TRIGGER trigger_update_coach_intake_forms_updated_at
      BEFORE UPDATE ON public.coach_intake_forms
      FOR EACH ROW
      EXECUTE FUNCTION update_coach_intake_forms_updated_at();
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_client_allergies_updated_at') THEN
    CREATE TRIGGER trigger_update_client_allergies_updated_at
      BEFORE UPDATE ON public.client_allergies
      FOR EACH ROW
      EXECUTE FUNCTION update_client_allergies_updated_at();
  END IF;
END $$;

-- Enable RLS
ALTER TABLE public.coach_intake_forms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intake_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_allergies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_violation_counts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for coach_intake_forms
-- Coach can read/write their own forms
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='coach_intake_forms' AND policyname='cif_rw_own') THEN
    CREATE POLICY cif_rw_own ON public.coach_intake_forms
    FOR ALL
    USING (coach_id = auth.uid())
    WITH CHECK (coach_id = auth.uid());
  END IF;
END $$;

-- Clients can read forms from their coaches
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='coach_intake_forms' AND policyname='cif_read_client') THEN
    CREATE POLICY cif_read_client ON public.coach_intake_forms FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM public.user_coach_links ucl
        WHERE ucl.client_id = auth.uid()
        AND ucl.coach_id = coach_intake_forms.coach_id
      )
    );
  END IF;
END $$;

-- Admins can read all forms
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='coach_intake_forms' AND policyname='cif_admin_read') THEN
    CREATE POLICY cif_admin_read ON public.coach_intake_forms FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('admin', 'superadmin')
      )
    );
  END IF;
END $$;

-- RLS Policies for intake_responses
-- Clients can read/write their own responses
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='intake_responses' AND policyname='ir_rw_own') THEN
    CREATE POLICY ir_rw_own ON public.intake_responses
    FOR ALL
    USING (client_id = auth.uid())
    WITH CHECK (client_id = auth.uid());
  END IF;
END $$;

-- Coaches can read responses for their clients
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='intake_responses' AND policyname='ir_read_coach') THEN
    CREATE POLICY ir_read_coach ON public.intake_responses FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM public.user_coach_links ucl
        WHERE ucl.coach_id = auth.uid()
        AND ucl.client_id = intake_responses.client_id
      )
    );
  END IF;
END $$;

-- Admins can read all responses
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='intake_responses' AND policyname='ir_admin_read') THEN
    CREATE POLICY ir_admin_read ON public.intake_responses FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('admin', 'superadmin')
      )
    );
  END IF;
END $$;

-- RLS Policies for client_allergies
-- Clients can read/write their own allergies
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='client_allergies' AND policyname='ca_rw_own') THEN
    CREATE POLICY ca_rw_own ON public.client_allergies
    FOR ALL
    USING (client_id = auth.uid())
    WITH CHECK (client_id = auth.uid());
  END IF;
END $$;

-- Coaches can read allergies for their clients
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='client_allergies' AND policyname='ca_read_coach') THEN
    CREATE POLICY ca_read_coach ON public.client_allergies FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM public.user_coach_links ucl
        WHERE ucl.coach_id = auth.uid()
        AND ucl.client_id = client_allergies.client_id
      )
    );
  END IF;
END $$;

-- Admins can read all allergies
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='client_allergies' AND policyname='ca_admin_read') THEN
    CREATE POLICY ca_admin_read ON public.client_allergies FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('admin', 'superadmin')
      )
    );
  END IF;
END $$;

-- RLS Policies for plan_violation_counts
-- Coaches can read/write violations for their clients
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='plan_violation_counts' AND policyname='pvc_rw_coach') THEN
    CREATE POLICY pvc_rw_coach ON public.plan_violation_counts
    FOR ALL
    USING (coach_id = auth.uid())
    WITH CHECK (coach_id = auth.uid());
  END IF;
END $$;

-- Admins can read all violations
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='plan_violation_counts' AND policyname='pvc_admin_read') THEN
    CREATE POLICY pvc_admin_read ON public.plan_violation_counts FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('admin', 'superadmin')
      )
    );
  END IF;
END $$;
