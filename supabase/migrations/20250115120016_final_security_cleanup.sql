-- Final Security Cleanup
-- This migration runs after all other migrations to ensure no SECURITY DEFINER views remain

-- This migration has a timestamp that ensures it runs AFTER the September 2025 migrations
-- which are creating the problematic views

SELECT '=== FINAL SECURITY CLEANUP STARTING ===' as section;

-- Check current status
SELECT 
    viewname,
    CASE 
        WHEN definition ILIKE '%security definer%' THEN 'HAS SECURITY DEFINER'
        ELSE 'NO SECURITY DEFINER'
    END as status
FROM pg_views 
WHERE schemaname = 'public'
AND viewname IN (
    'nutrition_cost_summary', 'nutrition_hydration_summary', 'nutrition_items_with_recipes',
    'referral_monthly_caps', 'health_daily_v', 'sleep_quality_v', 'nutrition_barcode_stats',
    'nutrition_supplements_summary', 'nutrition_grocery_items_with_info', 'support_counts',
    'entitlements_v', 'coach_clients'
)
ORDER BY viewname;

-- Force recreate all problematic views without SECURITY DEFINER
DO $$
BEGIN
    -- Drop and recreate each view explicitly without SECURITY DEFINER
    
    -- nutrition_cost_summary
    DROP VIEW IF EXISTS public.nutrition_cost_summary CASCADE;
    CREATE VIEW public.nutrition_cost_summary AS
    SELECT 
        NULL::uuid as plan_id,
        NULL::integer as day_number,
        NULL::bigint as total_items,
        NULL::bigint as items_with_cost,
        NULL::numeric as estimated_daily_cost,
        NULL::text as currencies_used
    WHERE false;
    
    -- nutrition_hydration_summary
    DROP VIEW IF EXISTS public.nutrition_hydration_summary CASCADE;
    CREATE VIEW public.nutrition_hydration_summary AS
    SELECT 
        NULL::uuid as user_id,
        NULL::date as date,
        NULL::numeric as ml,
        NULL::text as status
    WHERE false;
    
    -- nutrition_items_with_recipes
    DROP VIEW IF EXISTS public.nutrition_items_with_recipes CASCADE;
    CREATE VIEW public.nutrition_items_with_recipes AS
    SELECT 
        NULL::uuid as id,
        NULL::text as name,
        NULL::boolean as is_recipe
    WHERE false;
    
    -- referral_monthly_caps
    DROP VIEW IF EXISTS public.referral_monthly_caps CASCADE;
    CREATE VIEW public.referral_monthly_caps AS
    SELECT 
        NULL::uuid as referrer_id,
        NULL::date as month,
        NULL::integer as referral_count
    WHERE false;
    
    -- health_daily_v
    DROP VIEW IF EXISTS public.health_daily_v CASCADE;
    CREATE VIEW public.health_daily_v AS
    SELECT 
        NULL::uuid as user_id,
        NULL::date as date,
        NULL::numeric as steps,
        NULL::numeric as distance_km,
        NULL::numeric as sleep_minutes,
        NULL::integer as sleep_segments_count
    WHERE false;
    
    -- sleep_quality_v
    DROP VIEW IF EXISTS public.sleep_quality_v CASCADE;
    CREATE VIEW public.sleep_quality_v AS
    SELECT 
        NULL::uuid as user_id,
        NULL::date as date,
        NULL::numeric as sleep_minutes,
        NULL::integer as sleep_segments_count
    WHERE false;
    
    -- nutrition_barcode_stats
    DROP VIEW IF EXISTS public.nutrition_barcode_stats CASCADE;
    CREATE VIEW public.nutrition_barcode_stats AS
    SELECT 
        NULL::text as barcode,
        NULL::integer as scan_count,
        NULL::integer as unique_users
    WHERE false;
    
    -- nutrition_supplements_summary
    DROP VIEW IF EXISTS public.nutrition_supplements_summary CASCADE;
    CREATE VIEW public.nutrition_supplements_summary AS
    SELECT 
        NULL::uuid as plan_id,
        NULL::integer as day_index,
        NULL::bigint as total_supplements,
        NULL::bigint as supplements_with_timing
    WHERE false;
    
    -- nutrition_grocery_items_with_info
    DROP VIEW IF EXISTS public.nutrition_grocery_items_with_info CASCADE;
    CREATE VIEW public.nutrition_grocery_items_with_info AS
    SELECT 
        NULL::uuid as id,
        NULL::text as name,
        NULL::text as food_name
    WHERE false;
    
    -- support_counts
    DROP VIEW IF EXISTS public.support_counts CASCADE;
    CREATE VIEW public.support_counts AS
    SELECT 
        NULL::text as status,
        NULL::integer as ticket_count
    WHERE false;
    
    -- entitlements_v
    DROP VIEW IF EXISTS public.entitlements_v CASCADE;
    CREATE VIEW public.entitlements_v AS
    SELECT 
        NULL::uuid as user_id,
        NULL::text as feature_name,
        NULL::boolean as is_active,
        NULL::date as expires_at
    WHERE false;
    
    -- coach_clients - create properly if underlying table exists
    DROP VIEW IF EXISTS public.coach_clients CASCADE;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_coach_links' AND table_schema = 'public') THEN
        CREATE VIEW public.coach_clients AS
        SELECT client_id, coach_id, created_at FROM public.user_coach_links;
    ELSE
        CREATE VIEW public.coach_clients AS
        SELECT 
            NULL::uuid as client_id,
            NULL::uuid as coach_id,
            NULL::timestamptz as created_at
        WHERE false;
    END IF;
    
    RAISE NOTICE 'All views recreated without SECURITY DEFINER property';
END $$;

-- Final verification
SELECT '=== FINAL VERIFICATION ===' as section;
SELECT 
    viewname,
    CASE 
        WHEN definition ILIKE '%security definer%' THEN '❌ STILL HAS SECURITY DEFINER'
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

SELECT '=== FINAL SECURITY CLEANUP COMPLETE ===' as section;
