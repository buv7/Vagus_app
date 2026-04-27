-- Seed 3 starter anti-cringe rules

-- Rule 1: Warn on braggy/negative language
INSERT INTO anti_cringe_rules (
  rule_name,
  rule_type,
  rule_conditions,
  rule_action,
  enabled
) VALUES (
  'warn_braggy_language',
  'warn',
  '{"keywords": ["I''m better than", "weak", "loser"]}'::jsonb,
  '{"message": "Consider using more positive language"}'::jsonb,
  true
) ON CONFLICT (rule_name) DO NOTHING;

-- Rule 2: Modify excessive brag words
INSERT INTO anti_cringe_rules (
  rule_name,
  rule_type,
  rule_conditions,
  rule_action,
  enabled
) VALUES (
  'modify_excessive_brag',
  'modify_share',
  '{"keywords": ["destroyed", "humiliated"]}'::jsonb,
  '{"replacements": {"destroyed": "improved", "humiliated": "progressed"}}'::jsonb,
  true
) ON CONFLICT (rule_name) DO NOTHING;

-- Rule 3: Prevent share with personal medical info
INSERT INTO anti_cringe_rules (
  rule_name,
  rule_type,
  rule_conditions,
  rule_action,
  enabled
) VALUES (
  'prevent_medical_info',
  'prevent_share',
  '{"keywords": ["HIV", "STD", "diagnosis", "psychiatric"]}'::jsonb,
  '{"reason": "Content contains personal medical information and cannot be shared"}'::jsonb,
  true
) ON CONFLICT (rule_name) DO NOTHING;
