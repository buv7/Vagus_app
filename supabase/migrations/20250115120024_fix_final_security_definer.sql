-- Fix Final Security Definer View Issue
-- This migration fixes the last security_definer_view error

SELECT '=== FIXING FINAL SECURITY DEFINER VIEW ===' as section;

-- ========================================
-- FIX SECURITY_RECOMMENDATIONS VIEW
-- ========================================

-- Drop the security_recommendations view that has SECURITY DEFINER
DROP VIEW IF EXISTS public.security_recommendations CASCADE;

-- Recreate it as a simple view without SECURITY DEFINER
CREATE OR REPLACE VIEW public.security_recommendations AS
SELECT 
    'auth_otp_expiry' as recommendation_type,
    'Set OTP expiry to less than 1 hour' as description,
    'Go to Authentication → Settings and set OTP expiry to 15-30 minutes' as action_required,
    'HIGH' as priority
UNION ALL
SELECT 
    'auth_leaked_password_protection' as recommendation_type,
    'Enable leaked password protection' as description,
    'Go to Authentication → Settings → Password Security and enable leaked password protection' as action_required,
    'HIGH' as priority
UNION ALL
SELECT 
    'function_search_path' as recommendation_type,
    'All functions now have secure search_path settings' as description,
    'No action required - functions have been secured' as action_required,
    'RESOLVED' as priority
UNION ALL
SELECT 
    'extensions_schema' as recommendation_type,
    'Extensions moved to dedicated schema' as description,
    'No action required - extensions are now in extensions schema' as action_required,
    'RESOLVED' as priority;

-- Grant select permission on the view
GRANT SELECT ON public.security_recommendations TO authenticated;

-- ========================================
-- VERIFY NO MORE SECURITY DEFINER VIEWS
-- ========================================

-- Check if there are any remaining security definer views
SELECT '=== CHECKING FOR REMAINING SECURITY DEFINER VIEWS ===' as section;

SELECT 
    schemaname,
    viewname,
    CASE 
        WHEN definition ILIKE '%security definer%' THEN '❌ Has SECURITY DEFINER'
        ELSE '✅ No SECURITY DEFINER'
    END as security_status
FROM pg_views 
WHERE schemaname = 'public'
ORDER BY viewname;

SELECT '=== FINAL SECURITY DEFINER VIEW FIX COMPLETE ===' as section;
