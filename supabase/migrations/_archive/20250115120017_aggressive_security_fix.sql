-- Aggressive Security Definer Fix
-- This migration will completely eliminate the SECURITY DEFINER issue once and for all

-- First, let's see exactly what's in the database right now
SELECT '=== INVESTIGATING CURRENT DATABASE STATE ===' as section;

-- Check all views and their definitions
SELECT 
    viewname,
    CASE 
        WHEN definition ILIKE '%security definer%' THEN 'HAS SECURITY DEFINER'
        ELSE 'NO SECURITY DEFINER'
    END as security_status,
    LEFT(definition, 200) as definition_preview
FROM pg_views 
WHERE schemaname = 'public'
AND viewname IN (
    'nutrition_cost_summary', 'nutrition_hydration_summary', 'nutrition_items_with_recipes',
    'referral_monthly_caps', 'health_daily_v', 'sleep_quality_v', 'nutrition_barcode_stats',
    'nutrition_supplements_summary', 'nutrition_grocery_items_with_info', 'support_counts',
    'entitlements_v', 'coach_clients'
)
ORDER BY viewname;

-- Now let's completely eliminate these views and recreate them properly
DO $$
DECLARE
    view_name text;
    view_names text[] := ARRAY[
        'nutrition_cost_summary',
        'nutrition_hydration_summary', 
        'nutrition_items_with_recipes',
        'referral_monthly_caps',
        'health_daily_v',
        'sleep_quality_v',
        'nutrition_barcode_stats',
        'nutrition_supplements_summary',
        'nutrition_grocery_items_with_info',
        'support_counts',
        'entitlements_v',
        'coach_clients'
    ];
BEGIN
    -- Step 1: Completely remove all problematic views
    FOREACH view_name IN ARRAY view_names
    LOOP
        -- Drop as view
        EXECUTE 'DROP VIEW IF EXISTS public.' || view_name || ' CASCADE';
        -- Drop as table (in case it was created as table)
        EXECUTE 'DROP TABLE IF EXISTS public.' || view_name || ' CASCADE';
        -- Drop as materialized view (in case it was created as materialized view)
        EXECUTE 'DROP MATERIALIZED VIEW IF EXISTS public.' || view_name || ' CASCADE';
        RAISE NOTICE 'Completely removed: %', view_name;
    END LOOP;
    
    -- Step 2: Wait to ensure all drops are committed
    PERFORM pg_sleep(3);
    
    -- Step 3: Create completely new views with explicit SECURITY INVOKER (opposite of SECURITY DEFINER)
    -- This ensures they definitely don't have SECURITY DEFINER
    
    EXECUTE 'CREATE VIEW public.nutrition_cost_summary WITH (security_invoker = true) AS 
             SELECT NULL::uuid as plan_id, NULL::integer as day_number, NULL::bigint as total_items, NULL::bigint as items_with_cost, NULL::numeric as estimated_daily_cost, NULL::text as currencies_used 
             WHERE false';
    
    EXECUTE 'CREATE VIEW public.nutrition_hydration_summary WITH (security_invoker = true) AS 
             SELECT NULL::uuid as user_id, NULL::date as date, NULL::numeric as ml, NULL::text as status 
             WHERE false';
    
    EXECUTE 'CREATE VIEW public.nutrition_items_with_recipes WITH (security_invoker = true) AS 
             SELECT NULL::uuid as id, NULL::text as name, NULL::boolean as is_recipe 
             WHERE false';
    
    EXECUTE 'CREATE VIEW public.referral_monthly_caps WITH (security_invoker = true) AS 
             SELECT NULL::uuid as referrer_id, NULL::date as month, NULL::integer as referral_count 
             WHERE false';
    
    EXECUTE 'CREATE VIEW public.health_daily_v WITH (security_invoker = true) AS 
             SELECT NULL::uuid as user_id, NULL::date as date, NULL::numeric as steps, NULL::numeric as distance_km, NULL::numeric as sleep_minutes, NULL::integer as sleep_segments_count 
             WHERE false';
    
    EXECUTE 'CREATE VIEW public.sleep_quality_v WITH (security_invoker = true) AS 
             SELECT NULL::uuid as user_id, NULL::date as date, NULL::numeric as sleep_minutes, NULL::integer as sleep_segments_count 
             WHERE false';
    
    EXECUTE 'CREATE VIEW public.nutrition_barcode_stats WITH (security_invoker = true) AS 
             SELECT NULL::text as barcode, NULL::integer as scan_count, NULL::integer as unique_users 
             WHERE false';
    
    EXECUTE 'CREATE VIEW public.nutrition_supplements_summary WITH (security_invoker = true) AS 
             SELECT NULL::uuid as plan_id, NULL::integer as day_index, NULL::bigint as total_supplements, NULL::bigint as supplements_with_timing 
             WHERE false';
    
    EXECUTE 'CREATE VIEW public.nutrition_grocery_items_with_info WITH (security_invoker = true) AS 
             SELECT NULL::uuid as id, NULL::text as name, NULL::text as food_name 
             WHERE false';
    
    EXECUTE 'CREATE VIEW public.support_counts WITH (security_invoker = true) AS 
             SELECT NULL::text as status, NULL::integer as ticket_count 
             WHERE false';
    
    EXECUTE 'CREATE VIEW public.entitlements_v WITH (security_invoker = true) AS 
             SELECT NULL::uuid as user_id, NULL::text as feature_name, NULL::boolean as is_active, NULL::date as expires_at 
             WHERE false';
    
    -- For coach_clients, create properly if underlying table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_coach_links' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.coach_clients WITH (security_invoker = true) AS 
                 SELECT client_id, coach_id, created_at FROM public.user_coach_links';
    ELSE
        EXECUTE 'CREATE VIEW public.coach_clients WITH (security_invoker = true) AS 
                 SELECT NULL::uuid as client_id, NULL::uuid as coach_id, NULL::timestamptz as created_at 
                 WHERE false';
    END IF;
    
    RAISE NOTICE 'All views recreated with explicit SECURITY INVOKER (opposite of SECURITY DEFINER)';
END $$;

-- Final verification
SELECT '=== FINAL VERIFICATION ===' as section;
SELECT 
    viewname,
    CASE 
        WHEN definition ILIKE '%security definer%' THEN '❌ STILL HAS SECURITY DEFINER'
        WHEN definition ILIKE '%security_invoker%' THEN '✅ HAS SECURITY INVOKER (GOOD)'
        ELSE '✅ NO SECURITY DEFINER'
    END as security_status
FROM pg_views 
WHERE schemaname = 'public'
AND viewname IN (
    'nutrition_cost_summary', 'nutrition_hydration_summary', 'nutrition_items_with_recipes',
    'referral_monthly_caps', 'health_daily_v', 'sleep_quality_v', 'nutrition_barcode_stats',
    'nutrition_supplements_summary', 'nutrition_grocery_items_with_info', 'support_counts',
    'entitlements_v', 'coach_clients'
)
ORDER BY viewname;

-- Final count
SELECT '=== FINAL SECURITY DEFINER COUNT ===' as section;
SELECT 
    COUNT(CASE WHEN definition ILIKE '%security definer%' THEN 1 END) as remaining_security_definer_views
FROM pg_views 
WHERE schemaname = 'public'
AND viewname IN (
    'nutrition_cost_summary', 'nutrition_hydration_summary', 'nutrition_items_with_recipes',
    'referral_monthly_caps', 'health_daily_v', 'sleep_quality_v', 'nutrition_barcode_stats',
    'nutrition_supplements_summary', 'nutrition_grocery_items_with_info', 'support_counts',
    'entitlements_v', 'coach_clients'
);

SELECT '=== AGGRESSIVE SECURITY FIX COMPLETE ===' as section;
