-- CLUSTER 6: Viral Enhancements (Passive Virality + Anti-Cringe + Analytics)

-- 1) Viral events tracking
CREATE TABLE IF NOT EXISTS viral_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN ('share', 'referral', 'view', 'click', 'conversion')),
  event_data JSONB NOT NULL,
  source TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2) Anti-cringe rules (admin-defined)
CREATE TABLE IF NOT EXISTS anti_cringe_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_name TEXT NOT NULL UNIQUE,
  rule_type TEXT NOT NULL CHECK (rule_type IN ('prevent_share', 'modify_share', 'warn')),
  rule_conditions JSONB NOT NULL,
  rule_action JSONB NOT NULL,
  enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3) Viral analytics (daily aggregates)
CREATE TABLE IF NOT EXISTS viral_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value DECIMAL NOT NULL,
  metadata JSONB,
  calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(date, metric_name)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_viral_events_user_time ON viral_events (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_viral_events_type_time ON viral_events (event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_viral_analytics_date ON viral_analytics (date DESC);

-- RLS
ALTER TABLE viral_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE anti_cringe_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE viral_analytics ENABLE ROW LEVEL SECURITY;

-- viral_events policies
DROP POLICY IF EXISTS "Users can view own viral events" ON viral_events;
DROP POLICY IF EXISTS "System can insert viral events" ON viral_events;

CREATE POLICY "Users can view own viral events"
ON viral_events FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "System can insert viral events"
ON viral_events FOR INSERT
WITH CHECK (true); -- System inserts (via service)

-- anti_cringe_rules policies
DROP POLICY IF EXISTS "Admins can view anti-cringe rules" ON anti_cringe_rules;

CREATE POLICY "Admins can view anti-cringe rules"
ON anti_cringe_rules FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- viral_analytics policies
DROP POLICY IF EXISTS "Admins can view viral analytics" ON viral_analytics;

CREATE POLICY "Admins can view viral analytics"
ON viral_analytics FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);
