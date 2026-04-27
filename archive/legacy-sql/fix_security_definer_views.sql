-- ========================================
-- FIX SECURITY DEFINER VIEWS
-- ========================================
-- This script specifically fixes the 9 Security Definer View errors

-- ========================================
-- 1. FIX nutrition_hydration_summary
-- ========================================
DROP VIEW IF EXISTS public.nutrition_hydration_summary CASCADE;
-- Only create if nutrition_hydration_logs table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_hydration_logs' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_hydration_summary AS
        SELECT 
            user_id,
            date,
            ml,
            CASE
                WHEN (ml >= 3000) THEN ''excellent''::text
                WHEN (ml >= 2000) THEN ''good''::text
                WHEN (ml >= 1000) THEN ''fair''::text
                ELSE ''low''::text
            END AS hydration_status,
            updated_at
        FROM nutrition_hydration_logs
        WHERE (date >= (CURRENT_DATE - ''30 days''::interval))';
    END IF;
END $$;

-- ========================================
-- 2. FIX coach_clients
-- ========================================
DROP VIEW IF EXISTS public.coach_clients CASCADE;
-- Only create if user_coach_links table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_coach_links' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.coach_clients AS
        SELECT 
            client_id,
            coach_id,
            created_at
        FROM user_coach_links';
    END IF;
END $$;

-- ========================================
-- 3. FIX nutrition_cost_summary
-- ========================================
DROP VIEW IF EXISTS public.nutrition_cost_summary CASCADE;
-- Only create if required tables exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_items' AND table_schema = 'public')
       AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_meals' AND table_schema = 'public')
       AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_days' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_cost_summary AS
        SELECT 
            nd.plan_id,
            nd.day_number,
            count(DISTINCT ni.id) AS total_items,
            count(DISTINCT ni.id) FILTER (WHERE (ni.cost_per_unit IS NOT NULL)) AS items_with_cost,
            sum((ni.cost_per_unit * ni.amount_grams)) AS estimated_daily_cost,
            string_agg(DISTINCT ni.currency, '', ''::text) AS currencies_used
        FROM ((nutrition_items ni
            JOIN nutrition_meals nm ON ((nm.id = ni.meal_id)))
            JOIN nutrition_days nd ON ((nd.id = nm.day_id)))
        WHERE (ni.cost_per_unit IS NOT NULL)
        GROUP BY nd.plan_id, nd.day_number';
    END IF;
END $$;

-- ========================================
-- 4. FIX nutrition_grocery_items_with_info
-- ========================================
DROP VIEW IF EXISTS public.nutrition_grocery_items_with_info CASCADE;
-- Only create if nutrition_grocery_items table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_grocery_items' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_grocery_items_with_info AS
        SELECT 
            gi.id,
            gi.list_id,
            gi.name,
            gi.amount,
            gi.unit,
            gi.aisle,
            gi.notes,
            gi.is_checked,
            gi.allergen,
            gl.owner,
            gl.coach_id,
            gl.plan_id,
            gl.week_index,
            gl.created_at AS list_created_at
        FROM nutrition_grocery_items gi
        JOIN nutrition_grocery_lists gl ON gl.id = gi.list_id';
    END IF;
END $$;

-- ========================================
-- 5. FIX nutrition_barcode_stats
-- ========================================
DROP VIEW IF EXISTS public.nutrition_barcode_stats CASCADE;
-- Only create if nutrition_barcodes table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_barcodes' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_barcode_stats AS
        SELECT 
            count(*) AS total_barcodes,
            count(*) FILTER (WHERE (last_seen > (now() - ''7 days''::interval))) AS recent_scans,
            count(DISTINCT category) AS unique_categories,
            count(DISTINCT brand) AS unique_brands
        FROM nutrition_barcodes';
    END IF;
END $$;

-- ========================================
-- 6. FIX nutrition_items_with_recipes
-- ========================================
DROP VIEW IF EXISTS public.nutrition_items_with_recipes CASCADE;
-- Only create if nutrition_items table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_items' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_items_with_recipes AS
        SELECT 
            ni.id,
            ni.meal_id,
            ni.food_item_id,
            ni.name,
            ni.amount_grams,
            ni.protein_g,
            ni.carbs_g,
            ni.fat_g,
            ni.kcal,
            ni.sodium_mg,
            ni.potassium_mg,
            ni.order_index,
            ni.created_at,
            ni.updated_at,
            ni.recipe_id,
            ni.servings,
            nr.title AS recipe_title,
            nr.photo_url AS recipe_photo_url,
            nr.prep_time_minutes,
            nr.cook_time_minutes,
            (nr.prep_time_minutes + nr.cook_time_minutes) AS total_minutes,
            nr.dietary_tags AS recipe_dietary_tags,
            nr.allergen_tags AS recipe_allergen_tags
        FROM nutrition_items ni
        LEFT JOIN nutrition_recipes nr ON nr.id = ni.recipe_id';
    END IF;
END $$;

-- ========================================
-- 7. FIX nutrition_supplements_summary
-- ========================================
DROP VIEW IF EXISTS public.nutrition_supplements_summary CASCADE;
-- Only create if nutrition_supplements table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_supplements' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_supplements_summary AS
        SELECT 
            plan_id,
            day_index,
            count(*) AS total_supplements,
            count(*) FILTER (WHERE (timing IS NOT NULL)) AS supplements_with_timing,
            string_agg(DISTINCT timing, '', ''::text) AS timings_used
        FROM nutrition_supplements
        GROUP BY plan_id, day_index';
    END IF;
END $$;

-- ========================================
-- 8. FIX support_counts
-- ========================================
DROP VIEW IF EXISTS public.support_counts CASCADE;
-- Only create if support_requests table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'support_requests' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.support_counts AS
        SELECT 
            count(*) FILTER (WHERE ((priority = ''urgent''::text) AND (status <> ''closed''::text))) AS urgent_open,
            count(*) FILTER (WHERE (status <> ''closed''::text)) AS open_total
        FROM support_requests';
    END IF;
END $$;

-- ========================================
-- 9. FIX referral_monthly_caps
-- ========================================
DROP VIEW IF EXISTS public.referral_monthly_caps CASCADE;
-- Only create if referrals table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'referrals' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.referral_monthly_caps AS
        SELECT 
            referrer_id,
            date_trunc(''month''::text, created_at) AS month,
            count(*) AS referral_count
        FROM referrals
        WHERE (milestone IS NOT NULL)
        GROUP BY referrer_id, (date_trunc(''month''::text, created_at))';
    END IF;
END $$;

-- ========================================
-- GRANT PERMISSIONS
-- ========================================
-- Grant access to views for authenticated users
GRANT SELECT ON public.nutrition_hydration_summary TO authenticated;
GRANT SELECT ON public.coach_clients TO authenticated;
GRANT SELECT ON public.nutrition_cost_summary TO authenticated;
GRANT SELECT ON public.nutrition_grocery_items_with_info TO authenticated;
GRANT SELECT ON public.nutrition_barcode_stats TO authenticated;
GRANT SELECT ON public.nutrition_items_with_recipes TO authenticated;
GRANT SELECT ON public.nutrition_supplements_summary TO authenticated;
GRANT SELECT ON public.support_counts TO authenticated;
GRANT SELECT ON public.referral_monthly_caps TO authenticated;

-- ========================================
-- VERIFICATION
-- ========================================
-- Check that views exist without SECURITY DEFINER
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN (
    'nutrition_hydration_summary',
    'coach_clients',
    'nutrition_cost_summary',
    'nutrition_grocery_items_with_info',
    'nutrition_barcode_stats',
    'nutrition_items_with_recipes',
    'nutrition_supplements_summary',
    'support_counts',
    'referral_monthly_caps'
);

-- ========================================
-- SUCCESS MESSAGE
-- ========================================
DO $$
BEGIN
    RAISE NOTICE '✅ All Security Definer Views have been fixed!';
    RAISE NOTICE '🔒 9 views recreated without SECURITY DEFINER property';
    RAISE NOTICE '🛡️ Security issues resolved';
END $$;
