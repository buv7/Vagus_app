-- CLUSTER 2: Digestion + Travel/Chaos Control

-- 1) Digestion tracking
CREATE TABLE IF NOT EXISTS digestion_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  digestion_quality INTEGER CHECK (digestion_quality >= 1 AND digestion_quality <= 5),
  bloat_level INTEGER CHECK (bloat_level >= 0 AND bloat_level <= 10),
  bloating_factors TEXT[],
  compliance_score INTEGER CHECK (compliance_score >= 0 AND compliance_score <= 100),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- 2) Travel/chaos modes (macro overrides + context)
CREATE TABLE IF NOT EXISTS travel_modes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  start_date DATE NOT NULL,
  end_date DATE,
  mode TEXT NOT NULL CHECK (mode IN ('travel', 'chaos', 'rest_day', 'normal')),
  location TEXT,
  nutrition_plan_id UUID REFERENCES nutrition_plans(id) ON DELETE SET NULL,
  adapted_macros JSONB,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3) User settings for auto-adaptation
CREATE TABLE IF NOT EXISTS chaos_control_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  auto_adapt_on_chaos BOOLEAN DEFAULT true,
  chaos_detection_enabled BOOLEAN DEFAULT true,
  travel_mode_auto_enable BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

-- RLS
ALTER TABLE digestion_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE travel_modes ENABLE ROW LEVEL SECURITY;
ALTER TABLE chaos_control_settings ENABLE ROW LEVEL SECURITY;

-- digestion_logs policies
DROP POLICY IF EXISTS "Users can view own digestion logs" ON digestion_logs;
DROP POLICY IF EXISTS "Users can insert own digestion logs" ON digestion_logs;
DROP POLICY IF EXISTS "Users can update own digestion logs" ON digestion_logs;
DROP POLICY IF EXISTS "Coaches can view client digestion logs" ON digestion_logs;

CREATE POLICY "Users can view own digestion logs"
ON digestion_logs FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own digestion logs"
ON digestion_logs FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own digestion logs"
ON digestion_logs FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Coaches can view client digestion logs"
ON digestion_logs FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM coach_clients
    WHERE coach_id = auth.uid()
      AND client_id = digestion_logs.user_id
  )
);

-- travel_modes policies
DROP POLICY IF EXISTS "Users can view own travel modes" ON travel_modes;
DROP POLICY IF EXISTS "Users can insert own travel modes" ON travel_modes;
DROP POLICY IF EXISTS "Users can update own travel modes" ON travel_modes;
DROP POLICY IF EXISTS "Coaches can view client travel modes" ON travel_modes;

CREATE POLICY "Users can view own travel modes"
ON travel_modes FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own travel modes"
ON travel_modes FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own travel modes"
ON travel_modes FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Coaches can view client travel modes"
ON travel_modes FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM coach_clients
    WHERE coach_id = auth.uid()
      AND client_id = travel_modes.user_id
  )
);

-- chaos_control_settings policies
DROP POLICY IF EXISTS "Users can view own chaos settings" ON chaos_control_settings;
DROP POLICY IF EXISTS "Users can update own chaos settings" ON chaos_control_settings;
DROP POLICY IF EXISTS "Users can insert own chaos settings" ON chaos_control_settings;

CREATE POLICY "Users can view own chaos settings"
ON chaos_control_settings FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own chaos settings"
ON chaos_control_settings FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own chaos settings"
ON chaos_control_settings FOR UPDATE
USING (auth.uid() = user_id);
