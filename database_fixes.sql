-- VAGUS Database Fixes
-- Based on verification results from October 1, 2025
-- Apply these fixes to address security and schema issues

-- ============================================================
-- PRIORITY 1: CRITICAL SECURITY FIX
-- ============================================================

-- Fix 1: Add RLS to support_tickets (CRITICAL)
-- Current State: Table has no RLS, user support data exposed
-- Risk Level: HIGH

ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY support_tickets_user_access ON support_tickets
  FOR ALL
  USING (
    -- Users can access their own tickets
    auth.uid() = user_id
    OR
    -- Admins can access all tickets
    (auth.jwt() ->> 'role' = 'admin')
    OR
    -- Support staff can access all tickets
    (auth.jwt() ->> 'role' = 'support')
  );

COMMENT ON POLICY support_tickets_user_access ON support_tickets IS
  'Users can view/edit their own tickets. Admins and support staff can access all tickets.';

-- ============================================================
-- PRIORITY 2: OPTIONAL SECURITY IMPROVEMENTS
-- ============================================================

-- Fix 2: Add RLS to saved_views (if it contains user-specific data)
-- Uncomment if saved_views is user-specific, otherwise leave as is

-- ALTER TABLE saved_views ENABLE ROW LEVEL SECURITY;
--
-- CREATE POLICY saved_views_user_access ON saved_views
--   FOR ALL
--   USING (auth.uid() = user_id);
--
-- COMMENT ON POLICY saved_views_user_access ON saved_views IS
--   'Users can only access their own saved views.';

-- Fix 3: Add RLS to archive tables (defense-in-depth)
-- Optional: Archive tables are likely read-only, but RLS adds extra security

-- ALTER TABLE nutrition_meals_archive ENABLE ROW LEVEL SECURITY;
--
-- CREATE POLICY nutrition_meals_archive_access ON nutrition_meals_archive
--   FOR SELECT
--   USING (
--     auth.uid() = user_id
--     OR (auth.jwt() ->> 'role' = 'admin')
--   );

-- ALTER TABLE nutrition_plans_archive ENABLE ROW LEVEL SECURITY;
--
-- CREATE POLICY nutrition_plans_archive_access ON nutrition_plans_archive
--   FOR SELECT
--   USING (
--     auth.uid() = user_id
--     OR (auth.jwt() ->> 'role' = 'admin')
--   );

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

-- Verify RLS is enabled on support_tickets
SELECT
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'support_tickets';

-- Verify policy was created
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'support_tickets';

-- Check all tables without RLS (should be 4 now, down from 5)
SELECT
  tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = false
ORDER BY tablename;

-- Overall RLS coverage (should be ~97% now)
SELECT
  COUNT(*) FILTER (WHERE rowsecurity = true) as tables_with_rls,
  COUNT(*) FILTER (WHERE rowsecurity = false) as tables_without_rls,
  COUNT(*) as total,
  ROUND(
    (COUNT(*) FILTER (WHERE rowsecurity = true)::numeric / COUNT(*)::numeric) * 100,
    1
  ) as coverage_percent
FROM pg_tables
WHERE schemaname = 'public';

-- ============================================================
-- NOTES
-- ============================================================

-- 1. support_tickets RLS fix is CRITICAL and should be applied immediately
--
-- 2. After applying this fix, RLS coverage will improve from 96.9% to ~97.5%
--
-- 3. The remaining tables without RLS are:
--    - nutrition_meals_archive (archive table, low risk)
--    - nutrition_plans_archive (archive table, low risk)
--    - saved_views (need to determine if user-specific)
--    - sla_policies (global config table, acceptable)
--
-- 4. Test the support_tickets policy after applying:
--    - As a user, try to query support_tickets
--    - Verify you only see your own tickets
--    - As admin, verify you can see all tickets
--
-- 5. Monitor application logs for RLS-related errors after deployment
--
-- ============================================================

-- End of database fixes
