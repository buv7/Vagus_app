-- Seed 3 starter safety rules for testing

-- Rule 1: Prevent role escalation to admin
INSERT INTO safety_layer_rules (
  rule_name,
  action_pattern,
  conditions,
  action_on_match,
  approval_required_level,
  is_active
) VALUES (
  'prevent_admin_role_escalation',
  'update_user_role',
  '{"new_role": "admin"}'::jsonb,
  'block',
  5,
  true
) ON CONFLICT (rule_name) DO NOTHING;

-- Rule 2: Require approval for disabling users
INSERT INTO safety_layer_rules (
  rule_name,
  action_pattern,
  conditions,
  action_on_match,
  approval_required_level,
  is_active
) VALUES (
  'require_approval_disable_user',
  'disable_user',
  '{"enabled": false}'::jsonb,
  'require_approval',
  3,
  true
) ON CONFLICT (rule_name) DO NOTHING;

-- Rule 3: Warn on AI usage reset (simple payload check)
INSERT INTO safety_layer_rules (
  rule_name,
  action_pattern,
  conditions,
  action_on_match,
  approval_required_level,
  is_active
) VALUES (
  'warn_ai_usage_reset',
  'reset_user_ai_usage',
  '{}'::jsonb,
  'warn',
  1,
  true
) ON CONFLICT (rule_name) DO NOTHING;
