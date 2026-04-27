-- =====================================================
-- PHASE J: FATIGUE SNAPSHOTS TABLE
-- =====================================================
-- Stores daily computed fatigue snapshots for fast dashboard loading
-- Created: 2025-01-22

CREATE TABLE IF NOT EXISTS public.fatigue_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  snapshot_date date NOT NULL,
  
  -- Overall fatigue score 0-100 (normalized from local+systemic+connective)
  fatigue_score int NOT NULL DEFAULT 0 CHECK (fatigue_score >= 0 AND fatigue_score <= 100),

  -- Component scores (0-100 each, normalized)
  cns_score int NOT NULL DEFAULT 0 CHECK (cns_score >= 0 AND cns_score <= 100),
  local_score int NOT NULL DEFAULT 0 CHECK (local_score >= 0 AND local_score <= 100),
  joint_score int NOT NULL DEFAULT 0 CHECK (joint_score >= 0 AND joint_score <= 100),

  -- Useful aggregates
  volume_load numeric(10,2) NOT NULL DEFAULT 0,            -- e.g., tonnage sum (weight * reps)
  hard_sets int NOT NULL DEFAULT 0,                        -- Sets with RIR <= 2
  near_failure_sets int NOT NULL DEFAULT 0,                -- Sets with RIR <= 1
  high_fatigue_intensifier_uses int NOT NULL DEFAULT 0,    -- Count of high-fatigue intensifiers used

  -- Breakdown JSON
  muscle_fatigue jsonb NOT NULL DEFAULT '{}'::jsonb,       -- {"chest": 18, "back": 12, ...}
  intensifier_fatigue jsonb NOT NULL DEFAULT '{}'::jsonb,  -- {"rest_pause": 14, "drop_sets": 8, ...}
  notes jsonb NOT NULL DEFAULT '{}'::jsonb,                 -- optional flags, reasons, metadata

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (user_id, snapshot_date)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_fatigue_snapshots_user_date
ON public.fatigue_snapshots (user_id, snapshot_date DESC);

CREATE INDEX IF NOT EXISTS idx_fatigue_snapshots_date
ON public.fatigue_snapshots (snapshot_date DESC);

-- Updated timestamp trigger (reuse standard pattern if exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_fatigue_snapshots_updated_at ON public.fatigue_snapshots;
CREATE TRIGGER update_fatigue_snapshots_updated_at
BEFORE UPDATE ON public.fatigue_snapshots
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- RLS
-- =====================================================
ALTER TABLE public.fatigue_snapshots ENABLE ROW LEVEL SECURITY;

-- Users can view own snapshots
DROP POLICY IF EXISTS "Users can view own fatigue snapshots" ON public.fatigue_snapshots;
CREATE POLICY "Users can view own fatigue snapshots"
ON public.fatigue_snapshots FOR SELECT
USING (auth.uid() = user_id);

-- Users can insert own snapshots
DROP POLICY IF EXISTS "Users can insert own fatigue snapshots" ON public.fatigue_snapshots;
CREATE POLICY "Users can insert own fatigue snapshots"
ON public.fatigue_snapshots FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update own snapshots
DROP POLICY IF EXISTS "Users can update own fatigue snapshots" ON public.fatigue_snapshots;
CREATE POLICY "Users can update own fatigue snapshots"
ON public.fatigue_snapshots FOR UPDATE
USING (auth.uid() = user_id);

-- Coaches can view snapshots of linked clients
DROP POLICY IF EXISTS "Coaches can view client fatigue snapshots" ON public.fatigue_snapshots;
CREATE POLICY "Coaches can view client fatigue snapshots"
ON public.fatigue_snapshots FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.coach_clients cc
    WHERE cc.coach_id = auth.uid()
      AND cc.client_id = fatigue_snapshots.user_id
      AND cc.status = 'active'
  )
);

-- Admins can view all snapshots
DROP POLICY IF EXISTS "Admins can view all fatigue snapshots" ON public.fatigue_snapshots;
CREATE POLICY "Admins can view all fatigue snapshots"
ON public.fatigue_snapshots FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  )
);
