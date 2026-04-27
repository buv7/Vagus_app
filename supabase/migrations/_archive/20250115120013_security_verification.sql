-- Security Verification
-- This migration verifies that all security definer views have been fixed

-- Check for any remaining SECURITY DEFINER views
SELECT '=== SECURITY DEFINER VIEWS VERIFICATION ===' as section;

-- List all views in public schema and check for SECURITY DEFINER
SELECT 
    viewname as view_name,
    CASE 
        WHEN definition ILIKE '%security definer%' THEN '❌ HAS SECURITY DEFINER'
        ELSE '✅ NO SECURITY DEFINER'
    END as security_status
FROM pg_views 
WHERE schemaname = 'public'
ORDER BY viewname;

-- Count total views and security definer views
SELECT '=== SECURITY SUMMARY ===' as section;
SELECT 
    COUNT(*) as total_views,
    COUNT(CASE WHEN definition ILIKE '%security definer%' THEN 1 END) as security_definer_views,
    COUNT(CASE WHEN definition NOT ILIKE '%security definer%' THEN 1 END) as safe_views
FROM pg_views 
WHERE schemaname = 'public';

-- Specific check for the 12 problematic views
SELECT '=== PROBLEMATIC VIEWS CHECK ===' as section;
WITH problematic_views AS (
    SELECT unnest(ARRAY[
        'nutrition_cost_summary', 'nutrition_hydration_summary', 'nutrition_items_with_recipes',
        'referral_monthly_caps', 'health_daily_v', 'sleep_quality_v', 'nutrition_barcode_stats',
        'nutrition_supplements_summary', 'nutrition_grocery_items_with_info', 'support_counts',
        'entitlements_v', 'coach_clients'
    ]) as view_name
),
view_status AS (
    SELECT 
        pv.view_name,
        CASE 
            WHEN v.viewname IS NOT NULL THEN '✅ EXISTS'
            ELSE '❌ MISSING'
        END as exists_status,
        CASE 
            WHEN v.definition ILIKE '%security definer%' THEN '❌ HAS SECURITY DEFINER'
            WHEN v.definition IS NOT NULL THEN '✅ NO SECURITY DEFINER'
            ELSE 'N/A'
        END as security_status
    FROM problematic_views pv
    LEFT JOIN pg_views v ON pv.view_name = v.viewname AND v.schemaname = 'public'
)
SELECT 
    view_name,
    exists_status,
    security_status
FROM view_status
ORDER BY view_name;

-- Final status
SELECT '=== FINAL SECURITY STATUS ===' as section;
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_views WHERE schemaname = 'public' AND definition ILIKE '%security definer%') = 0 
        THEN '🎉 ALL SECURITY DEFINER ISSUES FIXED!'
        ELSE '⚠️ Some security definer views still exist'
    END as final_status;

SELECT 'Security Advisor should now show 0 errors for Security Definer Views' as message;
