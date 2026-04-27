-- CLUSTER 5: Meta-Admin + Compliance/Export + Safety Layer

-- 1) Admin hierarchy (meta-admin levels 1-5)
CREATE TABLE IF NOT EXISTS admin_hierarchy (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  level INTEGER NOT NULL CHECK (level >= 1 AND level <= 5),
  parent_admin_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  permissions JSONB DEFAULT '{}'::jsonb,
  assigned_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(admin_id)
);

CREATE INDEX IF NOT EXISTS idx_admin_hierarchy_level ON admin_hierarchy(level);
CREATE INDEX IF NOT EXISTS idx_admin_hierarchy_parent ON admin_hierarchy(parent_admin_id);

-- 2) Compliance reports (GDPR, data export, audit)
CREATE TABLE IF NOT EXISTS compliance_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_type TEXT NOT NULL CHECK (report_type IN ('gdpr', 'data_export', 'audit', 'user_data')),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  generated_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  report_data JSONB NOT NULL,
  file_path TEXT,
  file_url TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'generating', 'completed', 'failed')),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_compliance_reports_type ON compliance_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_compliance_reports_user ON compliance_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_compliance_reports_status ON compliance_reports(status);

-- 3) Safety layer rules (prevent destructive actions)
CREATE TABLE IF NOT EXISTS safety_layer_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_name TEXT NOT NULL UNIQUE,
  action_pattern TEXT NOT NULL,
  conditions JSONB NOT NULL,
  action_on_match TEXT NOT NULL CHECK (action_on_match IN ('block', 'require_approval', 'warn')),
  approval_required_level INTEGER DEFAULT 5 CHECK (approval_required_level >= 1 AND approval_required_level <= 5),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_safety_rules_active ON safety_layer_rules(is_active, action_pattern);

-- 4) Safety layer audit (log every trigger)
CREATE TABLE IF NOT EXISTS safety_layer_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_id UUID REFERENCES safety_layer_rules(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  payload JSONB NOT NULL,
  actor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  result TEXT NOT NULL CHECK (result IN ('allowed', 'blocked', 'requires_approval', 'warned')),
  reason TEXT,
  approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_safety_audit_actor ON safety_layer_audit(actor_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_safety_audit_result ON safety_layer_audit(result, created_at DESC);

-- RLS
ALTER TABLE admin_hierarchy ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_layer_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_layer_audit ENABLE ROW LEVEL SECURITY;

-- admin_hierarchy policies (admin-only)
DROP POLICY IF EXISTS "Admins can view hierarchy" ON admin_hierarchy;
DROP POLICY IF EXISTS "Admins can manage hierarchy" ON admin_hierarchy;

CREATE POLICY "Admins can view hierarchy"
ON admin_hierarchy FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

CREATE POLICY "Admins can manage hierarchy"
ON admin_hierarchy FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- compliance_reports policies (admin-only, users can view their own)
DROP POLICY IF EXISTS "Admins can view all compliance reports" ON compliance_reports;
DROP POLICY IF EXISTS "Users can view own compliance reports" ON compliance_reports;
DROP POLICY IF EXISTS "Admins can create compliance reports" ON compliance_reports;

CREATE POLICY "Admins can view all compliance reports"
ON compliance_reports FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
  OR user_id = auth.uid()
);

CREATE POLICY "Admins can create compliance reports"
ON compliance_reports FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- safety_layer_rules policies (admin-only)
DROP POLICY IF EXISTS "Admins can view safety rules" ON safety_layer_rules;
DROP POLICY IF EXISTS "Admins can manage safety rules" ON safety_layer_rules;

CREATE POLICY "Admins can view safety rules"
ON safety_layer_rules FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

CREATE POLICY "Admins can manage safety rules"
ON safety_layer_rules FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- safety_layer_audit policies (admin-only)
DROP POLICY IF EXISTS "Admins can view safety audit" ON safety_layer_audit;
DROP POLICY IF EXISTS "System can insert safety audit" ON safety_layer_audit;

CREATE POLICY "Admins can view safety audit"
ON safety_layer_audit FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

CREATE POLICY "System can insert safety audit"
ON safety_layer_audit FOR INSERT
WITH CHECK (true); -- System inserts (via service)
